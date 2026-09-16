import 'package:flutter/material.dart';

import 'package:sample/features/thesis/presentation/pages/thesis_page.dart';

/// Pushes [ThesisPage] for a debrief note. Home and voice-reply share this.
Future<void> openThesisResultPage(BuildContext context, String noteId) {
  return Navigator.of(
    context,
  ).push<void>(MaterialPageRoute(builder: (_) => ThesisPage(noteId: noteId)));
}
