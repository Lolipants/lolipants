import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/editor/providers/designs_providers.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';
import 'package:lolipants/shared/widgets/lolipants_text_field.dart';

/// Phase 6A edit profile screen. Lets the user update their display name and
/// upload a new avatar; email is read-only.
class EditProfileScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _saving = false;
  String? _avatarUrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider).value;
    if (auth is AuthAuthenticated) {
      _nameController.text = auth.user.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider).value;
    final user = auth is AuthAuthenticated ? auth.user : null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.gold),
          onPressed: () => context.pop(),
        ),
        title: Text('Edit profile', style: AppTextStyles.titleLarge),
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
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 64,
                        backgroundColor: AppColors.ember,
                        foregroundColor: AppColors.gold,
                        backgroundImage: _avatarUrl != null
                            ? NetworkImage(_avatarUrl!)
                            : null,
                        child: _avatarUrl != null
                            ? null
                            : Text(
                                user?.initials ?? '?',
                                style: AppTextStyles.displayMedium.copyWith(
                                  color: AppColors.gold,
                                ),
                              ),
                      ),
                      Positioned(
                        bottom: -4,
                        right: -4,
                        child: Material(
                          color: AppColors.gold,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _pickAvatar,
                            child: const Padding(
                              padding: EdgeInsets.all(AppSpacing.sm),
                              child:
                                  Icon(Icons.camera_alt, color: AppColors.ink),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                LolipantsTextField(
                  controller: _nameController,
                  label: 'Name · الاسم',
                ),
                const SizedBox(height: AppSpacing.md),
                // Email is read-only; rendered as a styled row rather than an
                // editable field so the user can't accidentally change it.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.smoke.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.mail_outline, color: AppColors.fog),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          user?.email ?? '',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_error != null) ...[
                  Text(_error!,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.rubyLight)),
                  const SizedBox(height: AppSpacing.md),
                ],
                LolipantsButton(
                  label: _saving ? 'Saving…' : 'Save',
                  onPressed: _saving ? null : _save,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final repo = ref.read(designsRepositoryProvider);
    final upload = await repo.uploadPrintImage(filePath: picked.path);
    upload.fold(
      (_) {
        if (!mounted) return;
        setState(() => _error = 'Could not upload avatar.');
      },
      (url) {
        if (!mounted) return;
        setState(() {
          _avatarUrl = url;
          _error = null;
        });
      },
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name is required.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final result =
        await ref.read(authProvider.notifier).updateProfile(name: name);
    if (!mounted) return;
    result.fold(
      (_) => setState(() {
        _saving = false;
        _error = 'Could not update profile.';
      }),
      (_) => context.pop(),
    );
  }
}
