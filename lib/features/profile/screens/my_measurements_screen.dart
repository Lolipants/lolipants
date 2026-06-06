import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lolipants/core/ai/ai_data_sharing_consent.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/constants/profile_strings.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/sizing/models/body_measurements.dart';
import 'package:lolipants/features/sizing/providers/sizing_providers.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Displays current user's saved measurements.
class MyMeasurementsScreen extends ConsumerStatefulWidget {
  /// Creates my measurements screen.
  const MyMeasurementsScreen({super.key});

  @override
  ConsumerState<MyMeasurementsScreen> createState() =>
      _MyMeasurementsScreenState();
}

class _MyMeasurementsScreenState extends ConsumerState<MyMeasurementsScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myMeasurementsProvider);
    final measurements = state.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizedFromContext(
            context,
            ProfileStrings.myMeasurements,
            ProfileStrings.myMeasurementsAr,
          ),
        ),
        actions: [
          IconButton(
            tooltip: localizedFromContext(
              context,
              AppStrings.sizingOptionsTooltip,
              AppStrings.sizingOptionsTooltipAr,
            ),
            onPressed: () => context.push('/sizing'),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          RefreshIndicator(
            onRefresh: () => ref.read(myMeasurementsProvider.notifier).reload(),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                if (state.isLoading && measurements == null)
                  const Center(child: CircularProgressIndicator())
                else if (measurements == null)
                  _EmptyMeasurements(
                    onTakeMeasurements: () => context.push('/sizing'),
                  )
                else
                  _MeasurementSummary(
                    measurements: measurements,
                    onEdit: () => context.push('/sizing/manual'),
                    onRescan: () async {
                      final allowed =
                          await AiDataSharingConsent.ensure(context, ref);
                      if (!allowed || !context.mounted) return;
                      await context.push('/sizing/ai');
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MeasurementSummary extends StatelessWidget {
  const _MeasurementSummary({
    required this.measurements,
    required this.onEdit,
    required this.onRescan,
  });

  final BodyMeasurements measurements;
  final VoidCallback onEdit;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    final lastUpdated = measurements.savedAt == null
        ? localizedFromContext(
            context,
            AppStrings.measurementUnknown,
            AppStrings.measurementUnknownAr,
          )
        : DateFormat('yyyy-MM-dd HH:mm').format(measurements.savedAt!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pickSlashFromContext(context, AppStrings.myMeasurementsSummaryTitle),
          style: AppTextStyles.titleLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${localizedFromContext(context, AppStrings.myMeasurementsLastUpdatedPrefix, AppStrings.myMeasurementsLastUpdatedPrefixAr)} $lastUpdated',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        _MeasurementRow(
          label: localizedFromContext(
            context,
            AppStrings.measurementChest,
            AppStrings.measurementChestAr,
          ),
          value: measurements.chest,
        ),
        _MeasurementRow(
          label: localizedFromContext(
            context,
            AppStrings.measurementWaist,
            AppStrings.measurementWaistAr,
          ),
          value: measurements.waist,
        ),
        _MeasurementRow(
          label: localizedFromContext(
            context,
            AppStrings.measurementHips,
            AppStrings.measurementHipsAr,
          ),
          value: measurements.hips,
        ),
        _MeasurementRow(
          label: localizedFromContext(
            context,
            AppStrings.measurementShoulderWidth,
            AppStrings.measurementShoulderWidthAr,
          ),
          value: measurements.shoulderWidth,
        ),
        _MeasurementRow(
          label: localizedFromContext(
            context,
            AppStrings.measurementHeight,
            AppStrings.measurementHeightAr,
          ),
          value: measurements.height,
        ),
        _MeasurementRow(
          label: localizedFromContext(
            context,
            AppStrings.measurementArmLength,
            AppStrings.measurementArmLengthAr,
          ),
          value: measurements.armLength,
        ),
        _TextMeasurementRow(
          label: localizedFromContext(
            context,
            AppStrings.measurementPreferredSize,
            AppStrings.measurementPreferredSizeAr,
          ),
          value: measurements.preferredSize,
        ),
        const SizedBox(height: AppSpacing.lg),
        LolipantsButton(
          label: pickSlashFromContext(context, AppStrings.myMeasurementsEdit),
          onPressed: onEdit,
        ),
        const SizedBox(height: AppSpacing.sm),
        LolipantsButton(
          label: pickSlashFromContext(context, AppStrings.myMeasurementsRescan),
          variant: LolipantsButtonVariant.secondary,
          onPressed: onRescan,
        ),
      ],
    );
  }
}

class _EmptyMeasurements extends StatelessWidget {
  const _EmptyMeasurements({required this.onTakeMeasurements});

  final VoidCallback onTakeMeasurements;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 120),
        Text(
          pickSlashFromContext(context, AppStrings.myMeasurementsEmpty),
          style: AppTextStyles.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        LolipantsButton(
          label: pickSlashFromContext(context, AppStrings.myMeasurementsTakeNow),
          onPressed: onTakeMeasurements,
        ),
      ],
    );
  }
}

class _MeasurementRow extends StatelessWidget {
  const _MeasurementRow({required this.label, required this.value});

  final String label;
  final double? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          Text(
            value == null
                ? '-'
                : '${value!.toStringAsFixed(1)} ${localizedFromContext(context, AppStrings.measurementUnitCm, AppStrings.measurementUnitCmAr)}',
            style: AppTextStyles.titleSmall,
          ),
        ],
      ),
    );
  }
}

class _TextMeasurementRow extends StatelessWidget {
  const _TextMeasurementRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          Text(value ?? '-', style: AppTextStyles.titleSmall),
        ],
      ),
    );
  }
}
