import 'package:equatable/equatable.dart';

/// How a thesis field is backed in the slice: founder words, a customer
/// signal, or still an unbacked stake.
enum ThesisEvidenceKind {
  founderClaim,
  customerSignal,
  unbacked;

  String get dbValue {
    switch (this) {
      case ThesisEvidenceKind.founderClaim:
        return 'founder_claim';
      case ThesisEvidenceKind.customerSignal:
        return 'customer_signal';
      case ThesisEvidenceKind.unbacked:
        return 'unbacked';
    }
  }

  static ThesisEvidenceKind fromDb(String value) {
    switch (value) {
      case 'founder_claim':
        return ThesisEvidenceKind.founderClaim;
      case 'customer_signal':
        return ThesisEvidenceKind.customerSignal;
      case 'unbacked':
        return ThesisEvidenceKind.unbacked;
      default:
        return ThesisEvidenceKind.unbacked;
    }
  }
}

/// JSON keys stored in `theses.field_evidence`.
class ThesisEvidenceFields {
  static const title = 'title';
  static const shortSummary = 'short_summary';
  static const problem = 'problem';
  static const solution = 'solution';
  static const targetAudience = 'target_audience';
  static const businessModel = 'business_model';
  static const keyMetrics = 'key_metrics';
  static const advantages = 'advantages';
  static const risksGaps = 'risks_gaps';
}

class ThesisFieldEvidence extends Equatable {
  const ThesisFieldEvidence({required this.kind, this.quote, this.noteId});

  final ThesisEvidenceKind kind;
  final String? quote;
  final String? noteId;

  @override
  List<Object?> get props => [kind, quote, noteId];
}
