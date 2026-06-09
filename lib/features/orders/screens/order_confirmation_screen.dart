import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/constants/orders_strings.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/orders/providers/checkout_providers.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Full-screen success screen shown after a paid order.
class OrderConfirmationScreen extends ConsumerWidget {
  /// Takes the confirmed [orderId].
  const OrderConfirmationScreen({required this.orderId, super.key});

  /// Confirmed order id.
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(settingsLocaleProvider);
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        children: [
          const Opacity(opacity: 0.03, child: ArabesqueBackground()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _StarBadge(),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    localizedFromLocale(
                      locale,
                      OrdersStrings.orderConfirmed,
                      OrdersStrings.orderConfirmedAr,
                    ),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleLarge
                        .copyWith(color: AppColors.sand),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    OrdersStrings.orderReference(orderId, locale),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.sand.withValues(alpha: 0.8)),
                  ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
                  if (kFeatureMockPayment) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      localizedFromLocale(
                        locale,
                        OrdersStrings.demoPaymentNoCharge,
                        OrdersStrings.demoPaymentNoChargeAr,
                      ),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  LolipantsButton(
                    label: localizedFromLocale(
                      locale,
                      OrdersStrings.trackOrder,
                      OrdersStrings.trackOrderAr,
                    ),
                    onPressed: () {
                      ref.read(checkoutDraftProvider.notifier).state = null;
                      context.go('/orders/detail/$orderId');
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  LolipantsButton(
                    label: localizedFromLocale(
                      locale,
                      OrdersStrings.continueDesigning,
                      OrdersStrings.continueDesigningAr,
                    ),
                    variant: LolipantsButtonVariant.secondary,
                    onPressed: () {
                      ref.read(checkoutDraftProvider.notifier).state = null;
                      context.go('/home');
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarBadge extends StatelessWidget {
  const _StarBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0.35),
            AppColors.gold.withValues(alpha: 0.0),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.star, color: AppColors.gold, size: 72),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1.05, 1.05),
          duration: 1200.ms,
          curve: Curves.easeInOut,
        );
  }
}
