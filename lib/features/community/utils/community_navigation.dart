import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/features/community/providers/community_providers.dart';

/// Inner Community hub tab: Feed.
const int kCommunityFeedTab = 0;

/// Inner Community hub tab: Showcase (orderable public designs).
const int kCommunityShowcaseTab = 1;

/// Inner Community hub tab: Pro designers.
const int kCommunityProsTab = 2;

/// Inner Community hub tab: Consultations.
const int kCommunityConsultTab = 3;

/// Opens the Community shell branch and selects an inner hub tab.
///
/// Uses tab state instead of nested `/community/showcase` routes so we never
/// stack a second [ShowcaseScreen] on the navigator (duplicate page keys).
void openCommunityHubTab(
  WidgetRef ref,
  GoRouter router, {
  required int tabIndex,
}) {
  final clamped = tabIndex.clamp(0, kCommunityConsultTab);
  ref.read(communityHubTabIndexProvider.notifier).state = clamped;
  if (kFeatureCommunity) {
    router.go('/community');
  }
}
