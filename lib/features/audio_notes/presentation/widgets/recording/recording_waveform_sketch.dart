import 'package:flutter/material.dart';

/// Lightweight pulsing waveform painted in a single `CustomPaint`.
///
/// Performance notes:
///  - Previously implemented as 11 `Container` widgets inside an
///    `AnimatedBuilder` that rebuilt the whole subtree at 60Hz. That meant
///    11 element rebuilds + 11 layout passes + 11 RenderObject paints per
///    frame.
///  - Now: zero widget rebuilds per frame. The `AnimationController` is
///    handed directly to `CustomPaint` as `repaint`, and the painter
///    redraws 11 rounded rectangles in one paint call. We also wrap in a
///    `RepaintBoundary` so the parent (`recording_page`) never repaints
///    just because the waveform animated.
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
    return RepaintBoundary(
      child: SizedBox(
        // Width is bounded by the parent (the recording page wraps us in
        // horizontal padding); height is fixed so the painter has a
        // predictable canvas to center bars within.
        height: 88,
        width: double.infinity,
        child: CustomPaint(
          painter: _WaveformPainter(
            color: widget.color,
            animation: _controller,
            isAnimating: widget.isAnimating,
          ),
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.color,
    required this.animation,
    required this.isAnimating,
  }) : super(repaint: animation);

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
  static const _barWidth = 5.0;
  static const _barGap = 4.0; // 2dp horizontal padding on each side

  final Color color;
  final Animation<double> animation;
  final bool isAnimating;

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = isAnimating ? (0.85 + animation.value * 0.35) : 1.0;
    final barCount = _baseHeights.length;
    final totalWidth = barCount * _barWidth + (barCount - 1) * _barGap;
    final startX = (size.width - totalWidth) / 2;
    // Vertically center each bar around the canvas midline. This makes the
    // waveform visually balanced (bars expand symmetrically up + down)
    // instead of being anchored to the bottom edge.
    final centerY = size.height / 2;

    final paint = Paint()..style = PaintingStyle.fill;
    const radius = Radius.circular(999);

    for (var i = 0; i < barCount; i++) {
      final alpha = (0.18 + (i / barCount) * 0.82).clamp(0.0, 1.0);
      paint.color = color.withValues(alpha: alpha);

      final barHeight = _baseHeights[i] * pulse;
      final left = startX + i * (_barWidth + _barGap);
      final top = centerY - barHeight / 2;
      final bottom = centerY + barHeight / 2;

      final rrect = RRect.fromLTRBR(
        left,
        top,
        left + _barWidth,
        bottom,
        radius,
      );
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    // The animation listener handles per-frame repaints via `super(repaint:)`.
    // We only need to repaint when one of the static inputs changes.
    return oldDelegate.color != color || oldDelegate.isAnimating != isAnimating;
  }
}
