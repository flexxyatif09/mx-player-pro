import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class PlayerProvider extends ChangeNotifier {
  double _playbackSpeed = 1.0;
  bool _repeatOne = false;
  bool _shuffle = false;
  String _audioTrack = 'default';
  String _subtitle = 'none';

  double get playbackSpeed => _playbackSpeed;
  bool get repeatOne => _repeatOne;
  bool get shuffle => _shuffle;
  String get audioTrack => _audioTrack;
  String get subtitle => _subtitle;

  void setSpeed(double speed) {
    _playbackSpeed = speed;
    notifyListeners();
  }

  void toggleRepeat() {
    _repeatOne = !_repeatOne;
    notifyListeners();
  }

  void toggleShuffle() {
    _shuffle = !_shuffle;
    notifyListeners();
  }
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  final _box = Hive.box('settings');

  ThemeProvider() {
    final saved = _box.get('theme', defaultValue: 'dark');
    _themeMode = saved == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _box.put('theme', isDark ? 'dark' : 'light');
    notifyListeners();
  }
}
