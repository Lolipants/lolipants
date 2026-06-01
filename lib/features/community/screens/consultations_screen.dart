import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/constants/community_strings.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/community/data/community_repository.dart';
import 'package:lolipants/features/community/providers/community_providers.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/error_banner.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';
import 'package:lolipants/shared/widgets/lolipants_text_field.dart';

/// Consultations hub: list the user's own requests and a submission form.
class ConsultationsScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const ConsultationsScreen({super.key});

  @override
  ConsumerState<ConsultationsScreen> createState() =>
      _ConsultationsScreenState();
}

class _ConsultationsScreenState extends ConsumerState<ConsultationsScreen> {
  final _descriptionController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  String _garmentType = 'Abaya';
  String? _error;

  @override
  void dispose() {
    _descriptionController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      setState(
        () => _error = localizedFromContext(
          context,
          CommunityStrings.describeNeedsRequired,
          CommunityStrings.describeNeedsRequiredAr,
        ),
      );
      return;
    }
    setState(() => _error = null);
    final id = await ref.read(consultationRequestProvider.notifier).submit(
          garmentType: _garmentType,
          description: description,
          budgetMin: _toDouble(_budgetMinController.text),
          budgetMax: _toDouble(_budgetMaxController.text),
        );
    if (!mounted) return;
    final state = ref.read(consultationRequestProvider);
    if (state.hasError || id == null) {
      setState(
        () => _error = communityErrorMessage(
          state.error!,
          fallback: localizedFromContext(
            context,
            CommunityStrings.couldNotSubmitConsultation,
            CommunityStrings.couldNotSubmitConsultationAr,
          ),
        ),
      );
      return;
    }
    _descriptionController.clear();
    _budgetMinController.clear();
    _budgetMaxController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          localizedFromContext(
            context,
            CommunityStrings.consultationSubmitted,
            CommunityStrings.consultationSubmittedAr,
          ),
        ),
      ),
    );
    ref.invalidate(myConsultationsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final consultations = ref.watch(myConsultationsProvider);
    final submitState = ref.watch(consultationRequestProvider);
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          localizedFromContext(
            context,
            CommunityStrings.consultationsTitle,
            CommunityStrings.consultationsTitleAr,
          ),
          style: AppTextStyles.titleLarge,
        ),
      ),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          SafeArea(
            child: RefreshIndicator(
              color: AppColors.gold,
              backgroundColor: AppColors.ink,
              onRefresh: () async {
                ref.invalidate(myConsultationsProvider);
              },
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
                  if (_error != null) ...[
                    ErrorBanner(
                      message: _error!,
                      onDismiss: () => setState(() => _error = null),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  _Form(
                    garmentType: _garmentType,
                    onGarmentTypeChanged: (value) =>
                        setState(() => _garmentType = value),
                    descriptionController: _descriptionController,
                    budgetMinController: _budgetMinController,
                    budgetMaxController: _budgetMaxController,
                    submitting: submitState.isLoading,
                    onSubmit: _submit,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    localizedFromContext(
                      context,
                      CommunityStrings.yourRequests,
                      CommunityStrings.yourRequestsAr,
                    ),
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  consultations.when(
                    data: (items) => items.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Text(
                              localizedFromContext(
                                context,
                                CommunityStrings.noConsultations,
                                CommunityStrings.noConsultationsAr,
                              ),
                              style: AppTextStyles.bodyMedium,
                            ),
                          )
                        : Column(
                            children: [
                              for (final c in items) _ConsultationTile(item: c),
                            ],
                          ),
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.gold),
                      ),
                    ),
                    error: (e, _) => Text(
                      communityErrorMessage(
                        e,
                        fallback: localizedFromContext(
                          context,
                          CommunityStrings.consultationsLoadError,
                          CommunityStrings.consultationsLoadErrorAr,
                        ),
                      ),
                    ),
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

String _localizedGarmentType(BuildContext context, String value) {
  return switch (value) {
    'Abaya' => localizedFromContext(
      context,
      CommunityStrings.filterAbaya,
      CommunityStrings.filterAbayaAr,
    ),
    'Thobe' => localizedFromContext(
      context,
      CommunityStrings.filterThobe,
      CommunityStrings.filterThobeAr,
    ),
    'Suit' => localizedFromContext(
      context,
      CommunityStrings.filterSuit,
      CommunityStrings.filterSuitAr,
    ),
    'Dress' => localizedFromContext(
      context,
      CommunityStrings.filterDress,
      CommunityStrings.filterDressAr,
    ),
    'Other' => localizedFromContext(
      context,
      CommunityStrings.garmentOther,
      CommunityStrings.garmentOtherAr,
    ),
    _ => value,
  };
}

double? _toDouble(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  return double.tryParse(trimmed);
}

class _Form extends StatelessWidget {
  const _Form({
    required this.garmentType,
    required this.onGarmentTypeChanged,
    required this.descriptionController,
    required this.budgetMinController,
    required this.budgetMaxController,
    required this.submitting,
    required this.onSubmit,
  });

  final String garmentType;
  final ValueChanged<String> onGarmentTypeChanged;
  final TextEditingController descriptionController;
  final TextEditingController budgetMinController;
  final TextEditingController budgetMaxController;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.stone,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizedFromContext(
              context,
              CommunityStrings.requestConsultation,
              CommunityStrings.requestConsultationAr,
            ),
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: garmentType,
            dropdownColor: AppColors.smoke,
            items: [
              DropdownMenuItem(
                value: 'Abaya',
                child: Text(_localizedGarmentType(context, 'Abaya')),
              ),
              if (kFeatureMens) ...[
                DropdownMenuItem(
                  value: 'Thobe',
                  child: Text(_localizedGarmentType(context, 'Thobe')),
                ),
                DropdownMenuItem(
                  value: 'Suit',
                  child: Text(_localizedGarmentType(context, 'Suit')),
                ),
              ],
              DropdownMenuItem(
                value: 'Dress',
                child: Text(_localizedGarmentType(context, 'Dress')),
              ),
              DropdownMenuItem(
                value: 'Other',
                child: Text(_localizedGarmentType(context, 'Other')),
              ),
            ],
            onChanged: (value) {
              if (value != null) onGarmentTypeChanged(value);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          LolipantsTextField(
            label: localizedFromContext(
              context,
              CommunityStrings.describeNeeds,
              CommunityStrings.describeNeedsAr,
            ),
            controller: descriptionController,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: LolipantsTextField(
                  label: localizedFromContext(
                    context,
                    CommunityStrings.budgetMinShort,
                    CommunityStrings.budgetMinShortAr,
                  ),
                  controller: budgetMinController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: LolipantsTextField(
                  label: localizedFromContext(
                    context,
                    CommunityStrings.budgetMaxShort,
                    CommunityStrings.budgetMaxShortAr,
                  ),
                  controller: budgetMaxController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          LolipantsButton(
            label: localizedFromContext(
              context,
              CommunityStrings.submitRequest,
              CommunityStrings.submitRequestAr,
            ),
            loading: submitting,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _ConsultationTile extends StatelessWidget {
  const _ConsultationTile({required this.item});

  final Consultation item;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.yMMMd();
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.stone,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(item.garmentType, style: AppTextStyles.titleSmall),
              const Spacer(),
              _StatusPill(status: item.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            fmt.format(item.createdAt.toLocal()),
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            item.description,
            style: AppTextStyles.bodyLarge,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          if (item.budgetMin != null || item.budgetMax != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${localizedFromContext(context, CommunityStrings.budgetRange, CommunityStrings.budgetRangeAr)} '
              '${item.budgetMin?.toStringAsFixed(0) ?? '-'} - '
              '${item.budgetMax?.toStringAsFixed(0) ?? '-'}',
              style: AppTextStyles.labelGold,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colour = switch (status.toLowerCase()) {
      'closed' => AppColors.fog,
      'in_progress' => AppColors.gold,
      _ => AppColors.tealLight,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: colour),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTextStyles.labelGold.copyWith(color: colour),
      ),
    );
  }
}
