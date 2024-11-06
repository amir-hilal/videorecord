import 'package:flutter/foundation.dart';

class VideoProvider with ChangeNotifier {
  final List<String> _videos = [];
  final List<String> _thumbnails = [];

  List<String> get videos => _videos;
  List<String> get thumbnails => _thumbnails;

  void addVideo(String videoUri, String thumbnailUri) {
    _videos.add(videoUri);
    _thumbnails.add(thumbnailUri);
    notifyListeners();
  }
}
