import 'package:flutter/material.dart';

/// Pass-through wrapper — retained for API compatibility.
/// The decorative blobs have been removed to reduce visual noise.
class FounderBackdrop extends StatelessWidget {
  const FounderBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
