import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
// import 'package:flutter/services.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:logger/logger.dart';

const platform = MethodChannel('com.example.videorecord/storage');

final logger = Logger();

// Future<String?> mirrorVideo(String inputPath) async {
//   const platform = MethodChannel('com.example.videorecord/video');
//   final outputPath =
//       '${inputPath}_mirrored.mp4'; // Corrected the variable definition

//   try {
//     final result = await platform.invokeMethod<String>(
//       'mirrorVideo',
//       {
//         'inputPath': inputPath,
//         'outputPath': outputPath,
//       },
//     );
//     return result;
//   } on PlatformException catch (e) {
//     print("Failed to mirror video: '${e.message}'.");
//     return null;
//   }
// }

Future<String?> generateThumbnail(String videoUri) async {
  try {
    final XFile thumbnailFile = await VideoThumbnail.thumbnailFile(
      video: videoUri,
      thumbnailPath: Directory.systemTemp.path,
      imageFormat: ImageFormat.PNG,
      maxHeight: 480,
      maxWidth: 270, // Ensure 9:16 aspect ratio
      quality: 75,
    );

    return thumbnailFile.path;
  } catch (error) {
    logger.e('Thumbnail generation failed', error: error);
    return null;
  }
}

Future<void> playReadyToRecordAudio() async {
  final player = AudioPlayer();
  try {
    await player.setSource(AssetSource("assets/audio/ready-to-record.mp3"));
    await player.resume();
  } catch (error) {
    logger.e('Failed to play audio', error: error);
  }
}

// const STORAGE_THRESHOLD = 50 * 1024 * 1024; // 50 MB buffer

Future<int> checkAvailableStorage() async {
  try {
    final int availableStorage =
        await platform.invokeMethod('getAvailableStorage');
    logger.i('Available storage: $availableStorage bytes');
    return availableStorage;
  } catch (error) {
    logger.e('Failed to get storage info', error: error);
    return 0;
  }
}

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
