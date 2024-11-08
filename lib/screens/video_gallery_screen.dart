//video_gallery_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/video_provider.dart';

class VideoGalleryScreen extends StatelessWidget {
  const VideoGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Provider.of<VideoProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Video Gallery',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      body: Consumer<VideoProvider>(
        builder: (context, videoProvider, child) {
          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 9 / 16,
            ),
            itemCount: videoProvider.videos.length,
            itemBuilder: (context, index) {
              final videoData = videoProvider.videos[index];
              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/player',
                    arguments: videoData.videoUrl,
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(videoData.thumbnailUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
