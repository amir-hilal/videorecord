import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
        title: (RichText(
          text: const TextSpan(
            text: 'Camera Preview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        )),
        actions: [
          IconButton(
            icon: Icon(
              isGridVisible ? Icons.grid_on : Icons.grid_off,
              color: Colors.white,
            ),
            onPressed: _toggleGrid,
          ),
          IconButton(
            icon: Icon(
              isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: _toggleFlash,
          ),
        ],
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
            bottom: 80,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.photo_library, color: Colors.white),
              onPressed: () {
                Navigator.pushNamed(context, '/gallery');
              },
            ),
          ),
          Positioned(
            bottom: 40,
            left: MediaQuery.of(context).size.width / 2 - 35,
            child: GestureDetector(
              onTap: () => isRecording ? _stopRecording() : _startRecording(),
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: isRecording ? Colors.red : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: isRecording
                    ? const Icon(Icons.stop, color: Colors.black, size: 30)
                    : const Icon(Icons.videocam, color: Colors.black, size: 30),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.cameraswitch, color: Colors.white),
              onPressed: _toggleCameraLens,
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
