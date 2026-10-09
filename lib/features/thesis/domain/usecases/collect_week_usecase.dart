import 'package:dartz/dartz.dart';

import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/audio_notes/domain/repositories/audio_notes_repository.dart';
import 'package:sample/features/thesis/domain/entities/weekly_thesis_export.dart';
import 'package:sample/features/thesis/domain/repositories/thesis_repository.dart';
import 'package:sample/features/thesis/domain/utils/select_week_notes.dart';

/// Loads the account thesis and notes in the last 7 days.
class CollectWeekUseCase implements UseCase<WeeklyThesisExport, NoParams> {
  CollectWeekUseCase({
    required ThesisRepository thesisRepository,
    required AudioNotesRepository audioNotesRepository,
    DateTime Function()? clock,
  }) : _thesisRepository = thesisRepository,
       _audioNotesRepository = audioNotesRepository,
       _clock = clock ?? DateTime.now;

  final ThesisRepository _thesisRepository;
  final AudioNotesRepository _audioNotesRepository;
  final DateTime Function() _clock;

  /// Enough for a discovery week; Home’s first page is only 20.
  static const _noteLimit = 100;
  static const _versionLimit = 50;

  @override
  Future<Either<Failure, WeeklyThesisExport>> call(NoParams params) async {
    final thesisResult = await _thesisRepository.getCurrentThesis();
    final thesisFailure = thesisResult.fold<Failure?>((l) => l, (_) => null);
    if (thesisFailure != null) return Left(thesisFailure);
    final thesis = thesisResult.fold((_) => null, (r) => r);
    if (thesis == null) return const Left(NotFoundFailure('No thesis'));

    final notesResult = await _audioNotesRepository.listNotes(
      limit: _noteLimit,
    );
    final notesFailure = notesResult.fold<Failure?>((l) => l, (_) => null);
    if (notesFailure != null) return Left(notesFailure);
    final notes = notesResult.fold((_) => null, (r) => r)!;

    final versionsResult = await _thesisRepository.listRecentVersions(
      limit: _versionLimit,
    );
    final versionsFailure = versionsResult.fold<Failure?>(
      (l) => l,
      (_) => null,
    );
    if (versionsFailure != null) return Left(versionsFailure);
    final versions = versionsResult.fold((_) => null, (r) => r)!;

    final now = _clock();
    final since = weekExportSince(now);
    final weekNotes = selectNotesCreatedSince(notes, since);
    return Right(
      WeeklyThesisExport(
        thesis: thesis,
        weekNotes: weekNotes,
        weekDebriefs: selectWeekDebriefs(weekNotes),
        windowStart: since,
        windowEnd: now,
        heardVersions: selectHeardInWindow(versions, since, now),
      ),
    );
  }
}
