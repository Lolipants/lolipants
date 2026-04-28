import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/community/models/designer_profile.dart';
import 'package:lolipants/features/community/models/showcase_item.dart';
import 'package:lolipants/features/community/providers/community_providers.dart';
import 'package:lolipants/features/community/widgets/showcase_card.dart';
import 'package:lolipants/features/community/widgets/user_avatar.dart';
import 'package:lolipants/features/orders/models/order_design_draft.dart';
import 'package:lolipants/features/orders/providers/checkout_providers.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Public designer profile: avatar, bio, follow toggle, designs grid.
class DesignerProfileScreen extends ConsumerWidget {
  /// Creates the designer profile screen.
  const DesignerProfileScreen({required this.designerId, super.key});

  /// Target designer id.
  final String designerId;

  void _orderShowcaseItem(
    WidgetRef ref,
    BuildContext context,
    ShowcaseItem item,
  ) {
    final design = OrderDesignDraft(
      designId: item.designId,
      name: item.name,
      garmentType: item.garmentType,
      primaryColour: item.primaryColour,
      accentColour: item.accentColour,
      designerId: item.designer.id,
      designerName: item.designer.name,
    );
    startCheckoutDraft(ref, design);
    context.push('/order/summary', extra: design);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(designerProfileProvider(designerId));

    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Designer', style: AppTextStyles.titleLarge),
      ),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          SafeArea(
            child: profileAsync.when(
              data: (profile) => _Body(
                profile: profile,
                onToggleFollow: () => ref
                    .read(designerProfileProvider(designerId).notifier)
                    .toggleFollow(),
                onOrder: (item) => _orderShowcaseItem(ref, context, item),
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    communityErrorMessage(e, fallback: 'Designer not found.'),
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

class _Body extends ConsumerWidget {
  const _Body({
    required this.profile,
    required this.onToggleFollow,
    required this.onOrder,
  });

  final DesignerProfile profile;
  final VoidCallback onToggleFollow;
  final ValueChanged<ShowcaseItem> onOrder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final designsAsync = ref.watch(designerPublicDesignsProvider(profile));
    final crossCount = MediaQuery.sizeOf(context).width >= 800 ? 3 : 2;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _Header(profile: profile, onToggleFollow: onToggleFollow),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          sliver: designsAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                      child: Text(
                        'No public designs yet.',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ),
                );
              }
              return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossCount,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 0.62,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = items[index];
                    return ShowcaseCard(
                      item: item,
                      onTap: () {},
                      onOrder: () => onOrder(item),
                    );
                  },
                  childCount: items.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  communityErrorMessage(e, fallback: 'Could not load designs.'),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile, required this.onToggleFollow});

  final DesignerProfile profile;
  final VoidCallback onToggleFollow;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                name: profile.name,
                avatarUrl: profile.avatarUrl,
                isProDesigner: profile.isProDesigner,
                radius: 36,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.name,
                            style: AppTextStyles.titleLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (profile.isProDesigner) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            color: AppColors.gold,
                            size: 18,
                          ),
                        ],
                      ],
                    ),
                    if (profile.speciality != null &&
                        profile.speciality!.isNotEmpty)
                      Text(profile.speciality!, style: AppTextStyles.labelGold),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _Stat(
                          label: 'Followers',
                          value: '${profile.followerCount}',
                        ),
                        const SizedBox(width: AppSpacing.md),
                        _Stat(
                          label: 'Designs',
                          value: '${profile.publicDesigns}',
                        ),
                        const SizedBox(width: AppSpacing.md),
                        _Stat(
                          label: 'Orders',
                          value: '${profile.ordersEarned}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(profile.bio!, style: AppTextStyles.bodyLarge),
          ],
          const SizedBox(height: AppSpacing.md),
          LolipantsButton(
            label: profile.isFollowing ? 'Following' : 'Follow',
            onPressed: onToggleFollow,
            variant: profile.isFollowing
                ? LolipantsButtonVariant.secondary
                : LolipantsButtonVariant.primary,
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTextStyles.titleMedium),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}
