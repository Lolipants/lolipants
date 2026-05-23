import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/orders/models/order_quote.dart';
import 'package:lolipants/features/orders/models/tailor_quote_option.dart';
import 'package:lolipants/features/orders/providers/checkout_providers.dart';
import 'package:lolipants/features/orders/providers/orders_providers.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Fetches and compares tailor quotes after delivery coordinates are set.
class OrderQuoteReviewScreen extends ConsumerStatefulWidget {
  const OrderQuoteReviewScreen({super.key});

  @override
  ConsumerState<OrderQuoteReviewScreen> createState() =>
      _OrderQuoteReviewScreenState();
}

class _OrderQuoteReviewScreenState extends ConsumerState<OrderQuoteReviewScreen> {
  bool _loading = true;
  String? _error;
  List<TailorQuoteOption> _options = const [];
  String? _selectedTailorId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchQuotes());
  }

  Future<void> _fetchQuotes() async {
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
    final result = await repo.compareQuotes(
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
      (options) {
        final selected = options.isNotEmpty ? options.first.tailorId : null;
        OrderQuote? quote;
        if (options.isNotEmpty) {
          quote = options.first.toOrderQuote(
            designId: designId,
            city: draft.city,
          );
        }
        ref.read(checkoutDraftProvider.notifier).state =
            draft.copyWith(quote: quote);
        setState(() {
          _loading = false;
          _options = options;
          _selectedTailorId = selected;
        });
      },
    );
  }

  void _selectTailor(TailorQuoteOption option) {
    final draft = ref.read(checkoutDraftProvider);
    if (draft == null) return;
    final designId = draft.design.designId?.trim() ?? '';
    ref.read(checkoutDraftProvider.notifier).state = draft.copyWith(
      quote: option.toOrderQuote(designId: designId, city: draft.city),
    );
    setState(() => _selectedTailorId = option.tailorId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compare tailors & prices')),
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
                    onPressed: _fetchQuotes,
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
          else if (_options.isNotEmpty)
            ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Text(
                  'Choose your tailor',
                  style: AppTextStyles.titleSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Prices include base, fabric tier, and delivery to your location.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.fog),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final option in _options)
                  _TailorQuoteCard(
                    option: option,
                    selected: _selectedTailorId == option.tailorId,
                    onTap: () => _selectTailor(option),
                  ),
                const SizedBox(height: AppSpacing.lg),
                LolipantsButton(
                  label: 'Continue to payment',
                  onPressed: _selectedTailorId == null
                      ? null
                      : () => context.push('/order/payment'),
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
            const Center(child: Text('No quotes available')),
        ],
      ),
    );
  }
}

class _TailorQuoteCard extends StatelessWidget {
  const _TailorQuoteCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final TailorQuoteOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: AppColors.stone,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: selected ? AppColors.gold : AppColors.borderSubtle,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        option.tailorName,
                        style: AppTextStyles.titleMedium,
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.check_circle, color: AppColors.gold),
                  ],
                ),
                if (option.shopName != null &&
                    option.shopName!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(option.shopName!, style: AppTextStyles.bodySmall),
                ],
                if (option.distanceKm != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '~${option.distanceKm!.toStringAsFixed(1)} km from workshop',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.fog,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                _priceRow('Base', option.basePrice),
                _priceRow('Fabric', option.fabricFee),
                _priceRow('Delivery', option.deliveryFee),
                const Divider(height: AppSpacing.md),
                _priceRow('Total', option.total, bold: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _priceRow(String label, int amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: bold ? AppTextStyles.titleSmall : AppTextStyles.bodySmall,
          ),
          Text(
            '$amount QAR',
            style: bold ? AppTextStyles.titleSmall : AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}
