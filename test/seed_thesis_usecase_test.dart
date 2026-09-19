import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/audio_notes/domain/entities/startup_analysis.dart';
import 'package:sample/features/thesis/domain/entities/thesis.dart';
import 'package:sample/features/thesis/domain/entities/thesis_field_evidence.dart';
import 'package:sample/features/thesis/domain/entities/thesis_seed_candidate.dart';
import 'package:sample/features/thesis/domain/repositories/thesis_repository.dart';
import 'package:sample/features/thesis/domain/usecases/seed_thesis_usecase.dart';
import 'package:sample/features/thesis/domain/utils/select_best_thesis_seed_candidate.dart';
import 'package:sample/features/thesis/domain/utils/thesis_draft_from_analysis.dart';

class _MockThesisRepository extends Mock implements ThesisRepository {}

void main() {
  const completeProblem = 'Founders lose ideas because capture is too slow.';
  const completeSolution = 'Voice-first notes with instant AI structuring.';
  const completeAudience = 'Solo founders and small startup teams.';
  const completeModel = 'Subscription with free tier and paid Pro plan.';
  const completeMetrics = 'Weekly active recorders and plan completion rate.';
  const completeAdvantages =
      'Founder-specific prompts and venture intelligence.';
  const completeRisks = 'Competition from generic note apps.';

  StartupAnalysis analysis({
    required String id,
    required String noteId,
    DateTime? createdAt,
    String? title = 'Havamind',
    String? summary = 'A living thesis for founders.',
    String? problem = completeProblem,
    String? solution = completeSolution,
    String? targetAudience = completeAudience,
    String? businessModel = completeModel,
    String? keyMetrics = completeMetrics,
    String? advantages = completeAdvantages,
    String? risksGaps = completeRisks,
    List<String>? followUpQuestions = const ['Who pays first?'],
  }) {
    return StartupAnalysis(
      id: id,
      audioNoteId: noteId,
      userId: 'user-1',
      startupTitle: title,
      shortSummary: summary,
      problem: problem,
      solution: solution,
      targetAudience: targetAudience,
      businessModel: businessModel,
      keyMetrics: keyMetrics,
      advantages: advantages,
      risksGaps: risksGaps,
      followUpQuestions: followUpQuestions,
      createdAt: createdAt ?? DateTime.utc(2026, 1, 1),
    );
  }

  Thesis thesis({String id = 'thesis-1'}) {
    return Thesis(
      id: id,
      userId: 'user-1',
      title: 'Havamind',
      createdAt: DateTime.utc(2026, 1, 2),
      updatedAt: DateTime.utc(2026, 1, 2),
    );
  }

  late _MockThesisRepository repository;
  late SeedThesisUseCase useCase;

  setUpAll(() {
    registerFallbackValue(const ThesisDraft());
  });

  setUp(() {
    repository = _MockThesisRepository();
    useCase = SeedThesisUseCase(repository);
  });

  group('selectBestThesisSeedCandidate', () {
    test('returns null when there are no candidates', () {
      expect(selectBestThesisSeedCandidate(const []), isNull);
    });

    test('prefers the higher PlanReadiness percent', () {
      final weak = ThesisSeedCandidate(
        analysis: analysis(
          id: 'a-weak',
          noteId: 'note-weak',
          problem: 'not specified',
          businessModel: null,
        ),
        noteCreatedAt: DateTime.utc(2026, 3, 1),
      );
      final strong = ThesisSeedCandidate(
        analysis: analysis(id: 'a-strong', noteId: 'note-strong'),
        noteCreatedAt: DateTime.utc(2026, 1, 1),
      );

      final best = selectBestThesisSeedCandidate([weak, strong]);

      expect(best?.analysis.id, 'a-strong');
    });

    test('breaks a readiness tie with the newest completed note', () {
      final older = ThesisSeedCandidate(
        analysis: analysis(id: 'a-old', noteId: 'note-old'),
        noteCreatedAt: DateTime.utc(2026, 1, 1),
      );
      final newer = ThesisSeedCandidate(
        analysis: analysis(id: 'a-new', noteId: 'note-new'),
        noteCreatedAt: DateTime.utc(2026, 2, 1),
      );

      final best = selectBestThesisSeedCandidate([older, newer]);

      expect(best?.analysis.id, 'a-new');
    });
  });

  group('thesisDraftFromAnalysis', () {
    test(
      'copies seven fields plus title/summary and founder_claim evidence',
      () {
        final source = analysis(id: 'a1', noteId: 'note-9');
        final draft = thesisDraftFromAnalysis(source);

        expect(draft.title, 'Havamind');
        expect(draft.shortSummary, 'A living thesis for founders.');
        expect(draft.problem, completeProblem);
        expect(draft.solution, completeSolution);
        expect(draft.targetAudience, completeAudience);
        expect(draft.businessModel, completeModel);
        expect(draft.keyMetrics, completeMetrics);
        expect(draft.advantages, completeAdvantages);
        expect(draft.risksGaps, completeRisks);
        expect(draft.followUpQuestions, ['Who pays first?']);
        expect(draft.nextConversationScript, isNull);

        expect(
          draft.fieldEvidence.keys,
          containsAll([
            ThesisEvidenceFields.title,
            ThesisEvidenceFields.shortSummary,
            ThesisEvidenceFields.problem,
            ThesisEvidenceFields.solution,
            ThesisEvidenceFields.targetAudience,
            ThesisEvidenceFields.businessModel,
            ThesisEvidenceFields.keyMetrics,
            ThesisEvidenceFields.advantages,
            ThesisEvidenceFields.risksGaps,
          ]),
        );
        expect(
          draft.fieldEvidence.values.every(
            (e) =>
                e.kind == ThesisEvidenceKind.founderClaim &&
                e.noteId == 'note-9',
          ),
          isTrue,
        );
      },
    );

    test('omits empty fields from evidence', () {
      final draft = thesisDraftFromAnalysis(
        analysis(
          id: 'a2',
          noteId: 'note-2',
          title: null,
          summary: '  ',
          businessModel: null,
        ),
      );

      expect(
        draft.fieldEvidence.containsKey(ThesisEvidenceFields.title),
        isFalse,
      );
      expect(
        draft.fieldEvidence.containsKey(ThesisEvidenceFields.shortSummary),
        isFalse,
      );
      expect(
        draft.fieldEvidence.containsKey(ThesisEvidenceFields.businessModel),
        isFalse,
      );
      expect(
        draft.fieldEvidence.containsKey(ThesisEvidenceFields.problem),
        isTrue,
      );
    });
  });

  group('SeedThesisUseCase', () {
    test('returns the existing thesis and re-attaches notes', () async {
      final existing = thesis();
      when(
        () => repository.getCurrentThesis(),
      ).thenAnswer((_) async => Right(existing));
      when(
        () => repository.attachThesisToAllNotes(existing.id),
      ).thenAnswer((_) async => const Right(unit));

      final result = await useCase(const NoParams());

      expect(result, Right(existing));
      verifyNever(() => repository.listSeedCandidates());
      verifyNever(() => repository.createThesis(any()));
      verify(() => repository.attachThesisToAllNotes('thesis-1')).called(1);
    });

    test('creates an empty thesis when no completed analysis exists', () async {
      final created = thesis(id: 'thesis-empty');
      when(
        () => repository.getCurrentThesis(),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => repository.listSeedCandidates(),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => repository.createThesis(const ThesisDraft()),
      ).thenAnswer((_) async => Right(created));
      when(
        () => repository.attachThesisToAllNotes(created.id),
      ).thenAnswer((_) async => const Right(unit));

      final result = await useCase(const NoParams());

      expect(result, Right(created));
      verify(() => repository.createThesis(const ThesisDraft())).called(1);
      verify(() => repository.attachThesisToAllNotes('thesis-empty')).called(1);
    });

    test('seeds from the best completed analysis and attaches notes', () async {
      final weak = ThesisSeedCandidate(
        analysis: analysis(
          id: 'a-weak',
          noteId: 'note-weak',
          problem: 'not specified',
        ),
        noteCreatedAt: DateTime.utc(2026, 4, 1),
      );
      final strong = ThesisSeedCandidate(
        analysis: analysis(id: 'a-strong', noteId: 'note-strong'),
        noteCreatedAt: DateTime.utc(2026, 1, 1),
      );
      final created = thesis(id: 'thesis-seeded');

      when(
        () => repository.getCurrentThesis(),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => repository.listSeedCandidates(),
      ).thenAnswer((_) async => Right([weak, strong]));
      when(() => repository.createThesis(any())).thenAnswer((invocation) async {
        final draft = invocation.positionalArguments[0] as ThesisDraft;
        expect(draft.title, 'Havamind');
        expect(draft.problem, completeProblem);
        expect(
          draft.fieldEvidence[ThesisEvidenceFields.problem]?.kind,
          ThesisEvidenceKind.founderClaim,
        );
        expect(
          draft.fieldEvidence[ThesisEvidenceFields.problem]?.noteId,
          'note-strong',
        );
        return Right(created);
      });
      when(
        () => repository.attachThesisToAllNotes(created.id),
      ).thenAnswer((_) async => const Right(unit));

      final result = await useCase(const NoParams());

      expect(result, Right(created));
      verify(() => repository.createThesis(any())).called(1);
      verify(
        () => repository.attachThesisToAllNotes('thesis-seeded'),
      ).called(1);
    });

    test('propagates getCurrentThesis failure', () async {
      const failure = UnexpectedFailure('down');
      when(
        () => repository.getCurrentThesis(),
      ).thenAnswer((_) async => const Left(failure));

      final result = await useCase(const NoParams());

      expect(result, const Left(failure));
      verifyNever(() => repository.createThesis(any()));
    });

    test('propagates createThesis failure', () async {
      const failure = ServerFailure('insert failed');
      when(
        () => repository.getCurrentThesis(),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => repository.listSeedCandidates(),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => repository.createThesis(any()),
      ).thenAnswer((_) async => const Left(failure));

      final result = await useCase(const NoParams());

      expect(result, const Left(failure));
      verifyNever(() => repository.attachThesisToAllNotes(any()));
    });

    test('propagates attach failure after a successful create', () async {
      const failure = ServerFailure('attach failed');
      final created = thesis();
      when(
        () => repository.getCurrentThesis(),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => repository.listSeedCandidates(),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => repository.createThesis(any()),
      ).thenAnswer((_) async => Right(created));
      when(
        () => repository.attachThesisToAllNotes(created.id),
      ).thenAnswer((_) async => const Left(failure));

      final result = await useCase(const NoParams());

      expect(result, const Left(failure));
    });
  });
}
