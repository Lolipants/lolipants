import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/orders/providers/checkout_providers.dart';
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
    final measurementsState = ref.watch(myMeasurementsProvider);
    final draft = ref.watch(checkoutDraftProvider);
    final measurements = measurementsState.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm size / تأكيد المقاس')),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          if (measurementsState.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (measurements == null || !_hasCore(measurements))
            _Missing(onFix: () => context.push('/sizing'))
          else
            ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Text(
                  _sizingMessage(ref),
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                _MeasurementsTable(measurements: measurements),
                const SizedBox(height: AppSpacing.lg),
                LolipantsButton(
                  label: 'Looks good · continue',
                  onPressed: () => context.push('/order/delivery'),
                ),
                const SizedBox(height: AppSpacing.sm),
                LolipantsButton(
                  label: 'Change measurements',
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

String _sizingMessage(WidgetRef ref) {
  final wedding = ref.read(weddingCheckoutDraftProvider)?.wedding;
  if (wedding != null) {
    return 'We will fit ${wedding.dressLabel} using these measurements.';
  }
  final name = ref.read(checkoutDraftProvider)?.design.name ?? 'your design';
  return 'We will tailor $name using these measurements.';
}

class _MeasurementsTable extends StatelessWidget {
  const _MeasurementsTable({required this.measurements});

  final BodyMeasurements measurements;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, double?)>[
      ('Height', measurements.height),
      ('Chest', measurements.chest),
      ('Waist', measurements.waist),
      ('Hips', measurements.hips),
      ('Shoulder', measurements.shoulderWidth),
      ('Arm length', measurements.armLength),
    ];
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
                    row.$2 == null ? '—' : '${row.$2!.toStringAsFixed(1)} cm',
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
  const _Missing({required this.onFix});

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
              'We still need your body measurements to tailor this order.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            LolipantsButton(label: 'Go to sizing', onPressed: onFix),
          ],
        ),
      ),
    );
  }
}
