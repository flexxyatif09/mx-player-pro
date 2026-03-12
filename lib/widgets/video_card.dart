import 'package:flutter/material.dart';
import 'dart:io';
import '../models/video_model.dart';
import '../utils/app_theme.dart';

class VideoCard extends StatelessWidget {
  final VideoModel video;
  final VoidCallback onTap;

  const VideoCard({super.key, required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: AppTheme.darkCardElevated,
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_outline,
                          color: AppTheme.primaryColor,
                          size: 40,
                        ),
                      ),
                    ),
                    // Duration badge
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          video.durationFormatted,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (video.resolution.isNotEmpty)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            video.resolution,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        video.sizeFormatted,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _showOptions(context),
                        child: const Icon(
                          Icons.more_vert,
                          color: AppTheme.textSecondary,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _VideoOptionsSheet(video: video),
    );
  }
}

class VideoListTile extends StatelessWidget {
  final VideoModel video;
  final VoidCallback onTap;

  const VideoListTile({super.key, required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 64,
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.play_circle_fill,
          color: AppTheme.primaryColor,
          size: 28,
        ),
      ),
      title: Text(
        video.title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${video.durationFormatted} • ${video.sizeFormatted}',
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 11,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: AppTheme.darkCard,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (_) => _VideoOptionsSheet(video: video),
          );
        },
      ),
    );
  }
}

class _VideoOptionsSheet extends StatelessWidget {
  final VideoModel video;

  const _VideoOptionsSheet({required this.video});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            video.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${video.sizeFormatted} • ${video.durationFormatted}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const Divider(color: AppTheme.darkCardElevated, height: 24),
          _OptionTile(icon: Icons.play_arrow, title: 'Play'),
          _OptionTile(icon: Icons.info_outline, title: 'Properties'),
          _OptionTile(icon: Icons.share, title: 'Share'),
          _OptionTile(icon: Icons.favorite_border, title: 'Add to Favorites'),
          _OptionTile(icon: Icons.playlist_add, title: 'Add to Playlist'),
          _OptionTile(icon: Icons.delete_outline, title: 'Delete',
              color: AppTheme.errorColor),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;

  const _OptionTile({
    required this.icon,
    required this.title,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.white, size: 20),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.white,
          fontSize: 14,
        ),
      ),
      contentPadding: EdgeInsets.zero,
      dense: true,
      onTap: () => Navigator.pop(context),
    );
  }
}
