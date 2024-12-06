import 'package:flutter/material.dart';

import 'screens/camera_screen.dart';
import 'screens/video_gallery_screen.dart';
import 'screens/video_player_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shootsolo',
      theme: ThemeData.dark(),
      initialRoute: '/',
      routes: {
        '/': (context) => const CameraScreen(),
        '/gallery': (context) => const VideoGalleryScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/player') {
          final videoUrl = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(videoUrl: videoUrl),
          );
        }
        return null;
      },
    );
  }
}
