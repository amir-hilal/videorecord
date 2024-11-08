import 'package:audioplayers/audioplayers.dart';
import 'package:logger/logger.dart';

final logger = Logger();

Future<void> playReadyToRecordAudio() async {
  final player = AudioPlayer();
  try {
    await player.play(AssetSource('audio/ready-to-record.mp3'));
  } catch (error) {
    logger.e('Failed to play ready to record audio', error: error);
  }
}

Future<void> playStartRecordAudio() async {
  final player = AudioPlayer();
  try {
    await player.play(AssetSource('audio/blip_start.mp3'));
  } catch (error) {
    logger.e('Failed to play blip start audio', error: error);
  }
}

Future<void> playStopRecordAudio() async {
  final player = AudioPlayer();
  try {
    await player.play(AssetSource('audio/blip_stop.mp3'));
  } catch (error) {
    logger.e('Failed to play blip stop audio', error: error);
  }
}

Future<void> playSaveTakeAudio() async {
  final player = AudioPlayer();
  try {
    await player.play(AssetSource('audio/save_take.mp3'));
    logger.i('playing save take audio');
  } catch (error) {
    logger.e('Failed to play save take audio', error: error);
  }
}
