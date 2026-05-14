import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/errors/app_exception_message_mapper.dart';
import 'package:lolipants/features/role_request/providers/role_request_providers.dart';

/// Multi-step tailor/delivery partner application (submits via existing API).
class PartnerApplicationWizard extends ConsumerStatefulWidget {
  /// Creates the wizard.
  const PartnerApplicationWizard({super.key});

  @override
  ConsumerState<PartnerApplicationWizard> createState() =>
      _PartnerApplicationWizardState();
}

class _PartnerApplicationWizardState
    extends ConsumerState<PartnerApplicationWizard> {
  final _pageController = PageController();
  int _step = 0;
  static const _stepCount = 4;

  String _role = 'tailor';

  final _cityCtrl = TextEditingController();
  final _yearsCtrl = TextEditingController();
  final _workshopCtrl = TextEditingController();
  final _portfolioCtrl = TextEditingController();
  final _specialtiesCtrl = TextEditingController();

  final _vehicleCtrl = TextEditingController();
  final _coverageCtrl = TextEditingController();
  final _availabilityCtrl = TextEditingController();

  final _reviewNoteCtrl = TextEditingController();

  bool _submitting = false;

  @override
  void dispose() {
    _pageController.dispose();
    _cityCtrl.dispose();
    _yearsCtrl.dispose();
    _workshopCtrl.dispose();
    _portfolioCtrl.dispose();
    _specialtiesCtrl.dispose();
    _vehicleCtrl.dispose();
    _coverageCtrl.dispose();
    _availabilityCtrl.dispose();
    _reviewNoteCtrl.dispose();
    super.dispose();
  }

  void _goToStep(int i) {
    setState(() => _step = i);
    _pageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  bool _detailsValid() {
    if (_role == 'tailor') {
      return _cityCtrl.text.trim().isNotEmpty &&
          _yearsCtrl.text.trim().isNotEmpty;
    }
    return _vehicleCtrl.text.trim().isNotEmpty &&
        _coverageCtrl.text.trim().isNotEmpty;
  }

  String _composeMessage() {
    final b = StringBuffer()
      ..writeln('--- Lolipants partner application ---')
      ..writeln('Requested role: $_role')
      ..writeln('');
    if (_role == 'tailor') {
      b
        ..writeln('City/region: ${_cityCtrl.text.trim()}')
        ..writeln('Years experience: ${_yearsCtrl.text.trim()}');
      if (_workshopCtrl.text.trim().isNotEmpty) {
        b.writeln('Workshop/studio: ${_workshopCtrl.text.trim()}');
      }
      if (_portfolioCtrl.text.trim().isNotEmpty) {
        b.writeln('Portfolio/URL: ${_portfolioCtrl.text.trim()}');
      }
      if (_specialtiesCtrl.text.trim().isNotEmpty) {
        b.writeln('Specialties: ${_specialtiesCtrl.text.trim()}');
      }
    } else {
      b
        ..writeln('Vehicle: ${_vehicleCtrl.text.trim()}')
        ..writeln('Coverage areas: ${_coverageCtrl.text.trim()}');
      if (_availabilityCtrl.text.trim().isNotEmpty) {
        b.writeln('Availability: ${_availabilityCtrl.text.trim()}');
      }
    }
    final note = _reviewNoteCtrl.text.trim();
    if (note.isNotEmpty) {
      b
        ..writeln('')
        ..writeln('Additional notes:')
        ..writeln(note);
    }
    return b.toString();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final repo = ref.read(roleRequestRepositoryProvider);
    final result = await repo.createRequest(
      requestedRole: _role,
      message: _composeMessage(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    result.fold(
      (err) {
        final msg = mapAppExceptionMessage(
          err,
          fallback: 'Request failed.',
          networkMessage: 'Network issue.',
          authMessage: 'Session issue.',
          statusMessages: {
            409: AppStrings.partnerErrorPendingExists,
          },
        );
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      },
      (_) {
        ref.invalidate(myRoleRequestsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppStrings.partnerDoneTitle}\n${AppStrings.partnerDoneBody}',
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: List.generate(_stepCount, (i) {
            final done = i < _step;
            final on = i == _step;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 3,
                  decoration: BoxDecoration(
                    color: done || on ? AppColors.gold : AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final pageHeight = (constraints.maxHeight.isFinite
                    ? constraints.maxHeight * 0.85
                    : MediaQuery.sizeOf(context).height * 0.42)
                .clamp(280.0, 520.0);
            return SizedBox(
              height: pageHeight,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _step = i),
                children: [
                  _WelcomePage(onNext: () => _goToStep(1)),
                  _RolePage(
                    selected: _role,
                    onChanged: (v) => setState(() => _role = v),
                    onNext: () => _goToStep(2),
                    onBack: () => _goToStep(0),
                  ),
                  _DetailsPage(
                    role: _role,
                    cityCtrl: _cityCtrl,
                    yearsCtrl: _yearsCtrl,
                    workshopCtrl: _workshopCtrl,
                    portfolioCtrl: _portfolioCtrl,
                    specialtiesCtrl: _specialtiesCtrl,
                    vehicleCtrl: _vehicleCtrl,
                    coverageCtrl: _coverageCtrl,
                    availabilityCtrl: _availabilityCtrl,
                    onNext: () {
                      if (!_detailsValid()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(AppStrings.partnerDetailsValidation),
                          ),
                        );
                        return;
                      }
                      _goToStep(3);
                    },
                    onBack: () => _goToStep(1),
                  ),
                  _ReviewPage(
                    role: _role,
                    city: _cityCtrl.text,
                    years: _yearsCtrl.text,
                    workshop: _workshopCtrl.text,
                    portfolio: _portfolioCtrl.text,
                    specialties: _specialtiesCtrl.text,
                    vehicle: _vehicleCtrl.text,
                    coverage: _coverageCtrl.text,
                    availability: _availabilityCtrl.text,
                    noteCtrl: _reviewNoteCtrl,
                    submitting: _submitting,
                    onSubmit: _submit,
                    onBack: () => _goToStep(2),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.partnerWelcomeTitle, style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppStrings.partnerWelcomeTitleAr,
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.gold),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(AppStrings.partnerWelcomeBody, style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.partnerWelcomeBodyAr,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.dust),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: AppSpacing.xl),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: onNext,
              child: const Text(AppStrings.partnerWizardNext),
            ),
          ),
        ],
      ),
    );
  }
}

class _RolePage extends StatelessWidget {
  const _RolePage({
    required this.selected,
    required this.onChanged,
    required this.onNext,
    required this.onBack,
  });

  final String selected;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.partnerChoosePathTitle,
            style: AppTextStyles.titleLarge,
          ),
          Text(
            AppStrings.partnerChoosePathTitleAr,
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.gold),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: AppSpacing.lg),
          _RoleCard(
            title: AppStrings.partnerRoleTailorTitle,
            bullets: AppStrings.partnerRoleTailorBullets,
            icon: Icons.cut,
            selected: selected == 'tailor',
            onTap: () => onChanged('tailor'),
          ),
          const SizedBox(height: AppSpacing.md),
          _RoleCard(
            title: AppStrings.partnerRoleDeliveryTitle,
            bullets: AppStrings.partnerRoleDeliveryBullets,
            icon: Icons.delivery_dining,
            selected: selected == 'delivery',
            onTap: () => onChanged('delivery'),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              OutlinedButton(
                onPressed: onBack,
                child: const Text(AppStrings.partnerWizardBack),
              ),
              const Spacer(),
              FilledButton(
                onPressed: onNext,
                child: const Text(AppStrings.partnerWizardNext),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.bullets,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String bullets;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.stone,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.borderDefault,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.gold, size: 28),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.titleSmall),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      bullets,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.dust,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: AppColors.gold, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailsPage extends StatelessWidget {
  const _DetailsPage({
    required this.role,
    required this.cityCtrl,
    required this.yearsCtrl,
    required this.workshopCtrl,
    required this.portfolioCtrl,
    required this.specialtiesCtrl,
    required this.vehicleCtrl,
    required this.coverageCtrl,
    required this.availabilityCtrl,
    required this.onNext,
    required this.onBack,
  });

  final String role;
  final TextEditingController cityCtrl;
  final TextEditingController yearsCtrl;
  final TextEditingController workshopCtrl;
  final TextEditingController portfolioCtrl;
  final TextEditingController specialtiesCtrl;
  final TextEditingController vehicleCtrl;
  final TextEditingController coverageCtrl;
  final TextEditingController availabilityCtrl;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final tailor = role == 'tailor';
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.partnerDetailsTitle,
            style: AppTextStyles.titleLarge,
          ),
          Text(
            AppStrings.partnerDetailsTitleAr,
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.gold),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (tailor) ...[
            TextField(
              controller: cityCtrl,
              decoration: const InputDecoration(
                labelText: AppStrings.partnerFieldCityRegion,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: yearsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: AppStrings.partnerFieldYearsExperience,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: workshopCtrl,
              decoration: const InputDecoration(
                labelText: AppStrings.partnerFieldWorkshopName,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: portfolioCtrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: AppStrings.partnerFieldPortfolioUrl,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: specialtiesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: AppStrings.partnerFieldSpecialties,
                border: OutlineInputBorder(),
              ),
            ),
          ] else ...[
            TextField(
              controller: vehicleCtrl,
              decoration: const InputDecoration(
                labelText: AppStrings.partnerFieldVehicle,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: coverageCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: AppStrings.partnerFieldCoverage,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: availabilityCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: AppStrings.partnerFieldAvailability,
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              OutlinedButton(
                onPressed: onBack,
                child: const Text(AppStrings.partnerWizardBack),
              ),
              const Spacer(),
              FilledButton(
                onPressed: onNext,
                child: const Text(AppStrings.partnerWizardNext),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewPage extends StatelessWidget {
  const _ReviewPage({
    required this.role,
    required this.city,
    required this.years,
    required this.workshop,
    required this.portfolio,
    required this.specialties,
    required this.vehicle,
    required this.coverage,
    required this.availability,
    required this.noteCtrl,
    required this.submitting,
    required this.onSubmit,
    required this.onBack,
  });

  final String role;
  final String city;
  final String years;
  final String workshop;
  final String portfolio;
  final String specialties;
  final String vehicle;
  final String coverage;
  final String availability;
  final TextEditingController noteCtrl;
  final bool submitting;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final tailor = role == 'tailor';
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.partnerReviewTitle, style: AppTextStyles.titleLarge),
          Text(
            AppStrings.partnerReviewTitleAr,
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.gold),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Role: $role', style: AppTextStyles.bodyMedium),
          if (tailor) ...[
            _ReviewLine(AppStrings.partnerFieldCityRegion, city),
            _ReviewLine(AppStrings.partnerFieldYearsExperience, years),
            if (workshop.trim().isNotEmpty)
              _ReviewLine(AppStrings.partnerFieldWorkshopName, workshop),
            if (portfolio.trim().isNotEmpty)
              _ReviewLine(AppStrings.partnerFieldPortfolioUrl, portfolio),
            if (specialties.trim().isNotEmpty)
              _ReviewLine(AppStrings.partnerFieldSpecialties, specialties),
          ] else ...[
            _ReviewLine(AppStrings.partnerFieldVehicle, vehicle),
            _ReviewLine(AppStrings.partnerFieldCoverage, coverage),
            if (availability.trim().isNotEmpty)
              _ReviewLine(AppStrings.partnerFieldAvailability, availability),
          ],
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: noteCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: AppStrings.partnerReviewNoteLabel,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              OutlinedButton(
                onPressed: submitting ? null : onBack,
                child: const Text(AppStrings.partnerWizardBack),
              ),
              const Spacer(),
              FilledButton(
                onPressed: submitting ? null : onSubmit,
                child: submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.ink,
                        ),
                      )
                    : const Text(AppStrings.partnerWizardSubmit),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewLine extends StatelessWidget {
  const _ReviewLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final base = AppTextStyles.bodySmall.copyWith(color: AppColors.dust);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Text.rich(
        TextSpan(
          style: base,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value.trim().isEmpty ? '—' : value.trim()),
          ],
        ),
      ),
    );
  }
}
