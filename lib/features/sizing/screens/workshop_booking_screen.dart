import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/sizing/providers/sizing_providers.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';
import 'package:lolipants/shared/widgets/lolipants_text_field.dart';

/// Booking flow for workshop/home sizing.
class WorkshopBookingScreen extends ConsumerStatefulWidget {
  /// Creates workshop booking screen.
  const WorkshopBookingScreen({super.key});

  @override
  ConsumerState<WorkshopBookingScreen> createState() =>
      _WorkshopBookingScreenState();
}

class _WorkshopBookingScreenState extends ConsumerState<WorkshopBookingScreen> {
  bool _homeVisit = false;
  DateTime? _date;
  String _slot = 'Morning 9-12';
  final _address = TextEditingController();
  final _city = TextEditingController(text: 'Doha');
  final _directions = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _address.dispose();
    _city.dispose();
    _directions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.workshopTitle)),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    label: Text(AppStrings.workshopVisitOption),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    label: Text(AppStrings.workshopHomeOption),
                  ),
                ],
                selected: {_homeVisit},
                onSelectionChanged: (selected) {
                  setState(() => _homeVisit = selected.first);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              if (_homeVisit) ...[
                LolipantsTextField(
                  label: AppStrings.workshopAddressLabel,
                  controller: _address,
                ),
                const SizedBox(height: AppSpacing.sm),
                LolipantsTextField(
                  label: AppStrings.workshopCityLabel,
                  controller: _city,
                ),
                const SizedBox(height: AppSpacing.sm),
                LolipantsTextField(
                  label: AppStrings.workshopDirectionsLabel,
                  controller: _directions,
                ),
                const SizedBox(height: AppSpacing.md),
              ] else ...[
                Text(
                  AppStrings.workshopVisitAddress,
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  _date == null
                      ? AppStrings.workshopPickDate
                      : DateFormat('yyyy-MM-dd').format(_date!),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                children: [
                  'Morning 9-12',
                  'Afternoon 12-17',
                  'Evening 17-20',
                ]
                    .map(
                      (slot) => ChoiceChip(
                        label: Text(slot),
                        selected: _slot == slot,
                        onSelected: (_) => setState(() => _slot = slot),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: AppSpacing.lg),
              LolipantsButton(
                label: AppStrings.workshopConfirm,
                loading: _isSubmitting,
                onPressed: _book,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 14)),
      initialDate: now.add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() => _date = picked);
  }

  Future<void> _book() async {
    if (_date == null) {
      _show(AppStrings.workshopDateRequired);
      return;
    }
    if (_homeVisit && _address.text.trim().isEmpty) {
      _show(AppStrings.workshopAddressRequired);
      return;
    }
    setState(() => _isSubmitting = true);
    final repo = ref.read(sizingRepositoryProvider);
    final result = await repo.createBooking(
      type: _homeVisit ? 'home_visit' : 'workshop_visit',
      date: DateFormat('yyyy-MM-dd').format(_date!),
      timeSlot: _slot,
      address: _homeVisit ? _address.text.trim() : null,
      city: _city.text.trim().isEmpty ? null : _city.text.trim(),
    );
    setState(() => _isSubmitting = false);
    if (!mounted) return;
    result.fold(
      (e) => _show(
        sizingErrorMessage(
          e,
          fallback: AppStrings.workshopConfirmFailed,
        ),
      ),
      (reference) => _show(
        '${AppStrings.workshopConfirmedPrefix} $reference '
        '/ ${AppStrings.workshopConfirmedArPrefix} $reference',
      ),
    );
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
