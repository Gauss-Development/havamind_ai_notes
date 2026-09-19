import 'package:flutter_test/flutter_test.dart';
import 'package:sample/features/audio_notes/domain/entities/recording_template.dart';
import 'package:sample/features/thesis/domain/entities/thesis.dart';
import 'package:sample/features/thesis/domain/entities/thesis_version.dart';
import 'package:sample/features/thesis/domain/utils/thesis_return_metrics.dart';

Thesis _thesis({int debriefs = 0, int shares = 0}) {
  return Thesis(
    id: 'thesis-1',
    userId: 'user-1',
    debriefCount: debriefs,
    weekArtifactShareCount: shares,
    createdAt: DateTime.utc(2026, 9, 1),
    updatedAt: DateTime.utc(2026, 9, 16),
  );
}

ThesisVersion _version({required String? templateId}) {
  return ThesisVersion(
    id: 'v1',
    thesisId: 'thesis-1',
    userId: 'user-1',
    roundNumber: 1,
    thesisSnapshot: const {},
    transcription: 'talk',
    sourceTemplateId: templateId,
    createdAt: DateTime.utc(2026, 9, 14),
  );
}

void main() {
  test('second and third return ignore the cold pitch', () {
    expect(ThesisReturnMetrics.reachedSecondReturn(1), isFalse);
    expect(ThesisReturnMetrics.reachedSecondReturn(2), isTrue);
    expect(ThesisReturnMetrics.reachedThirdReturn(2), isFalse);
    expect(ThesisReturnMetrics.reachedThirdReturn(3), isTrue);

    expect(ThesisReturnMetrics.thesisReachedSecondReturn(_thesis()), isFalse);
    expect(
      ThesisReturnMetrics.thesisReachedSecondReturn(_thesis(debriefs: 2)),
      isTrue,
    );
    expect(
      ThesisReturnMetrics.thesisReachedThirdReturn(_thesis(debriefs: 3)),
      isTrue,
    );
  });

  test('share counts only a recorded handoff, not generate', () {
    expect(ThesisReturnMetrics.recordedWeekShare(0), isFalse);
    expect(ThesisReturnMetrics.recordedWeekShare(1), isTrue);
    expect(
      ThesisReturnMetrics.thesisSharedWeekArtifact(_thesis(shares: 1)),
      isTrue,
    );
  });

  test('debrief versions skip founder_pitch rows', () {
    expect(
      ThesisReturnMetrics.isDebriefTemplate(
        RecordingTemplateIds.customerDiscovery,
      ),
      isTrue,
    );
    expect(
      ThesisReturnMetrics.debriefVersions([
        _version(templateId: RecordingTemplateIds.founderPitch),
        _version(templateId: RecordingTemplateIds.customerDiscovery),
        _version(templateId: RecordingTemplateIds.customerDiscovery),
      ]),
      2,
    );
  });
}
