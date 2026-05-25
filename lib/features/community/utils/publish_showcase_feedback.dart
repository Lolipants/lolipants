import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/features/community/providers/community_providers.dart';
import 'package:lolipants/features/community/widgets/publish_showcase_dialog.dart';

/// Refreshes community lists and shows the post-publish snackbar.
void notifyShowcasePublishSuccess(
  WidgetRef ref,
  BuildContext context, {
  required int commissionPct,
}) {
  ref.read(showcaseFeedProvider.notifier).refresh();
  for (final tag in kNewsFeedTagFilterKeys) {
    ref.invalidate(feedPostsProvider(tag));
  }
  showPublishSuccessSnackBar(
    context,
    commissionPct: commissionPct,
    router: GoRouter.of(context),
    ref: ref,
  );
}