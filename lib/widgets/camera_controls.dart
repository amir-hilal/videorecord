// lib/widgets/camera_controls.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../providers/video_modal_provider.dart';
import '../providers/video_provider.dart';
import 'zoom_control.dart';

class CameraControls extends StatelessWidget {
  final bool isSwitchingCamera;
  final bool isCameraInitialized;
  final double zoomLevel;
  final Function() toggleCameraLens;
  final Function() startRecording;
  final Function() stopRecording;
  final Function(double) setZoom;

  const CameraControls({
    super.key,
    required this.isSwitchingCamera,
    required this.isCameraInitialized,
    required this.zoomLevel,
    required this.toggleCameraLens,
    required this.startRecording,
    required this.stopRecording,
    required this.setZoom,
  });

  @override
  Widget build(BuildContext context) {
    final videoProvider = Provider.of<VideoProvider>(context);
    final videoModalProvider = Provider.of<VideoModalProvider>(context);

    if (videoModalProvider.isModalShown) return const SizedBox.shrink();

    return Stack(
      children: [
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
                    if (videoProvider.lastRecordedThumbnailPath != null) {
                      Navigator.pushNamed(context, '/gallery');
                    }
                  },
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                      image: videoProvider.lastRecordedThumbnailPath != null
                          ? DecorationImage(
                              image: FileImage(
                                File(videoProvider.lastRecordedThumbnailPath!),
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: videoProvider.lastRecordedThumbnailPath == null
                        ? const Icon(Icons.photo_library, color: Colors.white)
                        : null,
                  ),
                ),
              GestureDetector(
                onTap: () => videoProvider.isRecording
                    ? stopRecording()
                    : startRecording(),
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
                      : toggleCameraLens,
                  child: Opacity(
                    opacity:
                        (isSwitchingCamera || !isCameraInitialized) ? 0.5 : 1.0,
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
        Positioned(
          bottom: 155,
          left: 0,
          right: 0,
          child: ZoomControl(
            zoom: zoomLevel,
            setZoom: setZoom,
          ),
        ),
      ],
    );
  }
}
