//video_modal_provider.dart

import 'package:flutter/material.dart';
import 'package:videorecord/utils/audio_utils.dart';

class VideoModalProvider with ChangeNotifier {
  bool _isModalShown = false;

  bool get isModalShown => _isModalShown;

  void showModal() {
    playSaveTakeAudio();

    _isModalShown = true;
    notifyListeners();
  }

  void hideModal() {
    _isModalShown = false;
    notifyListeners();
  }
}
