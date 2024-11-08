import 'package:audioplayers/audioplayers.dart';
import 'package:logger/logger.dart';

final logger = Logger();

Future<void> playReadyToRecordAudio() async {
  final player = AudioPlayer();
  try {
    await player.play(AssetSource('audio/ready-to-record.mp3'));
  } catch (error) {
    logger.e('Failed to play audio', error: error);
  }
}
