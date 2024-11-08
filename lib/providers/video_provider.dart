// lib/providers/video_provider.dart

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class VideoProvider with ChangeNotifier {
  final List<VideoData> _videos = [];
  bool _isRecording = false;
  bool _isFlashOn = false;
  bool _isGridVisible = false;
  CameraLensDirection _lensDirection = CameraLensDirection.back;
  String? _lastRecordedThumbnailPath;

  List<VideoData> get videos => _videos;
  bool get isRecording => _isRecording;
  bool get isFlashOn => _isFlashOn;
  bool get isGridVisible => _isGridVisible;
  CameraLensDirection get lensDirection => _lensDirection;
  String? get lastRecordedThumbnailPath => _lastRecordedThumbnailPath;

  // Add a video and update the last recorded thumbnail
  void addVideo(String videoUri, String thumbnailUri) {
    _videos.add(VideoData(videoUrl: videoUri, thumbnailUrl: thumbnailUri));
    _updateLastRecordedThumbnail(thumbnailUri);
  }

  // Start video recording
  void startRecording() => _updateRecordingStatus(true);

  // Stop video recording
  void stopRecording() => _updateRecordingStatus(false);

  // Toggle flash on/off
  void toggleFlash() => _updateFlashStatus(!_isFlashOn);

  // Toggle grid visibility
  void toggleGrid() => _updateGridVisibility(!_isGridVisible);

  // Toggle between front and back camera lens
  void toggleCameraLens() {
    _lensDirection = _lensDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    notifyListeners();
  }

  // Set the last recorded thumbnail
  void setLastRecordedThumbnail(String thumbnailPath) {
    _updateLastRecordedThumbnail(thumbnailPath);
  }

  // Remove the last video from the list


  // Clear the last recorded thumbnail
  void clearLastRecordedThumbnail() {
    _updateLastRecordedThumbnail(null);
  }

  // Private method to update recording status
  void _updateRecordingStatus(bool isRecording) {
    _isRecording = isRecording;
    notifyListeners();
  }

  // Private method to update flash status
  void _updateFlashStatus(bool isFlashOn) {
    _isFlashOn = isFlashOn;
    notifyListeners();
  }

  // Private method to update grid visibility
  void _updateGridVisibility(bool isGridVisible) {
    _isGridVisible = isGridVisible;
    notifyListeners();
  }

  // Private method to update the last recorded thumbnail
  void _updateLastRecordedThumbnail(String? thumbnailPath) {
    _lastRecordedThumbnailPath = thumbnailPath;
    notifyListeners();
  }
}

class VideoData {
  final String videoUrl;
  final String thumbnailUrl;

  VideoData({required this.videoUrl, required this.thumbnailUrl});
}
