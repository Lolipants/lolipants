import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/permissions/device_permission_prompt.dart';
import 'package:lolipants/core/preferences/user_gender_provider.dart';
import 'package:lolipants/core/router/role_routing.dart';
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/utils/validators.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/auth/utils/auth_env.dart';
import 'package:lolipants/features/auth/utils/auth_error_mapper.dart';
import 'package:lolipants/features/auth/widgets/social_auth_row.dart';
import 'package:lolipants/features/editor/providers/designs_providers.dart';
import 'package:lolipants/shared/widgets/error_banner.dart';
import 'package:lolipants/shared/widgets/gold_divider.dart';
import 'package:lolipants/shared/widgets/loading_overlay.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';
import 'package:lolipants/shared/widgets/lolipants_text_field.dart';

/// Registration screen with gender choice and optional profile photo.
class SignupScreen extends ConsumerStatefulWidget {
  /// Creates the sign-up screen.
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String? _genderError;
  String? _banner;
  String? _selectedGender;
  String? _avatarLocalPath;
  String? _avatarUploadUrl;
  bool _loading = false;
  bool _uploadingAvatar = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool _validate() {
    final nameKey = Validators.nameErrorKey(_name.text);
    final emailKey = Validators.emailErrorKey(_email.text);
    final pwKey = Validators.passwordSignupErrorKey(_password.text);
    setState(() {
      _nameError = switch (nameKey) {
        'name_short' => AppStrings.errorNameShort,
        'required' => AppStrings.errorRequired,
        _ => null,
      };
      _emailError = switch (emailKey) {
        'required' => AppStrings.errorRequired,
        'invalid_email' => AppStrings.errorInvalidEmail,
        _ => null,
      };
      _passwordError = switch (pwKey) {
        'required' => AppStrings.errorRequired,
        'password_short' => AppStrings.errorPasswordShort,
        'password_no_digit' => AppStrings.errorPasswordDigit,
        _ => null,
      };
      _confirmError = _password.text != _confirm.text
          ? AppStrings.errorPasswordMismatch
          : null;
      _genderError = _selectedGender == null
          ? AppStrings.signupGenderRequired
          : null;
    });
    return _nameError == null &&
        _emailError == null &&
        _passwordError == null &&
        _confirmError == null &&
        _genderError == null;
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
    setState(() {
      _avatarLocalPath = picked.path;
      _avatarUploadUrl = null;
    });
  }

  Future<String?> _uploadAvatarIfNeeded() async {
    if (_avatarLocalPath == null) {
      return _avatarUploadUrl;
    }
    if (_avatarUploadUrl != null) {
      return _avatarUploadUrl;
    }
    setState(() => _uploadingAvatar = true);
    final repo = ref.read(designsRepositoryProvider);
    final upload = await repo.uploadPrintImage(filePath: _avatarLocalPath!);
    if (!mounted) return null;
    setState(() => _uploadingAvatar = false);
    return upload.fold(
      (err) {
        setState(() {
          _banner = switch (err) {
            ServerException(:final message) when message.isNotEmpty => message,
            AuthException(:final message) when message.isNotEmpty => message,
            NetworkException(:final message) when message.isNotEmpty => message,
            _ => AppStrings.errorAuthGeneric,
          };
        });
        return null;
      },
      (url) {
        _avatarUploadUrl = url;
        return url;
      },
    );
  }

  Future<void> _submit() async {
    setState(() => _banner = null);
    if (!_validate()) {
      return;
    }
    final envMsg = missingBetterAuthBaseUrlMessage();
    if (envMsg != null) {
      setState(() => _banner = envMsg);
      return;
    }
    setState(() => _loading = true);
    final avatarUrl = await _uploadAvatarIfNeeded();
    if (!mounted) return;
    if (_avatarLocalPath != null && avatarUrl == null) {
      setState(() => _loading = false);
      return;
    }
    final result = await ref.read(authProvider.notifier).signUpWithProfile(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          avatarUrl: avatarUrl,
        );
    if (!mounted) {
      return;
    }
    setState(() => _loading = false);
    await result.fold(
      (e) async => setState(() => _banner = mapAuthExceptionToUserMessage(e)),
      (user) async {
        if (_selectedGender != null) {
          await ref
              .read(userGenderProvider.notifier)
              .setGender(_selectedGender!);
        }
        if (!mounted) return;
        final returnTo = ref.read(pendingAuthReturnToProvider);
        ref.read(pendingAuthReturnToProvider.notifier).state = null;
        context.go(postAuthLocation(user, returnTo));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.chevron_left),
                      ),
                    ],
                  ),
                  Text(
                    AppStrings.createAccount,
                    style: AppTextStyles.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      AppStrings.createAccountAr,
                      style: AppTextStyles.arabicLabel,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const GoldDivider(width: 40),
                  const SizedBox(height: AppSpacing.xl),
                  if (_banner != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: ErrorBanner(
                        message: _banner!,
                        onDismiss: () => setState(() => _banner = null),
                      ),
                    ),
                  Center(
                    child: GestureDetector(
                      onTap: _uploadingAvatar ? null : _pickAvatar,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: AppColors.ember,
                            backgroundImage: _avatarLocalPath != null
                                ? FileImage(File(_avatarLocalPath!))
                                : null,
                            child: _avatarLocalPath == null
                                ? const Icon(
                                    Icons.person_outline,
                                    size: 40,
                                    color: AppColors.gold,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.gold,
                              child: _uploadingAvatar
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.ink,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt,
                                      size: 16,
                                      color: AppColors.ink,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    AppStrings.signupPhotoHint,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.fog),
                    textAlign: TextAlign.center,
                  ),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      AppStrings.signupPhotoHintAr,
                      style: AppTextStyles.arabicBody.copyWith(fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    AppStrings.signupGenderLabel,
                    style: AppTextStyles.bodyMedium,
                  ),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      AppStrings.signupGenderLabelAr,
                      style: AppTextStyles.arabicLabel.copyWith(fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _GenderChip(
                        label: AppStrings.homeCategoryMen,
                        selected: _selectedGender == UserGenderPreference.men,
                        onTap: () => setState(() {
                          _selectedGender = UserGenderPreference.men;
                          _genderError = null;
                        }),
                      ),
                      _GenderChip(
                        label: AppStrings.homeCategoryWomen,
                        selected:
                            _selectedGender == UserGenderPreference.women,
                        onTap: () => setState(() {
                          _selectedGender = UserGenderPreference.women;
                          _genderError = null;
                        }),
                      ),
                      _GenderChip(
                        label: AppStrings.homeCategoryKids,
                        selected: _selectedGender == UserGenderPreference.kids,
                        onTap: () => setState(() {
                          _selectedGender = UserGenderPreference.kids;
                          _genderError = null;
                        }),
                      ),
                    ],
                  ),
                  if (_genderError != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _genderError!,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.rubyLight),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  LolipantsTextField(
                    label: AppStrings.fullName,
                    controller: _name,
                    errorText: _nameError,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  LolipantsTextField(
                    label: AppStrings.email,
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    errorText: _emailError,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  LolipantsTextField(
                    label: AppStrings.password,
                    controller: _password,
                    obscureText: true,
                    obscureToggle: true,
                    errorText: _passwordError,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  LolipantsTextField(
                    label: AppStrings.confirmPassword,
                    controller: _confirm,
                    obscureText: true,
                    obscureToggle: true,
                    errorText: _confirmError,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  LolipantsButton(
                    label: AppStrings.createAccountCta,
                    onPressed: _submit,
                    loading: _loading || _uploadingAvatar,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(color: AppColors.borderSubtle),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: Text(
                          'or',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.fog,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(color: AppColors.borderSubtle),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SocialAuthRow(
                    onError: (msg) => setState(() => _banner = msg),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.alreadyHaveAccount,
                        style: AppTextStyles.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () => context.push('/login'),
                        child: Text(
                          '${AppStrings.logIn} / ${AppStrings.logInAr}',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          LoadingOverlay(visible: _loading),
        ],
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  const _GenderChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.gold,
      checkmarkColor: AppColors.ink,
      labelStyle: AppTextStyles.bodySmall.copyWith(
        color: selected ? AppColors.ink : AppColors.fog,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
      side: BorderSide(
        color: selected ? AppColors.gold : AppColors.borderSubtle,
      ),
    );
  }
}
