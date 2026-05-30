import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/push/onesignal_bootstrap.dart';
import 'package:permission_handler/permission_handler.dart';

/// Device capabilities that require OS permission.
enum AppDevicePermission {
  camera,
  photos,
  location,
  notifications,
  audioFiles,
}

/// Result of a permission prompt flow.
enum DevicePermissionOutcome {
  granted,
  denied,
  permanentlyDenied,
}

/// Shows a rationale [AlertDialog] before requesting OS permissions.
abstract final class DevicePermissionPrompt {
  /// Requests permission for [ImagePicker] based on [source].
  static Future<bool> ensureForImageSource(
    BuildContext context,
    ImageSource source,
  ) {
    return ensure(
      context,
      source == ImageSource.camera
          ? AppDevicePermission.camera
          : AppDevicePermission.photos,
    );
  }

  /// Shows rationale, then requests the OS permission when the user continues.
  static Future<bool> ensure(
    BuildContext context,
    AppDevicePermission kind,
  ) async {
    final outcome = await requestWithRationale(context, kind);
    return outcome == DevicePermissionOutcome.granted;
  }

  /// Like [ensure] but returns the full [DevicePermissionOutcome].
  static Future<DevicePermissionOutcome> requestWithRationale(
    BuildContext context,
    AppDevicePermission kind,
  ) async {
    // Gallery picks on iOS use PHPicker and do not require photo-library
    // permission. Pre-checking [Permission.photos] can falsely report
    // "permanently denied" and send users to Settings before the system
    // prompt (App Store Guideline 5.1.1(iv)).
    if (Platform.isIOS && kind == AppDevicePermission.photos) {
      return DevicePermissionOutcome.granted;
    }

    final permissions = await _permissionsFor(kind);
    if (await _isSatisfied(permissions)) {
      return DevicePermissionOutcome.granted;
    }

    if (!context.mounted) return DevicePermissionOutcome.denied;
    final proceed = await _showRationaleDialog(context, kind);
    if (!proceed) return DevicePermissionOutcome.denied;

    if (kind == AppDevicePermission.location) {
      final outcome = await _requestLocation();
      if (outcome == DevicePermissionOutcome.permanentlyDenied &&
          context.mounted) {
        await _showOpenSettingsDialog(context, kind);
      }
      return outcome;
    }
    if (kind == AppDevicePermission.notifications) {
      return _requestNotifications();
    }

    if (permissions.length > 1) {
      for (final permission in permissions) {
        final status = await permission.request();
        if (status.isGranted || status.isLimited) {
          return DevicePermissionOutcome.granted;
        }
        if (status.isPermanentlyDenied) {
          if (context.mounted) {
            await _showOpenSettingsDialog(context, kind);
          }
          return DevicePermissionOutcome.permanentlyDenied;
        }
      }
      return DevicePermissionOutcome.denied;
    }

    final status = await permissions.single.request();
    if (status.isGranted || status.isLimited) {
      return DevicePermissionOutcome.granted;
    }
    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await _showOpenSettingsDialog(context, kind);
      }
      return DevicePermissionOutcome.permanentlyDenied;
    }
    return DevicePermissionOutcome.denied;
  }

  static Future<List<Permission>> _permissionsFor(
    AppDevicePermission kind,
  ) async {
    return switch (kind) {
      AppDevicePermission.camera => [Permission.camera],
      AppDevicePermission.photos => await _photoPermissions(),
      AppDevicePermission.location => [Permission.locationWhenInUse],
      AppDevicePermission.notifications => [Permission.notification],
      AppDevicePermission.audioFiles => await _audioPermissions(),
    };
  }

  static Future<List<Permission>> _photoPermissions() async {
    if (Platform.isAndroid) {
      return [Permission.photos, Permission.storage];
    }
    return [Permission.photos];
  }

  static Future<List<Permission>> _audioPermissions() async {
    if (Platform.isAndroid) {
      return [Permission.audio, Permission.storage];
    }
    return [Permission.storage];
  }

  static Future<bool> _isSatisfied(List<Permission> permissions) async {
    if (permissions.length > 1) {
      for (final permission in permissions) {
        final status = await permission.status;
        if (status.isGranted || status.isLimited) {
          return true;
        }
      }
      return false;
    }
    final status = await permissions.single.status;
    return status.isGranted || status.isLimited;
  }

  static Future<DevicePermissionOutcome> _requestLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return DevicePermissionOutcome.denied;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse =>
        DevicePermissionOutcome.granted,
      LocationPermission.deniedForever =>
        DevicePermissionOutcome.permanentlyDenied,
      _ => DevicePermissionOutcome.denied,
    };
  }

  static Future<DevicePermissionOutcome> _requestNotifications() async {
    final granted = await requestPushPermission();
    return granted
        ? DevicePermissionOutcome.granted
        : DevicePermissionOutcome.denied;
  }

  static Future<bool> _showRationaleDialog(
    BuildContext context,
    AppDevicePermission kind,
  ) async {
    final copy = _copyFor(kind);
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(copy.title),
        content: Text(copy.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.permissionNotNow),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(AppStrings.permissionContinue),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<void> _showOpenSettingsDialog(
    BuildContext context,
    AppDevicePermission kind,
  ) async {
    final copy = _copyFor(kind);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(copy.deniedTitle),
        content: Text(copy.deniedMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(AppStrings.permissionNotNow),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await openAppSettings();
            },
            child: const Text(AppStrings.permissionOpenSettings),
          ),
        ],
      ),
    );
  }

  static _PermissionCopy _copyFor(AppDevicePermission kind) {
    return switch (kind) {
      AppDevicePermission.camera => const _PermissionCopy(
          title: AppStrings.permissionCameraTitle,
          message: AppStrings.permissionCameraMessage,
          deniedTitle: AppStrings.permissionCameraDeniedTitle,
          deniedMessage: AppStrings.permissionCameraDeniedMessage,
        ),
      AppDevicePermission.photos => const _PermissionCopy(
          title: AppStrings.permissionPhotosTitle,
          message: AppStrings.permissionPhotosMessage,
          deniedTitle: AppStrings.permissionPhotosDeniedTitle,
          deniedMessage: AppStrings.permissionPhotosDeniedMessage,
        ),
      AppDevicePermission.location => const _PermissionCopy(
          title: AppStrings.permissionLocationTitle,
          message: AppStrings.permissionLocationMessage,
          deniedTitle: AppStrings.permissionLocationDeniedTitle,
          deniedMessage: AppStrings.permissionLocationDeniedMessage,
        ),
      AppDevicePermission.notifications => const _PermissionCopy(
          title: AppStrings.permissionNotificationsTitle,
          message: AppStrings.permissionNotificationsMessage,
          deniedTitle: AppStrings.permissionNotificationsDeniedTitle,
          deniedMessage: AppStrings.permissionNotificationsDeniedMessage,
        ),
      AppDevicePermission.audioFiles => const _PermissionCopy(
          title: AppStrings.permissionAudioTitle,
          message: AppStrings.permissionAudioMessage,
          deniedTitle: AppStrings.permissionAudioDeniedTitle,
          deniedMessage: AppStrings.permissionAudioDeniedMessage,
        ),
    };
  }
}

class _PermissionCopy {
  const _PermissionCopy({
    required this.title,
    required this.message,
    required this.deniedTitle,
    required this.deniedMessage,
  });

  final String title;
  final String message;
  final String deniedTitle;
  final String deniedMessage;
}
