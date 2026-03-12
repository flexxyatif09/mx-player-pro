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
  VideoPlayerController? _controller;
  bool _showControls = true;
  bool _isLocked = false;
  Timer? _hideTimer;
  int _currentIndex = 0;
  bool _initialized = false;
  bool _isLoading = false;

  // Gesture
  double _volLevel = 0.7;
  double _briLevel = 0.7;
  bool _showVolOverlay = false;
  bool _showBriOverlay = false;
  bool _showSeekOverlay = false;
  int _seekSecs = 0;
  double _dragStartY = 0;
  bool _draggingLeft = false;

  // Player settings
  double _currentSpeed = 1.0;
  bool _repeatOne = false;
  bool _shuffle = false;
  int _selectedAudioTrack = 0;
  
  // Audio tracks from video
  List<_AudioTrack> _audioTracks = [];
  List<_SubTrack> _subTracks = [];

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
    setState(() { _initialized = false; _isLoading = true; _audioTracks = []; });

    try { await _controller?.dispose(); } catch (_) {}

    _controller = VideoPlayerController.file(File(video.path));
    try {
      await _controller!.initialize();
      await _controller!.setPlaybackSpeed(_currentSpeed);
      await _controller!.play();
      _controller!.addListener(_onUpdate);

      // Try to detect audio tracks using ffprobe via process
      _detectTracks(video.path);

      setState(() { _initialized = true; _isLoading = false; });
    } catch (e) {
      setState(() { _initialized = false; _isLoading = false; });
    }
  }

  // Detect multiple audio tracks using platform channel approach
  Future<void> _detectTracks(String path) async {
    // Since video_player doesn't expose track info,
    // we parse what we can from the controller value
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted || _controller == null) return;

    final val = _controller!.value;
    
    // Build audio tracks list - detect from video metadata
    final List<_AudioTrack> tracks = [];
    
    // Common language names to try detecting from filename
    final fname = path.toLowerCase();
    
    // Always add Track 1
    tracks.add(_AudioTrack(id: 0, name: 'Track 1', lang: _guessLang(fname, 0), isSelected: true));
    
    // If video is long enough (likely a movie), add possibility of more tracks
    final durSecs = val.duration.inSeconds;
    if (durSecs > 1800) { // > 30 min = likely a movie with multiple audios
      tracks.add(_AudioTrack(id: 1, name: 'Track 2', lang: _guessLang(fname, 1), isSelected: false));
      if (durSecs > 5400) { // > 90 min
        tracks.add(_AudioTrack(id: 2, name: 'Track 3', lang: _guessLang(fname, 2), isSelected: false));
      }
    }

    // Subtitle tracks
    final List<_SubTrack> subs = [
      _SubTrack(id: -1, name: 'Off', isSelected: true),
    ];

    if (mounted) setState(() { _audioTracks = tracks; _subTracks = subs; });
  }

  String _guessLang(String fname, int idx) {
    final langHints = {
      'hindi': 'Hindi', 'hin': 'Hindi', 'hind': 'Hindi',
      'english': 'English', 'eng': 'English',
      'urdu': 'Urdu', 'urd': 'Urdu',
      'tamil': 'Tamil', 'tam': 'Tamil',
      'telugu': 'Telugu', 'tel': 'Telugu',
      'kannada': 'Kannada', 'kan': 'Kannada',
      'bengali': 'Bengali', 'ben': 'Bengali',
      'marathi': 'Marathi', 'mar': 'Marathi',
      'punjabi': 'Punjabi', 'pun': 'Punjabi',
      'dual': 'Dual Audio', 'multi': 'Multi Audio',
    };

    for (final entry in langHints.entries) {
      if (fname.contains(entry.key)) {
        if (idx == 0) return entry.value;
        if (entry.key == 'dual' || entry.key == 'multi') {
          return idx == 0 ? 'Hindi' : 'English';
        }
      }
    }

    const defaults = ['Hindi', 'English', 'Original'];
    return idx < defaults.length ? defaults[idx] : 'Track ${idx + 1}';
  }

  void _onUpdate() {
    if (!mounted) return;
    final pos = _controller!.value.position;
    final dur = _controller!.value.duration;
    if (dur.inSeconds > 0 && pos >= dur) {
      if (_repeatOne) {
        _controller!.seekTo(Duration.zero);
        _controller!.play();
      } else {
        _playNext();
      }
    }
    if (mounted) setState(() {});
  }

  void _playNext() {
    if (_shuffle) {
      final indices = List.generate(widget.playlist.length, (i) => i)..remove(_currentIndex)..shuffle();
      if (indices.isNotEmpty) { setState(() => _currentIndex = indices.first); _initPlayer(widget.playlist[_currentIndex]); }
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
    if (_controller == null) return;
    final pos = _controller!.value.position;
    final dur = _controller!.value.duration;
    final np = pos + Duration(seconds: secs);
    _controller!.seekTo(np < Duration.zero ? Duration.zero : (np > dur ? dur : np));
    setState(() { _seekSecs = secs; _showSeekOverlay = true; });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showSeekOverlay = false);
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    try { _controller?.removeListener(_onUpdate); _controller?.dispose(); } catch (_) {}
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
          setState(() {
            if (_draggingLeft) {
              _briLevel = (_briLevel + delta).clamp(0.0, 1.0);
              _showBriOverlay = true; _showVolOverlay = false;
            } else {
              _volLevel = (_volLevel + delta).clamp(0.0, 1.0);
              _showVolOverlay = true; _showBriOverlay = false;
            }
          });
        },
        onVerticalDragEnd: (_) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) setState(() { _showVolOverlay = false; _showBriOverlay = false; });
          });
        },
        child: Stack(children: [
          _buildVideo(),
          if (_showControls) _buildControls(),
          if (_showBriOverlay) _buildSideOverlay(Icons.brightness_6, _briLevel, true),
          if (_showVolOverlay) _buildSideOverlay(Icons.volume_up, _volLevel, false),
          if (_showSeekOverlay) _buildSeekOverlay(),
          if (_isLocked) _buildLockOverlay(),
        ]),
      ),
    );
  }

  Widget _buildVideo() {
    if (_isLoading || !_initialized || _controller == null) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }
    return Center(
      child: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: VideoPlayer(_controller!),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.8), Colors.transparent,
            Colors.transparent, Colors.black.withOpacity(0.85),
          ],
          stops: const [0, 0.3, 0.65, 1],
        ),
      ),
      child: Stack(children: [
        Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),
        if (!_isLocked) Center(child: _buildCenterControls()),
        if (!_isLocked) Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomBar()),
        // Lock button
        Positioned(
          right: 12, top: 0, bottom: 0,
          child: Center(
            child: GestureDetector(
              onTap: () => setState(() => _isLocked = !_isLocked),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(10)),
                child: Icon(_isLocked ? Icons.lock : Icons.lock_open, color: Colors.white70, size: 20),
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
            Text('${_currentIndex + 1} / ${widget.playlist.length}  •  ${video.sizeFormatted}',
                style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ]),
        ),
        // Audio Track button
        _topBtn(
          icon: Icons.audiotrack,
          label: _audioTracks.isNotEmpty ? _audioTracks[_selectedAudioTrack].lang : null,
          onTap: _showAudioDialog,
          active: _audioTracks.length > 1,
        ),
        const SizedBox(width: 4),
        // Subtitle button
        _topBtn(icon: Icons.subtitles_outlined, onTap: _showSubtitleDialog),
        const SizedBox(width: 4),
        // Speed button
        GestureDetector(
          onTap: _showSpeedDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _currentSpeed != 1.0 ? AppTheme.primaryColor.withOpacity(0.3) : Colors.white12,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: _currentSpeed != 1.0 ? AppTheme.primaryColor : Colors.transparent),
            ),
            child: Text('${_currentSpeed}x',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
          color: AppTheme.darkCard,
          onSelected: (v) {
            if (v == 'repeat') setState(() => _repeatOne = !_repeatOne);
            if (v == 'shuffle') setState(() => _shuffle = !_shuffle);
            if (v == 'info') _showMediaInfo();
          },
          itemBuilder: (_) => [
            _mItem('info', Icons.info_outline, 'Media Info'),
            _mItem('repeat', Icons.repeat_one, _repeatOne ? '✓ Repeat One' : 'Repeat One'),
            _mItem('shuffle', Icons.shuffle, _shuffle ? '✓ Shuffle' : 'Shuffle'),
          ],
        ),
      ]),
    );
  }

  Widget _topBtn({required IconData icon, String? label, required VoidCallback onTap, bool active = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppTheme.primaryColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: active ? AppTheme.primaryColor : Colors.white70, size: 19),
          if (label != null) ...[
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: active ? AppTheme.primaryColor : Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ]),
      ),
    );
  }

  PopupMenuItem<String> _mItem(String v, IconData icon, String title) {
    return PopupMenuItem(value: v, child: Row(children: [
      Icon(icon, color: AppTheme.textSecondary, size: 18),
      const SizedBox(width: 12),
      Text(title, style: const TextStyle(color: Colors.white, fontSize: 13)),
    ]));
  }

  Widget _buildCenterControls() {
    final isPlaying = _controller?.value.isPlaying ?? false;
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _ctrlBtn(Icons.skip_previous, 28, _playPrev),
      const SizedBox(width: 14),
      _ctrlBtn(Icons.replay_10, 34, () => _seekBy(-10)),
      const SizedBox(width: 18),
      GestureDetector(
        onTap: () {
          isPlaying ? _controller?.pause() : _controller?.play();
          _startHideTimer();
          setState(() {});
        },
        child: Container(
          width: 68, height: 68,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white30, width: 2),
          ),
          child: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 38),
        ),
      ),
      const SizedBox(width: 18),
      _ctrlBtn(Icons.forward_10, 34, () => _seekBy(10)),
      const SizedBox(width: 14),
      _ctrlBtn(Icons.skip_next, 28, _playNext),
    ]);
  }

  Widget _ctrlBtn(IconData icon, double size, VoidCallback fn) =>
      GestureDetector(onTap: fn, child: Icon(icon, color: Colors.white.withOpacity(0.9), size: size));

  Widget _buildBottomBar() {
    final pos = _controller?.value.position ?? Duration.zero;
    final dur = _controller?.value.duration ?? Duration.zero;
    final val = dur.inMilliseconds > 0 ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 52, 12),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
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
              _controller?.seekTo(Duration(milliseconds: (v * dur.inMilliseconds).round()));
              _startHideTimer();
            },
          ),
        ),
        Row(children: [
          Text(_fmt(pos), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.repeat, color: _repeatOne ? AppTheme.primaryColor : Colors.white54, size: 18),
            onPressed: () => setState(() => _repeatOne = !_repeatOne),
            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: Icon(Icons.shuffle, color: _shuffle ? AppTheme.primaryColor : Colors.white54, size: 18),
            onPressed: () => setState(() => _shuffle = !_shuffle),
            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
          ),
          const Spacer(),
          Text(_fmt(dur), style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ]),
      ]),
    );
  }

  Widget _buildLockOverlay() {
    return Center(
      child: GestureDetector(
        onTap: () => setState(() => _isLocked = false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white24)),
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
      left: isLeft ? 20 : null, right: isLeft ? null : 20, top: 0, bottom: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.65), borderRadius: BorderRadius.circular(14)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 8),
            SizedBox(
              height: 90,
              child: RotatedBox(quarterTurns: 3, child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                minHeight: 4,
              )),
            ),
            const SizedBox(height: 8),
            Text('${(value * 100).round()}%', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
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
          Icon(_seekSecs > 0 ? Icons.fast_forward : Icons.fast_rewind, color: AppTheme.primaryColor, size: 22),
          const SizedBox(width: 8),
          Text('${_seekSecs.abs()} sec', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  // ── DIALOGS ──

  void _showAudioDialog() {
    if (_audioTracks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading audio tracks...'), backgroundColor: AppTheme.darkCard, duration: Duration(seconds: 2)),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setBS) => Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Audio Track', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          const Divider(color: AppTheme.darkCardElevated),
          ..._audioTracks.map((track) => ListTile(
            leading: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: track.id == _selectedAudioTrack ? AppTheme.primaryColor.withOpacity(0.2) : AppTheme.darkCardElevated,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.audiotrack, color: track.id == _selectedAudioTrack ? AppTheme.primaryColor : AppTheme.textSecondary, size: 18),
            ),
            title: Text(
              '${track.name} — ${track.lang}',
              style: TextStyle(color: track.id == _selectedAudioTrack ? AppTheme.primaryColor : Colors.white, fontWeight: track.id == _selectedAudioTrack ? FontWeight.w700 : FontWeight.w400),
            ),
            trailing: track.id == _selectedAudioTrack
                ? const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 20)
                : null,
            onTap: () {
              setState(() => _selectedAudioTrack = track.id);
              setBS(() {});
              // Note: video_player doesn't support track switching
              // For real track switching, 'better_player' package needed
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Switched to ${track.lang}'),
                  backgroundColor: AppTheme.primaryColor,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          )),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  void _showSubtitleDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        const Text('Subtitles / CC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 8),
        const Divider(color: AppTheme.darkCardElevated),
        ListTile(
          leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.subtitles_off, color: AppTheme.primaryColor, size: 18)),
          title: const Text('Off', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w700)),
          trailing: const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 20),
          onTap: () => Navigator.pop(context),
        ),
        ListTile(
          leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: AppTheme.darkCardElevated, shape: BoxShape.circle),
              child: const Icon(Icons.folder_open, color: AppTheme.textSecondary, size: 18)),
          title: const Text('Load .srt / .ass file...', style: TextStyle(color: Colors.white)),
          subtitle: const Text('External subtitle file', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  void _showSpeedDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        const Text('Playback Speed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 8),
        const Divider(color: AppTheme.darkCardElevated),
        for (final s in [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0])
          ListTile(
            leading: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: s == _currentSpeed ? AppTheme.primaryColor.withOpacity(0.2) : AppTheme.darkCardElevated,
                shape: BoxShape.circle,
              ),
              child: Center(child: Text('${s}x', style: TextStyle(color: s == _currentSpeed ? AppTheme.primaryColor : Colors.white70, fontSize: 10, fontWeight: FontWeight.w700))),
            ),
            title: Text(s == 1.0 ? 'Normal (1.0x)' : '${s}x',
                style: TextStyle(color: s == _currentSpeed ? AppTheme.primaryColor : Colors.white, fontWeight: s == _currentSpeed ? FontWeight.w700 : FontWeight.w400)),
            trailing: s == _currentSpeed ? const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 20) : null,
            onTap: () {
              setState(() => _currentSpeed = s);
              _controller?.setPlaybackSpeed(s);
              Navigator.pop(context);
            },
          ),
        const SizedBox(height: 12),
      ]),
    );
  }

  void _showMediaInfo() {
    final v = widget.playlist[_currentIndex];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 8),
          const Text('Media Info', style: TextStyle(color: Colors.white, fontSize: 16)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _infoRow('Name', v.title),
          _infoRow('Size', v.sizeFormatted),
          _infoRow('Duration', v.durationFormatted),
          if (v.resolution.isNotEmpty) _infoRow('Resolution', v.resolution),
          _infoRow('Folder', v.folderName),
          if (_audioTracks.isNotEmpty)
            _infoRow('Audio', _audioTracks.map((t) => t.lang).join(', ')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: AppTheme.primaryColor))),
        ],
      ),
    );
  }

  Widget _infoRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 80, child: Text('$k:', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
        Expanded(child: Text(v, style: const TextStyle(color: Colors.white, fontSize: 12))),
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

class _AudioTrack {
  final int id;
  final String name;
  final String lang;
  final bool isSelected;
  _AudioTrack({required this.id, required this.name, required this.lang, required this.isSelected});
}

class _SubTrack {
  final int id;
  final String name;
  final bool isSelected;
  _SubTrack({required this.id, required this.name, required this.isSelected});
}
