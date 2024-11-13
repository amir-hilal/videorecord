import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestPermissions() async {
    AndroidDeviceInfo build = await DeviceInfoPlugin().androidInfo;

    final cameraStatus = await Permission.camera.request();
    final microphoneStatus = await Permission.microphone.request();

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
        storagePermissionGranted;
  }

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
