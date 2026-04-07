enum AudioNoteStatus {
  draft,
  uploaded,
  processingTranscription,
  processingAnalysis,
  completed,
  failed;

  static AudioNoteStatus fromDb(String value) {
    switch (value) {
      case 'processing_transcription':
        return AudioNoteStatus.processingTranscription;
      case 'processing_analysis':
        return AudioNoteStatus.processingAnalysis;
      default:
        return AudioNoteStatus.values.firstWhere(
          (e) => e.name == value,
          orElse: () => AudioNoteStatus.draft,
        );
    }
  }

  String get dbValue {
    switch (this) {
      case AudioNoteStatus.processingTranscription:
        return 'processing_transcription';
      case AudioNoteStatus.processingAnalysis:
        return 'processing_analysis';
      default:
        return name;
    }
  }

  bool get isProcessing =>
      this == processingTranscription || this == processingAnalysis;

  /// After upload, before or during Edge Function (covers `uploaded` race).
  bool get isPendingPipeline => isProcessing || this == uploaded;
}
