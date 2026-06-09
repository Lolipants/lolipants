import 'dart:ui' show Locale;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/constants/orders_strings.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/orders/providers/checkout_providers.dart';
import 'package:lolipants/features/orders/providers/orders_providers.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Fetches accessory purchase quote after delivery coordinates are set.
class OrderAccessoryQuoteReviewScreen extends ConsumerStatefulWidget {
  const OrderAccessoryQuoteReviewScreen({super.key});

  @override
  ConsumerState<OrderAccessoryQuoteReviewScreen> createState() =>
      _OrderAccessoryQuoteReviewScreenState();
}

class _OrderAccessoryQuoteReviewScreenState
    extends ConsumerState<OrderAccessoryQuoteReviewScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchQuote());
  }

  Future<void> _fetchQuote() async {
    final locale = ref.read(settingsLocaleProvider);
    final draft = ref.read(accessoryCheckoutDraftProvider);
    final lat = draft?.deliveryLat;
    final lng = draft?.deliveryLng;
    if (draft == null || lat == null || lng == null) {
      setState(() {
        _loading = false;
        _error = localizedFromLocale(
          locale,
          OrdersStrings.deliveryDetailsMissing,
          OrdersStrings.deliveryDetailsMissingAr,
        );
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final repo = ref.read(ordersRepositoryProvider);
    final result = await repo.getAccessoryQuote(
      accessoryId: draft.accessory.accessoryId,
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
          fallback: localizedFromLocale(
            locale,
            OrdersStrings.noTailorNearLocation,
            OrdersStrings.noTailorNearLocationAr,
          ),
        );
      }),
      (quote) {
        ref.read(accessoryCheckoutDraftProvider.notifier).state =
            draft.copyWith(quote: quote);
        setState(() => _loading = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(settingsLocaleProvider);
    final draft = ref.watch(accessoryCheckoutDraftProvider);
    final quote = draft?.quote;
    final title = localizedFromLocale(
      locale,
      OrdersStrings.accessoryQuoteTitle,
      OrdersStrings.accessoryQuoteTitleAr,
    );

    return Scaffold(
      appBar: AppBar(title: Text(title)),
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
                LolipantsButton(
                  label: localizedFromLocale(
                    locale,
                    OrdersStrings.retry,
                    OrdersStrings.retryAr,
                  ),
                  onPressed: _fetchQuote,
                ),
              ],
            )
          else if (quote == null)
            Center(
              child: Text(
                localizedFromLocale(
                  locale,
                  OrdersStrings.noQuoteAvailable,
                  OrdersStrings.noQuoteAvailableAr,
                ),
              ),
            )
          else
            ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Text(draft!.accessory.accessoryLabel,
                    style: AppTextStyles.titleMedium),
                if (quote.tailorName != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    OrdersStrings.tailorColon(quote.tailorName!, locale) +
                        (quote.shopName != null
                            ? ' · ${quote.shopName}'
                            : ''),
                    style: AppTextStyles.bodySmall,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                _PriceRow(
                  locale: locale,
                  label: OrdersStrings.item,
                  labelAr: OrdersStrings.itemAr,
                  value: '${quote.accessoryFee} ${quote.currency}',
                ),
                _PriceRow(
                  locale: locale,
                  label: OrdersStrings.delivery,
                  labelAr: OrdersStrings.deliveryAr,
                  value: '${quote.deliveryFee} ${quote.currency}',
                ),
                const Divider(height: AppSpacing.xl),
                _PriceRow(
                  locale: locale,
                  label: OrdersStrings.total,
                  labelAr: OrdersStrings.totalAr,
                  value: '${quote.total} ${quote.currency}',
                  emphasized: true,
                ),
                const SizedBox(height: AppSpacing.xl),
                LolipantsButton(
                  label: localizedFromLocale(
                    locale,
                    OrdersStrings.continueToPayment,
                    OrdersStrings.continueToPaymentAr,
                  ),
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
    required this.locale,
    required this.label,
    required this.labelAr,
    required this.value,
    this.emphasized = false,
  });

  final Locale locale;
  final String label;
  final String labelAr;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized ? AppTextStyles.titleSmall : AppTextStyles.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            localizedFromLocale(locale, label, labelAr),
            style: style,
          ),
          Text(
            value,
            style: style.copyWith(
              color: emphasized ? AppColors.gold : null,
            ),
          ),
        ],
      ),
    );
  }
}
