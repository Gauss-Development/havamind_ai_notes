import 'package:flutter/material.dart';

/// Visual scale presets for [RecordingMicActionButton].
enum RecordingMicScale {
  /// Default — comfortable on tablets and tall phones.
  normal(haloSize: 150, buttonSize: 112, iconSize: 48),

  /// Smaller footprint for compact phones.
  compact(haloSize: 120, buttonSize: 92, iconSize: 40),

  /// Minimal — used when vertical space is very tight.
  small(haloSize: 100, buttonSize: 80, iconSize: 34);

  const RecordingMicScale({
    required this.haloSize,
    required this.buttonSize,
    required this.iconSize,
  });

  final double haloSize;
  final double buttonSize;
  final double iconSize;
}

/// Big tappable mic button used on the recording screen.
class RecordingMicActionButton extends StatelessWidget {
  const RecordingMicActionButton({
    super.key,
    required this.color,
    required this.iconColor,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.scale = RecordingMicScale.normal,
  });

  final Color color;
  final Color iconColor;
  final IconData icon;
  final VoidCallback onPressed;
  final String semanticLabel;
  final RecordingMicScale scale;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: semanticLabel,
      child: Semantics(
        button: true,
        label: semanticLabel,
        child: RepaintBoundary(
          child: SizedBox(
            width: scale.haloSize,
            height: scale.haloSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
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
                    child: SizedBox(
                      width: scale.haloSize,
                      height: scale.haloSize,
                    ),
                  ),
                ),
                Material(
                  color: color,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onPressed,
                    customBorder: const CircleBorder(),
                    child: SizedBox(
                      width: scale.buttonSize,
                      height: scale.buttonSize,
                      child: Icon(icon, size: scale.iconSize, color: iconColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
