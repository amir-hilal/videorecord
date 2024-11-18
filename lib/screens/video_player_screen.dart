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
  bool _showControls = false;

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

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      Future.delayed(const Duration(seconds: 3), () {
        if (_showControls) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
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
                onTap: _toggleControls,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color:
                      Colors.transparent, // Ensure the gesture area is active
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Video Player
                      SizedBox(
                        height: deviceHeight / 2,
                        width: deviceWidth / 2,
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _videoPlayerController.value.size.width,
                            height: _videoPlayerController.value.size.height,
                            child: VideoPlayer(_videoPlayerController),
                          ),
                        ),
                      ),
                      // Middle Play/Pause Button
                      if (_showControls)
                        Center(
                          child: GestureDetector(
                            onTap: _togglePlayPause,
                            child: Icon(
                              _isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                              color: Colors.white.withOpacity(0.7),
                              size: 80,
                            ),
                          ),
                        ),
                      // Bottom Controls
                      if (_showControls)
                        Positioned(
                          bottom: 20,
                          left: 20,
                          right: 20,
                          child: Column(
                            children: [
                              // Progress Bar and Time
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    _formatDuration(
                                        _videoPlayerController.value.position),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  const SizedBox(
                                      width:
                                          10), // Left margin for the progress bar
                                  Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal:
                                              10), // Add margin on both sides
                                      child: VideoProgressIndicator(
                                        _videoPlayerController,
                                        allowScrubbing: true,
                                        colors: const VideoProgressColors(
                                          playedColor: Color.fromARGB(202, 50, 165, 203),
                                          bufferedColor: Colors.grey,
                                          backgroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                      width:
                                          10), // Right margin for the progress bar
                                  Text(
                                    _formatDuration(
                                        _videoPlayerController.value.duration),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Additional Controls
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }

  String _formatDuration(Duration position) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final String minutes = twoDigits(position.inMinutes.remainder(60));
    final String seconds = twoDigits(position.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
