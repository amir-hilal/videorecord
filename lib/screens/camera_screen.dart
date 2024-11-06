import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  CameraScreenState createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool isCameraInitialized = false;
  bool isRecording = false;
  bool isFlashOn = false;
  bool isGridVisible = false;
  CameraLensDirection lensDirection = CameraLensDirection.back;
  Timer? _timer;
  int _recordingTime = 0; // Time in seconds

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final selectedCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == lensDirection,
    );

    _controller = CameraController(
      selectedCamera,
      ResolutionPreset.high,
      enableAudio: true,
    );
    await _controller?.initialize();
    setState(() {
      isCameraInitialized = true;
    });
  }

  void _toggleFlash() {
    setState(() {
      isFlashOn = !isFlashOn;
      _controller?.setFlashMode(isFlashOn ? FlashMode.torch : FlashMode.off);
    });
  }

  void _toggleGrid() {
    setState(() {
      isGridVisible = !isGridVisible;
    });
  }

  void _toggleCameraLens() async {
    lensDirection = lensDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    await _initializeCamera();
  }

  void _startRecording() async {
    if (!_controller!.value.isInitialized || isRecording) return;
    try {
      await _controller?.startVideoRecording();
      setState(() {
        isRecording = true;
        _recordingTime = 0; // Reset the timer
      });

      // Start a timer to update recording time every second
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingTime++;
        });
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  void _stopRecording() async {
    if (!_controller!.value.isInitialized || !isRecording) return;
    try {
      final file = await _controller?.stopVideoRecording();
      setState(() {
        isRecording = false;
        _timer?.cancel(); // Stop the timer
      });
      if (file != null) {
        // Save or process the recorded video
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
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

    return Scaffold(
      appBar: AppBar(
        title: isRecording
            ? Container(
                width: double
                    .infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recording',
                      style: TextStyle(
                        fontSize: 15, // Set font size
                        fontWeight: FontWeight.w400, // Set font weight
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12, // Adjust horizontal padding
                        vertical: 5, // Adjust vertical padding
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius:
                            BorderRadius.circular(12), // Set border radius
                      ),
                      child: Text(
                        _formatRecordingTime(_recordingTime),
                        style: const TextStyle(
                          fontSize: 14, // Adjust font size
                          fontWeight: FontWeight.w700, // Adjust font weight
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
                      isGridVisible
                          ? 'lib/assets/icons/grid-on.svg'
                          : 'lib/assets/icons/grid-off.svg',
                      width: 24,
                      height: 24,
                      placeholderBuilder: (BuildContext context) =>
                          const CircularProgressIndicator(),
                    ),
                    onPressed: _toggleGrid,
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: SvgPicture.asset(
                      isFlashOn
                          ? 'lib/assets/icons/flash-on.svg'
                          : 'lib/assets/icons/flash-off.svg',
                      width: 24,
                      height: 24,
                      placeholderBuilder: (BuildContext context) =>
                          const CircularProgressIndicator(),
                    ),
                    onPressed: _toggleFlash,
                  ),
                ],
              ),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          if (isCameraInitialized)
            Center(
              child: SizedBox(
                width: screenWidth,
                height: cameraHeight,
                child: CameraPreview(_controller!),
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),
          if (isGridVisible && isCameraInitialized && !isRecording)
            Positioned.fill(
              child: CustomPaint(
                painter: GridPainter(),
              ),
            ),
          Positioned(
            bottom: 35,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.photo_library, color: Colors.white),
                  onPressed: () {
                    Navigator.pushNamed(context, '/gallery');
                  },
                ),
                GestureDetector(
                  onTap: () =>
                      isRecording ? _stopRecording() : _startRecording(),
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: isRecording ? 23 : 22,
                        height: isRecording ? 23 : 22,
                        decoration: BoxDecoration(
                          color: isRecording ? Colors.black : Colors.red,
                          shape: isRecording
                              ? BoxShape.rectangle
                              : BoxShape.circle,
                          borderRadius:
                              isRecording ? BorderRadius.circular(3) : null,
                        ),
                      ),
                    ),
                  ),
                ),
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
