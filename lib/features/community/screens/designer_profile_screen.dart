import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/constants/community_strings.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/community/models/designer_profile.dart';
import 'package:lolipants/features/community/models/showcase_item.dart';
import 'package:lolipants/features/community/providers/community_providers.dart';
import 'package:lolipants/features/community/utils/showcase_order.dart';
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

  void _previewShowcaseItem(
    WidgetRef ref,
    BuildContext context,
    ShowcaseItem item,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.58,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          builder: (_, scrollController) {
            return DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.stone,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg),
                ),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.md,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.borderDefault,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  Text(item.name, style: AppTextStyles.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.garmentType,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.fog,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${localizedFromContext(context, CommunityStrings.byDesigner, CommunityStrings.byDesignerAr)} ${item.designer.name}',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (item.previewImageUrl != null &&
                      item.previewImageUrl!.trim().isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: AspectRatio(
                        aspectRatio: 3 / 4,
                        child: CachedNetworkImage(
                          imageUrl: item.previewImageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: AppColors.fog,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  LolipantsButton(
                    label: localizedFromContext(
                      context,
                      CommunityStrings.orderThisDesign,
                      CommunityStrings.orderThisDesignAr,
                    ),
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      _orderShowcaseItem(ref, context, item);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(designerProfileProvider(designerId));

    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          localized(ref, CommunityStrings.designer, CommunityStrings.designerAr),
          style: AppTextStyles.titleLarge,
        ),
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
                onPreview: (item) => _previewShowcaseItem(ref, context, item),
              ),
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
                        CommunityStrings.designerNotFound,
                        CommunityStrings.designerNotFoundAr,
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

class _Body extends ConsumerWidget {
  const _Body({
    required this.profile,
    required this.onToggleFollow,
    required this.onOrder,
    required this.onPreview,
  });

  final DesignerProfile profile;
  final VoidCallback onToggleFollow;
  final ValueChanged<ShowcaseItem> onOrder;
  final ValueChanged<ShowcaseItem> onPreview;

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
                        localizedFromContext(
                          context,
                          CommunityStrings.noPublicDesigns,
                          CommunityStrings.noPublicDesignsAr,
                        ),
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
                  childAspectRatio: kShowcaseGridAspectRatio,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = items[index];
                    return ShowcaseCard(
                      item: item,
                      onTap: () => onPreview(item),
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
                  communityErrorMessage(
                    e,
                    fallback: localizedFromContext(
                      context,
                      CommunityStrings.couldNotLoadDesigns,
                      CommunityStrings.couldNotLoadDesignsAr,
                    ),
                  ),
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
                          label: localizedFromContext(
                            context,
                            CommunityStrings.followers,
                            CommunityStrings.followersAr,
                          ),
                          value: '${profile.followerCount}',
                        ),
                        const SizedBox(width: AppSpacing.md),
                        _Stat(
                          label: localizedFromContext(
                            context,
                            CommunityStrings.designs,
                            CommunityStrings.designsAr,
                          ),
                          value: '${profile.publicDesigns}',
                        ),
                        const SizedBox(width: AppSpacing.md),
                        _Stat(
                          label: localizedFromContext(
                            context,
                            CommunityStrings.orders,
                            CommunityStrings.ordersAr,
                          ),
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
            label: profile.isFollowing
                ? localizedFromContext(
                    context,
                    CommunityStrings.following,
                    CommunityStrings.followingAr,
                  )
                : localizedFromContext(
                    context,
                    CommunityStrings.follow,
                    CommunityStrings.followAr,
                  ),
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
