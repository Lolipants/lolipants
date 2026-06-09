import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/constants/orders_strings.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/orders/models/checkout_draft.dart';
import 'package:lolipants/features/orders/models/order_design_draft.dart';
import 'package:lolipants/features/orders/models/accessory_checkout_draft.dart';
import 'package:lolipants/features/orders/models/wedding_checkout_draft.dart';
import 'package:lolipants/features/orders/providers/checkout_providers.dart';
import 'package:lolipants/features/orders/providers/orders_providers.dart';
import 'package:lolipants/core/permissions/device_permission_prompt.dart';
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
    final locale = ref.watch(settingsLocaleProvider);
    final paymentTitle = localizedFromLocale(
      locale,
      OrdersStrings.payment,
      OrdersStrings.paymentAr,
    );
    final accessoryDraft = ref.watch(accessoryCheckoutDraftProvider);
    if (accessoryDraft != null) {
      return _buildAccessoryPayment(context, locale, accessoryDraft);
    }
    final weddingDraft = ref.watch(weddingCheckoutDraftProvider);
    if (weddingDraft != null) {
      return _buildWeddingPayment(context, locale, weddingDraft);
    }
    final draft = ref.watch(checkoutDraftProvider);
    if (draft == null) {
      return Scaffold(
        appBar: AppBar(title: Text(paymentTitle)),
        body: Center(
          child: Text(
            localizedFromLocale(
              locale,
              OrdersStrings.checkoutExpired,
              OrdersStrings.checkoutExpiredAr,
            ),
          ),
        ),
      );
    }
    final quote = draft.quote;
    return Scaffold(
      appBar: AppBar(title: Text(paymentTitle)),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              _PriceCard(
                locale: locale,
                draft: draft,
                expanded: _expanded,
                onToggle: () => setState(() => _expanded = !_expanded),
              ),
              const SizedBox(height: AppSpacing.md),
              _DesignFabricSummary(locale: locale, design: draft.design),
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
                    Text(
                      localizedFromLocale(
                        locale,
                        OrdersStrings.payWithCard,
                        OrdersStrings.payWithCardAr,
                      ),
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      kFeatureMockPayment
                          ? localizedFromLocale(
                              locale,
                              OrdersStrings.demoPaymentModeActive,
                              OrdersStrings.demoPaymentModeActiveAr,
                            )
                          : localizedFromLocale(
                              locale,
                              OrdersStrings.cardPaymentManualMode,
                              OrdersStrings.cardPaymentManualModeAr,
                            ),
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              LolipantsButton(
                label: _processing
                    ? localizedFromLocale(
                        locale,
                        OrdersStrings.processing,
                        OrdersStrings.processingAr,
                      )
                    : quote == null
                        ? localizedFromLocale(
                            locale,
                            OrdersStrings.pricingUnavailable,
                            OrdersStrings.pricingUnavailableAr,
                          )
                        : OrdersStrings.payAmount(
                            '${quote.total}',
                            quote.currency,
                            locale,
                          ),
                onPressed:
                    _processing || quote == null ? null : () => _pay(draft),
              ),
              const SizedBox(height: AppSpacing.sm),
              LolipantsButton(
                label: localizedFromLocale(
                  locale,
                  OrdersStrings.back,
                  OrdersStrings.backAr,
                ),
                variant: LolipantsButtonVariant.secondary,
                onPressed: _processing ? null : () => context.pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccessoryPayment(
    BuildContext context,
    Locale locale,
    AccessoryCheckoutDraft draft,
  ) {
    final quote = draft.quote;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizedFromLocale(
            locale,
            OrdersStrings.payment,
            OrdersStrings.paymentAr,
          ),
        ),
      ),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              Text(draft.accessory.accessoryLabel, style: AppTextStyles.titleMedium),
              const SizedBox(height: AppSpacing.md),
              if (quote != null)
                Text(
                  OrdersStrings.totalLine(
                    '${quote.total}',
                    quote.currency,
                    locale,
                  ),
                  style: AppTextStyles.titleSmall,
                ),
              const SizedBox(height: AppSpacing.lg),
              if (_errorMessage != null) ...[
                ErrorBanner(
                  message: _errorMessage!,
                  onDismiss: () => setState(() => _errorMessage = null),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              LolipantsButton(
                label: _processing
                    ? localizedFromLocale(
                        locale,
                        OrdersStrings.processing,
                        OrdersStrings.processingAr,
                      )
                    : quote == null
                        ? localizedFromLocale(
                            locale,
                            OrdersStrings.pricingUnavailable,
                            OrdersStrings.pricingUnavailableAr,
                          )
                        : OrdersStrings.payAmount(
                            '${quote.total}',
                            quote.currency,
                            locale,
                          ),
                onPressed: _processing || quote == null
                    ? null
                    : () => _payAccessory(draft),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _payAccessory(AccessoryCheckoutDraft draft) async {
    final locale = ref.read(settingsLocaleProvider);
    setState(() {
      _processing = true;
      _errorMessage = null;
    });
    await _ensurePushRegistered();
    final ordersRepo = ref.read(ordersRepositoryProvider);
    final paymentsRepo = ref.read(paymentsRepositoryProvider);
    final quote = draft.quote;
    if (quote == null ||
        quote.tailorId == null ||
        quote.tailorId!.isEmpty ||
        draft.deliveryLat == null ||
        draft.deliveryLng == null) {
      _fail(
        localizedFromLocale(
          locale,
          OrdersStrings.pricingExpiredGoBack,
          OrdersStrings.pricingExpiredGoBackAr,
        ),
      );
      return;
    }

    final orderResult = await ordersRepo.createAccessoryOrder(
      accessoryId: draft.accessory.accessoryId,
      fulfillmentType: draft.accessory.fulfillmentType,
      deliveryAddress: draft.address,
      deliveryCity: draft.city,
      deliveryPhone: draft.phone,
      deliveryLat: draft.deliveryLat!,
      deliveryLng: draft.deliveryLng!,
      tailorId: quote.tailorId!,
      basePrice: quote.basePrice,
      fabricFee: quote.fabricFee,
      deliveryFee: quote.deliveryFee,
      accessoryFee: quote.accessoryFee,
      totalPrice: quote.total,
      deliveryNotes: draft.notes,
      idempotencyKey: draft.idempotencyKey,
    );
    final orderOrError = orderResult.fold<String>(
      (e) => orderErrorMessage(
        e,
        fallback: localizedFromLocale(
          locale,
          OrdersStrings.couldNotCreateOrder,
          OrdersStrings.couldNotCreateOrderAr,
        ),
      ),
      (_) => '',
    );
    if (orderOrError.isNotEmpty) {
      _fail(orderOrError);
      return;
    }
    final order = orderResult.toNullable();
    if (order == null) {
      _fail(
        localizedFromLocale(
          locale,
          OrdersStrings.orderCreationNoPayload,
          OrdersStrings.orderCreationNoPayloadAr,
        ),
      );
      return;
    }
    ref.read(accessoryCheckoutDraftProvider.notifier).state =
        draft.copyWith(orderId: order.id);

    final intentResult = await paymentsRepo.createIntent(
      orderId: order.id,
      idempotencyKey: draft.idempotencyKey,
    );
    final intentError = intentResult.fold<String>(
      (e) => orderErrorMessage(
        e,
        fallback: localizedFromLocale(
          locale,
          OrdersStrings.couldNotStartPayment,
          OrdersStrings.couldNotStartPaymentAr,
        ),
      ),
      (_) => '',
    );
    if (intentError.isNotEmpty) {
      _fail(intentError);
      return;
    }
    final intent = intentResult.toNullable();
    if (intent == null) {
      _fail(
        localizedFromLocale(
          locale,
          OrdersStrings.paymentIntentNoPayload,
          OrdersStrings.paymentIntentNoPayloadAr,
        ),
      );
      return;
    }
    ref.read(accessoryCheckoutDraftProvider.notifier).state = (ref
                .read(accessoryCheckoutDraftProvider) ??
            draft)
        .copyWith(
      orderId: order.id,
      paymentReference: intent.reference,
    );

    final tapToken = await _requestTapToken();
    if (tapToken == null) {
      _fail(
        localizedFromLocale(
          locale,
          OrdersStrings.paymentCancelled,
          OrdersStrings.paymentCancelledAr,
        ),
      );
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
      (e) => orderErrorMessage(
        e,
        fallback: localizedFromLocale(
          locale,
          OrdersStrings.paymentNotCaptured,
          OrdersStrings.paymentNotCapturedAr,
        ),
      ),
      (_) => '',
    );
    if (chargeError.isNotEmpty) {
      _fail(chargeError);
      return;
    }

    if (!mounted) return;
    unawaited(ref.read(myOrdersProvider.notifier).reload());
    ref.read(accessoryCheckoutDraftProvider.notifier).state = null;
    context.go('/order/confirmed/${order.id}');
  }

  Widget _buildWeddingPayment(
    BuildContext context,
    Locale locale,
    WeddingCheckoutDraft draft,
  ) {
    final quote = draft.quote;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizedFromLocale(
            locale,
            OrdersStrings.payment,
            OrdersStrings.paymentAr,
          ),
        ),
      ),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              Text(draft.wedding.dressLabel, style: AppTextStyles.titleMedium),
              const SizedBox(height: AppSpacing.md),
              if (quote != null) ...[
                Text(
                  OrdersStrings.totalLine(
                    '${quote.total}',
                    quote.currency,
                    locale,
                  ),
                  style: AppTextStyles.titleSmall,
                ),
                if (quote.isRent && quote.insuranceDeposit != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      OrdersStrings.includesRefundableDeposit(
                        '${quote.insuranceDeposit}',
                        quote.currency,
                        locale,
                      ),
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
              ],
              const SizedBox(height: AppSpacing.lg),
              if (_errorMessage != null) ...[
                ErrorBanner(
                  message: _errorMessage!,
                  onDismiss: () => setState(() => _errorMessage = null),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              LolipantsButton(
                label: _processing
                    ? localizedFromLocale(
                        locale,
                        OrdersStrings.processing,
                        OrdersStrings.processingAr,
                      )
                    : quote == null
                        ? localizedFromLocale(
                            locale,
                            OrdersStrings.pricingUnavailable,
                            OrdersStrings.pricingUnavailableAr,
                          )
                        : OrdersStrings.payAmount(
                            '${quote.total}',
                            quote.currency,
                            locale,
                          ),
                onPressed:
                    _processing || quote == null ? null : () => _payWedding(draft),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _payWedding(WeddingCheckoutDraft draft) async {
    final locale = ref.read(settingsLocaleProvider);
    setState(() {
      _processing = true;
      _errorMessage = null;
    });
    await _ensurePushRegistered();
    final ordersRepo = ref.read(ordersRepositoryProvider);
    final paymentsRepo = ref.read(paymentsRepositoryProvider);
    final quote = draft.quote;
    if (quote == null ||
        quote.tailorId == null ||
        quote.tailorId!.isEmpty ||
        draft.deliveryLat == null ||
        draft.deliveryLng == null) {
      _fail(
        localizedFromLocale(
          locale,
          OrdersStrings.pricingExpiredGoBack,
          OrdersStrings.pricingExpiredGoBackAr,
        ),
      );
      return;
    }

    final orderResult = await ordersRepo.createWeddingOrder(
      weddingDressId: draft.wedding.dressId,
      fulfillmentType: draft.wedding.fulfillmentType,
      fulfillment: draft.wedding.fulfillmentApiValue,
      rentalDays: draft.wedding.rentalDays,
      deliveryAddress: draft.address,
      deliveryCity: draft.city,
      deliveryPhone: draft.phone,
      deliveryLat: draft.deliveryLat!,
      deliveryLng: draft.deliveryLng!,
      tailorId: quote.tailorId!,
      basePrice: quote.basePrice,
      fabricFee: quote.fabricFee,
      deliveryFee: quote.deliveryFee,
      totalPrice: quote.total,
      deliveryNotes: draft.notes,
      idempotencyKey: draft.idempotencyKey,
    );
    final orderOrError = orderResult.fold<String>(
      (e) => orderErrorMessage(
        e,
        fallback: localizedFromLocale(
          locale,
          OrdersStrings.couldNotCreateOrder,
          OrdersStrings.couldNotCreateOrderAr,
        ),
      ),
      (_) => '',
    );
    if (orderOrError.isNotEmpty) {
      _fail(orderOrError);
      return;
    }
    final order = orderResult.toNullable();
    if (order == null) {
      _fail(
        localizedFromLocale(
          locale,
          OrdersStrings.orderCreationNoPayload,
          OrdersStrings.orderCreationNoPayloadAr,
        ),
      );
      return;
    }
    ref.read(weddingCheckoutDraftProvider.notifier).state =
        draft.copyWith(orderId: order.id);

    final intentResult = await paymentsRepo.createIntent(
      orderId: order.id,
      idempotencyKey: draft.idempotencyKey,
    );
    final intentError = intentResult.fold<String>(
      (e) => orderErrorMessage(
        e,
        fallback: localizedFromLocale(
          locale,
          OrdersStrings.couldNotStartPayment,
          OrdersStrings.couldNotStartPaymentAr,
        ),
      ),
      (_) => '',
    );
    if (intentError.isNotEmpty) {
      _fail(intentError);
      return;
    }
    final intent = intentResult.toNullable();
    if (intent == null) {
      _fail(
        localizedFromLocale(
          locale,
          OrdersStrings.paymentIntentNoPayload,
          OrdersStrings.paymentIntentNoPayloadAr,
        ),
      );
      return;
    }
    ref.read(weddingCheckoutDraftProvider.notifier).state = (ref
                .read(weddingCheckoutDraftProvider) ??
            draft)
        .copyWith(paymentReference: intent.reference);

    final tapToken = await _requestTapToken();
    if (tapToken == null) {
      _fail(
        localizedFromLocale(
          locale,
          OrdersStrings.paymentCancelled,
          OrdersStrings.paymentCancelledAr,
        ),
      );
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
      (e) => orderErrorMessage(
        e,
        fallback: localizedFromLocale(
          locale,
          OrdersStrings.paymentNotCaptured,
          OrdersStrings.paymentNotCapturedAr,
        ),
      ),
      (_) => '',
    );
    if (chargeError.isNotEmpty) {
      _fail(chargeError);
      return;
    }

    if (!mounted) return;
    unawaited(ref.read(myOrdersProvider.notifier).reload());
    ref.read(weddingCheckoutDraftProvider.notifier).state = null;
    context.go('/order/confirmed/${order.id}');
  }

  Future<void> _pay(CheckoutDraft draft) async {
    final locale = ref.read(settingsLocaleProvider);
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
      _fail(
        localizedFromLocale(
          locale,
          OrdersStrings.saveDesignBeforeOrder,
          OrdersStrings.saveDesignBeforeOrderAr,
        ),
      );
      return;
    }

    final quote = draft.quote;
    if (quote == null ||
        quote.tailorId == null ||
        quote.tailorId!.isEmpty ||
        draft.deliveryLat == null ||
        draft.deliveryLng == null) {
      _fail(
        localizedFromLocale(
          locale,
          OrdersStrings.pricingExpiredGoBack,
          OrdersStrings.pricingExpiredGoBackAr,
        ),
      );
      return;
    }

    final orderResult = await ordersRepo.createOrder(
      designId: designId,
      deliveryAddress: draft.address,
      deliveryCity: draft.city,
      deliveryPhone: draft.phone,
      deliveryLat: draft.deliveryLat!,
      deliveryLng: draft.deliveryLng!,
      tailorId: quote.tailorId!,
      basePrice: quote.basePrice,
      fabricFee: quote.fabricFee,
      deliveryFee: quote.deliveryFee,
      accessoryFee: quote.accessoryFee,
      totalPrice: quote.total,
      accessoryIds: draft.design.accessoryIds,
      deliveryNotes: draft.notes,
      idempotencyKey: draft.idempotencyKey,
      designerId: draft.design.designerId,
      quoteLockToken: quote.quoteLockToken,
    );
    final orderOrError = orderResult.fold<String>(
      (e) => orderErrorMessage(
        e,
        fallback: localizedFromLocale(
          locale,
          OrdersStrings.couldNotCreateOrder,
          OrdersStrings.couldNotCreateOrderAr,
        ),
      ),
      (_) => '',
    );
    if (orderOrError.isNotEmpty) {
      _fail(orderOrError);
      return;
    }
    final order = orderResult.toNullable();
    if (order == null) {
      _fail(
        localizedFromLocale(
          locale,
          OrdersStrings.orderCreationNoPayload,
          OrdersStrings.orderCreationNoPayloadAr,
        ),
      );
      return;
    }
    ref.read(checkoutDraftProvider.notifier).state =
        draft.copyWith(orderId: order.id);

    final intentResult = await paymentsRepo.createIntent(
      orderId: order.id,
      idempotencyKey: draft.idempotencyKey,
    );
    final intentError = intentResult.fold<String>(
      (e) => orderErrorMessage(
        e,
        fallback: localizedFromLocale(
          locale,
          OrdersStrings.couldNotStartPayment,
          OrdersStrings.couldNotStartPaymentAr,
        ),
      ),
      (_) => '',
    );
    if (intentError.isNotEmpty) {
      _fail(intentError);
      return;
    }
    final intent = intentResult.toNullable();
    if (intent == null) {
      _fail(
        localizedFromLocale(
          locale,
          OrdersStrings.paymentIntentNoPayload,
          OrdersStrings.paymentIntentNoPayloadAr,
        ),
      );
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
      _fail(
        localizedFromLocale(
          locale,
          OrdersStrings.paymentCancelled,
          OrdersStrings.paymentCancelledAr,
        ),
      );
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
      (e) => orderErrorMessage(
        e,
        fallback: localizedFromLocale(
          locale,
          OrdersStrings.paymentNotCaptured,
          OrdersStrings.paymentNotCapturedAr,
        ),
      ),
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
    final locale = ref.read(settingsLocaleProvider);
    final token = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TapTokenEntrySheet(locale: locale),
    );
    return token;
  }

  /// Requests notification permission (first order only) and registers the
  /// resulting OneSignal player id with the backend. Any failure is logged
  /// but the payment flow continues.
  Future<void> _ensurePushRegistered() async {
    final settings = ref.read(settingsProvider);
    if (settings.pushEnabled) return;
    if (!mounted) return;
    await DevicePermissionPrompt.ensure(
      context,
      AppDevicePermission.notifications,
    );
    if (!mounted) return;
    await ref.read(settingsProvider.notifier).applyPushPreference(
          want: true,
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
  const _DesignFabricSummary({required this.locale, required this.design});

  final Locale locale;
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
          Text(
            localizedFromLocale(
              locale,
              OrdersStrings.fabric,
              OrdersStrings.fabricAr,
            ),
            style: AppTextStyles.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(line, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({
    required this.locale,
    required this.draft,
    required this.expanded,
    required this.onToggle,
  });

  final Locale locale;
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
                      ? localizedFromLocale(
                          locale,
                          OrdersStrings.fetchingPrice,
                          OrdersStrings.fetchingPriceAr,
                        )
                      : OrdersStrings.totalLine(
                          '${quote.total}',
                          quote.currency,
                          locale,
                        ),
                  style: AppTextStyles.titleMedium,
                ),
              ),
              TextButton(
                onPressed: quote == null ? null : onToggle,
                child: Text(
                  expanded
                      ? localizedFromLocale(
                          locale,
                          OrdersStrings.hide,
                          OrdersStrings.hideAr,
                        )
                      : localizedFromLocale(
                          locale,
                          OrdersStrings.details,
                          OrdersStrings.detailsAr,
                        ),
                ),
              ),
            ],
          ),
          if (quote?.tailorName != null && quote!.tailorName!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              OrdersStrings.tailorColon(quote.tailorName!, locale),
              style: AppTextStyles.bodySmall,
            ),
          ],
          if (expanded && quote != null) ...[
            const Divider(),
            _Line(
              label: localizedFromLocale(
                locale,
                OrdersStrings.baseGarment,
                OrdersStrings.baseGarmentAr,
              ),
              amount: '${quote.basePrice}',
            ),
            _Line(
              label: localizedFromLocale(
                locale,
                OrdersStrings.fabric,
                OrdersStrings.fabricAr,
              ),
              amount: '${quote.fabricFee}',
            ),
            _Line(
              label: OrdersStrings.deliveryCityLine(quote.city, locale),
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
  const _TapTokenEntrySheet({required this.locale});

  final Locale locale;

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
          Text(
            localizedFromLocale(
              widget.locale,
              OrdersStrings.completeTapPayment,
              OrdersStrings.completeTapPaymentAr,
            ),
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            localizedFromLocale(
              widget.locale,
              OrdersStrings.tapTokenDescription,
              OrdersStrings.tapTokenDescriptionAr,
            ),
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: localizedFromLocale(
                widget.locale,
                OrdersStrings.tapToken,
                OrdersStrings.tapTokenAr,
              ),
              hintText: localizedFromLocale(
                widget.locale,
                OrdersStrings.tapTokenHint,
                OrdersStrings.tapTokenHintAr,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.lg),
          LolipantsButton(
            label: localizedFromLocale(
              widget.locale,
              OrdersStrings.confirmToken,
              OrdersStrings.confirmTokenAr,
            ),
            onPressed: token.isEmpty
                ? null
                : () => Navigator.of(context).pop(token),
          ),
          const SizedBox(height: AppSpacing.sm),
          LolipantsButton(
            label: localizedFromLocale(
              widget.locale,
              OrdersStrings.cancel,
              OrdersStrings.cancelAr,
            ),
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
