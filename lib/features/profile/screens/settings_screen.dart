import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/gold_divider.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Phase 6A settings screen. Hosts language toggle, notification placeholder,
/// app version, privacy/terms links, and the delete-account action.
class SettingsScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _version;
  bool _deleting = false;

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

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isArabic = settings.locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.gold),
          onPressed: () => context.pop(),
        ),
        title: Text('Settings', style: AppTextStyles.titleLarge),
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
                _SectionTitle(label: 'Language'),
                _LanguageRow(
                  isArabic: isArabic,
                  onChanged: (value) => ref
                      .read(settingsProvider.notifier)
                      .setLocale(Locale(value ? 'ar' : 'en')),
                ),
                const SizedBox(height: AppSpacing.lg),
                const GoldDivider(),
                const SizedBox(height: AppSpacing.lg),
                _SectionTitle(label: 'Notifications'),
                SwitchListTile(
                  value: settings.pushEnabled,
                  onChanged: (value) => ref
                      .read(settingsProvider.notifier)
                      .setPushEnabled(value),
                  title: Text(
                    'Push notifications',
                    style: AppTextStyles.titleSmall,
                  ),
                  subtitle: Text(
                    'Order updates, delivery status, designer replies.',
                    style: AppTextStyles.bodySmall,
                  ),
                  activeColor: AppColors.gold,
                ),
                const SizedBox(height: AppSpacing.lg),
                const GoldDivider(),
                const SizedBox(height: AppSpacing.lg),
                _SectionTitle(label: 'Legal'),
                _LegalTile(
                  label: 'Privacy policy',
                  url: 'https://lolipants.com/privacy',
                ),
                _LegalTile(
                  label: 'Terms of service',
                  url: 'https://lolipants.com/terms',
                ),
                const SizedBox(height: AppSpacing.lg),
                const GoldDivider(),
                const SizedBox(height: AppSpacing.lg),
                _SectionTitle(label: 'About'),
                ListTile(
                  leading:
                      const Icon(Icons.info_outline, color: AppColors.gold),
                  title: Text('App version', style: AppTextStyles.titleSmall),
                  subtitle: Text(
                    _version ?? 'Loading…',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                LolipantsButton(
                  label: _deleting ? 'Deleting…' : 'Delete account',
                  variant: LolipantsButtonVariant.destructive,
                  onPressed: _deleting ? null : _confirmDelete,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.stone,
        title: Text('Delete account?', style: AppTextStyles.titleMedium),
        content: Text(
          'This removes your profile, designs, and measurements. Active orders '
          'continue to completion. This cannot be undone.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.rubyLight),
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
          const SnackBar(content: Text('Could not delete account.')),
        );
      },
      (_) => context.go('/login'),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        label,
        style: AppTextStyles.labelGold,
      ),
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
          child: _LangButton(
            label: 'English',
            selected: !isArabic,
            onTap: () => onChanged(false),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _LangButton(
            label: 'العربية',
            selected: isArabic,
            onTap: () => onChanged(true),
          ),
        ),
      ],
    );
  }
}

class _LangButton extends StatelessWidget {
  const _LangButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
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
          style: AppTextStyles.titleSmall.copyWith(
            color: selected ? AppColors.ink : AppColors.sand,
          ),
        ),
      ),
    );
  }
}

class _LegalTile extends StatelessWidget {
  const _LegalTile({required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.article_outlined, color: AppColors.gold),
      title: Text(label, style: AppTextStyles.titleSmall),
      trailing: const Icon(Icons.chevron_right, color: AppColors.fog),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _WebViewScreen(url: url, title: label),
          ),
        );
      },
    );
  }
}

class _WebViewScreen extends StatelessWidget {
  const _WebViewScreen({required this.url, required this.title});

  final String url;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: AppTextStyles.titleMedium),
        backgroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.link, color: AppColors.gold, size: 40),
              const SizedBox(height: AppSpacing.md),
              Text(url, style: AppTextStyles.bodyMedium),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'This link opens in an in-app browser on release builds.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
