import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/orders/providers/orders_providers.dart';
import 'package:lolipants/features/orders/widgets/order_card.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/error_banner.dart';
import 'package:lolipants/shared/widgets/loading_overlay.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Orders tab: live list from the API with pull-to-refresh.
class OrdersScreen extends ConsumerStatefulWidget {
  /// Creates the orders tab.
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  bool _hideErrorBanner = false;

  Future<void> _refresh() async {
    setState(() {
      _hideErrorBanner = false;
    });
    await ref.read(myOrdersProvider.notifier).reload();
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(myOrdersProvider);
    final orders = ordersState.valueOrNull ?? const [];
    final hasError = ordersState.hasError && !_hideErrorBanner;
    final errorMessage = hasError
        ? orderErrorMessage(
            ordersState.error!,
            fallback: 'Could not load orders. Pull to retry.',
          )
        : '';
    return Scaffold(
      body: Stack(
        children: [
          const ArabesqueBackground(),
          SafeArea(
            child: ordersState.isLoading && orders.isEmpty
                ? const SizedBox.shrink()
                : orders.isEmpty
                ? _EmptyOrders(onStart: () => context.go('/home'))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl,
                          AppSpacing.lg,
                          AppSpacing.xl,
                          AppSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: Text(
                                      AppStrings.myOrdersAr,
                                      style: AppTextStyles.arabicLabel,
                                    ),
                                  ),
                                  Text(
                                    AppStrings.myOrders,
                                    style: AppTextStyles.titleLarge,
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.gold,
                                side: const BorderSide(color: AppColors.gold),
                              ),
                              child: const Text(AppStrings.filter),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _refresh,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                            ),
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              return OrderCard(order: orders[index]);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          if (hasError)
            Positioned(
              left: AppSpacing.xl,
              right: AppSpacing.xl,
              top: AppSpacing.lg,
              child: ErrorBanner(
                message: errorMessage,
                onDismiss: () => setState(() => _hideErrorBanner = true),
              ),
            ),
          LoadingOverlay(visible: ordersState.isLoading && orders.isNotEmpty),
        ],
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.diamond_outlined, size: 48, color: AppColors.gold),
            const SizedBox(height: AppSpacing.lg),
            Text(AppStrings.ordersEmpty, style: AppTextStyles.titleMedium),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                AppStrings.ordersEmptyAr,
                style: AppTextStyles.arabicBody,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            LolipantsButton(
              label: '${AppStrings.startDesigning} / ${AppStrings.startDesigningAr}',
              variant: LolipantsButtonVariant.secondary,
              onPressed: onStart,
            ),
          ],
        ),
      ),
    );
  }
}
