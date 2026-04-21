import 'package:flutter/material.dart';

/// Big tappable mic button used on the recording screen.
///
/// Performance notes:
///  - Previously stacked a 42px-blur halo `BoxShadow` *and* an `ElevatedButton`
///    with `elevation: 12`. Two large blurred shadows on the same circle means
///    two full-size offscreen blur passes per frame on the GPU — measurable
///    jank on mid-range Android. Worse, the button rebuilds every second when
///    `RecordingBloc` ticks elapsed time, so those shadows were being
///    re-rasterized constantly.
///  - Now: one soft halo via a single radial-blur `BoxShadow` (smaller blur
///    + spread), a flat `Material`-backed circular tap surface (no
///    `ElevatedButton.elevation`), and the whole thing wrapped in a
///    `RepaintBoundary` so the surrounding recording UI never repaints when
///    the button does (and vice versa).
class RecordingMicActionButton extends StatelessWidget {
  const RecordingMicActionButton({
    super.key,
    required this.color,
    required this.iconColor,
    required this.icon,
    required this.onPressed,
  });

  final Color color;
  final Color iconColor;
  final IconData icon;
  final VoidCallback onPressed;

  static const double _haloSize = 170;
  static const double _buttonSize = 132;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: _haloSize,
        height: _haloSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Static, cheap halo. Single shadow, moderate blur, no spread
            // animation. Kept in its own `IgnorePointer` so it never
            // intercepts taps near the edges of the button.
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.09),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.22),
                      blurRadius: 24,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const SizedBox(width: _haloSize, height: _haloSize),
              ),
            ),
            // Flat circular tap surface. No `elevation`, so no second blurred
            // shadow rasterized per frame. `Material` + `InkWell` still gives
            // us correct ripple + tap target semantics.
            Material(
              color: color,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onPressed,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: _buttonSize,
                  height: _buttonSize,
                  child: Icon(icon, size: 54, color: iconColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
