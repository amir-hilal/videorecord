import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

final logger = Logger();

const MethodChannel _mediaChannel =
    MethodChannel('com.productra.shootsolo/media');

Future<void> saveVideoToGalleryNative(String filePath) async {
  try {
    await _mediaChannel.invokeMethod('addToGallery', {"path": filePath});
    logger.i('Video added to gallery successfully.');
  } catch (e) {
    logger.e('Failed to save video to gallery: $e');
  }
}

Future<int> checkAvailableStorage() async {
  try {
    const platform = MethodChannel('com.productra.shootsolo/storage');
    final int availableStorage =
        await platform.invokeMethod('getAvailableStorage');
    logger.i('Available storage: $availableStorage bytes');
    return availableStorage;
  } catch (error) {
    logger.e('Failed to get storage info', error: error);
    return 0;
  }
}

const platform = MethodChannel('com.productra.shootsolo/storage');

Future<int> getRecordedVideoSize(String videoUri) async {
  try {
    final file = File(videoUri);
    final size = await file.length();
    return size;
  } catch (error) {
    logger.e('Failed to get video file size', error: error);
    return 0;
  }
}
