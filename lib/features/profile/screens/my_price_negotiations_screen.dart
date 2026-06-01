import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/constants/profile_strings.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/orders/models/quote_negotiation.dart';
import 'package:lolipants/features/orders/providers/orders_providers.dart';
import 'package:lolipants/features/orders/utils/negotiation_checkout.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Lists the customer's tailor price negotiations and resumes checkout when accepted.
class MyPriceNegotiationsScreen extends ConsumerStatefulWidget {
  const MyPriceNegotiationsScreen({super.key});

  @override
  ConsumerState<MyPriceNegotiationsScreen> createState() =>
      _MyPriceNegotiationsScreenState();
}

class _MyPriceNegotiationsScreenState
    extends ConsumerState<MyPriceNegotiationsScreen> {
  List<QuoteNegotiation> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ref.read(ordersRepositoryProvider).listMyNegotiations();
    if (!mounted) return;
    result.fold(
      (e) => setState(() {
        _loading = false;
        _error = orderErrorMessage(
          e,
          fallback: localized(
            ref,
            ProfileStrings.negotiationsLoadError,
            ProfileStrings.negotiationsLoadErrorAr,
          ),
        );
      }),
      (items) => setState(() {
        _loading = false;
        _items = items;
      }),
    );
  }

  void _openDetail(QuoteNegotiation neg) {
    context.push('/order/quote-negotiation/${neg.id}').then((_) {
      if (mounted) _load();
    });
  }

  void _continueToPayment(QuoteNegotiation neg) {
    if (neg.status != QuoteNegotiationStatus.accepted) return;
    applyNegotiationToCheckout(ref, neg);
    context.push('/order/payment');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizedFromContext(
            context,
            ProfileStrings.priceNegotiations,
            ProfileStrings.priceNegotiationsAr,
          ),
        ),
      ),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          RefreshIndicator(
            onRefresh: _load,
            child: _loading
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(child: CircularProgressIndicator()),
                    ],
                  )
                : _error != null
                    ? ListView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Text(_error!),
                          ),
                        ],
                      )
                    : _items.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 120),
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.xl),
                                  child: Text(
                                    localizedFromContext(
                                      context,
                                      ProfileStrings.negotiationsEmptyLong,
                                      ProfileStrings.negotiationsEmptyLongAr,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              final neg = _items[index];
                              return _NegotiationTile(
                                negotiation: neg,
                                onTap: () => _openDetail(neg),
                                onContinue: neg.status ==
                                        QuoteNegotiationStatus.accepted
                                    ? () => _continueToPayment(neg)
                                    : null,
                                onReviewCounter: neg.status ==
                                        QuoteNegotiationStatus.countered
                                    ? () => _openDetail(neg)
                                    : null,
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _NegotiationTile extends StatelessWidget {
  const _NegotiationTile({
    required this.negotiation,
    required this.onTap,
    this.onContinue,
    this.onReviewCounter,
  });

  final QuoteNegotiation negotiation;
  final VoidCallback onTap;
  final VoidCallback? onContinue;
  final VoidCallback? onReviewCounter;

  Color _statusColor() {
    switch (negotiation.status) {
      case QuoteNegotiationStatus.accepted:
        return AppColors.tealLight;
      case QuoteNegotiationStatus.countered:
        return AppColors.gold;
      case QuoteNegotiationStatus.declined:
      case QuoteNegotiationStatus.cancelled:
      case QuoteNegotiationStatus.expired:
        return AppColors.rubyLight;
      case QuoteNegotiationStatus.tailorReview:
      case QuoteNegotiationStatus.open:
        return AppColors.dust;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColour = _statusColor();
    return Material(
      color: AppColors.stone,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${localizedFromContext(context, ProfileStrings.offer, ProfileStrings.offerAr)} ${negotiation.offeredTotal} ${negotiation.currency}',
                      style: AppTextStyles.titleSmall,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColour.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: statusColour),
                    ),
                    child: Text(
                      negotiation.statusLabel,
                      style: AppTextStyles.labelGold.copyWith(
                        color: statusColour,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${localizedFromContext(context, ProfileStrings.listPrice, ProfileStrings.listPriceAr)} ${negotiation.listTotal} ${negotiation.currency}'
                '${negotiation.tailorName != null ? ' • ${negotiation.tailorName}' : ''}',
                style: AppTextStyles.bodySmall,
              ),
              if (negotiation.isActive) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  negotiation.status == QuoteNegotiationStatus.countered
                      ? localizedFromContext(
                          context,
                          ProfileStrings.tailorCounterOfferActive,
                          ProfileStrings.tailorCounterOfferActiveAr,
                        )
                      : localizedFromContext(
                          context,
                          ProfileStrings.paymentOnHold,
                          ProfileStrings.paymentOnHoldAr,
                        ),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.fog,
                  ),
                ),
              ],
              if (onReviewCounter != null) ...[
                const SizedBox(height: AppSpacing.sm),
                LolipantsButton(
                  label: localizedFromContext(
                    context,
                    ProfileStrings.reviewCounterOffer,
                    ProfileStrings.reviewCounterOfferAr,
                  ),
                  onPressed: onReviewCounter,
                ),
              ],
              if (onContinue != null) ...[
                const SizedBox(height: AppSpacing.sm),
                LolipantsButton(
                  label: localizedFromContext(
                    context,
                    ProfileStrings.continueToPayment,
                    ProfileStrings.continueToPaymentAr,
                  ),
                  onPressed: onContinue,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
