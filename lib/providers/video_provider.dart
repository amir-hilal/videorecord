import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';

class VideoProvider with ChangeNotifier {
  final List<String> _videos = [];
  final List<String> _thumbnails = [];
  bool _isRecording = false;
  bool _isFlashOn = false;
  bool _isGridVisible = false;
  CameraLensDirection _lensDirection = CameraLensDirection.back;

  List<String> get videos => _videos;
  List<String> get thumbnails => _thumbnails;
  bool get isRecording => _isRecording;
  bool get isFlashOn => _isFlashOn;
  bool get isGridVisible => _isGridVisible;
  CameraLensDirection get lensDirection => _lensDirection;

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
}
