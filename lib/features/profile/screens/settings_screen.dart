import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/profile_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/permissions/device_permission_prompt.dart';
import 'package:lolipants/core/push/onesignal_bootstrap.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/music/providers/music_provider.dart';
import 'package:lolipants/features/settings/models/settings_state.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/gold_divider.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Settings hub: language, accessibility, notifications, media, legal,
/// support, account shortcuts, and about.
class SettingsScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _version;
  bool _deleting = false;
  bool _pushBusy = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _version = '${info.version}+${info.buildNumber}');
    } on Object {
      if (!mounted) return;
      setState(() => _version = '—');
    }
  }

  String _helpCenterUrl() {
    final u = dotenv.env['HELP_CENTER_URL']?.trim();
    if (u != null && u.isNotEmpty) return u;
    return AppStrings.settingsDefaultHelpUrl;
  }

  String _faqUrl() {
    final u = dotenv.env['FAQ_URL']?.trim();
    if (u != null && u.isNotEmpty) return u;
    return AppStrings.settingsDefaultFaqUrl;
  }

  String _supportMailto() {
    final u = dotenv.env['SUPPORT_MAILTO']?.trim();
    if (u != null && u.isNotEmpty) return u;
    return AppStrings.settingsDefaultSupportMailto;
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await canLaunchUrl(uri);
    if (!ok || !mounted) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _onPushChanged(bool want) async {
    if (_pushBusy) return;
    setState(() => _pushBusy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (want) {
        final allowed = await DevicePermissionPrompt.ensure(
          context,
          AppDevicePermission.notifications,
        );
        if (!allowed) {
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                localizedFromContext(context, AppStrings.settingsPushPermissionDenied, AppStrings.settingsPushPermissionDeniedAr),
              ),
            ),
          );
          return;
        }
        final ok =
            await ref.read(settingsProvider.notifier).applyPushPreference(
                  want: true,
                );
        if (!mounted) return;
        if (!ok) {
          if (!isOneSignalAppConfigured()) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  localizedFromContext(context, AppStrings.settingsPushUnavailable, AppStrings.settingsPushUnavailableAr),
                ),
              ),
            );
          } else {
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  localizedFromContext(context, AppStrings.settingsPushPermissionDenied, AppStrings.settingsPushPermissionDeniedAr),
                ),
              ),
            );
          }
        }
      } else {
        await ref.read(settingsProvider.notifier).applyPushPreference(
              want: false,
            );
      }
    } finally {
      if (mounted) setState(() => _pushBusy = false);
    }
  }

  Future<void> _confirmClearMusic() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.stone,
        title: Text(
          localizedFromContext(context, AppStrings.settingsClearMusicConfirmTitle, AppStrings.settingsClearMusicConfirmTitleAr),
          style: AppTextStyles.titleMedium,
        ),
        content: Text(
          localizedFromContext(context, AppStrings.settingsClearMusicConfirmBody, AppStrings.settingsClearMusicConfirmBodyAr),
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              localizedFromContext(context, AppStrings.cancel, AppStrings.cancelAr),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              localizedFromContext(context, AppStrings.confirm, AppStrings.confirmAr),
              style: const TextStyle(color: AppColors.rubyLight),
            ),
          ),
        ],
      ),
    );
    if ((ok ?? false) && mounted) {
      await ref.read(musicProvider.notifier).clearLibraryAndStop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizedFromContext(context, AppStrings.settingsMusicQueueCleared, AppStrings.settingsMusicQueueClearedAr),
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.stone,
        title: Text(
          localizedFromContext(context, AppStrings.settingsDeleteDialogTitle, AppStrings.settingsDeleteDialogTitleAr),
          style: AppTextStyles.titleMedium,
        ),
        content: Text(
          localizedFromContext(context, AppStrings.settingsDeleteDialogBody, AppStrings.settingsDeleteDialogBodyAr),
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(localizedFromContext(context, AppStrings.cancel, AppStrings.cancelAr)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              localizedFromContext(context, AppStrings.settingsDeleteDialogConfirm, AppStrings.settingsDeleteDialogConfirmAr),
              style: const TextStyle(color: AppColors.rubyLight),
            ),
          ),
        ],
      ),
    );
    if (!mounted || ok != true) return;
    setState(() => _deleting = true);
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref.read(authProvider.notifier).deleteAccount();
    if (!mounted) return;
    result.fold(
      (err) {
        setState(() => _deleting = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              localizedFromContext(context, AppStrings.settingsDeleteAccountFailed, AppStrings.settingsDeleteAccountFailedAr),
            ),
          ),
        );
      },
      (_) => context.go('/login'),
    );
  }

  Future<void> _confirmSignOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.stone,
        title: Text(
          localizedFromContext(context, AppStrings.logOutConfirmTitle, AppStrings.logOutConfirmTitleAr),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(localizedFromContext(context, AppStrings.cancel, AppStrings.cancelAr)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              localizedFromContext(context, AppStrings.confirm, AppStrings.confirmAr),
              style: const TextStyle(color: AppColors.rubyLight),
            ),
          ),
        ],
      ),
    );
    if ((ok ?? false) && mounted) {
      await ref.read(authProvider.notifier).signOutEverywhere();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isArabic = settings.locale.languageCode == 'ar';
    final isAuthed = ref.watch(authProvider).maybeWhen(
          data: (s) => s is AuthAuthenticated,
          orElse: () => false,
        );
    final pushConfigured = isOneSignalAppConfigured();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.gold),
          onPressed: () => context.pop(),
        ),
        title: Text(
          localizedFromContext(context, AppStrings.settingsScreenTitle, AppStrings.settingsScreenTitleAr),
          style: AppTextStyles.titleLarge,
        ),
        backgroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                _BilingualSectionTitle(
                  titleEn: AppStrings.settingsSectionGeneral,
                  titleAr: AppStrings.settingsSectionGeneralAr,
                ),
                _BilingualLabel(
                  labelEn: AppStrings.settingsLanguageLabel,
                  labelAr: AppStrings.settingsLanguageLabelAr,
                ),
                const SizedBox(height: AppSpacing.sm),
                _LanguageRow(
                  isArabic: isArabic,
                  onChanged: (value) => ref
                      .read(settingsProvider.notifier)
                      .setLocale(Locale(value ? 'ar' : 'en')),
                ),
                const SizedBox(height: AppSpacing.lg),
                const GoldDivider(),
                const SizedBox(height: AppSpacing.lg),
                _BilingualSectionTitle(
                  titleEn: AppStrings.settingsSectionAppearance,
                  titleAr: AppStrings.settingsSectionAppearanceAr,
                ),
                _BilingualLabel(
                  labelEn: AppStrings.settingsTextSizeLabel,
                  labelAr: AppStrings.settingsTextSizeLabelAr,
                ),
                const SizedBox(height: AppSpacing.sm),
                _TextScaleRow(
                  current: settings.textScale,
                  onChanged: (o) =>
                      ref.read(settingsProvider.notifier).setTextScale(o),
                ),
                SwitchListTile(
                  value: settings.reduceMotion,
                  onChanged: (v) => ref
                      .read(settingsProvider.notifier)
                      .setReduceMotion(value: v),
                  title: Text(
                    localizedFromContext(context, AppStrings.settingsReduceMotionTitle, AppStrings.settingsReduceMotionTitleAr),
                    style: AppTextStyles.titleSmall,
                  ),
                  subtitle: Text(
                    localizedFromContext(context, AppStrings.settingsReduceMotionSubtitle, AppStrings.settingsReduceMotionSubtitleAr),
                    style: AppTextStyles.bodySmall,
                  ),
                  activeThumbColor: AppColors.gold,
                ),
                const SizedBox(height: AppSpacing.lg),
                const GoldDivider(),
                const SizedBox(height: AppSpacing.lg),
                _BilingualSectionTitle(
                  titleEn: AppStrings.settingsSectionNotifications,
                  titleAr: AppStrings.settingsSectionNotificationsAr,
                ),
                SwitchListTile(
                  value: settings.pushEnabled,
                  onChanged: (!pushConfigured || _pushBusy)
                      ? null
                      : (v) => unawaited(_onPushChanged(v)),
                  title: Text(
                    localizedFromContext(context, AppStrings.settingsPushTitle, AppStrings.settingsPushTitleAr),
                    style: AppTextStyles.titleSmall,
                  ),
                  subtitle: Text(
                    pushConfigured
                        ? localizedFromContext(context, AppStrings.settingsPushSubtitle, AppStrings.settingsPushSubtitleAr)
                        : localizedFromContext(context, AppStrings.settingsPushUnavailable, AppStrings.settingsPushUnavailableAr),
                    style: AppTextStyles.bodySmall,
                  ),
                  activeThumbColor: AppColors.gold,
                ),
                if (kFeatureMusicPlayer) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const GoldDivider(),
                  const SizedBox(height: AppSpacing.lg),
                  _BilingualSectionTitle(
                    titleEn: AppStrings.settingsSectionMedia,
                    titleAr: AppStrings.settingsSectionMediaAr,
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.queue_music_outlined,
                      color: AppColors.gold,
                    ),
                    title: Text(
                      localizedFromContext(context, AppStrings.settingsClearMusicQueue, AppStrings.settingsClearMusicQueueAr),
                      style: AppTextStyles.titleSmall,
                    ),
                    subtitle: Text(
                      localizedFromContext(context, AppStrings.settingsClearMusicQueueSubtitle, AppStrings.settingsClearMusicQueueSubtitleAr),
                      style: AppTextStyles.bodySmall,
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.fog,
                    ),
                    onTap: _confirmClearMusic,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                const GoldDivider(),
                const SizedBox(height: AppSpacing.lg),
                _BilingualSectionTitle(
                  titleEn: AppStrings.settingsSectionPrivacy,
                  titleAr: AppStrings.settingsSectionPrivacyAr,
                ),
                _LegalWebTile(
                  labelEn: AppStrings.settingsPrivacyPolicy,
                  labelAr: AppStrings.settingsPrivacyPolicyAr,
                  url: AppStrings.settingsDefaultPrivacyUrl,
                ),
                _LegalWebTile(
                  labelEn: AppStrings.settingsTermsOfService,
                  labelAr: AppStrings.settingsTermsOfServiceAr,
                  url: AppStrings.settingsDefaultTermsUrl,
                ),
                const SizedBox(height: AppSpacing.lg),
                const GoldDivider(),
                const SizedBox(height: AppSpacing.lg),
                _BilingualSectionTitle(
                  titleEn: AppStrings.settingsSectionSupport,
                  titleAr: AppStrings.settingsSectionSupportAr,
                ),
                ListTile(
                  leading: const Icon(
                    Icons.help_outline,
                    color: AppColors.gold,
                  ),
                  title: Text(
                    localizedFromContext(context, AppStrings.settingsHelpCenter, AppStrings.settingsHelpCenterAr),
                    style: AppTextStyles.titleSmall,
                  ),
                  trailing: const Icon(
                    Icons.open_in_new,
                    color: AppColors.fog,
                    size: 20,
                  ),
                  onTap: () => _openExternalUrl(_helpCenterUrl()),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.quiz_outlined,
                    color: AppColors.gold,
                  ),
                  title: Text(
                    localizedFromContext(context, AppStrings.settingsFaq, AppStrings.settingsFaqAr),
                    style: AppTextStyles.titleSmall,
                  ),
                  trailing: const Icon(
                    Icons.open_in_new,
                    color: AppColors.fog,
                    size: 20,
                  ),
                  onTap: () => _openExternalUrl(_faqUrl()),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.mail_outline,
                    color: AppColors.gold,
                  ),
                  title: Text(
                    localizedFromContext(context, AppStrings.settingsContactSupport, AppStrings.settingsContactSupportAr),
                    style: AppTextStyles.titleSmall,
                  ),
                  trailing: const Icon(
                    Icons.open_in_new,
                    color: AppColors.fog,
                    size: 20,
                  ),
                  onTap: () => _openExternalUrl(_supportMailto()),
                ),
                if (isAuthed) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const GoldDivider(),
                  const SizedBox(height: AppSpacing.lg),
                  _BilingualSectionTitle(
                    titleEn: AppStrings.settingsSectionAccount,
                    titleAr: AppStrings.settingsSectionAccountAr,
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.design_services_outlined,
                      color: AppColors.gold,
                    ),
                    title: Text(
                      localizedFromContext(context, AppStrings.myDesigns, AppStrings.myDesignsAr),
                      style: AppTextStyles.titleSmall,
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.fog,
                    ),
                    onTap: () => context.push('/profile/designs'),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.straighten,
                      color: AppColors.gold,
                    ),
                    title: Text(
                      localizedFromContext(context, AppStrings.myMeasurements, AppStrings.myMeasurementsAr),
                      style: AppTextStyles.titleSmall,
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.fog,
                    ),
                    onTap: () => context.push('/profile/measurements'),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.person_outline,
                      color: AppColors.gold,
                    ),
                    title: Text(
                      localizedFromContext(context, AppStrings.settingsEditProfile, AppStrings.settingsEditProfileAr),
                      style: AppTextStyles.titleSmall,
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.fog,
                    ),
                    onTap: () => context.push('/profile/edit'),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.logout,
                      color: AppColors.rubyLight,
                    ),
                    title: Text(
                      localizedFromContext(context, AppStrings.settingsSignOut, AppStrings.settingsSignOutAr),
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.rubyLight,
                      ),
                    ),
                    onTap: _confirmSignOut,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  LolipantsButton(
                    label:
                        localizedFromContext(context, AppStrings.settingsDeleteAccount, AppStrings.settingsDeleteAccountAr),
                    variant: LolipantsButtonVariant.destructive,
                    loading: _deleting,
                    onPressed: _deleting
                        ? null
                        : () {
                            unawaited(_confirmDelete());
                          },
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                const GoldDivider(),
                const SizedBox(height: AppSpacing.lg),
                _BilingualSectionTitle(
                  titleEn: AppStrings.settingsSectionAbout,
                  titleAr: AppStrings.settingsSectionAboutAr,
                ),
                ListTile(
                  leading: const Icon(
                    Icons.info_outline,
                    color: AppColors.gold,
                  ),
                  title: Text(
                    localizedFromContext(context, AppStrings.settingsAppVersion, AppStrings.settingsAppVersionAr),
                    style: AppTextStyles.titleSmall,
                  ),
                  subtitle: Text(
                    _version ??
                        localizedFromContext(context, AppStrings.settingsVersionLoading, AppStrings.settingsVersionLoadingAr),
                    style: AppTextStyles.bodySmall,
                  ),
                ),
                if (kDebugMode) ...[
                  ListTile(
                    leading: const Icon(
                      Icons.bug_report_outlined,
                      color: AppColors.gold,
                    ),
                    title: Text(
                      localizedFromContext(context, AppStrings.settingsApiBaseDebug, AppStrings.settingsApiBaseDebugAr),
                      style: AppTextStyles.titleSmall,
                    ),
                    subtitle: SelectableText(
                      (dotenv.env['API_BASE_URL'] ?? '').trim().isEmpty
                          ? '(empty)'
                          : dotenv.env['API_BASE_URL']!.trim(),
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BilingualSectionTitle extends ConsumerWidget {
  const _BilingualSectionTitle({
    required this.titleEn,
    required this.titleAr,
  });

  final String titleEn;
  final String titleAr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(settingsLocaleProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        localizedFromLocale(locale, titleEn, titleAr),
        style: AppTextStyles.labelGold,
      ),
    );
  }
}

class _BilingualLabel extends ConsumerWidget {
  const _BilingualLabel({
    required this.labelEn,
    required this.labelAr,
  });

  final String labelEn;
  final String labelAr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(settingsLocaleProvider);
    return Text(
      localizedFromLocale(locale, labelEn, labelAr),
      style: AppTextStyles.bodySmall.copyWith(color: AppColors.sand),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({required this.isArabic, required this.onChanged});

  final bool isArabic;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PillChoice(
            label: ProfileStrings.settingsLanguageEnglish,
            selected: !isArabic,
            onTap: () => onChanged(false),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _PillChoice(
            label: ProfileStrings.settingsLanguageArabic,
            selected: isArabic,
            onTap: () => onChanged(true),
          ),
        ),
      ],
    );
  }
}

class _TextScaleRow extends ConsumerWidget {
  const _TextScaleRow({
    required this.current,
    required this.onChanged,
  });

  final AppTextScaleOption current;
  final ValueChanged<AppTextScaleOption> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(settingsLocaleProvider);
    Widget chip(AppTextScaleOption o, String en, String ar) {
      final selected = current == o;
      return Expanded(
        child: _PillChoice(
          label: localizedFromLocale(locale, en, ar),
          selected: selected,
          onTap: () => onChanged(o),
          maxLines: 2,
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            chip(
              AppTextScaleOption.compact,
              AppStrings.settingsTextSizeCompact,
              AppStrings.settingsTextSizeCompactAr,
            ),
            const SizedBox(width: AppSpacing.sm),
            chip(
              AppTextScaleOption.normal,
              AppStrings.settingsTextSizeNormal,
              AppStrings.settingsTextSizeNormalAr,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            chip(
              AppTextScaleOption.comfortable,
              AppStrings.settingsTextSizeComfortable,
              AppStrings.settingsTextSizeComfortableAr,
            ),
            const SizedBox(width: AppSpacing.sm),
            chip(
              AppTextScaleOption.large,
              AppStrings.settingsTextSizeLarge,
              AppStrings.settingsTextSizeLargeAr,
            ),
          ],
        ),
      ],
    );
  }
}

class _PillChoice extends StatelessWidget {
  const _PillChoice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.maxLines = 1,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold : AppColors.stone,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.gold : AppColors.borderSubtle,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.titleSmall.copyWith(
            color: selected ? AppColors.ink : AppColors.sand,
            fontSize: maxLines > 1 ? 12 : null,
          ),
        ),
      ),
    );
  }
}

class _LegalWebTile extends ConsumerWidget {
  const _LegalWebTile({
    required this.labelEn,
    required this.labelAr,
    required this.url,
  });

  final String labelEn;
  final String labelAr;
  final String url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(settingsLocaleProvider);
    final label = localizedFromLocale(locale, labelEn, labelAr);
    return ListTile(
      leading: const Icon(Icons.article_outlined, color: AppColors.gold),
      title: Text(
        label,
        style: AppTextStyles.titleSmall,
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.fog),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _WebViewScreen(
              url: url,
              title: label,
            ),
          ),
        );
      },
    );
  }
}

class _WebViewScreen extends StatefulWidget {
  const _WebViewScreen({required this.url, required this.title});

  final String url;
  final String title;

  @override
  State<_WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<_WebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: AppTextStyles.titleMedium),
        backgroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
