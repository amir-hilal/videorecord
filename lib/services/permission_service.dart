import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestPermissions() async {
    AndroidDeviceInfo build = await DeviceInfoPlugin().androidInfo;
    if (!Platform.isIOS && !Platform.isAndroid) {
      // If on a non-mobile platform (e.g., simulator), skip permissions.
      return true;
    }
    // Request camera permission
    final cameraStatus = await Permission.camera.request();
    // if (cameraStatus.isDenied || cameraStatus.isPermanentlyDenied) {
    //   openAppSettings();
    //   return false;
    // }

    // Request microphone permission
    final microphoneStatus = await Permission.microphone.request();
    // if (microphoneStatus.isDenied || microphoneStatus.isPermanentlyDenied) {
    //   openAppSettings();
    //   return false;
    // }

    // Request photo library permission
    final photoStatus = await Permission.photos.request();
    // if (photoStatus.isDenied || photoStatus.isPermanentlyDenied) {
    //   openAppSettings();
    //   return false;
    // }

    bool storagePermissionGranted;

    if (build.version.sdkInt >= 33) {
      // Android 13+
      final videoPermissionStatus = await Permission.videos.request();
      storagePermissionGranted = videoPermissionStatus.isGranted;
    } else if (build.version.sdkInt <= 29) {
      var storageStatus = await Permission.storage.request();
      storagePermissionGranted = storageStatus.isGranted;
    } else {
      storagePermissionGranted = true;
    }

    return cameraStatus.isGranted &&
        microphoneStatus.isGranted &&
        (photoStatus.isGranted ^ storagePermissionGranted);
  }

  // static Future<bool> _requestAndroidSpecificPermissions() async {
  //   // Check Android SDK version
  //   final videoPermissionStatus = await Permission.videos.status;
  //   if (!videoPermissionStatus.isGranted) {
  //     final videoPermissionRequest = await Permission.videos.request();
  //     if (!videoPermissionRequest.isGranted && videoPermissionRequest.isPermanentlyDenied) {
  //       openAppSettings();
  //       return false;
  //     }
  //   }
  //   return true;
  // }
  static Future<bool> isStoragePermissionGranted() async {
    AndroidDeviceInfo build = await DeviceInfoPlugin().androidInfo;
    if (build.version.sdkInt >= 33) {
      // Android 13+
      var videoPermissionStatus = await Permission.videos.status;
      return videoPermissionStatus.isGranted;
    } else if (build.version.sdkInt <= 29) {
      var storageStatus = await Permission.storage.status;
      return storageStatus.isGranted;
    } else {
      return true;
    }
  }
}
