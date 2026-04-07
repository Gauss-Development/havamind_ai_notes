import 'package:flutter/material.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note_status.dart';

String audioNoteStatusLabel(AudioNoteStatus status) {
  switch (status) {
    case AudioNoteStatus.draft:
      return 'Draft';
    case AudioNoteStatus.uploaded:
      return 'Uploaded';
    case AudioNoteStatus.processingTranscription:
      return 'Transcribing...';
    case AudioNoteStatus.processingAnalysis:
      return 'Analyzing...';
    case AudioNoteStatus.completed:
      return 'Ready';
    case AudioNoteStatus.failed:
      return 'Failed';
  }
}

Color audioNoteStatusColor(BuildContext context, AudioNoteStatus status) {
  final t = context.obsidian;
  switch (status) {
    case AudioNoteStatus.draft:
      return t.onSurfaceVariant;
    case AudioNoteStatus.uploaded:
    case AudioNoteStatus.processingTranscription:
    case AudioNoteStatus.processingAnalysis:
      return t.warning;
    case AudioNoteStatus.completed:
      return t.secondary;
    case AudioNoteStatus.failed:
      return Theme.of(context).colorScheme.error;
  }
}
