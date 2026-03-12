import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../models/video_model.dart';

class MediaProvider extends ChangeNotifier {
  List<VideoModel> _videos = [];
  bool _isScanning = false;
  String _scanStatus = '';

  List<VideoModel> get videos => _videos;
  bool get isScanning => _isScanning;
  String get scanStatus => _scanStatus;

  // Supported video formats
  static const _videoExtensions = [
    '.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv',
    '.webm', '.m4v', '.3gp', '.ts', '.m2ts', '.vob',
    '.ogv', '.rmvb', '.divx', '.xvid', '.hevc',
  ];

  // Common media paths on Android
  static const _scanPaths = [
    '/storage/emulated/0/',
    '/storage/emulated/0/Movies/',
    '/storage/emulated/0/Video/',
    '/storage/emulated/0/Videos/',
    '/storage/emulated/0/Download/',
    '/storage/emulated/0/Downloads/',
    '/storage/emulated/0/DCIM/',
    '/storage/emulated/0/WhatsApp/Media/',
  ];

  Future<void> scanMedia({bool forceRefresh = false}) async {
    if (_isScanning && !forceRefresh) return;

    _isScanning = true;
    _scanStatus = 'Requesting permissions...';
    notifyListeners();

    // Request storage permission
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      // Try manageExternalStorage for Android 11+
      await Permission.manageExternalStorage.request();
    }

    _scanStatus = 'Scanning media files...';
    notifyListeners();

    final List<VideoModel> found = [];

    for (final path in _scanPaths) {
      final dir = Directory(path);
      if (!await dir.exists()) continue;

      try {
        await for (final entity in dir.list(recursive: true)) {
          if (entity is File) {
            final ext = entity.path.toLowerCase();
            if (_videoExtensions.any((e) => ext.endsWith(e))) {
              try {
                final stat = await entity.stat();
                final name = entity.path.split('/').last;
                final folder = entity.path
                    .split('/')
                    .reversed
                    .skip(1)
                    .first;

                found.add(VideoModel(
                  id: entity.path,
                  title: name.replaceAll(
                    RegExp(r'\.[^.]+$'), ''),
                  path: entity.path,
                  folderName: folder,
                  duration: 0, // Would need media metadata
                  size: stat.size,
                  dateAdded: stat.modified,
                ));
              } catch (_) {}
            }
          }
        }
      } catch (_) {}
    }

    _videos = found;
    _isScanning = false;
    _scanStatus = '';
    notifyListeners();
  }
}
