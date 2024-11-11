// lib/screens/camera_screen.dart
import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:videorecord/widgets/grid_painter.dart';
import 'package:videorecord/widgets/save_video_modal.dart';
import 'package:videorecord/widgets/zoom_control.dart';

import '../providers/video_modal_provider.dart';
import '../providers/video_provider.dart';
import '../services/camera_service.dart';
import '../utils/audio_utils.dart';
import '../utils/storage_utils.dart';
import '../utils/video_utils.dart';

final logger = Logger();

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  CameraScreenState createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool isCameraInitialized = false;
  Timer? _timer;
  Timer? _storageCheckTimer;
  int _recordingTime = 0;
  String? lastRecordedVideoPath;
  bool isSwitchingCamera = false;
  int _currentCameraIndex = 0;
  double _zoomLevel = 1.0;
  double _lastDistance = 0.0;
  String? _tempThumbnailPath;
  static const int storageThreshold = 50 * 1024 * 1024; // 50 MB threshold
  final CameraService _cameraService = CameraService();

  int _retryCount = 0; // Counter for retry attempts
  static const int _maxRetryAttempts = 3; // Maximum retry attempts
  static const Duration _retryDelay =
      Duration(seconds: 2); // Delay between retries

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _enableImmersiveMode();
  }

  void _enableImmersiveMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: []); // Hides both status and nav bars
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor:
            Colors.transparent, // Makes the status bar transparent if shown
        systemNavigationBarColor: Colors.black, // Color of the nav bar if shown
      ),
    );
  }

  void _disableImmersiveMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values); // Shows the bars again
  }

  Future<void> _initializeCamera() async {
    setState(() {
      isCameraInitialized = false;
      isSwitchingCamera = true;
    });

    try {
      await _cameraService.initializeCamera(_currentCameraIndex, _zoomLevel);
      if (!mounted) return;

      setState(() {
        _controller = _cameraService.controller;
        isCameraInitialized = true;
        isSwitchingCamera = false;
        _retryCount = 0;
      });
    } catch (e) {
      _handleCameraError(e);
    }
  }

  void _handleCameraError(Object e) {
    logger.e('Error initializing camera', error: e);
    setState(() {
      isSwitchingCamera = false;
    });

    if (_retryCount < _maxRetryAttempts) {
      _retryCount++;
      logger.w(
          'Retrying camera initialization ($_retryCount/$_maxRetryAttempts)...');
      Future.delayed(_retryDelay, _initializeCamera);
    } else {
      logger
          .e('Camera failed to initialize after $_maxRetryAttempts attempts.');
      // You can show a message to the user here if desired
      _showInitializationError();
    }
  }

  void _showInitializationError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("Failed to initialize camera after several attempts.")),
    );
  }

  Future<void> _toggleCameraLens() async {
    final videoProvider = Provider.of<VideoProvider>(context, listen: false);
    videoProvider.stopRecording();

    setState(() {
      isCameraInitialized = false;
      isSwitchingCamera = true;
    });

    try {
      _currentCameraIndex =
          (_currentCameraIndex + 1) % await _cameraService.availableCameraCount;
      await _cameraService.switchCamera(_currentCameraIndex, _zoomLevel);
      if (!mounted) return;

      setState(() {
        _controller = _cameraService.controller;
        isCameraInitialized = true;
        isSwitchingCamera = false;
      });
    } catch (e) {
      _handleCameraError(e);
    }
  }

  Future<void> _startRecording() async {
    if (!_controller!.value.isInitialized) return;

    int availableStorage = await checkAvailableStorage();
    if (availableStorage < storageThreshold) {
      _showSaveVideoModal(
          "Storage is full, please free up some space to start recording.");
      return;
    }

    try {
      await _prepareRecording();
      _updateRecordingStatus(true);
    } catch (e) {
      logger.i(e);
    }
  }

  Future<void> _prepareRecording() async {
    final videoProvider = Provider.of<VideoProvider>(context, listen: false);
    await _controller?.startVideoRecording();
    videoProvider.startRecording();
    playStartRecordAudio();
    _startTimers();
  }

  void _updateRecordingStatus(bool isRecording) {
    final videoProvider = Provider.of<VideoProvider>(context, listen: false);
    if (!isRecording) {
      _stopTimers();
      videoProvider.stopRecording();
    }
    setState(() {
      _recordingTime = isRecording ? 0 : _recordingTime;
      lastRecordedVideoPath = isRecording ? null : lastRecordedVideoPath;
    });
  }

  void _startTimers() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingTime++;
      });
    });

    _storageCheckTimer?.cancel();
    _storageCheckTimer =
        Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _checkStorageDuringRecording();
    });
  }

  void _stopTimers() {
    _timer?.cancel();
    _timer = null;
    _storageCheckTimer?.cancel();
    _storageCheckTimer = null;
  }

  Future<void> _checkStorageDuringRecording() async {
    final videoProvider = Provider.of<VideoProvider>(context, listen: false);
    if (videoProvider.isRecording) {
      int availableStorage = await checkAvailableStorage();
      if (availableStorage < storageThreshold) {
        _stopRecording();
        _showSaveVideoModal("Insufficient Storage Space.\n Recording stopped.");
      }
    }
  }

  void _stopRecording() async {
    if (!_controller!.value.isRecordingVideo) {
      logger.e("Cannot stop recording: No recording in progress.");
      return;
    }

    try {
      final file = await _controller?.stopVideoRecording();
      if (file != null) {
        await _handleVideoRecorded(file);
      }
      playStopRecordAudio();
      _updateRecordingStatus(false);
    } catch (e) {
      logger.e("Error while stopping recording: $e");
    }
  }

  Future<void> _handleVideoRecorded(XFile file) async {
    logger.i('Video URI: ${file.path}');
    final thumbnailPath = await generateThumbnail(file.path);
    if (!mounted) return;

    setState(() {
      lastRecordedVideoPath = file.path;
      _tempThumbnailPath = thumbnailPath ?? 'assets/images/placeholder.png';
    });

    final videoModalProvider =
        Provider.of<VideoModalProvider>(context, listen: false);
    videoModalProvider.showModal();
  }

  void _showSaveVideoModal(String? message) {
    final videoModalProvider =
        Provider.of<VideoModalProvider>(context, listen: false);
    videoModalProvider.showModal();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SaveVideoModal(
          onSave: () => _handleSave(videoModalProvider),
          onDiscard: () => _handleDiscard(videoModalProvider),
          message: message,
        );
      },
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    ).then((_) {
      videoModalProvider.hideModal();
    });
  }

  Future<void> _handleSave(VideoModalProvider videoModalProvider) async {
    videoModalProvider.hideModal();

    bool permissionGranted = await _requestStoragePermission();
    if (!permissionGranted) {
      logger.e('Storage permission not granted.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Storage permission is required to save the video.")),
      );
      return;
    }

    if (lastRecordedVideoPath != null) {
      saveVideoToGalleryNative(lastRecordedVideoPath!).then((_) {
        logger.i('Video saved successfully');

        Provider.of<VideoProvider>(context, listen: false).addVideo(
          lastRecordedVideoPath!,
          _tempThumbnailPath ?? 'assets/images/placeholder.png',
        );

        playReadyToRecordAudio();
      }).catchError((e) {
        logger.e('Failed to save video to gallery: $e');
      });
    } else {
      logger.e('No video path available to save');
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (await Permission.storage.isGranted) {
      return true;
    }
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  void _handleDiscard(VideoModalProvider videoModalProvider) {
    videoModalProvider.hideModal();
    if (lastRecordedVideoPath != null) {
      final file = File(lastRecordedVideoPath!);
      if (file.existsSync()) {
        file.deleteSync();
      }

      setState(() {
        lastRecordedVideoPath = null;
        _tempThumbnailPath = null;
      });
    }

    logger.i('Video discarded successfully');
    playReadyToRecordAudio();
  }

  String _formatRecordingTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _setZoom(double newZoom) {
    setState(() {
      _zoomLevel = newZoom;
      _controller?.setZoomLevel(newZoom);
    });
  }

  double _baseZoomLevel = 1.0;

  void _handlePinchZoom(ScaleUpdateDetails details) {
    if (details.pointerCount == 2) {
      if (_lastDistance == 0.0) {
        _baseZoomLevel = _zoomLevel;
      }

      const double sensitivityMultiplier =
          1.5; // Increase for faster zoom sensitivity
      final adjustedScale = 1.0 + (details.scale - 1.0) * sensitivityMultiplier;
      final newZoomLevel = (_baseZoomLevel * adjustedScale).clamp(1.0, 8.0);

      _setZoom(newZoomLevel);

      _lastDistance = details.scale;
    }
  }

  void _resetPinch() {
    _lastDistance = 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final videoProvider = Provider.of<VideoProvider>(context);
    final videoModalProvider = Provider.of<VideoModalProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        toolbarHeight: 55,
        title: videoModalProvider.isModalShown
            ? null
            : videoProvider.isRecording
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recording',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _formatRecordingTime(_recordingTime),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: SvgPicture.asset(
                          videoProvider.isGridVisible
                              ? 'assets/icons/grid-on.svg'
                              : 'assets/icons/grid-off.svg',
                          width: 24,
                          height: 24,
                        ),
                        onPressed: () =>
                            Provider.of<VideoProvider>(context, listen: false)
                                .toggleGrid(),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: Opacity(
                          opacity: _cameraService.isFrontCamera ? 0.5 : 1.0,
                          child: SvgPicture.asset(
                            videoProvider.isFlashOn
                                ? 'assets/icons/flash-on.svg'
                                : 'assets/icons/flash-off.svg',
                            width: 24,
                            height: 24,
                          ),
                        ),
                        onPressed: _cameraService.isFrontCamera
                            ? null
                            : () async {
                                videoProvider.toggleFlash();
                                try {
                                  await _cameraService
                                      .toggleFlash(videoProvider.isFlashOn);
                                } catch (e) {
                                  logger.e('Error toggling flash', error: e);
                                }
                              },
                      ),
                    ],
                  ),
        automaticallyImplyLeading: false,
      ),
      body: GestureDetector(
        onScaleUpdate: _handlePinchZoom,
        onScaleEnd: (_) => _resetPinch(),
        child: Center(
          child: AspectRatio(
            aspectRatio: 9 / 16, // Ensure 9:16 aspect ratio
            child: Stack(
              children: [
                if (isCameraInitialized && !isSwitchingCamera)
                  CameraPreview(
                      _controller!), // CameraPreview directly inside AspectRatio
                if (videoProvider.isGridVisible && isCameraInitialized)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: GridPainter(),
                    ),
                  ),
                if (!videoModalProvider.isModalShown)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (!videoProvider.isRecording)
                          GestureDetector(
                            onTap: () {
                              if (videoProvider.lastRecordedThumbnailPath !=
                                  null) {
                                Navigator.pushNamed(context, '/gallery');
                              }
                            },
                            child: Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                shape: BoxShape.circle,
                                image:
                                    videoProvider.lastRecordedThumbnailPath !=
                                            null
                                        ? DecorationImage(
                                            image: FileImage(
                                              File(videoProvider
                                                  .lastRecordedThumbnailPath!),
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                              ),
                              child: videoProvider.lastRecordedThumbnailPath ==
                                      null
                                  ? const Icon(Icons.photo_library,
                                      color: Colors.white)
                                  : null,
                            ),
                          ),
                        GestureDetector(
                          onTap: () => videoProvider.isRecording
                              ? _stopRecording()
                              : _startRecording(),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                width: videoProvider.isRecording ? 20 : 19,
                                height: videoProvider.isRecording ? 20 : 19,
                                decoration: BoxDecoration(
                                  color: videoProvider.isRecording
                                      ? Colors.black
                                      : Colors.red,
                                  shape: videoProvider.isRecording
                                      ? BoxShape.rectangle
                                      : BoxShape.circle,
                                  borderRadius: videoProvider.isRecording
                                      ? BorderRadius.circular(3)
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (!videoProvider.isRecording)
                          GestureDetector(
                            onTap: (isSwitchingCamera || !isCameraInitialized)
                                ? null
                                : _toggleCameraLens,
                            child: Opacity(
                              opacity:
                                  (isSwitchingCamera || !isCameraInitialized)
                                      ? 0.5
                                      : 1.0,
                              child: Container(
                                width: 45,
                                height: 45,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: SvgPicture.asset(
                                    'assets/icons/flip.svg',
                                    width: 22,
                                    height: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                if (!videoModalProvider.isModalShown)
                  Positioned(
                    bottom: 155,
                    left: 0,
                    right: 0,
                    child: ZoomControl(
                      zoom: _zoomLevel,
                      setZoom: _setZoom,
                    ),
                  ),
                if (videoModalProvider.isModalShown)
                  SaveVideoModal(
                    onSave: () => _handleSave(videoModalProvider),
                    onDiscard: () => _handleDiscard(videoModalProvider),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _disableImmersiveMode();
    _controller?.dispose();
    _stopTimers();
    super.dispose();
  }
}
