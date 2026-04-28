import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/community/providers/community_providers.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/error_banner.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Available tag options for post creation.
const _tagOptions = <String>[
  'abaya',
  'thobe',
  'suit',
  'dress',
  'showcase',
  'inspiration',
  'sale',
];

const _maxImages = 4;
const _maxBodyLength = 4000;
const _maxTags = 5;

/// Prefill payload for [CreatePostScreen] (used by editor share).
class CreatePostPrefill {
  /// Creates prefill data.
  const CreatePostPrefill({
    this.body,
    this.imageBytes,
    this.imageFilename,
    this.tags = const [],
  });

  /// Prefilled body text.
  final String? body;

  /// Optional in-memory image bytes (e.g. from the editor share flow).
  final Uint8List? imageBytes;

  /// Filename to attach to the uploaded image.
  final String? imageFilename;

  /// Initial tags.
  final List<String> tags;
}

/// Screen for creating a new community post.
class CreatePostScreen extends ConsumerStatefulWidget {
  /// Creates the create-post screen.
  const CreatePostScreen({this.prefill, super.key});

  /// Optional prefill payload (e.g. from the editor share flow).
  final CreatePostPrefill? prefill;

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  late final TextEditingController _bodyController;
  final _picker = ImagePicker();
  final _selectedTags = <String>{};
  final _images = <_DraftImage>[];
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _bodyController = TextEditingController(text: widget.prefill?.body ?? '');
    _selectedTags.addAll(widget.prefill?.tags ?? const <String>[]);
    final bytes = widget.prefill?.imageBytes;
    if (bytes != null) {
      _images.add(
        _DraftImage.bytes(
          bytes,
          filename: widget.prefill?.imageFilename ?? 'design.png',
        ),
      );
    }
  }

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_images.length >= _maxImages) return;
    try {
      final picked = await _picker.pickMultiImage(imageQuality: 80);
      if (picked.isEmpty) return;
      setState(() {
        for (final p in picked) {
          if (_images.length >= _maxImages) break;
          _images.add(_DraftImage.xfile(p));
        }
      });
    } on Exception catch (_) {
      setState(() => _errorMessage = 'Could not open photo library.');
    }
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else if (_selectedTags.length < _maxTags) {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _submit() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty) {
      setState(() => _errorMessage = 'Write something before posting.');
      return;
    }
    if (body.length > _maxBodyLength) {
      setState(() => _errorMessage = 'Post is too long.');
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final uploadRepo = ref.read(mediaUploadRepositoryProvider);
    final urls = <String>[];
    for (final image in _images) {
      final result = image.bytes != null
          ? await uploadRepo.uploadBytes(
              bytes: image.bytes!,
              filename: image.filename,
            )
          : await uploadRepo.uploadFile(
              filePath: image.path!,
              filename: image.filename,
            );
      final next = result.fold<String?>(
        (e) {
          setState(() {
            _submitting = false;
            _errorMessage = communityErrorMessage(
              e,
              fallback: 'Could not upload image.',
            );
          });
          return null;
        },
        (url) => url,
      );
      if (next == null) return;
      urls.add(next);
    }

    final postsRepo = ref.read(postsRepositoryProvider);
    final created = await postsRepo.createPost(
      body: body,
      imageUrls: urls,
      tags: _selectedTags.toList(growable: false),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    created.fold(
      (e) {
        setState(
          () => _errorMessage = communityErrorMessage(
            e,
            fallback: 'Could not publish post.',
          ),
        );
      },
      (post) {
        ref
            .read(feedPostsProvider(null).notifier)
            .insertPost(post);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post published')),
        );
        context.pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('New post', style: AppTextStyles.titleLarge),
      ),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: ErrorBanner(
                        message: _errorMessage!,
                        onDismiss: () =>
                            setState(() => _errorMessage = null),
                      ),
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.smoke,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.md,
                            ),
                            child: TextField(
                              controller: _bodyController,
                              maxLines: 6,
                              minLines: 3,
                              maxLength: _maxBodyLength,
                              style: AppTextStyles.bodyLarge,
                              cursorColor: AppColors.gold,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'What are you showcasing?',
                                hintStyle: AppTextStyles.bodyMedium,
                                counterStyle: AppTextStyles.bodySmall,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text('Images', style: AppTextStyles.titleSmall),
                          const SizedBox(height: AppSpacing.sm),
                          _ImageTray(
                            images: _images,
                            onAdd: _pickImages,
                            onRemove: (idx) =>
                                setState(() => _images.removeAt(idx)),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text('Tags', style: AppTextStyles.titleSmall),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final tag in _tagOptions)
                                _TagChip(
                                  label: '#$tag',
                                  active: _selectedTags.contains(tag),
                                  onTap: () => _toggleTag(tag),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                      ),
                    ),
                  ),
                  LolipantsButton(
                    label: 'Publish post',
                    loading: _submitting,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftImage {
  _DraftImage.xfile(XFile file)
      : path = file.path,
        filename = file.name,
        bytes = null;

  _DraftImage.bytes(Uint8List data, {required this.filename})
      : path = null,
        bytes = data;

  final String? path;
  final Uint8List? bytes;
  final String filename;
}

class _ImageTray extends StatelessWidget {
  const _ImageTray({
    required this.images,
    required this.onAdd,
    required this.onRemove,
  });

  final List<_DraftImage> images;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == images.length) {
            return _AddImageTile(
              disabled: images.length >= _maxImages,
              onTap: onAdd,
            );
          }
          final image = images[index];
          return _ImageTile(image: image, onRemove: () => onRemove(index));
        },
      ),
    );
  }
}

class _AddImageTile extends StatelessWidget {
  const _AddImageTile({required this.disabled, required this.onTap});

  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Opacity(
        opacity: disabled ? 0.4 : 1,
        child: Container(
          width: 100,
          decoration: BoxDecoration(
            color: AppColors.stone,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.borderDefault,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_photo_alternate_outlined,
                color: AppColors.gold,
              ),
              const SizedBox(height: 4),
              Text('Add', style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({required this.image, required this.onRemove});

  final _DraftImage image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    Widget preview;
    if (image.bytes != null) {
      preview = Image.memory(image.bytes!, fit: BoxFit.cover);
    } else if (image.path != null) {
      preview = kIsWeb
          ? const SizedBox.shrink()
          : Image.file(File(image.path!), fit: BoxFit.cover);
    } else {
      preview = const SizedBox.shrink();
    }
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.smoke,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: preview,
        ),
        Positioned(
          top: 2,
          right: 2,
          child: Material(
            color: AppColors.ink.withValues(alpha: 0.8),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onRemove,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.close, size: 14, color: AppColors.sand),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.gold : AppColors.ember,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: active ? AppColors.gold : AppColors.borderDefault,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelGold.copyWith(
            color: active ? AppColors.ink : AppColors.gold,
          ),
        ),
      ),
    );
  }
}
