import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note_status.dart';
import 'package:sample/features/audio_notes/domain/entities/recording_template.dart';
import 'package:sample/features/thesis/domain/entities/thesis.dart';
import 'package:sample/features/thesis/domain/entities/weekly_thesis_export.dart';
import 'package:sample/features/thesis/domain/usecases/collect_week_usecase.dart';
import 'package:sample/features/thesis/presentation/cubit/thesis_week_export_cubit.dart';

class _MockCollectWeek extends Mock implements CollectWeekUseCase {}

WeeklyThesisExport _export({required bool withDebrief}) {
  final thesis = Thesis(
    id: 'thesis-1',
    userId: 'user-1',
    title: 'Havamind',
    createdAt: DateTime.utc(2026, 9, 1),
    updatedAt: DateTime.utc(2026, 9, 16),
  );
  final debrief = AudioNote(
    id: 'd1',
    userId: 'user-1',
    title: 'Clinic call',
    audioPath: null,
    durationSeconds: 90,
    status: AudioNoteStatus.completed,
    createdAt: DateTime.utc(2026, 9, 14),
    updatedAt: DateTime.utc(2026, 9, 14),
    templateId: RecordingTemplateIds.customerDiscovery,
  );
  return WeeklyThesisExport(
    thesis: thesis,
    weekNotes: withDebrief ? [debrief] : const [],
    weekDebriefs: withDebrief ? [debrief] : const [],
    windowStart: DateTime.utc(2026, 9, 9),
    windowEnd: DateTime.utc(2026, 9, 16),
  );
}

void main() {
  late _MockCollectWeek collectWeek;
  late ThesisWeekExportCubit cubit;

  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    collectWeek = _MockCollectWeek();
    cubit = ThesisWeekExportCubit(collectWeek: collectWeek);
  });

  tearDown(() async {
    await cubit.close();
  });

  test('load emits ready when the week has debriefs', () async {
    when(() => collectWeek(any()))
        .thenAnswer((_) async => Right(_export(withDebrief: true)));

    await cubit.load();

    expect(cubit.state, isA<ThesisWeekExportReady>());
    final ready = cubit.state as ThesisWeekExportReady;
    expect(ready.export.weekDebriefs, hasLength(1));
  });

  test('load emits empty when there are no debriefs this week', () async {
    when(() => collectWeek(any()))
        .thenAnswer((_) async => Right(_export(withDebrief: false)));

    await cubit.load();

    expect(cubit.state, const ThesisWeekExportEmpty());
  });

  test('load emits error when collect week fails', () async {
    const failure = ServerFailure('down');
    when(() => collectWeek(any())).thenAnswer((_) async => const Left(failure));

    await cubit.load();

    expect(cubit.state, const ThesisWeekExportError(failure));
  });
}
