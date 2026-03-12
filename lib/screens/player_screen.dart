import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'dart:io';

import '../models/video_model.dart';
import '../utils/app_theme.dart';
import '../widgets/player_controls.dart';
import '../widgets/player_gestures.dart';

class PlayerScreen extends StatefulWidget {
  final VideoModel video;
  final List<VideoModel> playlist;
  final int initialIndex;

  const PlayerScreen({
    super.key,
    required this.video,
    required this.playlist,
    required this.initialIndex,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with TickerProviderStateMixin {
  late VideoPlayerController _controller;
  late AnimationController _controlsController;
  late Animation<double> _controlsOpacity;

  bool _showControls = true;
  bool _isFullscreen = false;
  bool _isLocked = false;
  Timer? _hideTimer;
  int _currentIndex = 0;

  double _brightness = 0.5;
  double _volume = 0.5;
  bool _showBrightnessOverlay = false;
  bool _showVolumeOverlay = false;
  bool _showSeekOverlay = false;
  int _seekSeconds = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controlsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controlsOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controlsController, curve: Curves.easeInOut),
    );
    _controller = VideoPlayerController.file(File(widget.video.path));
    _initPlayer(widget.video);
    _enterFullscreen();
    _startHideTimer();
  }

  void _enterFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _exitFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _initPlayer(VideoModel video) async {
    try {
      if (_controller.value.isInitialized) {
        await _controller.dispose();
      }
      _controller = VideoPlayerController.file(File(video.path));
      await _controller.initialize();
      await _controller.play();
      _controller.addListener(_onVideoUpdate);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Player error: $e');
    }
  }

  void _onVideoUpdate() {
    if (_controller.value.position >= _controller.value.duration &&
        _controller.value.duration > Duration.zero) {
      _playNext();
    }
    if (mounted) setState(() {});
  }

  void _playNext() {
    if (_currentIndex < widget.playlist.length - 1) {
      setState(() => _currentIndex++);
      _initPlayer(widget.playlist[_currentIndex]);
    }
  }

  void _playPrevious() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _initPlayer(widget.playlist[_currentIndex]);
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _controlsController.forward();
      _startHideTimer();
    } else {
      _controlsController.reverse();
      _hideTimer?.cancel();
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (!_isLocked && mounted) {
        setState(() => _showControls = false);
        _controlsController.reverse();
      }
    });
  }

  void _seekRelative(int seconds) {
    final pos = _controller.value.position;
    final dur = _controller.value.duration;
    Duration newPos;
    if (seconds > 0) {
      newPos = pos + Duration(seconds: seconds);
      if (newPos > dur) newPos = dur;
    } else {
      newPos = pos + Duration(seconds: seconds);
      if (newPos < Duration.zero) newPos = Duration.zero;
    }
    _controller.seekTo(newPos);
    setState(() {
      _seekSeconds = seconds;
      _showSeekOverlay = true;
    });
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _showSeekOverlay = false);
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.removeListener(_onVideoUpdate);
    _controller.dispose();
    _controlsController.dispose();
    _exitFullscreen();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          if (!_isLocked) _toggleControls();
        },
        child: Stack(
          children: [
            _buildVideoPlayer(),
            PlayerGestures(
              onBrightnessChanged: (v) => setState(() {
                _brightness = v;
                _showBrightnessOverlay = true;
              }),
              onVolumeChanged: (v) => setState(() {
                _volume = v;
                _showVolumeOverlay = true;
              }),
              onSeek: _seekRelative,
              onHideOverlays: () => setState(() {
                _showBrightnessOverlay = false;
                _showVolumeOverlay = false;
              }),
            ),
            if (_showControls)
              AnimatedBuilder(
                animation: _controlsOpacity,
                builder: (context, child) => Opacity(
                  opacity: _controlsOpacity.value,
                  child: PlayerControls(
                    controller: _controller,
                    video: widget.playlist[_currentIndex],
                    isLocked: _isLocked,
                    isFullscreen: _isFullscreen,
                    onPlayPause: () {
                      _controller.value.isPlaying
                          ? _controller.pause()
                          : _controller.play();
                      _startHideTimer();
                      setState(() {});
                    },
                    onNext: _playNext,
                    onPrevious: _playPrevious,
                    onBack: () => Navigator.pop(context),
                    onLock: () => setState(() => _isLocked = !_isLocked),
                    onFullscreen: () => setState(() => _isFullscreen = !_isFullscreen),
                    onSeek: (pos) {
                      _controller.seekTo(pos);
                      _startHideTimer();
                    },
                  ),
                ),
              ),
            if (_showBrightnessOverlay)
              _buildSideOverlay(icon: Icons.brightness_6, value: _brightness, isLeft: true),
            if (_showVolumeOverlay)
              _buildSideOverlay(icon: Icons.volume_up, value: _volume, isLeft: false),
            if (_showSeekOverlay)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _seekSeconds > 0 ? Icons.fast_forward : Icons.fast_rewind,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_seekSeconds.abs()}s',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (!_controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }
    return Center(
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      ),
    );
  }

  Widget _buildSideOverlay({required IconData icon, required double value, required bool isLeft}) {
    return Positioned(
      left: isLeft ? 24 : null,
      right: isLeft ? null : 24,
      top: 0,
      bottom: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: RotatedBox(
                  quarterTurns: 3,
                  child: LinearProgressIndicator(
                    value: value,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(value * 100).round()}%',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
