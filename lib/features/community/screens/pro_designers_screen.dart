import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/constants/community_strings.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/community/models/designer_profile.dart';
import 'package:lolipants/features/community/providers/community_providers.dart';
import 'package:lolipants/features/community/widgets/user_avatar.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';

/// Pro designers directory.
class ProDesignersScreen extends ConsumerWidget {
  /// Creates the screen.
  const ProDesignersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final designersAsync = ref.watch(proDesignersProvider);
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          localized(
            ref,
            CommunityStrings.proDesigners,
            CommunityStrings.proDesignersAr,
          ),
          style: AppTextStyles.titleLarge,
        ),
      ),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          SafeArea(
            child: designersAsync.when(
              data: (designers) {
                if (designers.isEmpty) {
                  return Center(
                    child: Text(
                      localized(
                        ref,
                        CommunityStrings.noProDesigners,
                        CommunityStrings.noProDesignersAr,
                      ),
                      style: AppTextStyles.bodyMedium,
                    ),
                  );
                }
                return RefreshIndicator(
                  color: AppColors.gold,
                  backgroundColor: AppColors.ink,
                  onRefresh: () async {
                    ref.invalidate(proDesignersProvider);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: designers.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) => _Tile(
                      profile: designers[index],
                      onTap: () => context.push(
                        '/community/designer/${designers[index].id}',
                      ),
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    communityErrorMessage(
                      e,
                      fallback: localized(
                        ref,
                        CommunityStrings.proDesignersLoadError,
                        CommunityStrings.proDesignersLoadErrorAr,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.profile, required this.onTap});

  final DesignerProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.stone,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            UserAvatar(
              name: profile.name,
              avatarUrl: profile.avatarUrl,
              isProDesigner: true,
              radius: 22,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.name, style: AppTextStyles.titleMedium),
                  if (profile.speciality != null &&
                      profile.speciality!.isNotEmpty)
                    Text(profile.speciality!, style: AppTextStyles.labelGold),
                  Text(
                    '${profile.followerCount} ${localizedFromContext(context, CommunityStrings.followersLower, CommunityStrings.followersLowerAr)}',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.dust),
          ],
        ),
      ),
    );
  }
}
