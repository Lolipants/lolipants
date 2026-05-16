import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/orders/providers/checkout_providers.dart';
import 'package:lolipants/features/orders/providers/orders_providers.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Fetches proximity-based tailor quote after delivery coordinates are set.
class OrderQuoteReviewScreen extends ConsumerStatefulWidget {
  const OrderQuoteReviewScreen({super.key});

  @override
  ConsumerState<OrderQuoteReviewScreen> createState() =>
      _OrderQuoteReviewScreenState();
}

class _OrderQuoteReviewScreenState extends ConsumerState<OrderQuoteReviewScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchQuote());
  }

  Future<void> _fetchQuote() async {
    final draft = ref.read(checkoutDraftProvider);
    final designId = draft?.design.designId?.trim();
    final lat = draft?.deliveryLat;
    final lng = draft?.deliveryLng;
    if (draft == null ||
        designId == null ||
        designId.isEmpty ||
        lat == null ||
        lng == null) {
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
    final result = await repo.getQuote(
      designId: designId,
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
        ref.read(checkoutDraftProvider.notifier).state =
            draft.copyWith(quote: quote);
        setState(() => _loading = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(checkoutDraftProvider);
    final quote = draft?.quote;

    return Scaffold(
      appBar: AppBar(title: const Text('Your tailor & price')),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  Text(_error!, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: AppSpacing.lg),
                  LolipantsButton(
                    label: 'Retry',
                    onPressed: _fetchQuote,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  LolipantsButton(
                    label: 'Change delivery',
                    variant: LolipantsButtonVariant.secondary,
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            )
          else if (quote != null)
            ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.stone,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Assigned tailor', style: AppTextStyles.titleSmall),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        quote.tailorName ?? 'Tailor',
                        style: AppTextStyles.titleMedium,
                      ),
                      if (quote.shopName != null &&
                          quote.shopName!.trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(quote.shopName!, style: AppTextStyles.bodySmall),
                      ],
                      if (quote.distanceKm != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '~${quote.distanceKm!.toStringAsFixed(1)} km from workshop',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _priceRow('Base', quote.basePrice),
                _priceRow('Fabric', quote.fabricFee),
                _priceRow('Delivery', quote.deliveryFee),
                const Divider(height: AppSpacing.xl),
                _priceRow('Total', quote.total, bold: true),
                const SizedBox(height: AppSpacing.lg),
                LolipantsButton(
                  label: 'Continue to payment',
                  onPressed: () => context.push('/order/payment'),
                ),
                const SizedBox(height: AppSpacing.sm),
                LolipantsButton(
                  label: 'Back',
                  variant: LolipantsButtonVariant.secondary,
                  onPressed: () => context.pop(),
                ),
              ],
            )
          else
            const Center(child: Text('No quote available')),
        ],
      ),
    );
  }

  Widget _priceRow(String label, int amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: bold ? AppTextStyles.titleSmall : AppTextStyles.bodyMedium,
          ),
          Text(
            '$amount QAR',
            style: bold ? AppTextStyles.titleSmall : AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}
