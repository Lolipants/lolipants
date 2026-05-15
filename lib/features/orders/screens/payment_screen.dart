import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/orders/models/checkout_draft.dart';
import 'package:lolipants/features/orders/models/order_design_draft.dart';
import 'package:lolipants/features/orders/providers/checkout_providers.dart';
import 'package:lolipants/features/orders/providers/orders_providers.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/error_banner.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Step-4 checkout screen. Calls `POST /orders` (idempotent), then
/// `POST /payments/intent`, then confirms via **manual Tap token entry** in
/// release builds or the server-side sandbox path in debug / mock mode.
/// The Tap Flutter SDK is intentionally not bundled until product requests it.
/// All three requests share the draft's [CheckoutDraft.idempotencyKey] so a
/// retry never creates two orders.
class PaymentScreen extends ConsumerStatefulWidget {
  /// Default constructor.
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _expanded = false;
  bool _processing = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(checkoutDraftProvider);
    if (draft == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment')),
        body: const Center(
          child: Text('Checkout session expired. Please restart.'),
        ),
      );
    }
    final quote = draft.quote;
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              _PriceCard(
                draft: draft,
                expanded: _expanded,
                onToggle: () => setState(() => _expanded = !_expanded),
              ),
              const SizedBox(height: AppSpacing.md),
              _DesignFabricSummary(design: draft.design),
              const SizedBox(height: AppSpacing.lg),
              if (_errorMessage != null) ...[
                ErrorBanner(
                  message: _errorMessage!,
                  onDismiss: () => setState(() => _errorMessage = null),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.stone,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pay with card', style: AppTextStyles.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      kFeatureMockPayment
                          ? 'Demo payment mode is active. No real card will be '
                              'charged in this build.'
                          : 'Card payments: this build collects a Tap-compatible '
                              'token manually (no Tap Flutter SDK). Your card '
                              'details never touch our servers.',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              LolipantsButton(
                label: _processing
                    ? 'Processing...'
                    : quote == null
                        ? 'Pricing unavailable'
                        : 'Pay ${quote.total} ${quote.currency}',
                onPressed:
                    _processing || quote == null ? null : () => _pay(draft),
              ),
              const SizedBox(height: AppSpacing.sm),
              LolipantsButton(
                label: 'Back',
                variant: LolipantsButtonVariant.secondary,
                onPressed: _processing ? null : () => context.pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pay(CheckoutDraft draft) async {
    setState(() {
      _processing = true;
      _errorMessage = null;
    });
    // First order of business: ask for push permission if we haven't yet, so
    // transactional notifications are available. Silent on refusal.
    await _ensurePushRegistered();
    final ordersRepo = ref.read(ordersRepositoryProvider);
    final paymentsRepo = ref.read(paymentsRepositoryProvider);
    final designId = draft.design.designId;
    if (designId == null || designId.isEmpty) {
      _fail('Please save the design before ordering.');
      return;
    }

    final orderResult = await ordersRepo.createOrder(
      designId: designId,
      deliveryAddress: draft.address,
      deliveryCity: draft.city,
      deliveryPhone: draft.phone,
      deliveryNotes: draft.notes,
      idempotencyKey: draft.idempotencyKey,
      designerId: draft.design.designerId,
    );
    final orderOrError = orderResult.fold<String>(
      (e) => orderErrorMessage(e, fallback: 'Could not create order.'),
      (_) => '',
    );
    if (orderOrError.isNotEmpty) {
      _fail(orderOrError);
      return;
    }
    final order = orderResult.toNullable();
    if (order == null) {
      _fail('Order creation returned no payload.');
      return;
    }
    ref.read(checkoutDraftProvider.notifier).state =
        draft.copyWith(orderId: order.id);

    final intentResult = await paymentsRepo.createIntent(
      orderId: order.id,
      idempotencyKey: draft.idempotencyKey,
    );
    final intentError = intentResult.fold<String>(
      (e) => orderErrorMessage(e, fallback: 'Could not start payment.'),
      (_) => '',
    );
    if (intentError.isNotEmpty) {
      _fail(intentError);
      return;
    }
    final intent = intentResult.toNullable();
    if (intent == null) {
      _fail('Payment intent returned no payload.');
      return;
    }
    ref.read(checkoutDraftProvider.notifier).state = (ref
                .read(checkoutDraftProvider) ??
            draft)
        .copyWith(paymentReference: intent.reference);

    // Request a Tap SDK token. In release builds this calls the first-party
    // Tap Flutter widget; in debug builds we fall back to the server-side
    // sandbox path so dev flows don't need a Tap merchant account.
    final tapToken = await _requestTapToken();
    if (tapToken == null) {
      _fail('Payment was cancelled.');
      return;
    }

    final chargeResult = tapToken == _kSandboxToken
        ? await paymentsRepo.sandboxConfirm(paymentReference: intent.reference)
        : await paymentsRepo.confirmWithToken(
            paymentReference: intent.reference,
            tapToken: tapToken,
            idempotencyKey: draft.idempotencyKey,
          );
    final chargeError = chargeResult.fold<String>(
      (e) => orderErrorMessage(e, fallback: 'Payment could not be captured.'),
      (_) => '',
    );
    if (chargeError.isNotEmpty) {
      _fail(chargeError);
      return;
    }

    if (!mounted) return;
    unawaited(ref.read(myOrdersProvider.notifier).reload());
    context.go('/order/confirmed/${order.id}');
  }

  /// Wraps Tap token collection behind a single call. In debug builds we
  /// short-circuit to the sandbox token so local smoke tests do not require
  /// provider credentials.
  ///
  /// In mock-payment reviewer builds (`FEATURE_MOCK_PAYMENT=true`) this also
  /// uses the sandbox token and skips manual token entry.
  ///
  /// In non-mock release builds we collect the provider token produced by the
  /// Tap card flow and pass it to `POST /payments/confirm`.
  Future<String?> _requestTapToken() async {
    if (kDebugMode || kFeatureMockPayment) {
      return _kSandboxToken;
    }
    final token = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _TapTokenEntrySheet(),
    );
    return token;
  }

  /// Requests notification permission (first order only) and registers the
  /// resulting OneSignal player id with the backend. Any failure is logged
  /// but the payment flow continues.
  Future<void> _ensurePushRegistered() async {
    final settings = ref.read(settingsProvider);
    if (settings.pushEnabled) return;
    await ref.read(settingsProvider.notifier).applyPushPreference(
          want: true,
          requestOsPermission: true,
          persistWhenOneSignalMissing: true,
        );
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _processing = false;
      _errorMessage = message;
    });
  }
}

class _DesignFabricSummary extends StatelessWidget {
  const _DesignFabricSummary({required this.design});

  final OrderDesignDraft design;

  @override
  Widget build(BuildContext context) {
    final rawId = design.fabricId?.trim();
    if (rawId == null || rawId.isEmpty) {
      return const SizedBox.shrink();
    }
    final q = design.fabricQuality?.trim();
    final line = (q == null || q.isEmpty)
        ? rawId
        : '$rawId · ${q.replaceAll('_', ' ')}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.smoke,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fabric', style: AppTextStyles.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(line, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({
    required this.draft,
    required this.expanded,
    required this.onToggle,
  });

  final CheckoutDraft draft;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final quote = draft.quote;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.smoke,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  quote == null
                      ? 'Fetching price...'
                      : 'Total: ${quote.total} ${quote.currency}',
                  style: AppTextStyles.titleMedium,
                ),
              ),
              TextButton(
                onPressed: quote == null ? null : onToggle,
                child: Text(expanded ? 'Hide' : 'Details'),
              ),
            ],
          ),
          if (expanded && quote != null) ...[
            const Divider(),
            _Line(label: 'Base garment', amount: '${quote.basePrice}'),
            _Line(label: 'Fabric', amount: '${quote.fabricFee}'),
            _Line(
              label: 'Delivery (${quote.city})',
              amount: '${quote.deliveryFee}',
            ),
          ],
        ],
      ),
    );
  }
}

/// Sentinel token used when the debug sandbox path should confirm the
/// payment without contacting Tap.
const String _kSandboxToken = '__sandbox__';

/// Release token handoff modal.
///
/// This keeps payment confirmation production-safe on the server side while
/// we pass through the token returned by the provider card flow.
class _TapTokenEntrySheet extends StatefulWidget {
  const _TapTokenEntrySheet();

  @override
  State<_TapTokenEntrySheet> createState() => _TapTokenEntrySheetState();
}

class _TapTokenEntrySheetState extends State<_TapTokenEntrySheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final token = _controller.text.trim();
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Complete Tap payment', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Paste the Tap token generated by the card widget/session. '
            'The app sends only this token to Lolipants API for capture.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Tap token',
              hintText: 'tok_xxx or src_xxx',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.lg),
          LolipantsButton(
            label: 'Confirm token',
            onPressed: token.isEmpty
                ? null
                : () => Navigator.of(context).pop(token),
          ),
          const SizedBox(height: AppSpacing.sm),
          LolipantsButton(
            label: 'Cancel',
            variant: LolipantsButtonVariant.secondary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.amount});

  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          Text(amount, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
