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

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == lensDirection,
    );

    _controller = CameraController(
      frontCamera,
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
      });
      if (file != null) {
        // Navigate to the save screen or save the video
        // Here you can navigate to the gallery or save the file
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: SizedBox(
                width: 24,
                height: 24,
                child: SvgPicture.asset(
                  isGridVisible
                      ? 'lib/assets/icons/grid-on.svg'
                      : 'lib/assets/icons/grid-off.svg',
                  placeholderBuilder: (BuildContext context) =>
                      const CircularProgressIndicator(),
                ),
              ),
              onPressed: _toggleGrid,
            ),
            const SizedBox(width: 20), // Add spacing between the icons
            IconButton(
              icon: SizedBox(
                width: 24,
                height: 24,
                child: SvgPicture.asset(
                  isFlashOn
                      ? 'lib/assets/icons/flash-on.svg'
                      : 'lib/assets/icons/flash-off.svg',
                ),
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
            CameraPreview(_controller!)
          else
            const Center(child: CircularProgressIndicator()),
          if (isGridVisible && isCameraInitialized)
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
                // Go to Gallery Button
                IconButton(
                  icon: const Icon(Icons.photo_library, color: Colors.white),
                  onPressed: () {
                    Navigator.pushNamed(context, '/gallery');
                  },
                ),
                // Recording Button
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
                // Flip Camera Button
                GestureDetector(
                  onTap: _toggleCameraLens,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.black
                          .withOpacity(0.4), // Semi-transparent background
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
    super.dispose();
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.0;

    // Draw vertical lines
    final verticalGap = size.width / 3;
    for (double x = verticalGap; x < size.width; x += verticalGap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    final horizontalGap = size.height / 3;
    for (double y = horizontalGap; y < size.height; y += horizontalGap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
