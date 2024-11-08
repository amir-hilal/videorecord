import 'dart:async';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

final logger = Logger();
const MethodChannel _mediaChannel =
    MethodChannel('com.example.videorecord/media');

Future<void> saveVideoToGalleryNative(String filePath) async {
  try {
    if (await Permission.storage.request().isGranted) {
      await _mediaChannel.invokeMethod('addToGallery', {"path": filePath});
      logger.i('Video added to gallery successfully.');
    } else {
      logger.e('Permission to write to storage was denied.');
    }
  } catch (e) {
    logger.e('Failed to save video to gallery: $e');
  }
}

Future<int> checkAvailableStorage() async {
  try {
    const platform = MethodChannel('com.example.videorecord/storage');
    final int availableStorage =
        await platform.invokeMethod('getAvailableStorage');
    logger.i('Available storage: $availableStorage bytes');
    return availableStorage;
  } catch (error) {
    logger.e('Failed to get storage info', error: error);
    return 0;
  }
}
