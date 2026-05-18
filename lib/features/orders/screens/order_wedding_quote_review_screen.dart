import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/errors/app_exception_message_mapper.dart';
import 'package:lolipants/features/orders/providers/checkout_providers.dart';
import 'package:lolipants/features/orders/providers/orders_providers.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Fetches wedding dress quote after delivery coordinates are set.
class OrderWeddingQuoteReviewScreen extends ConsumerStatefulWidget {
  const OrderWeddingQuoteReviewScreen({super.key});

  @override
  ConsumerState<OrderWeddingQuoteReviewScreen> createState() =>
      _OrderWeddingQuoteReviewScreenState();
}

class _OrderWeddingQuoteReviewScreenState
    extends ConsumerState<OrderWeddingQuoteReviewScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchQuote());
  }

  Future<void> _fetchQuote() async {
    final draft = ref.read(weddingCheckoutDraftProvider);
    final lat = draft?.deliveryLat;
    final lng = draft?.deliveryLng;
    if (draft == null || lat == null || lng == null) {
      setState(() {
        _loading = false;
        _error = 'Delivery details missing. Go back and try again.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final repo = ref.read(ordersRepositoryProvider);
    final result = await repo.getWeddingQuote(
      dressId: draft.wedding.dressId,
      fulfillment: draft.wedding.fulfillmentApiValue,
      rentalDays: draft.wedding.rentalDays,
      city: draft.city,
      deliveryLat: lat,
      deliveryLng: lng,
    );
    if (!mounted) return;
    result.fold(
      (e) => setState(() {
        _loading = false;
        _error = orderErrorMessage(
          e,
          fallback: 'No tailor available near this location.',
        );
      }),
      (quote) {
        ref.read(weddingCheckoutDraftProvider.notifier).state =
            draft.copyWith(quote: quote);
        setState(() => _loading = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(weddingCheckoutDraftProvider);
    final quote = draft?.quote;

    return Scaffold(
      appBar: AppBar(title: const Text('Wedding quote')),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Text(_error!, style: AppTextStyles.bodyMedium),
                const SizedBox(height: AppSpacing.md),
                LolipantsButton(label: 'Retry', onPressed: _fetchQuote),
              ],
            )
          else if (quote == null)
            const Center(child: Text('No quote available.'))
          else
            ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Text(draft!.wedding.dressLabel, style: AppTextStyles.titleMedium),
                if (quote.tailorName != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Tailor: ${quote.tailorName}'
                    '${quote.shopName != null ? ' · ${quote.shopName}' : ''}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                _PriceRow(
                  label: quote.isRent ? 'Rental subtotal' : 'Dress price',
                  value: '${quote.basePrice} ${quote.currency}',
                ),
                if (quote.isRent && quote.insuranceDeposit != null)
                  _PriceRow(
                    label: 'Insurance deposit',
                    value: '${quote.insuranceDeposit} ${quote.currency}',
                  ),
                _PriceRow(
                  label: 'Delivery',
                  value: '${quote.deliveryFee} ${quote.currency}',
                ),
                const Divider(height: AppSpacing.xl),
                _PriceRow(
                  label: 'Total',
                  value: '${quote.total} ${quote.currency}',
                  emphasized: true,
                ),
                if (quote.isRent) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    AppStrings.weddingDepositDisclaimer,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.fog),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                LolipantsButton(
                  label: 'Continue to payment',
                  onPressed: () => context.push('/order/payment'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized ? AppTextStyles.titleSmall : AppTextStyles.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
