import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/video_model.dart';
import '../utils/app_theme.dart';

class PlayerControls extends StatelessWidget {
  final VideoPlayerController controller;
  final VideoModel video;
  final bool isLocked;
  final bool isFullscreen;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onBack;
  final VoidCallback onLock;
  final VoidCallback onFullscreen;
  final Function(Duration) onSeek;

  const PlayerControls({
    super.key,
    required this.controller,
    required this.video,
    required this.isLocked,
    required this.isFullscreen,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
    required this.onBack,
    required this.onLock,
    required this.onFullscreen,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.8),
          ],
          stops: const [0, 0.3, 0.7, 1],
        ),
      ),
      child: Stack(
        children: [
          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(context),
          ),

          // Center controls
          Center(
            child: isLocked
                ? _buildLockedControls()
                : _buildCenterControls(),
          ),

          // Bottom bar
          if (!isLocked)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomBar(context),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
            onPressed: onBack,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  video.folderName,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Top action buttons
          _buildTopAction(Icons.subtitles_outlined, 'Subtitle'),
          _buildTopAction(Icons.audiotrack_outlined, 'Audio'),
          _buildTopAction(Icons.speed, 'Speed'),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
            color: AppTheme.darkCard,
            itemBuilder: (_) => [
              _menuItem(Icons.info_outline, 'Media Info'),
              _menuItem(Icons.screenshot_monitor, 'Screenshot'),
              _menuItem(Icons.share, 'Share'),
              _menuItem(Icons.equalizer, 'Equalizer'),
              _menuItem(Icons.timer_outlined, 'Sleep Timer'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopAction(IconData icon, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: () {},
      ),
    );
  }

  PopupMenuItem<String> _menuItem(IconData icon, String title) {
    return PopupMenuItem(
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 18),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildLockedControls() {
    return GestureDetector(
      onTap: onLock,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.lock, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildCenterControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous
        _buildControlButton(
          icon: Icons.skip_previous,
          size: 32,
          onPressed: onPrevious,
        ),
        const SizedBox(width: 16),

        // Rewind 10s
        _buildControlButton(
          icon: Icons.replay_10,
          size: 36,
          onPressed: () {
            final pos = controller.value.position;
            controller.seekTo(
                (pos - const Duration(seconds: 10))
                    .clamp(Duration.zero, controller.value.duration));
          },
        ),
        const SizedBox(width: 16),

        // Play/Pause
        GestureDetector(
          onTap: onPlayPause,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: Icon(
              controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Forward 10s
        _buildControlButton(
          icon: Icons.forward_10,
          size: 36,
          onPressed: () {
            final pos = controller.value.position;
            controller.seekTo(
                (pos + const Duration(seconds: 10))
                    .clamp(Duration.zero, controller.value.duration));
          },
        ),
        const SizedBox(width: 16),

        // Next
        _buildControlButton(
          icon: Icons.skip_next,
          size: 32,
          onPressed: onNext,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required double size,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Icon(icon, color: Colors.white.withOpacity(0.9), size: size),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final position = controller.value.position;
    final duration = controller.value.duration;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbRadius: 8,
              thumbColor: AppTheme.primaryColor,
              activeTrackColor: AppTheme.primaryColor,
              inactiveTrackColor: Colors.white24,
              overlayRadius: 14,
              overlayColor: AppTheme.primaryColor.withOpacity(0.2),
            ),
            child: Slider(
              value: duration.inMilliseconds > 0
                  ? (position.inMilliseconds /
                      duration.inMilliseconds)
                      .clamp(0.0, 1.0)
                  : 0.0,
              onChanged: (value) {
                onSeek(Duration(
                  milliseconds: (value * duration.inMilliseconds).round(),
                ));
              },
            ),
          ),

          // Time row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(position),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                // Bottom action icons
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isLocked ? Icons.lock : Icons.lock_open,
                        color: Colors.white70,
                        size: 18,
                      ),
                      onPressed: onLock,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.loop, color: Colors.white70, size: 18),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(
                        isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                        color: Colors.white70,
                        size: 20,
                      ),
                      onPressed: onFullscreen,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),

                Text(
                  _formatDuration(duration),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) return '$hours:$minutes:$seconds';
    return '$minutes:$seconds';
  }
}
