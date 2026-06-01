import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lolipants/core/permissions/device_permission_prompt.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/constants/profile_strings.dart';
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
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
  bool _seededFromSession = false;
  bool _uploadingAvatar = false;
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    _seedFromAuthIfReady();
  }

  void _seedFromAuthIfReady() {
    if (_seededFromSession) return;
    final auth = ref.read(authProvider).value;
    if (auth is! AuthAuthenticated) return;
    _seededFromSession = true;
    _nameController.text = auth.user.name;
    _avatarUrl = auth.user.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authProvider);
    _seedFromAuthIfReady();
    final auth = ref.watch(authProvider).value;
    final user = auth is AuthAuthenticated ? auth.user : null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.gold),
          onPressed: () => context.pop(),
        ),
        title: Text(
          localizedFromContext(
            context,
            ProfileStrings.editProfile,
            ProfileStrings.editProfileAr,
          ),
          style: AppTextStyles.titleLarge,
        ),
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
                        backgroundImage: _safeNetworkImage(_avatarUrl),
                        child: _safeNetworkImage(_avatarUrl) != null
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
                            onTap: _uploadingAvatar ? null : _pickAvatar,
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              child: _uploadingAvatar
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.ink,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt,
                                      color: AppColors.ink,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (_uploadingAvatar) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: LinearProgressIndicator(
                      value: _uploadProgress > 0 ? _uploadProgress : null,
                      minHeight: 6,
                      backgroundColor: AppColors.borderSubtle,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                LolipantsTextField(
                  controller: _nameController,
                  label: localizedFromContext(
                    context,
                    ProfileStrings.nameLabel,
                    ProfileStrings.nameLabelAr,
                  ),
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
                  Text(
                    _error!,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.rubyLight),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                LolipantsButton(
                  label: _saving
                      ? localizedFromContext(
                          context,
                          ProfileStrings.saving,
                          ProfileStrings.savingAr,
                        )
                      : localizedFromContext(
                          context,
                          ProfileStrings.save,
                          ProfileStrings.saveAr,
                        ),
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
    final granted = await DevicePermissionPrompt.ensureForImageSource(
      context,
      ImageSource.gallery,
    );
    if (!granted) return;
    final picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final repo = ref.read(designsRepositoryProvider);
    setState(() {
      _uploadingAvatar = true;
      _uploadProgress = 0;
      _error = null;
    });
    final upload = await repo.uploadPrintImage(
      filePath: picked.path,
      onSendProgress: (sent, total) {
        if (!mounted) return;
        if (total <= 0) return;
        setState(() => _uploadProgress = sent / total);
      },
    );
    upload.fold(
      (err) {
        if (!mounted) return;
        setState(() {
          _uploadingAvatar = false;
          _error = err is ServerException && err.message.isNotEmpty
              ? err.message
              : localizedFromContext(
                  context,
                  ProfileStrings.avatarUploadFailed,
                  ProfileStrings.avatarUploadFailedAr,
                );
        });
      },
      (url) {
        if (!mounted) return;
        setState(() {
          _avatarUrl = url;
          _error = null;
          _uploadingAvatar = false;
        });
        _persistProfile(closeOnSuccess: false);
      },
    );
  }

  static ImageProvider? _safeNetworkImage(String? url) {
    final raw = url?.trim() ?? '';
    if (raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null) return null;
    if (!(uri.isScheme('http') || uri.isScheme('https'))) return null;
    if (uri.host.isEmpty) return null;
    return NetworkImage(raw);
  }

  Future<void> _save() async {
    await _persistProfile(closeOnSuccess: true);
  }

  Future<void> _persistProfile({required bool closeOnSuccess}) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(
        () => _error = localizedFromContext(
          context,
          ProfileStrings.nameRequired,
          ProfileStrings.nameRequiredAr,
        ),
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref.read(authProvider.notifier).updateProfile(
          name: name,
          image: _avatarUrl,
        );
    if (!mounted) return;
    result.fold(
      (err) => setState(() {
        _saving = false;
        _error = err is AuthException && err.message.isNotEmpty
            ? err.message
            : localizedFromContext(
                context,
                ProfileStrings.profileUpdateFailed,
                ProfileStrings.profileUpdateFailedAr,
              );
      }),
      (_) {
        if (!mounted) return;
        if (closeOnSuccess) {
          context.pop();
          return;
        }
        setState(() => _saving = false);
      },
    );
  }
}
