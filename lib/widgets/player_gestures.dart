import 'package:flutter/material.dart';

class PlayerGestures extends StatefulWidget {
  final Function(double) onBrightnessChanged;
  final Function(double) onVolumeChanged;
  final Function(int) onSeek;
  final VoidCallback onHideOverlays;

  const PlayerGestures({
    super.key,
    required this.onBrightnessChanged,
    required this.onVolumeChanged,
    required this.onSeek,
    required this.onHideOverlays,
  });

  @override
  State<PlayerGestures> createState() => _PlayerGesturesState();
}

class _PlayerGesturesState extends State<PlayerGestures> {
  double _brightness = 0.5;
  double _volume = 0.5;
  double _dragStart = 0;
  bool _isVerticalDrag = false;
  bool _isLeftSide = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final halfWidth = size.width / 2;

    return Row(
      children: [
        // Left half - brightness
        GestureDetector(
          onVerticalDragStart: (details) {
            _dragStart = details.globalPosition.dy;
            _isLeftSide = true;
            _isVerticalDrag = true;
          },
          onVerticalDragUpdate: (details) {
            if (!_isVerticalDrag || !_isLeftSide) return;
            final delta =
                (_dragStart - details.globalPosition.dy) / size.height;
            _brightness = (_brightness + delta).clamp(0.0, 1.0);
            _dragStart = details.globalPosition.dy;
            widget.onBrightnessChanged(_brightness);
          },
          onVerticalDragEnd: (_) {
            widget.onHideOverlays();
            _isVerticalDrag = false;
          },
          onDoubleTap: () => widget.onSeek(-10),
          behavior: HitTestBehavior.translucent,
          child: SizedBox(width: halfWidth, height: size.height),
        ),

        // Right half - volume
        GestureDetector(
          onVerticalDragStart: (details) {
            _dragStart = details.globalPosition.dy;
            _isLeftSide = false;
            _isVerticalDrag = true;
          },
          onVerticalDragUpdate: (details) {
            if (!_isVerticalDrag || _isLeftSide) return;
            final delta =
                (_dragStart - details.globalPosition.dy) / size.height;
            _volume = (_volume + delta).clamp(0.0, 1.0);
            _dragStart = details.globalPosition.dy;
            widget.onVolumeChanged(_volume);
          },
          onVerticalDragEnd: (_) {
            widget.onHideOverlays();
            _isVerticalDrag = false;
          },
          onDoubleTap: () => widget.onSeek(10),
          behavior: HitTestBehavior.translucent,
          child: SizedBox(width: halfWidth, height: size.height),
        ),
      ],
    );
  }
}
