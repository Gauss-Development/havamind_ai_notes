import 'package:dartz/dartz.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note_transcript.dart';
import 'package:sample/features/audio_notes/domain/entities/startup_analysis.dart';

abstract class AudioNotesRepository {
  Future<Either<Failure, List<AudioNote>>> listNotes({
    int limit = 20,
    int offset = 0,
  });

  Future<Either<Failure, AudioNote>> getNote(String id);

  Future<Either<Failure, AudioNote>> saveRecording({
    required String localFilePath,
    required int durationSeconds,
  });

  Future<Either<Failure, AudioNote>> processLocalAudioNote({
    required String localFilePath,
    required int durationSeconds,
  });

  Future<Either<Failure, Unit>> deleteNote(String id);

  Future<Either<Failure, Unit>> requestProcessing(String noteId);

  Future<Either<Failure, Unit>> deleteLocalAudioFile(String noteId);

  Future<Either<Failure, AudioNoteTranscript?>> getTranscript(String noteId);

  Future<Either<Failure, StartupAnalysis?>> getAnalysis(String noteId);

  Future<Either<Failure, Unit>> updateAnalysisField({
    required String noteId,
    required StartupAnalysisEditableField field,
    required String value,
  });

  Future<Either<Failure, Unit>> updateNoteTitle({
    required String noteId,
    required String title,
  });

  Future<Either<Failure, int>> getTotalUsageSeconds({
    required DateTime from,
    required DateTime to,
  });

  Stream<AudioNote> watchNote(String noteId);
}
