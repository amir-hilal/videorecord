//utils.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

const platform = MethodChannel('com.example.videorecord/storage');

final logger = Logger();

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
