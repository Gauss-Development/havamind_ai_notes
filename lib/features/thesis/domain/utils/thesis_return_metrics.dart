import 'package:sample/features/audio_notes/domain/entities/recording_template.dart';
import 'package:sample/features/thesis/domain/entities/thesis.dart';
import 'package:sample/features/thesis/domain/entities/thesis_version.dart';

/// Hard return numbers from the living-thesis slice: second and third
/// debrief, plus at least one weekly letter sent via the share sheet.
abstract final class ThesisReturnMetrics {
  static const secondReturnDebriefs = 2;
  static const thirdReturnDebriefs = 3;

  static bool isDebriefTemplate(String? templateId) =>
      templateId == RecordingTemplateIds.customerDiscovery;

  static bool reachedSecondReturn(int debriefCount) =>
      debriefCount >= secondReturnDebriefs;

  static bool reachedThirdReturn(int debriefCount) =>
      debriefCount >= thirdReturnDebriefs;

  static bool recordedWeekShare(int shareCount) => shareCount > 0;

  static bool thesisReachedSecondReturn(Thesis thesis) =>
      reachedSecondReturn(thesis.debriefCount);

  static bool thesisReachedThirdReturn(Thesis thesis) =>
      reachedThirdReturn(thesis.debriefCount);

  static bool thesisSharedWeekArtifact(Thesis thesis) =>
      recordedWeekShare(thesis.weekArtifactShareCount);

  /// `thesis_versions` rows that are real debriefs, not a cold pitch.
  static int debriefVersions(Iterable<ThesisVersion> versions) => versions
      .where((version) => isDebriefTemplate(version.sourceTemplateId))
      .length;
}
