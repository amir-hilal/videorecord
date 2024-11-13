// lib/widgets/camera_app_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../providers/video_modal_provider.dart';
import '../providers/video_provider.dart';
import '../services/camera_service.dart';

class CameraAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int recordingTime;
  final CameraService cameraService;
  final Function toggleGrid;
  final Function toggleFlash;
  final String Function(int) formatRecordingTime;

  const CameraAppBar({
    super.key,
    required this.recordingTime,
    required this.cameraService,
    required this.toggleGrid,
    required this.toggleFlash,
    required this.formatRecordingTime,
  });

  @override
  Size get preferredSize => const Size.fromHeight(55);

  @override
  Widget build(BuildContext context) {
    final videoProvider = Provider.of<VideoProvider>(context);
    final videoModalProvider = Provider.of<VideoModalProvider>(context);

    return AppBar(
      backgroundColor: Colors.black.withOpacity(0.5),
      elevation: 0,
      toolbarHeight: 55,
      automaticallyImplyLeading: false,
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
                          formatRecordingTime(recordingTime),
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
                      onPressed: () => toggleGrid(),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: Opacity(
                        opacity: cameraService.isFrontCamera ? 0.5 : 1.0,
                        child: SvgPicture.asset(
                          videoProvider.isFlashOn
                              ? 'assets/icons/flash-on.svg'
                              : 'assets/icons/flash-off.svg',
                          width: 24,
                          height: 24,
                        ),
                      ),
                      onPressed: cameraService.isFrontCamera
                          ? null
                          : () async {
                              toggleFlash();
                              try {
                                await cameraService
                                    .toggleFlash(videoProvider.isFlashOn);
                              } catch (e) {
                                // Handle any errors related to toggling flash here
                              }
                            },
                    ),
                  ],
                ),
    );
  }
}
