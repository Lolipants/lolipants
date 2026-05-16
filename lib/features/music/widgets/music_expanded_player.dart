import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/music/models/track.dart';
import 'package:lolipants/core/permissions/device_permission_prompt.dart';
import 'package:lolipants/features/music/providers/music_provider.dart';

/// Full-height modal sheet showing artwork, transport controls, and the
/// current queue. Opened from the mini-player.
class MusicExpandedPlayer extends ConsumerWidget {
  /// Creates the expanded player.
  const MusicExpandedPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(musicProvider);
    final track = state.currentTrack;
    final mediaSize = MediaQuery.sizeOf(context);
    final sheetHeight = mediaSize.height * 0.9;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: sheetHeight,
        child: Column(
          children: [
            _Handle(),
            Expanded(
              child: state.queue.isEmpty
                  ? const _EmptyQueue()
                  : track == null
                      ? const _EmptyState()
                      : _LoadedBody(state: state, track: track, ref: ref),
            ),
          ],
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Container(
        width: 44,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.borderStrong,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class _EmptyQueue extends ConsumerWidget {
  const _EmptyQueue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.library_music_outlined,
            color: AppColors.gold,
            size: 56,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No music yet',
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Choose MP3 or other audio files stored on this device. '
            'Your selection is remembered for next time.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.dust),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: () async {
              final granted = await DevicePermissionPrompt.ensure(
                context,
                AppDevicePermission.audioFiles,
              );
              if (!granted || !context.mounted) return;
              await ref.read(musicProvider.notifier).pickAndAddTracks();
            },
            icon: const Icon(Icons.folder_open),
            label: const Text('Choose files'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No track loaded.',
        style: AppTextStyles.bodyMedium,
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({
    required this.state,
    required this.track,
    required this.ref,
  });

  final MusicState state;
  final Track track;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final duration = state.duration;
    final progress = state.progress.clamp(0.0, duration);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: () async {
                final granted = await DevicePermissionPrompt.ensure(
                  context,
                  AppDevicePermission.audioFiles,
                );
                if (!granted || !context.mounted) return;
                await ref.read(musicProvider.notifier).pickAndAddTracks();
              },
              icon: const Icon(
                Icons.library_add,
                color: AppColors.gold,
                size: 20,
              ),
              label: Text(
                'Add music',
                style: AppTextStyles.labelGold.copyWith(fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: const _CoverLarge(),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            track.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleLarge,
          ),
          Text(
            track.artist,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Slider(
            value: duration > 0 ? progress : 0,
            max: duration > 0 ? duration : 1,
            activeColor: AppColors.gold,
            inactiveColor: AppColors.borderSubtle,
            onChanged: (value) => ref.read(musicProvider.notifier).seek(value),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_format(progress), style: AppTextStyles.bodySmall),
              Text(_format(duration), style: AppTextStyles.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 32,
                icon: const Icon(Icons.skip_previous, color: AppColors.gold),
                onPressed: ref.read(musicProvider.notifier).previous,
              ),
              const SizedBox(width: AppSpacing.lg),
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.gold,
                child: IconButton(
                  iconSize: 32,
                  icon: Icon(
                    state.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: AppColors.ink,
                  ),
                  onPressed: ref.read(musicProvider.notifier).toggle,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              IconButton(
                iconSize: 32,
                icon: const Icon(Icons.skip_next, color: AppColors.gold),
                onPressed: ref.read(musicProvider.notifier).next,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: _QueueList(state: state),
          ),
        ],
      ),
    );
  }

  String _format(double seconds) {
    final total = seconds.round();
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _CoverLarge extends StatelessWidget {
  const _CoverLarge();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.smoke,
      child: Center(
        child: Icon(Icons.audiotrack, color: AppColors.gold, size: 72),
      ),
    );
  }
}

class _QueueList extends ConsumerWidget {
  const _QueueList({required this.state});

  final MusicState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      itemCount: state.queue.length,
      separatorBuilder: (_, __) =>
          const Divider(color: AppColors.borderSubtle, height: 1),
      itemBuilder: (context, index) {
        final track = state.queue[index];
        final active = index == state.currentIndex;
        return ListTile(
          leading: Icon(
            active ? Icons.graphic_eq : Icons.music_note,
            color: active ? AppColors.gold : AppColors.fog,
          ),
          title: Text(
            track.title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: active ? AppColors.gold : AppColors.sand,
            ),
          ),
          subtitle: Text(
            track.artist,
            style: AppTextStyles.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => ref.read(musicProvider.notifier).playIndex(index),
        );
      },
    );
  }
}
