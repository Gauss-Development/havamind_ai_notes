import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 170,
          height: 170,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.09),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.18),
                blurRadius: 42,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        SizedBox(
          width: 132,
          height: 132,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              backgroundColor: color,
              foregroundColor: iconColor,
              elevation: 12,
              shadowColor: color.withValues(alpha: 0.45),
              padding: EdgeInsets.zero,
            ),
            onPressed: onPressed,
            child: Icon(icon, size: 54),
          ),
        ),
      ],
    );
  }
}
