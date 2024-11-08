import 'dart:io';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:logger/logger.dart';

final logger = Logger();

Future<String?> generateThumbnail(String videoUri) async {
  try {
    final XFile thumbnailFile = await VideoThumbnail.thumbnailFile(
      video: videoUri,
      thumbnailPath: Directory.systemTemp.path,
      imageFormat: ImageFormat.PNG,
      maxHeight: 480,
      maxWidth: 270,
      quality: 75,
    );

    return thumbnailFile.path;
  } catch (error) {
    logger.e('Thumbnail generation failed', error: error);
    return null;
  }
}
