import 'package:equatable/equatable.dart';

enum StartupAnalysisEditableField {
  problem,
  solution,
  targetAudience,
  businessModel,
  keyMetrics,
  advantages,
  risksGaps,
  shortSummary,
  startupTitle,
}

class StartupAnalysis extends Equatable {
  const StartupAnalysis({
    required this.id,
    required this.audioNoteId,
    required this.userId,
    this.shortSummary,
    this.startupTitle,
    this.problem,
    this.solution,
    this.targetAudience,
    this.businessModel,
    this.keyMetrics,
    this.advantages,
    this.risksGaps,
    this.followUpQuestions,
    this.marketPotentialScore,
    this.technicalComplexityScore,
    required this.createdAt,
  });

  final String id;
  final String audioNoteId;
  final String userId;
  final String? shortSummary;
  final String? startupTitle;
  final String? problem;
  final String? solution;
  final String? targetAudience;
  final String? businessModel;
  final String? keyMetrics;
  final String? advantages;
  final String? risksGaps;
  final List<String>? followUpQuestions;
  final int? marketPotentialScore;
  final int? technicalComplexityScore;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    audioNoteId,
    userId,
    shortSummary,
    startupTitle,
    problem,
    solution,
    targetAudience,
    businessModel,
    keyMetrics,
    advantages,
    risksGaps,
    followUpQuestions,
    marketPotentialScore,
    technicalComplexityScore,
    createdAt,
  ];
}
