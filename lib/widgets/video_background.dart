
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoBackground extends StatefulWidget {
  final Widget child;
  final Color overlayColor;

  const VideoBackground({
    super.key,
    required this.child,
    this.overlayColor = const Color.fromARGB(46, 174, 225, 248),
  });

  @override
  State<VideoBackground> createState() =>
      _VideoBackgroundState();
}

class _VideoBackgroundState extends State<VideoBackground> {
  late final VideoPlayerController _controller;
  bool _videoError = false;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset(
      'lib/assets/videos/pink_sparkling_water.mp4',
    );

    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      await _controller.initialize();
      await _controller.setLooping(true);
      await _controller.setVolume(0);
      await _controller.play();

      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      debugPrint('Background video error: $error');

      if (mounted) {
        setState(() {
          _videoError = true;
        });
      }
    }
  }

  Widget _buildVideo() {
    if (_videoError) {
      return const ColoredBox(
        color: Color.fromARGB(255, 144, 223, 243),
      );
    }

    if (!_controller.value.isInitialized) {
      return const ColoredBox(
        color: Color.fromARGB(255, 151, 213, 241),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildVideo(),
        ColoredBox(
          color: widget.overlayColor,
        ),
        widget.child,
      ],
    );
  }
}
