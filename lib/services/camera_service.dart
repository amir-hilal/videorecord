// lib/services/camera_service.dart

import 'package:camera/camera.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class CameraService {
  CameraController? _controller;

  CameraController? get controller => _controller;

  Future<void> initializeCamera(int cameraIndex, double zoomLevel) async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }
      final selectedCamera = cameras[cameraIndex];
      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: true,
      );
      await _controller!.initialize();
      await _controller!.setZoomLevel(zoomLevel);
    } catch (e) {
      logger.e('Error initializing camera', error: e);
      rethrow;
    }
  }

  Future<int> get availableCameraCount async {
    final cameras = await availableCameras();
    return cameras.length;
  }

  Future<void> switchCamera(int cameraIndex, double zoomLevel) async {
    try {
      await disposeCamera();
      await initializeCamera(cameraIndex, zoomLevel);
    } catch (e) {
      logger.e('Error switching camera', error: e);
      rethrow;
    }
  }

  Future<void> disposeCamera() async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }
  }

  Future<void> startRecording() async {
    _ensureInitialized();
    try {
      await _controller!.startVideoRecording();
    } catch (e) {
      logger.e('Error starting video recording', error: e);
      rethrow;
    }
  }

  Future<XFile?> stopRecording() async {
    _ensureInitialized();
    if (!_controller!.value.isRecordingVideo) {
      throw Exception('No video recording in progress');
    }
    try {
      return await _controller!.stopVideoRecording();
    } catch (e) {
      logger.e('Error stopping video recording', error: e);
      rethrow;
    }
  }

  Future<void> toggleFlash(bool isFlashOn) async {
    _ensureInitialized();
    try {
      await _controller!
          .setFlashMode(isFlashOn ? FlashMode.torch : FlashMode.off);
    } catch (e) {
      logger.e('Error toggling flash', error: e);
      rethrow;
    }
  }

  void _ensureInitialized() {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('Camera is not initialized');
    }
  }
}
