import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

final logger = Logger();

Future<XFile?> generateThumbnail(String videoUri) async {
  try {
    final thumbnailPath = await VideoThumbnail.thumbnailFile(
      video: videoUri,
      thumbnailPath: (await getTemporaryDirectory()).path,
      imageFormat: ImageFormat.PNG,
      maxHeight: 200, // specify the height, width auto-scales
      quality: 75,
    );
    return thumbnailPath;
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
    final directory = await getApplicationDocumentsDirectory();
    final freeSpace = await directory.stat().then((stat) => stat.size);
    return freeSpace;
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
