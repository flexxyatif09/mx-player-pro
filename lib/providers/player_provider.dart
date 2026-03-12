import 'package:flutter/foundation.dart';

class PlayerProvider extends ChangeNotifier {
  double _playbackSpeed = 1.0;
  bool _repeatOne = false;
  bool _shuffle = false;

  double get playbackSpeed => _playbackSpeed;
  bool get repeatOne => _repeatOne;
  bool get shuffle => _shuffle;

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
