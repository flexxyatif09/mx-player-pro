import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'dart:io';
import '../models/video_model.dart';
import '../utils/app_theme.dart';

class PlayerScreen extends StatefulWidget {
  final VideoModel video;
  final List<VideoModel> playlist;
  final int initialIndex;
  const PlayerScreen({super.key, required this.video, required this.playlist, required this.initialIndex});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with TickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _showControls = true;
  bool _isLocked = false;
  bool _isFullscreen = true;
  Timer? _hideTimer;
  int _currentIndex = 0;
  bool _initialized = false;

  // Gesture overlays
  bool _showVolOverlay = false;
  bool _showBriOverlay = false;
  bool _showSeekOverlay = false;
  double _volLevel = 0.7;
  double _briLevel = 0.7;
  int _seekSecs = 0;
  double _dragStartY = 0;
  bool _draggingLeft = false;

  // Speed options
  final List<double> _speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
  double _currentSpeed = 1.0;

  // Repeat mode
  bool _repeatOne = false;
  bool _shuffle = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _enterFullscreen();
    _initPlayer(widget.playlist[_currentIndex]);
    _startHideTimer();
  }

  void _enterFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  }

  void _exitFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown, DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  }

  Future<void> _initPlayer(VideoModel video) async {
    setState(() => _initialized = false);
    try {
      if (_initialized) await _controller.dispose();
    } catch (_) {}

    _controller = VideoPlayerController.file(File(video.path));
    try {
      await _controller.initialize();
      await _controller.setPlaybackSpeed(_currentSpeed);
      await _controller.play();
      _controller.addListener(_onUpdate);
      setState(() => _initialized = true);
    } catch (e) {
      setState(() => _initialized = false);
    }
  }

  void _onUpdate() {
    if (!mounted) return;
    final pos = _controller.value.position;
    final dur = _controller.value.duration;
    if (dur.inSeconds > 0 && pos >= dur) {
      if (_repeatOne) {
        _controller.seekTo(Duration.zero);
        _controller.play();
      } else {
        _playNext();
      }
    }
    if (mounted) setState(() {});
  }

  void _playNext() {
    if (_shuffle) {
      final next = (List.generate(widget.playlist.length, (i) => i)..remove(_currentIndex))
        ..shuffle();
      if (next.isNotEmpty) {
        setState(() => _currentIndex = next.first);
        _initPlayer(widget.playlist[_currentIndex]);
      }
    } else if (_currentIndex < widget.playlist.length - 1) {
      setState(() => _currentIndex++);
      _initPlayer(widget.playlist[_currentIndex]);
    }
  }

  void _playPrev() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _initPlayer(widget.playlist[_currentIndex]);
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && !_isLocked) setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    if (_isLocked) return;
    setState(() => _showControls = !_showControls);
    if (_showControls) _startHideTimer();
  }

  void _seekBy(int secs) {
    final pos = _controller.value.position;
    final dur = _controller.value.duration;
    final np = pos + Duration(seconds: secs);
    _controller.seekTo(np < Duration.zero ? Duration.zero : (np > dur ? dur : np));
    setState(() {
      _seekSecs = secs;
      _showSeekOverlay = true;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showSeekOverlay = false);
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    try { _controller.removeListener(_onUpdate); _controller.dispose(); } catch (_) {}
    _exitFullscreen();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        onDoubleTapDown: (d) {
          final x = d.globalPosition.dx;
          final w = MediaQuery.of(context).size.width;
          _seekBy(x < w / 2 ? -10 : 10);
        },
        onVerticalDragStart: (d) {
          _dragStartY = d.globalPosition.dy;
          _draggingLeft = d.globalPosition.dx < MediaQuery.of(context).size.width / 2;
        },
        onVerticalDragUpdate: (d) {
          final delta = (_dragStartY - d.globalPosition.dy) / MediaQuery.of(context).size.height;
          _dragStartY = d.globalPosition.dy;
          if (_draggingLeft) {
            setState(() {
              _briLevel = (_briLevel + delta).clamp(0.0, 1.0);
              _showBriOverlay = true;
              _showVolOverlay = false;
            });
          } else {
            setState(() {
              _volLevel = (_volLevel + delta).clamp(0.0, 1.0);
              _showVolOverlay = true;
              _showBriOverlay = false;
            });
          }
        },
        onVerticalDragEnd: (_) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) setState(() { _showVolOverlay = false; _showBriOverlay = false; });
          });
        },
        child: Stack(children: [
          // Video
          _buildVideo(),
          // Controls
          if (_showControls) _buildControls(),
          // Overlays
          if (_showBriOverlay) _buildSideOverlay(Icons.brightness_6, _briLevel, true),
          if (_showVolOverlay) _buildSideOverlay(Icons.volume_up, _volLevel, false),
          if (_showSeekOverlay) _buildSeekOverlay(),
          // Lock icon (always visible when locked)
          if (_isLocked) _buildLockIndicator(),
        ]),
      ),
    );
  }

  Widget _buildVideo() {
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }
    return Center(
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.8), Colors.transparent, Colors.transparent, Colors.black.withOpacity(0.85)],
          stops: const [0, 0.3, 0.65, 1],
        ),
      ),
      child: Stack(children: [
        // Top bar
        Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),
        // Center controls
        if (!_isLocked) Center(child: _buildCenterControls()),
        // Bottom bar
        if (!_isLocked) Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomBar()),
        // Lock button (right side middle)
        Positioned(
          right: 12,
          top: 0, bottom: 0,
          child: Center(
            child: GestureDetector(
              onTap: () => setState(() => _isLocked = !_isLocked),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_isLocked ? Icons.lock : Icons.lock_open, color: Colors.white70, size: 22),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildTopBar() {
    final video = widget.playlist[_currentIndex];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(video.title,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('${_currentIndex + 1} / ${widget.playlist.length}',
                style: const TextStyle(color: Colors.white60, fontSize: 10)),
          ]),
        ),
        // Audio tracks
        IconButton(
          icon: const Icon(Icons.audiotrack, color: Colors.white, size: 20),
          onPressed: _showAudioTracks,
          tooltip: 'Audio Track',
        ),
        // Subtitles
        IconButton(
          icon: const Icon(Icons.subtitles_outlined, color: Colors.white, size: 20),
          onPressed: _showSubtitles,
          tooltip: 'Subtitles',
        ),
        // Speed
        GestureDetector(
          onTap: _showSpeedDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _currentSpeed != 1.0 ? AppTheme.primaryColor.withOpacity(0.3) : Colors.white12,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('${_currentSpeed}x',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 4),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
          color: AppTheme.darkCard,
          onSelected: _onMenuSelected,
          itemBuilder: (_) => [
            _mItem('info', Icons.info_outline, 'Media Info'),
            _mItem('screenshot', Icons.screenshot_monitor, 'Screenshot'),
            _mItem('share', Icons.share, 'Share'),
            _mItem('sleep', Icons.timer_outlined, 'Sleep Timer'),
            _mItem('repeat', Icons.repeat_one, _repeatOne ? '✓ Repeat One' : 'Repeat One'),
            _mItem('shuffle', Icons.shuffle, _shuffle ? '✓ Shuffle' : 'Shuffle'),
          ],
        ),
      ]),
    );
  }

  PopupMenuItem<String> _mItem(String val, IconData icon, String title) {
    return PopupMenuItem(
      value: val,
      child: Row(children: [
        Icon(icon, color: AppTheme.textSecondary, size: 18),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ]),
    );
  }

  void _onMenuSelected(String val) {
    switch (val) {
      case 'repeat': setState(() => _repeatOne = !_repeatOne); break;
      case 'shuffle': setState(() => _shuffle = !_shuffle); break;
      case 'info': _showMediaInfo(); break;
    }
  }

  Widget _buildCenterControls() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _ctrlBtn(Icons.skip_previous, 28, _playPrev),
      const SizedBox(width: 12),
      _ctrlBtn(Icons.replay_10, 34, () => _seekBy(-10)),
      const SizedBox(width: 16),
      // Play/Pause
      GestureDetector(
        onTap: () {
          _controller.value.isPlaying ? _controller.pause() : _controller.play();
          _startHideTimer();
          setState(() {});
        },
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white30, width: 2),
          ),
          child: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white, size: 38),
        ),
      ),
      const SizedBox(width: 16),
      _ctrlBtn(Icons.forward_10, 34, () => _seekBy(10)),
      const SizedBox(width: 12),
      _ctrlBtn(Icons.skip_next, 28, _playNext),
    ]);
  }

  Widget _ctrlBtn(IconData icon, double size, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: Colors.white.withOpacity(0.9), size: size),
    );
  }

  Widget _buildBottomBar() {
    final pos = _controller.value.position;
    final dur = _controller.value.duration;
    final val = dur.inMilliseconds > 0 ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Seek bar
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbColor: AppTheme.primaryColor,
            activeTrackColor: AppTheme.primaryColor,
            inactiveTrackColor: Colors.white24,
            overlayColor: AppTheme.primaryColor.withOpacity(0.2),
          ),
          child: Slider(
            value: val,
            onChanged: (v) {
              _controller.seekTo(Duration(milliseconds: (v * dur.inMilliseconds).round()));
              _startHideTimer();
            },
          ),
        ),
        // Time + actions row
        Row(children: [
          Text(_fmt(pos), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          const Spacer(),
          // Zoom/fit
          IconButton(
            icon: const Icon(Icons.fit_screen, color: Colors.white70, size: 18),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 14),
          // Repeat
          IconButton(
            icon: Icon(Icons.repeat, color: _repeatOne ? AppTheme.primaryColor : Colors.white70, size: 18),
            onPressed: () => setState(() => _repeatOne = !_repeatOne),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 14),
          // Fullscreen
          IconButton(
            icon: const Icon(Icons.fullscreen, color: Colors.white70, size: 22),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const Spacer(),
          Text(_fmt(dur), style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ]),
      ]),
    );
  }

  Widget _buildLockIndicator() {
    return Center(
      child: GestureDetector(
        onTap: () => setState(() => _isLocked = false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white24),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.lock, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Tap to unlock', style: TextStyle(color: Colors.white, fontSize: 13)),
          ]),
        ),
      ),
    );
  }

  Widget _buildSideOverlay(IconData icon, double value, bool isLeft) {
    return Positioned(
      left: isLeft ? 20 : null,
      right: isLeft ? null : 20,
      top: 0, bottom: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.65),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 8),
            SizedBox(
              height: 90,
              child: RotatedBox(
                quarterTurns: 3,
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  minHeight: 4,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('${(value * 100).round()}%',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }

  Widget _buildSeekOverlay() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(_seekSecs > 0 ? Icons.fast_forward : Icons.fast_rewind,
              color: AppTheme.primaryColor, size: 22),
          const SizedBox(width: 8),
          Text('${_seekSecs.abs()} sec',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  // ── DIALOGS ──

  void _showSpeedDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Playback Speed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        ),
        const Divider(color: AppTheme.darkCardElevated),
        ...[ 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0 ].map((s) => ListTile(
          title: Text(s == 1.0 ? 'Normal (1x)' : '${s}x',
              style: TextStyle(color: s == _currentSpeed ? AppTheme.primaryColor : Colors.white, fontWeight: s == _currentSpeed ? FontWeight.w700 : FontWeight.w400)),
          trailing: s == _currentSpeed ? const Icon(Icons.check, color: AppTheme.primaryColor, size: 18) : null,
          onTap: () {
            setState(() => _currentSpeed = s);
            _controller.setPlaybackSpeed(s);
            Navigator.pop(context);
          },
        )),
        const SizedBox(height: 12),
      ]),
    );
  }

  void _showAudioTracks() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Audio Track', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        ),
        const Divider(color: AppTheme.darkCardElevated),
        ListTile(
          leading: const Icon(Icons.audiotrack, color: AppTheme.primaryColor),
          title: const Text('Track 1 (Default)', style: TextStyle(color: Colors.white)),
          trailing: const Icon(Icons.check, color: AppTheme.primaryColor, size: 18),
          onTap: () => Navigator.pop(context),
        ),
        ListTile(
          leading: const Icon(Icons.audiotrack, color: AppTheme.textSecondary),
          title: const Text('Track 2', style: TextStyle(color: AppTheme.textSecondary)),
          subtitle: const Text('Not available in this video', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  void _showSubtitles() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Subtitles / CC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        ),
        const Divider(color: AppTheme.darkCardElevated),
        ListTile(
          leading: const Icon(Icons.subtitles_off_outlined, color: AppTheme.textSecondary),
          title: const Text('Off', style: TextStyle(color: Colors.white)),
          trailing: const Icon(Icons.check, color: AppTheme.primaryColor, size: 18),
          onTap: () => Navigator.pop(context),
        ),
        ListTile(
          leading: const Icon(Icons.folder_open, color: AppTheme.primaryColor),
          title: const Text('Load from file...', style: TextStyle(color: AppTheme.primaryColor)),
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  void _showMediaInfo() {
    final v = widget.playlist[_currentIndex];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Media Info', style: TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _infoRow('Name', v.title),
          _infoRow('Size', v.sizeFormatted),
          _infoRow('Duration', v.durationFormatted),
          if (v.resolution.isNotEmpty) _infoRow('Resolution', v.resolution),
          _infoRow('Folder', v.folderName),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppTheme.primaryColor)))],
      ),
    );
  }

  Widget _infoRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 80, child: Text('$k:', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
        Expanded(child: Text(v, style: const TextStyle(color: Colors.white, fontSize: 13))),
      ]),
    );
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}
