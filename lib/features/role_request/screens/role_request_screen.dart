import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/errors/app_exception_message_mapper.dart';
import 'package:lolipants/features/role_request/providers/role_request_providers.dart';
import 'package:lolipants/features/role_request/widgets/partner_application_wizard.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/locale_bilingual_text.dart';

bool _hasPendingRoleRequest(List<Map<String, dynamic>> rows) {
  for (final r in rows) {
    if ((r['status']?.toString() ?? '') == 'pending') return true;
  }
  return false;
}

/// Strips trailing slashes so we can compare configured origins.
String _envOrigin(String? raw) {
  final s = raw?.trim() ?? '';
  if (s.isEmpty) return '';
  return s.replaceAll(RegExp(r'/+$'), '');
}

/// Lets a customer request tailor or delivery partner access.
class RoleRequestScreen extends ConsumerWidget {
  /// Creates the screen.
  const RoleRequestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiBase = dotenv.env['API_BASE_URL']?.trim() ?? '';
    final authBase = dotenv.env['BETTER_AUTH_BASE_URL']?.trim() ?? '';
    final apiPointsAtAuth = apiBase.isNotEmpty &&
        authBase.isNotEmpty &&
        _envOrigin(apiBase) == _envOrigin(authBase);
    final history =
        apiBase.isNotEmpty && !apiPointsAtAuth ? ref.watch(myRoleRequestsProvider) : null;

    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        title: Text(AppStrings.partnerTitleEn),
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.sand,
      ),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.md,
                    AppSpacing.xl,
                    AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LocaleBilingualText(
                        en: AppStrings.partnerTitleEn,
                        ar: AppStrings.partnerTitleAr,
                        enStyle: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.gold,
                        ),
                        arStyle: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.gold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      LocaleBilingualText(
                        en: AppStrings.partnerHeaderSubtitleEn,
                        ar: AppStrings.partnerHeaderSubtitleAr,
                        enStyle: AppTextStyles.bodyMedium,
                        arStyle: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.dust,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: apiBase.isEmpty
                      ? _EnvMissingPanel(
                          onOpenSettings: () {
                            context.push('/profile/settings');
                          },
                        )
                      : apiPointsAtAuth
                          ? _WrongApiBasePanel(
                              onOpenSettings: () {
                                context.push('/profile/settings');
                              },
                            )
                          : history!.when(
                              loading: () => const _PartnerLoadingPanel(),
                              error: (e, _) => _PartnerErrorPanel(
                                error: e,
                                onRetry: () =>
                                    ref.invalidate(myRoleRequestsProvider),
                              ),
                          data: (rows) {
                            final pending = _hasPendingRoleRequest(rows);
                            return SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.xl,
                                0,
                                AppSpacing.xl,
                                AppSpacing.xxl,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (pending) ...[
                                    Card(
                                      color: AppColors.stone,
                                      child: Padding(
                                        padding: const EdgeInsets.all(
                                          AppSpacing.md,
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.hourglass_top,
                                              color: AppColors.ember,
                                            ),
                                            const SizedBox(
                                              width: AppSpacing.md,
                                            ),
                                            Expanded(
                                              child: Text(
                                                AppStrings.partnerPendingBanner,
                                                style: AppTextStyles.bodyMedium,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                  ],
                                  Text(
                                    AppStrings.partnerPreviousRequests,
                                    style: AppTextStyles.titleSmall,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  if (rows.isEmpty)
                                    Text(
                                      AppStrings.partnerNoRequestsYet,
                                      style: AppTextStyles.bodySmall,
                                    )
                                  else
                                    ...rows.map((r) {
                                      final st = r['status']?.toString() ?? '';
                                      final role =
                                          r['requested_role']?.toString() ??
                                              r['requestedRole']?.toString() ??
                                              '';
                                      final created =
                                          r['created_at']?.toString() ?? '';
                                      return ListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        title: Text('$role · $st'),
                                        subtitle: Text(
                                          created,
                                          style: AppTextStyles.bodySmall,
                                        ),
                                      );
                                    }),
                                  if (!pending) ...[
                                    const SizedBox(height: AppSpacing.xl),
                                    const PartnerApplicationWizard(),
                                  ],
                                  const SizedBox(height: AppSpacing.lg),
                                  Text(
                                    AppStrings.partnerPostApprovalHint,
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PartnerLoadingPanel extends StatelessWidget {
  const _PartnerLoadingPanel();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.gold),
            const SizedBox(height: AppSpacing.lg),
            Text(
              AppStrings.partnerLoadingRequests,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PartnerErrorPanel extends StatelessWidget {
  const _PartnerErrorPanel({
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = error is AppException
        ? mapAppExceptionMessage(
            error as AppException,
            fallback: 'Could not load requests.',
            networkMessage:
                'Network issue. Check your connection and try again.',
            authMessage: 'Session expired. Sign in again to continue.',
          )
        : error.toString();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_outlined, color: AppColors.dust, size: 40),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: onRetry,
              child: const Text(AppStrings.partnerRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class _WrongApiBasePanel extends StatelessWidget {
  const _WrongApiBasePanel({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Card(
          color: AppColors.stone,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.link_off_outlined, color: AppColors.rubyLight),
                const SizedBox(height: AppSpacing.md),
                Text(
                  AppStrings.errorApiBaseUrlSameAsAuth,
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton(
                  onPressed: onOpenSettings,
                  child: Text(AppStrings.settings),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EnvMissingPanel extends StatelessWidget {
  const _EnvMissingPanel({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Card(
          color: AppColors.stone,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.settings_suggest_outlined,
                    color: AppColors.gold),
                const SizedBox(height: AppSpacing.md),
                Text(
                  AppStrings.errorApiBaseUrlMissing,
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton(
                  onPressed: onOpenSettings,
                  child: Text(AppStrings.settings),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
