import 'dart:ui' show Locale;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/constants/orders_strings.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/orders/providers/checkout_providers.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';
import 'package:lolipants/features/sizing/models/body_measurements.dart';
import 'package:lolipants/features/sizing/providers/sizing_providers.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Read-only measurement confirmation between summary and delivery.
class SizeConfirmationScreen extends ConsumerWidget {
  /// Takes measurements from [myMeasurementsProvider].
  const SizeConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(settingsLocaleProvider);
    final measurementsState = ref.watch(myMeasurementsProvider);
    final measurements = measurementsState.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizedFromLocale(
            locale,
            OrdersStrings.confirmSizeTitle,
            OrdersStrings.confirmSizeTitleAr,
          ),
        ),
      ),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          if (measurementsState.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (measurements == null || !_hasCore(measurements))
            _Missing(locale: locale, onFix: () => context.push('/sizing'))
          else
            ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Text(
                  _sizingMessage(ref, locale),
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                _MeasurementsTable(locale: locale, measurements: measurements),
                const SizedBox(height: AppSpacing.lg),
                LolipantsButton(
                  label: localizedFromLocale(
                    locale,
                    OrdersStrings.looksGoodContinue,
                    OrdersStrings.looksGoodContinueAr,
                  ),
                  onPressed: () => context.push('/order/delivery'),
                ),
                const SizedBox(height: AppSpacing.sm),
                LolipantsButton(
                  label: localizedFromLocale(
                    locale,
                    OrdersStrings.changeMeasurements,
                    OrdersStrings.changeMeasurementsAr,
                  ),
                  variant: LolipantsButtonVariant.secondary,
                  onPressed: () => context.push('/sizing'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  bool _hasCore(BodyMeasurements m) =>
      m.height != null && m.chest != null && m.waist != null;
}

String _sizingMessage(WidgetRef ref, Locale locale) {
  final wedding = ref.read(weddingCheckoutDraftProvider)?.wedding;
  if (wedding != null) {
    return OrdersStrings.weWillFitUsingMeasurements(
      wedding.dressLabel,
      locale,
    );
  }
  final name = ref.read(checkoutDraftProvider)?.design.name ??
      localizedFromLocale(
        locale,
        OrdersStrings.yourDesign,
        OrdersStrings.yourDesignAr,
      );
  return OrdersStrings.weWillTailorUsingMeasurements(name, locale);
}

class _MeasurementsTable extends StatelessWidget {
  const _MeasurementsTable({required this.locale, required this.measurements});

  final Locale locale;
  final BodyMeasurements measurements;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, double?)>[
      (
        localizedFromLocale(
          locale,
          AppStrings.measurementHeight,
          AppStrings.measurementHeightAr,
        ),
        measurements.height,
      ),
      (
        localizedFromLocale(
          locale,
          AppStrings.measurementChest,
          AppStrings.measurementChestAr,
        ),
        measurements.chest,
      ),
      (
        localizedFromLocale(
          locale,
          AppStrings.measurementWaist,
          AppStrings.measurementWaistAr,
        ),
        measurements.waist,
      ),
      (
        localizedFromLocale(
          locale,
          AppStrings.measurementHips,
          AppStrings.measurementHipsAr,
        ),
        measurements.hips,
      ),
      (
        localizedFromLocale(
          locale,
          AppStrings.measurementShoulderWidth,
          AppStrings.measurementShoulderWidthAr,
        ),
        measurements.shoulderWidth,
      ),
      (
        localizedFromLocale(
          locale,
          AppStrings.measurementArmLength,
          AppStrings.measurementArmLengthAr,
        ),
        measurements.armLength,
      ),
    ];
    final unit = localizedFromLocale(
      locale,
      AppStrings.measurementUnitCm,
      AppStrings.measurementUnitCmAr,
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.stone,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(row.$1, style: AppTextStyles.bodyMedium),
                  ),
                  Text(
                    row.$2 == null
                        ? '—'
                        : '${row.$2!.toStringAsFixed(1)} $unit',
                    style: AppTextStyles.titleSmall,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Missing extends StatelessWidget {
  const _Missing({required this.locale, required this.onFix});

  final Locale locale;
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              localizedFromLocale(
                locale,
                OrdersStrings.measurementsNeededForOrder,
                OrdersStrings.measurementsNeededForOrderAr,
              ),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            LolipantsButton(
              label: localizedFromLocale(
                locale,
                OrdersStrings.goToSizing,
                OrdersStrings.goToSizingAr,
              ),
              onPressed: onFix,
            ),
          ],
        ),
      ),
    );
  }
}
