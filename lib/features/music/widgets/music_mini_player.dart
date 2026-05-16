import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/permissions/device_permission_prompt.dart';
import 'package:lolipants/features/music/providers/music_provider.dart';
import 'package:lolipants/features/music/widgets/music_expanded_player.dart';

/// 56px persistent mini-player displayed above the bottom nav bar. Tapping
/// the body (not the controls) opens [MusicExpandedPlayer] as a modal sheet.
class MusicMiniPlayer extends ConsumerStatefulWidget {
  /// Creates the mini-player.
  const MusicMiniPlayer({super.key});

  @override
  ConsumerState<MusicMiniPlayer> createState() => _MusicMiniPlayerState();
}

class _MusicMiniPlayerState extends ConsumerState<MusicMiniPlayer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(musicProvider.notifier).ensureQueueLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(musicProvider);
    if (state.queue.isEmpty) {
      return Material(
        color: AppColors.stone,
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              IconButton(
                tooltip: 'Choose audio files',
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: AppColors.gold,
                ),
                onPressed: () async {
                  final granted = await DevicePermissionPrompt.ensure(
                    context,
                    AppDevicePermission.audioFiles,
                  );
                  if (!granted || !context.mounted) return;
                  await ref.read(musicProvider.notifier).pickAndAddTracks();
                },
              ),
              Expanded(
                child: InkWell(
                  onTap: () => _openExpanded(context),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      'Add music from your device',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.fog,
                      ),
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _openExpanded(context),
                child: Text(
                  'Open',
                  style: AppTextStyles.labelGold.copyWith(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final track = state.currentTrack;
    if (track == null) {
      return const SizedBox.shrink();
    }
    final progress = state.duration > 0
        ? (state.progress / state.duration).clamp(0.0, 1.0)
        : 0.0;

    return Material(
      color: AppColors.stone,
      child: InkWell(
        onTap: () => _openExpanded(context),
        child: SizedBox(
          height: 56,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const SizedBox(width: AppSpacing.sm),
                    const _CoverArt(),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.sand),
                          ),
                          Text(
                            track.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.fog,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Previous',
                      icon: const Icon(
                        Icons.skip_previous,
                        color: AppColors.gold,
                      ),
                      onPressed: ref.read(musicProvider.notifier).previous,
                    ),
                    IconButton(
                      tooltip: state.isPlaying ? 'Pause' : 'Play',
                      icon: Icon(
                        state.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: AppColors.gold,
                      ),
                      onPressed: ref.read(musicProvider.notifier).toggle,
                    ),
                    IconButton(
                      tooltip: 'Next',
                      icon:
                          const Icon(Icons.skip_next, color: AppColors.gold),
                      onPressed: ref.read(musicProvider.notifier).next,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 2,
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 2,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.gold),
                  backgroundColor: AppColors.borderSubtle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openExpanded(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.ink,
      builder: (_) => const MusicExpandedPlayer(),
    );
  }
}

class _CoverArt extends StatelessWidget {
  const _CoverArt();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: const SizedBox(
        width: 40,
        height: 40,
        child: ColoredBox(
          color: AppColors.smoke,
          child: Icon(
            Icons.audiotrack,
            color: AppColors.gold,
            size: 22,
          ),
        ),
      ),
    );
  }
}
