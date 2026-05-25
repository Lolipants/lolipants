import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/orders/models/order_quote.dart';
import 'package:lolipants/features/orders/models/quote_negotiation.dart';
import 'package:lolipants/features/orders/models/tailor_quote_option.dart';
import 'package:lolipants/features/orders/providers/checkout_providers.dart';
import 'package:lolipants/features/orders/providers/orders_providers.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';
import 'package:lolipants/shared/widgets/lolipants_text_field.dart';

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
  Map<String, QuoteNegotiation> _negotiationsByTailor = {};
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
    final compareResult = await repo.compareQuotes(
      designId: designId,
      city: draft.city,
      deliveryLat: lat,
      deliveryLng: lng,
    );
    final negResult = await repo.listMyNegotiations();
    if (!mounted) return;

    compareResult.fold(
      (e) => setState(() {
        _loading = false;
        _error = orderErrorMessage(
          e,
          fallback: 'No tailor available near this location.',
        );
      }),
      (options) {
        final negMap = <String, QuoteNegotiation>{};
        negResult.fold((_) {}, (items) {
          for (final n in items) {
            if (n.designId == designId) {
              negMap[n.tailorId] = n;
            }
          }
        });
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
          _negotiationsByTailor = negMap;
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

  QuoteNegotiation? _negotiationFor(String tailorId) =>
      _negotiationsByTailor[tailorId];

  Future<void> _openNegotiateSheet(TailorQuoteOption option) async {
    final draft = ref.read(checkoutDraftProvider);
    if (draft == null) return;
    final designId = draft.design.designId?.trim() ?? '';
    if (designId.isEmpty) return;

    final totalCtrl = TextEditingController(
      text: (option.total * 0.85).round().toString(),
    );
    final noteCtrl = TextEditingController();
    final floor = (option.total * 0.7).ceil();

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.stone,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Negotiate price', style: AppTextStyles.titleSmall),
              Text(
                'List price: ${option.total} QAR • min offer $floor QAR',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              LolipantsTextField(
                controller: totalCtrl,
                label: 'Your offer (QAR)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.sm),
              LolipantsTextField(
                controller: noteCtrl,
                label: 'Note to tailor (optional)',
              ),
              const SizedBox(height: AppSpacing.lg),
              LolipantsButton(
                label: 'Send to tailor',
                onPressed: () => Navigator.pop(ctx, true),
              ),
            ],
          ),
        );
      },
    );
    if (submitted != true || !mounted) return;

    final offered = int.tryParse(totalCtrl.text.trim());
    if (offered == null || offered < floor) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Offer must be at least $floor QAR')),
      );
      return;
    }

    final repo = ref.read(ordersRepositoryProvider);
    final result = await repo.createNegotiation(
      designId: designId,
      tailorId: option.tailorId,
      offeredTotal: offered,
      deliveryAddress: draft.address,
      deliveryCity: draft.city,
      deliveryPhone: draft.phone,
      deliveryLat: draft.deliveryLat!,
      deliveryLng: draft.deliveryLng!,
      customerNote: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
    );
    if (!mounted) return;
    result.fold(
      (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            orderErrorMessage(e, fallback: 'Could not send offer.'),
          ),
        ),
      ),
      (detail) {
        setState(() {
          _negotiationsByTailor[option.tailorId] = detail.negotiation;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer sent to tailor')),
        );
      },
    );
  }

  void _applyAcceptedQuote(QuoteNegotiation neg, TailorQuoteOption option) {
    final draft = ref.read(checkoutDraftProvider);
    if (draft == null) return;
    final designId = draft.design.designId?.trim() ?? '';
    final base = neg.lockedBasePrice ?? option.basePrice;
    final fabric = neg.lockedFabricFee ?? option.fabricFee;
    final delivery = neg.lockedDeliveryFee ?? option.deliveryFee;
    final total = neg.lockedTotal ?? neg.offeredTotal;
    ref.read(checkoutDraftProvider.notifier).state = draft.copyWith(
      quote: OrderQuote(
        designId: designId,
        city: draft.city,
        basePrice: base,
        fabricFee: fabric,
        deliveryFee: delivery,
        total: total,
        currency: neg.currency,
        tailorId: neg.tailorId,
        tailorName: option.tailorName,
        shopName: option.shopName,
        distanceKm: option.distanceKm,
        pricePlanId: neg.pricePlanId,
        quoteLockToken: neg.quoteLockToken,
        negotiationId: neg.id,
      ),
    );
    setState(() => _selectedTailorId = neg.tailorId);
    context.push('/order/payment');
  }

  @override
  Widget build(BuildContext context) {
    final selectedNeg = _selectedTailorId != null
        ? _negotiationFor(_selectedTailorId!)
        : null;
    final hasAcceptedSelected =
        selectedNeg?.status == QuoteNegotiationStatus.accepted;
    final hasActiveSelected = selectedNeg?.isActive ?? false;

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
                  LolipantsButton(label: 'Retry', onPressed: _fetchQuotes),
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
                Text('Choose your tailor', style: AppTextStyles.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Continue at list price or negotiate with a tailor.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.fog),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final option in _options)
                  _TailorQuoteCard(
                    option: option,
                    selected: _selectedTailorId == option.tailorId,
                    negotiation: _negotiationFor(option.tailorId),
                    onTap: () => _selectTailor(option),
                    onNegotiate: () => _openNegotiateSheet(option),
                    onViewNegotiation: () {
                      final neg = _negotiationFor(option.tailorId);
                      if (neg != null) {
                        context.push('/order/quote-negotiation/${neg.id}');
                      }
                    },
                    onPayAgreed: () {
                      final neg = _negotiationFor(option.tailorId);
                      if (neg != null) {
                        _applyAcceptedQuote(neg, option);
                      }
                    },
                  ),
                const SizedBox(height: AppSpacing.lg),
                if (hasActiveSelected && selectedNeg != null) ...[
                  Text(
                    selectedNeg.status == QuoteNegotiationStatus.countered
                        ? 'Accept the counter offer before paying, or choose another tailor.'
                        : 'Payment is unavailable while your price offer is pending.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.fog,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  LolipantsButton(
                    label: selectedNeg.status ==
                            QuoteNegotiationStatus.countered
                        ? 'Review counter offer'
                        : 'View negotiation',
                    onPressed: () => context.push(
                      '/order/quote-negotiation/${selectedNeg.id}',
                    ),
                  ),
                ] else
                  LolipantsButton(
                    label: hasAcceptedSelected
                        ? 'Pay agreed price'
                        : 'Continue to payment',
                    onPressed: _selectedTailorId == null
                        ? null
                        : () {
                            if (hasAcceptedSelected && selectedNeg != null) {
                              final option = _options.firstWhere(
                                (o) => o.tailorId == _selectedTailorId,
                              );
                              _applyAcceptedQuote(selectedNeg, option);
                            } else {
                              context.push('/order/payment');
                            }
                          },
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
    required this.onNegotiate,
    required this.onViewNegotiation,
    required this.onPayAgreed,
    this.negotiation,
  });

  final TailorQuoteOption option;
  final bool selected;
  final QuoteNegotiation? negotiation;
  final VoidCallback onTap;
  final VoidCallback onNegotiate;
  final VoidCallback onViewNegotiation;
  final VoidCallback onPayAgreed;

  @override
  Widget build(BuildContext context) {
    final neg = negotiation;
    final accepted = neg?.status == QuoteNegotiationStatus.accepted;

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
                    if (neg != null && (neg.isActive || accepted))
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          neg.statusLabel,
                          style: AppTextStyles.labelGold,
                        ),
                      ),
                    if (selected)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.check_circle, color: AppColors.gold),
                      ),
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
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (accepted)
                      TextButton(
                        onPressed: onPayAgreed,
                        child: const Text('Pay agreed price'),
                      )
                    else if (neg != null &&
                        neg.status == QuoteNegotiationStatus.countered)
                      TextButton(
                        onPressed: onViewNegotiation,
                        child: const Text('Review counter offer'),
                      )
                    else if (neg == null ||
                        neg.status == QuoteNegotiationStatus.declined)
                      TextButton(
                        onPressed: onNegotiate,
                        child: const Text('Negotiate price'),
                      ),
                    if (neg != null)
                      TextButton(
                        onPressed: onViewNegotiation,
                        child: const Text('Messages'),
                      ),
                  ],
                ),
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
