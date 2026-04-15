import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
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
        title: const Text(AppStrings.myMeasurements),
        actions: [
          IconButton(
            tooltip: AppStrings.sizingOptionsTooltip,
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
                    onRescan: () => context.push('/sizing/ai'),
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
        ? AppStrings.measurementUnknown
        : DateFormat('yyyy-MM-dd HH:mm').format(measurements.savedAt!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.myMeasurementsSummaryTitle, style: AppTextStyles.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${AppStrings.myMeasurementsLastUpdatedPrefix} $lastUpdated '
          '/ ${AppStrings.myMeasurementsLastUpdatedAr}',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        _MeasurementRow(label: AppStrings.measurementChest, value: measurements.chest),
        _MeasurementRow(label: AppStrings.measurementWaist, value: measurements.waist),
        _MeasurementRow(label: AppStrings.measurementHips, value: measurements.hips),
        _MeasurementRow(
          label: AppStrings.measurementShoulderWidth,
          value: measurements.shoulderWidth,
        ),
        _MeasurementRow(label: AppStrings.measurementHeight, value: measurements.height),
        _MeasurementRow(
          label: AppStrings.measurementArmLength,
          value: measurements.armLength,
        ),
        _TextMeasurementRow(
          label: AppStrings.measurementPreferredSize,
          value: measurements.preferredSize,
        ),
        const SizedBox(height: AppSpacing.lg),
        LolipantsButton(label: AppStrings.myMeasurementsEdit, onPressed: onEdit),
        const SizedBox(height: AppSpacing.sm),
        LolipantsButton(
          label: AppStrings.myMeasurementsRescan,
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
          AppStrings.myMeasurementsEmpty,
          style: AppTextStyles.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        LolipantsButton(
          label: AppStrings.myMeasurementsTakeNow,
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
                : '${value!.toStringAsFixed(1)} ${AppStrings.measurementUnitCm}',
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
