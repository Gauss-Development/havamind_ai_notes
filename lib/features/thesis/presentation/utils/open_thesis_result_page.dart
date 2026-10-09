import 'package:flutter/material.dart';

import 'package:sample/features/thesis/presentation/concept_result_entry.dart';
import 'package:sample/features/thesis/presentation/pages/thesis_page.dart';

/// Pushes [ThesisPage]. [entry] decides whether a rewrite asks who heard it.
Future<void> openThesisResultPage(
  BuildContext context,
  String noteId, {
  ConceptResultEntry entry = ConceptResultEntry.view,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => ThesisPage(noteId: noteId, entry: entry),
    ),
  );
}
