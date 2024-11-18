import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerScreen({super.key, required this.videoUrl});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController =
        VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
          ..initialize().then((_) {
            setState(() {
              _isPlaying = true;
              _videoPlayerController.play();
            });
          });
    _videoPlayerController.setLooping(false);
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_videoPlayerController.value.isPlaying) {
        _videoPlayerController.pause();
        _isPlaying = false;
      } else {
        _videoPlayerController.play();
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get device dimensions
    final double deviceHeight = MediaQuery.of(context).size.height;
    final double deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Player'),
      ),
      body: Center(
        child: _videoPlayerController.value.isInitialized
            ? GestureDetector(
                onTap: _togglePlayPause,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Video Player
                    SizedBox(
                      height: deviceHeight/2,
                      width: deviceWidth/2,
                      child: FittedBox(
                        fit: BoxFit.cover, 
                        child: SizedBox(
                          width: _videoPlayerController.value.size.width,
                          height: _videoPlayerController.value.size.height,
                          child: VideoPlayer(_videoPlayerController),
                        ),
                      ),
                    ),
                    // Play/Pause Icon Overlay
                    if (!_isPlaying)
                      Icon(
                        Icons.play_circle_filled,
                        color: Colors.white.withOpacity(0.7),
                        size: 80,
                      ),
                  ],
                ),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
