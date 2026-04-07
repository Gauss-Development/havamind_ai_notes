import 'package:flutter/material.dart';

class RecordingWaveformSketch extends StatefulWidget {
  const RecordingWaveformSketch({
    super.key,
    required this.color,
    required this.isAnimating,
  });

  final Color color;
  final bool isAnimating;

  @override
  State<RecordingWaveformSketch> createState() =>
      _RecordingWaveformSketchState();
}

class _RecordingWaveformSketchState extends State<RecordingWaveformSketch>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _baseHeights = <double>[
    6,
    12,
    18,
    24,
    18,
    30,
    20,
    36,
    24,
    14,
    8,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant RecordingWaveformSketch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating && !oldWidget.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isAnimating && oldWidget.isAnimating) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final pulse = widget.isAnimating
            ? (0.85 + _controller.value * 0.35)
            : 1;
        return SizedBox(
          height: 120,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(_baseHeights.length, (index) {
              final alpha = 0.18 + (index / _baseHeights.length) * 0.82;
              final height = _baseHeights[index] * pulse;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  width: 5,
                  height: height,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(
                      alpha: alpha.clamp(0.0, 1.0),
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
