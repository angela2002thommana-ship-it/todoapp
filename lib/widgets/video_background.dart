import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoBackground extends StatefulWidget {
  final Widget child;
  final Color overlayColor;
  final bool enableVideo;

  const VideoBackground({
    super.key,
    required this.child,
    this.overlayColor = const Color.fromARGB(46, 174, 225, 248),
    this.enableVideo = true,
  });

  @override
  State<VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends State<VideoBackground> {
  VideoPlayerController? _controller;
  bool _videoError = false;
  int _initializationId = 0;

  @override
  void initState() {
    super.initState();

    if (widget.enableVideo) {
      _initializeVideo();
    }
  }

  @override
  void didUpdateWidget(covariant VideoBackground oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.enableVideo != widget.enableVideo) {
      if (widget.enableVideo) {
        _videoError = false;
        _initializeVideo();
      } else {
        _initializationId++;

        final oldController = _controller;
        _controller = null;
        oldController?.dispose();

        setState(() {
          _videoError = false;
        });
      }
    }
  }

  Future<void> _initializeVideo() async {
    final initializationId = ++_initializationId;

    final controller = VideoPlayerController.asset(
      'lib/assets/videos/pink_sparkling_water.mp4',
    );

    _controller = controller;

    try {
      await controller.initialize();

      if (!mounted ||
          initializationId != _initializationId ||
          !widget.enableVideo) {
        await controller.dispose();
        return;
      }

      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();

      if (mounted && initializationId == _initializationId) {
        setState(() {
          _videoError = false;
        });
      }
    } catch (error) {
      debugPrint('Background video error: $error');

      if (initializationId == _initializationId) {
        _controller = null;

        if (mounted) {
          setState(() {
            _videoError = true;
          });
        }
      }

      await controller.dispose();
    }
  }

  Widget _buildVideo() {
    final controller = _controller;

    if (!widget.enableVideo || _videoError) {
      return const ColoredBox(color: Color.fromARGB(255, 144, 223, 243));
    }

    if (controller == null || !controller.value.isInitialized) {
      return const ColoredBox(color: Color.fromARGB(255, 151, 213, 241));
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _initializationId++;
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildVideo(),
        ColoredBox(color: widget.overlayColor),
        widget.child,
      ],
    );
  }
}
