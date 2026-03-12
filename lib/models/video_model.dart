class VideoModel {
  final String id;
  final String title;
  final String path;
  final String folderName;
  final int duration; // milliseconds
  final int size; // bytes
  final DateTime dateAdded;
  final String? thumbnailPath;
  final int width;
  final int height;

  const VideoModel({
    required this.id,
    required this.title,
    required this.path,
    required this.folderName,
    required this.duration,
    required this.size,
    required this.dateAdded,
    this.thumbnailPath,
    this.width = 0,
    this.height = 0,
  });

  String get durationFormatted {
    final d = Duration(milliseconds: duration);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  String get sizeFormatted {
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get resolution {
    if (width > 0 && height > 0) {
      if (height >= 2160) return '4K';
      if (height >= 1080) return '1080p';
      if (height >= 720) return '720p';
      if (height >= 480) return '480p';
      return '${width}x$height';
    }
    return '';
  }
}
