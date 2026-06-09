import 'dart:ui' show Locale;

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
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/role_request/providers/role_request_providers.dart';
import 'package:lolipants/features/role_request/widgets/partner_application_wizard.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';

bool _hasPendingRoleRequest(List<Map<String, dynamic>> rows) {
  for (final r in rows) {
    if ((r['status']?.toString() ?? '') == 'pending') return true;
  }
  return false;
}

String _localizedPartnerRole(Locale locale, String role) {
  switch (role) {
    case 'tailor':
      return localizedFromLocale(
        locale,
        AppStrings.partnerRoleTailorTitle,
        AppStrings.partnerRoleTailorTitleAr,
      );
    case 'delivery':
      return localizedFromLocale(
        locale,
        AppStrings.partnerRoleDeliveryTitle,
        AppStrings.partnerRoleDeliveryTitleAr,
      );
    default:
      return role;
  }
}

String _localizedPartnerStatus(Locale locale, String status) {
  switch (status) {
    case 'pending':
      return localizedFromLocale(
        locale,
        AppStrings.partnerStatusPending,
        AppStrings.partnerStatusPendingAr,
      );
    case 'approved':
      return localizedFromLocale(
        locale,
        AppStrings.partnerStatusApproved,
        AppStrings.partnerStatusApprovedAr,
      );
    case 'rejected':
      return localizedFromLocale(
        locale,
        AppStrings.partnerStatusRejected,
        AppStrings.partnerStatusRejectedAr,
      );
    default:
      return status;
  }
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
    final locale = ref.watch(settingsLocaleProvider);
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
        title: Text(
          localizedFromLocale(
            locale,
            AppStrings.partnerTitleEn,
            AppStrings.partnerTitleAr,
          ),
        ),
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
                      Text(
                        localizedFromLocale(
                          locale,
                          AppStrings.partnerTitleEn,
                          AppStrings.partnerTitleAr,
                        ),
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.gold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        localizedFromLocale(
                          locale,
                          AppStrings.partnerHeaderSubtitleEn,
                          AppStrings.partnerHeaderSubtitleAr,
                        ),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.dust,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: apiBase.isEmpty
                      ? _EnvMissingPanel(
                          locale: locale,
                          onOpenSettings: () {
                            context.push('/profile/settings');
                          },
                        )
                      : apiPointsAtAuth
                          ? _WrongApiBasePanel(
                              locale: locale,
                              onOpenSettings: () {
                                context.push('/profile/settings');
                              },
                            )
                          : history!.when(
                              loading: () => _PartnerLoadingPanel(locale: locale),
                              error: (e, _) => _PartnerErrorPanel(
                                locale: locale,
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
                                                localizedFromLocale(
                                                  locale,
                                                  AppStrings.partnerPendingBanner,
                                                  AppStrings.partnerPendingBannerAr,
                                                ),
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
                                    localizedFromLocale(
                                      locale,
                                      AppStrings.partnerPreviousRequests,
                                      AppStrings.partnerPreviousRequestsAr,
                                    ),
                                    style: AppTextStyles.titleSmall,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  if (rows.isEmpty)
                                    Text(
                                      localizedFromLocale(
                                        locale,
                                        AppStrings.partnerNoRequestsYet,
                                        AppStrings.partnerNoRequestsYetAr,
                                      ),
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
                                        title: Text(
                                          '${_localizedPartnerRole(locale, role)} · '
                                          '${_localizedPartnerStatus(locale, st)}',
                                        ),
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
                                    localizedFromLocale(
                                      locale,
                                      AppStrings.partnerPostApprovalHint,
                                      AppStrings.partnerPostApprovalHintAr,
                                    ),
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
  const _PartnerLoadingPanel({required this.locale});

  final Locale locale;

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
              localizedFromLocale(
                locale,
                AppStrings.partnerLoadingRequests,
                AppStrings.partnerLoadingRequestsAr,
              ),
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
    required this.locale,
    required this.error,
    required this.onRetry,
  });

  final Locale locale;
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = error is AppException
        ? mapAppExceptionMessage(
            error as AppException,
            fallback: localizedFromLocale(
              locale,
              AppStrings.partnerCouldNotLoadRequests,
              AppStrings.partnerCouldNotLoadRequestsAr,
            ),
            networkMessage: localizedFromLocale(
              locale,
              AppStrings.partnerNetworkError,
              AppStrings.partnerNetworkErrorAr,
            ),
            authMessage: localizedFromLocale(
              locale,
              AppStrings.partnerSessionExpiredError,
              AppStrings.partnerSessionExpiredErrorAr,
            ),
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
              child: Text(
                localizedFromLocale(
                  locale,
                  AppStrings.partnerRetry,
                  AppStrings.partnerRetryAr,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WrongApiBasePanel extends StatelessWidget {
  const _WrongApiBasePanel({
    required this.locale,
    required this.onOpenSettings,
  });

  final Locale locale;
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
                  localizedFromLocale(
                    locale,
                    AppStrings.errorApiBaseUrlSameAsAuth,
                    AppStrings.errorApiBaseUrlSameAsAuthAr,
                  ),
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton(
                  onPressed: onOpenSettings,
                  child: Text(
                    localizedFromLocale(
                      locale,
                      AppStrings.settings,
                      AppStrings.settingsAr,
                    ),
                  ),
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
  const _EnvMissingPanel({
    required this.locale,
    required this.onOpenSettings,
  });

  final Locale locale;
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
                  localizedFromLocale(
                    locale,
                    AppStrings.errorApiBaseUrlMissing,
                    AppStrings.errorApiBaseUrlMissingAr,
                  ),
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton(
                  onPressed: onOpenSettings,
                  child: Text(
                    localizedFromLocale(
                      locale,
                      AppStrings.settings,
                      AppStrings.settingsAr,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
