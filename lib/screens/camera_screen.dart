import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:videorecord/widgets/save_video_modal.dart';

import '../providers/video_modal_provider.dart';
import '../providers/video_provider.dart';
import '../utils/utils.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  CameraScreenState createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool isCameraInitialized = false;
  Timer? _timer;
  int _recordingTime = 0;
  String? lastRecordedVideoPath;
  bool isSwitchingCamera = false;
  int _currentCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    setState(() {
      isCameraInitialized = false;
      isSwitchingCamera = true;
    });

    try {
      final cameras = await availableCameras();
      final selectedCamera = cameras[_currentCameraIndex];
      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: true,
      );
      await _controller?.initialize();
      if (!mounted) return;

      setState(() {
        isCameraInitialized = true;
        isSwitchingCamera = false;
      });
    } catch (e) {
      logger.e('Error initializing camera', error: e);
      setState(() {
        isSwitchingCamera = false;
      });
    }
  }

  Future<void> _toggleCameraLens() async {
    final videoProvider = Provider.of<VideoProvider>(context, listen: false);
    videoProvider.stopRecording();

    setState(() {
      isCameraInitialized = false;
      isSwitchingCamera = true;
    });

    if (_controller != null) {
      await _controller?.dispose();
    }

    try {
      final cameras = await availableCameras();
      _currentCameraIndex = (_currentCameraIndex + 1) % cameras.length;
      final selectedCamera = cameras[_currentCameraIndex];

      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: true,
      );

      await _controller?.initialize();
      if (!mounted) return;

      setState(() {
        isCameraInitialized = true;
        isSwitchingCamera = false;
      });
    } catch (e) {
      logger.e('Error initializing camera', error: e);
      setState(() {
        isSwitchingCamera = false;
      });
    }
  }

  void _toggleFlash() {
    setState(() {
      final videoProvider = Provider.of<VideoProvider>(context, listen: false);
      videoProvider.toggleFlash();
      _controller?.setFlashMode(
          videoProvider.isFlashOn ? FlashMode.torch : FlashMode.off);
    });
  }

  void _toggleGrid() {
    setState(() {
      final videoProvider = Provider.of<VideoProvider>(context, listen: false);
      videoProvider.toggleGrid();
    });
  }

  void _startRecording() async {
    final videoProvider = Provider.of<VideoProvider>(context, listen: false);
    if (!_controller!.value.isInitialized || videoProvider.isRecording) return;

    try {
      await _controller?.startVideoRecording();
      videoProvider.startRecording();
      setState(() {
        _recordingTime = 0;
        lastRecordedVideoPath = null;
      });

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingTime++;
        });
      });
    } catch (e) {
      print(e);
    }
  }

  void _stopRecording() async {
    final videoProvider = Provider.of<VideoProvider>(context, listen: false);
    if (!_controller!.value.isInitialized || !videoProvider.isRecording) return;

    try {
      final file = await _controller?.stopVideoRecording();

      if (file != null) {
        _handleVideoRecorded(file);
      }

      setState(() {
        videoProvider.stopRecording();
        _timer?.cancel();
        _timer = null;
        _recordingTime = 0;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _handleVideoRecorded(XFile file) async {
    print('Video URI: ${file.path}');

    final thumbnailPath = await generateThumbnail(file.path);

    if (!mounted) return;

    setState(() {
      lastRecordedVideoPath = file.path;

      if (thumbnailPath != null) {
        Provider.of<VideoProvider>(context, listen: false)
            .addVideo(file.path, thumbnailPath);
        Provider.of<VideoProvider>(context, listen: false)
            .setLastRecordedThumbnail(thumbnailPath); // Save thumbnail path
      } else {
        Provider.of<VideoProvider>(context, listen: false)
            .addVideo(file.path, 'assets/images/placeholder.png');
        Provider.of<VideoProvider>(context, listen: false)
            .setLastRecordedThumbnail('assets/images/placeholder.png');
      }
    });

    final videoModalProvider =
        Provider.of<VideoModalProvider>(context, listen: false);
    _showSaveVideoModal(videoModalProvider);
  }

  Future<void> _showSaveVideoModal(
      VideoModalProvider videoModalProvider) async {
    if (!mounted ||
        lastRecordedVideoPath == null ||
        videoModalProvider.isModalShown) {
      return;
    }

    videoModalProvider.showModal();
  }

  void _handleSave(VideoModalProvider videoModalProvider) {
    videoModalProvider.hideModal();

    logger.i('Video saved successfully');
  }

  void _handleDiscard(VideoModalProvider videoModalProvider) {
    videoModalProvider.hideModal();
    setState(() {
      lastRecordedVideoPath = null;
    });
    logger.i('Video discarded successfully');
  }

  String _formatRecordingTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cameraHeight = screenWidth * (16 / 9);

    final videoProvider = Provider.of<VideoProvider>(context);
    final videoModalProvider = Provider.of<VideoModalProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        toolbarHeight: 60,
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
                              ? 'lib/assets/icons/grid-on.svg'
                              : 'lib/assets/icons/grid-off.svg',
                          width: 24,
                          height: 24,
                        ),
                        onPressed: _toggleGrid,
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: SvgPicture.asset(
                          videoProvider.isFlashOn
                              ? 'lib/assets/icons/flash-on.svg'
                              : 'lib/assets/icons/flash-off.svg',
                          width: 24,
                          height: 24,
                        ),
                        onPressed: _toggleFlash,
                      ),
                    ],
                  ),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          if (isCameraInitialized && !isSwitchingCamera)
            Center(
              child: SizedBox(
                width: screenWidth,
                height: cameraHeight,
                child: CameraPreview(_controller!),
              ),
            ),
          if (videoProvider.isGridVisible && isCameraInitialized)
            Positioned.fill(child: CustomPaint(painter: GridPainter())),
          if (!videoModalProvider.isModalShown)
            Positioned(
              bottom: 35,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (!videoProvider.isRecording)
                    GestureDetector(
                      onTap: () {
                        if (videoProvider.lastRecordedThumbnailPath != null) {
                          Navigator.pushNamed(context, '/gallery');
                        }
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                          image: videoProvider.lastRecordedThumbnailPath != null
                              ? DecorationImage(
                                  image: FileImage(
                                    File(videoProvider
                                        .lastRecordedThumbnailPath!),
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: videoProvider.lastRecordedThumbnailPath == null
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
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: videoProvider.isRecording ? 23 : 22,
                          height: videoProvider.isRecording ? 23 : 22,
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
                      onTap: _toggleCameraLens,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            'lib/assets/icons/flip.svg',
                            width: 24,
                            height: 24,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (videoModalProvider.isModalShown)
            SaveVideoModal(
              onSave: () => _handleSave(videoModalProvider),
              onDiscard: () => _handleDiscard(videoModalProvider),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _timer?.cancel();
    super.dispose();
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.0;

    final verticalGap = size.width / 3;
    for (double x = verticalGap; x < size.width; x += verticalGap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    final horizontalGap = size.height / 3;
    for (double y = horizontalGap; y < size.height; y += horizontalGap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
