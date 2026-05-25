import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/auth/models/user.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/community/utils/community_navigation.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/gold_divider.dart';

/// Profile tab with account summary and settings list.
class ProfileScreen extends ConsumerWidget {
  /// Creates the profile tab.
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider).value;
    final user = auth is AuthAuthenticated ? auth.user : null;

    return Scaffold(
      body: Stack(
        children: [
          const ArabesqueBackground(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 80,
                    backgroundColor: AppColors.ember,
                    foregroundColor: AppColors.gold,
                    backgroundImage: _profileAvatarImage(user),
                    child: _profileAvatarImage(user) != null
                        ? null
                        : Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.borderStrong,
                                width: 2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              user?.initials ?? '?',
                              style: AppTextStyles.displayMedium.copyWith(
                                color: AppColors.gold,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (user != null) ...[
                  Text(
                    user.name,
                    style: AppTextStyles.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    user.email,
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                const GoldDivider(),
                const SizedBox(height: AppSpacing.md),
                _ProfileTile(
                  labelEn: AppStrings.myDesigns,
                  labelAr: AppStrings.myDesignsAr,
                  icon: Icons.design_services_outlined,
                  onTap: () => context.push('/profile/designs'),
                ),
                _ProfileTile(
                  labelEn: AppStrings.myMeasurements,
                  labelAr: AppStrings.myMeasurementsAr,
                  icon: Icons.straighten,
                  onTap: () => context.push('/profile/measurements'),
                ),
                _ProfileTile(
                  labelEn: 'Price negotiations',
                  labelAr: 'تفاوض الأسعار',
                  icon: Icons.price_change_outlined,
                  onTap: () => context.push('/profile/price-negotiations'),
                ),
                if (kFeatureCommunity) ...[
                  _ProfileTile(
                    labelEn: 'Designer earnings',
                    labelAr: 'أرباح المصمم',
                    icon: Icons.account_balance_wallet_outlined,
                    onTap: () => context.push('/community/earnings'),
                  ),
                  _ProfileTile(
                    labelEn: 'My consultations',
                    labelAr: 'استشاراتي',
                    icon: Icons.forum_outlined,
                    onTap: () => openCommunityHubTab(
                      ref,
                      GoRouter.of(context),
                      tabIndex: kCommunityConsultTab,
                    ),
                  ),
                ],
                _ProfileTile(
                  labelEn: 'Edit profile',
                  labelAr: 'تعديل الملف',
                  icon: Icons.person_outline,
                  onTap: () => context.push('/profile/edit'),
                ),
                if (user != null && user.normalizedRole == UserRoles.user)
                  _ProfileTile(
                    labelEn: 'Partner with Lolipants',
                    labelAr: 'كن شريكاً',
                    icon: Icons.handshake_outlined,
                    onTap: () => context.push('/profile/role-request'),
                  ),
                _ProfileTile(
                  labelEn: AppStrings.settings,
                  labelAr: AppStrings.settingsAr,
                  icon: Icons.settings_outlined,
                  onTap: () => context.push('/profile/settings'),
                ),
                _ProfileTile(
                  labelEn: AppStrings.logOut,
                  labelAr: AppStrings.logOutAr,
                  icon: Icons.logout,
                  destructive: true,
                  onTap: () => _confirmLogOut(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static ImageProvider? _profileAvatarImage(User? user) {
    final raw = user?.imageUrl?.trim() ?? '';
    if (raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null) return null;
    if (!(uri.isScheme('http') || uri.isScheme('https'))) return null;
    if (uri.host.isEmpty) return null;
    return NetworkImage(raw);
  }

  Future<void> _confirmLogOut(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.stone,
        title: const Text(
          '${AppStrings.logOutConfirmTitle} / ${AppStrings.logOutConfirmTitleAr}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('${AppStrings.cancel} / ${AppStrings.cancelAr}'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              '${AppStrings.confirm} / ${AppStrings.confirmAr}',
              style: TextStyle(color: AppColors.rubyLight),
            ),
          ),
        ],
      ),
    );
    if ((ok ?? false) && context.mounted) {
      await ref.read(authProvider.notifier).signOutEverywhere();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.labelEn,
    required this.labelAr,
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });

  final String labelEn;
  final String labelAr;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.rubyLight : AppColors.sand;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        labelEn,
        style: AppTextStyles.titleSmall.copyWith(color: color),
      ),
      subtitle: Directionality(
        textDirection: TextDirection.rtl,
        child: Text(
          labelAr,
          style: AppTextStyles.arabicLabel.copyWith(color: color),
        ),
      ),
      onTap: onTap,
    );
  }
}
