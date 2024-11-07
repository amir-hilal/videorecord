import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class VideoProvider with ChangeNotifier {
  final List<String> _videos = [];
  final List<String> _thumbnails = [];
  bool _isRecording = false;
  bool _isFlashOn = false;
  bool _isGridVisible = false;
  CameraLensDirection _lensDirection = CameraLensDirection.back;
  String? _lastRecordedThumbnailPath;

  List<String> get videos => _videos;
  List<String> get thumbnails => _thumbnails;
  bool get isRecording => _isRecording;
  bool get isFlashOn => _isFlashOn;
  bool get isGridVisible => _isGridVisible;
  CameraLensDirection get lensDirection => _lensDirection;
  String? get lastRecordedThumbnailPath => _lastRecordedThumbnailPath;

  void addVideo(String videoUri, String thumbnailUri) {
    _videos.add(videoUri);
    _thumbnails.add(thumbnailUri);
    notifyListeners();
  }

  void startRecording() {
    _isRecording = true;
    notifyListeners();
  }

  void stopRecording() {
    _isRecording = false;
    notifyListeners();
  }

  void toggleFlash() {
    _isFlashOn = !_isFlashOn;
    notifyListeners();
  }

  void toggleGrid() {
    _isGridVisible = !_isGridVisible;
    notifyListeners();
  }

  void toggleCameraLens() {
    _lensDirection = _lensDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    notifyListeners();
  }

  void setLastRecordedThumbnail(String thumbnailPath) {
    _lastRecordedThumbnailPath = thumbnailPath;
    notifyListeners();
  }

  void removeLastVideo() {
    if (_videos.isNotEmpty && _thumbnails.isNotEmpty) {
      _videos.removeLast();
      _thumbnails.removeLast();
      notifyListeners();
    }
  }
}
