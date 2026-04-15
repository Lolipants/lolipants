import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/community/models/post.dart';
import 'package:lolipants/features/community/providers/community_providers.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/error_banner.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';
import 'package:lolipants/shared/widgets/lolipants_text_field.dart';

/// Community hub stub (Phase 4 wiring later).
class CommunityScreen extends ConsumerStatefulWidget {
  /// Creates the community tab.
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  final _descriptionController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  String _garmentType = 'Abaya';
  String? _submitError;

  @override
  void dispose() {
    _descriptionController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedPostsProvider(null));
    final consultationState = ref.watch(consultationRequestProvider);
    const sections = [
      _SectionData(
        titleEn: 'Fashion news',
        titleAr: 'أخبار الموضة',
        subtitleEn: 'Latest drops and trends',
        subtitleAr: 'آخر الأخبار والاتجاهات',
      ),
      _SectionData(
        titleEn: 'Designer showcase',
        titleAr: 'معرض المصممين',
        subtitleEn: 'Designs that earn commission',
        subtitleAr: 'تصاميم تكسب عمولة',
      ),
      _SectionData(
        titleEn: 'Consultations',
        titleAr: 'الاستشارات',
        subtitleEn: 'Get advice on your design',
        subtitleAr: 'احصل على نصيحة لتصميمك',
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          const ArabesqueBackground(),
          SafeArea(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.xl),
              itemCount: sections.length + 3,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          AppStrings.communityHeaderAr,
                          style: AppTextStyles.arabicLabel,
                        ),
                      ),
                      Text(
                        AppStrings.communityHeader,
                        style: AppTextStyles.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  );
                }
                if (index == sections.length + 1) {
                  return _ConsultationForm(
                    garmentType: _garmentType,
                    onGarmentTypeChanged: (value) =>
                        setState(() => _garmentType = value),
                    descriptionController: _descriptionController,
                    budgetMinController: _budgetMinController,
                    budgetMaxController: _budgetMaxController,
                    isSubmitting: consultationState.isLoading,
                    onSubmit: _submitConsultation,
                  );
                }
                if (index == sections.length + 2) {
                  return _FeedPreview(feedState: feedState);
                }
                final s = sections[index - 1];
                return _SectionCard(
                  data: s,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text(AppStrings.comingPhase4)),
                    );
                  },
                );
              },
            ),
          ),
          if (_submitError != null)
            Positioned(
              left: AppSpacing.xl,
              right: AppSpacing.xl,
              top: AppSpacing.lg,
              child: ErrorBanner(
                message: _submitError!,
                onDismiss: () => setState(() => _submitError = null),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _submitConsultation() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      setState(() => _submitError = 'Please add consultation details.');
      return;
    }
    setState(() => _submitError = null);
    final requestId = await ref
        .read(consultationRequestProvider.notifier)
        .submit(
          garmentType: _garmentType,
          description: description,
          budgetMin: _toDouble(_budgetMinController.text),
          budgetMax: _toDouble(_budgetMaxController.text),
        );
    if (!mounted) return;
    final state = ref.read(consultationRequestProvider);
    if (state.hasError || requestId == null) {
      setState(() {
        _submitError = communityErrorMessage(
          state.error!,
          fallback: 'Could not submit consultation request.',
        );
      });
      return;
    }
    _descriptionController.clear();
    _budgetMinController.clear();
    _budgetMaxController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Consultation request submitted')),
    );
  }
}

class _SectionData {
  const _SectionData({
    required this.titleEn,
    required this.titleAr,
    required this.subtitleEn,
    required this.subtitleAr,
  });

  final String titleEn;
  final String titleAr;
  final String subtitleEn;
  final String subtitleAr;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.data,
    required this.onTap,
  });

  final _SectionData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.stone,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CustomPaint(painter: _GoldDiamondPainter()),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.titleEn, style: AppTextStyles.titleMedium),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        data.titleAr,
                        style: AppTextStyles.arabicLabel,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(data.subtitleEn, style: AppTextStyles.bodyMedium),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        data.subtitleAr,
                        style: AppTextStyles.arabicBody.copyWith(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoldDiamondPainter extends CustomPainter {
  const _GoldDiamondPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2.2;
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r, c.dy)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - r, c.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FeedPreview extends StatelessWidget {
  const _FeedPreview({required this.feedState});

  final AsyncValue<List<Post>> feedState;

  @override
  Widget build(BuildContext context) {
    return feedState.when(
      data: (posts) {
        if (posts.isEmpty) {
          return Text(
            'No posts yet.',
            style: AppTextStyles.bodyMedium,
          );
        }
        final top = posts.take(3).toList(growable: false);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Latest posts', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            for (final post in top)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.stone,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  post.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium,
                ),
              ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: LinearProgressIndicator(minHeight: 2),
      ),
      error: (error, _) => Text(
        communityErrorMessage(
          error,
          fallback: 'Could not load feed preview.',
        ),
        style: AppTextStyles.bodySmall,
      ),
    );
  }
}

class _ConsultationForm extends StatelessWidget {
  const _ConsultationForm({
    required this.garmentType,
    required this.onGarmentTypeChanged,
    required this.descriptionController,
    required this.budgetMinController,
    required this.budgetMaxController,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final String garmentType;
  final ValueChanged<String> onGarmentTypeChanged;
  final TextEditingController descriptionController;
  final TextEditingController budgetMinController;
  final TextEditingController budgetMaxController;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.stone,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Request consultation', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: garmentType,
            dropdownColor: AppColors.smoke,
            items: const [
              DropdownMenuItem(value: 'Abaya', child: Text('Abaya')),
              DropdownMenuItem(value: 'Thobe', child: Text('Thobe')),
              DropdownMenuItem(value: 'Suit', child: Text('Suit')),
              DropdownMenuItem(value: 'Dress', child: Text('Dress')),
              DropdownMenuItem(value: 'Other', child: Text('Other')),
            ],
            onChanged: (value) {
              if (value != null) onGarmentTypeChanged(value);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          LolipantsTextField(
            label: 'Describe what you are looking for',
            controller: descriptionController,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: LolipantsTextField(
                  label: 'Budget min',
                  controller: budgetMinController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: LolipantsTextField(
                  label: 'Budget max',
                  controller: budgetMaxController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          LolipantsButton(
            label: 'Submit request',
            loading: isSubmitting,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

double? _toDouble(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;
  return double.tryParse(trimmed);
}
