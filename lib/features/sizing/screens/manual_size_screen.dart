import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/sizing/models/body_measurements.dart';
import 'package:lolipants/features/sizing/providers/sizing_providers.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Manual measurements entry form.
class ManualSizeScreen extends ConsumerStatefulWidget {
  /// Creates manual sizing screen.
  const ManualSizeScreen({super.key});

  @override
  ConsumerState<ManualSizeScreen> createState() => _ManualSizeScreenState();
}

class _ManualSizeScreenState extends ConsumerState<ManualSizeScreen> {
  final _height = TextEditingController();
  final _chest = TextEditingController();
  final _waist = TextEditingController();
  final _hips = TextEditingController();
  final _shoulder = TextEditingController();
  final _arm = TextEditingController();
  String? _preferredSize;
  bool _isSaving = false;
  bool _hydrated = false;

  @override
  void dispose() {
    _height.dispose();
    _chest.dispose();
    _waist.dispose();
    _hips.dispose();
    _shoulder.dispose();
    _arm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(myMeasurementsProvider).valueOrNull;
    if (!_hydrated && current != null) {
      _height.text = _toText(current.height);
      _chest.text = _toText(current.chest);
      _waist.text = _toText(current.waist);
      _hips.text = _toText(current.hips);
      _shoulder.text = _toText(current.shoulderWidth);
      _arm.text = _toText(current.armLength);
      _preferredSize = current.preferredSize;
      _hydrated = true;
    }

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.manualMeasurementsTitle)),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              Text(
                AppStrings.manualMeasurementsSubtitle,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              _Input(label: AppStrings.measurementHeight, controller: _height),
              _Input(label: AppStrings.measurementChest, controller: _chest),
              _Input(label: AppStrings.measurementWaist, controller: _waist),
              _Input(label: AppStrings.measurementHips, controller: _hips),
              _Input(
                label: AppStrings.measurementShoulderWidth,
                controller: _shoulder,
              ),
              _Input(label: AppStrings.measurementArmLength, controller: _arm),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                children: ['XS', 'S', 'M', 'L', 'XL', 'XXL']
                    .map(
                      (size) => ChoiceChip(
                        label: Text(size),
                        selected: _preferredSize == size,
                        onSelected: (_) => setState(() => _preferredSize = size),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: AppSpacing.lg),
              LolipantsButton(
                label: AppStrings.manualSave,
                loading: _isSaving,
                onPressed: _save,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final values = [
      _parse(_height.text),
      _parse(_chest.text),
      _parse(_waist.text),
      _parse(_hips.text),
      _parse(_shoulder.text),
      _parse(_arm.text),
    ];
    if (values.every((v) => v == null)) {
      _show(AppStrings.manualErrorAtLeastOne);
      return;
    }
    if (values.any((v) => v != null && v > 300)) {
      _show(AppStrings.manualErrorMax300);
      return;
    }
    setState(() => _isSaving = true);
    await ref.read(myMeasurementsProvider.notifier).save(
          BodyMeasurements(
            height: values[0],
            chest: values[1],
            waist: values[2],
            hips: values[3],
            shoulderWidth: values[4],
            armLength: values[5],
            preferredSize: _preferredSize,
          ),
        );
    setState(() => _isSaving = false);
    if (!mounted) return;
    final next = ref.read(myMeasurementsProvider);
    if (next.hasError) {
      _show(
        sizingErrorMessage(
          next.error!,
          fallback: AppStrings.manualSaveFailed,
        ),
      );
      return;
    }
    _show(AppStrings.manualSaved);
    if (context.mounted) context.pop();
  }

  double? _parse(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _toText(double? value) => value == null ? '' : value.toStringAsFixed(1);
}

class _Input extends StatelessWidget {
  const _Input({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
