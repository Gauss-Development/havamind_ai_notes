import 'package:equatable/equatable.dart';

/// What the founder asked the concept rewrite to do.
class RewriteConceptRequest extends Equatable {
  const RewriteConceptRequest({
    required this.noteId,
    this.heardByLabel,
    this.rewriteUnheard = false,
    this.proposedRewrite,
  });

  final String noteId;

  /// Founder-confirmed label. Not a user id.
  final String? heardByLabel;

  /// Cold pitch: replace the speech without marking anyone as having heard it.
  final bool rewriteUnheard;

  /// Model proposal from a previous suggestion response. Skips a second call.
  final Map<String, dynamic>? proposedRewrite;

  @override
  List<Object?> get props => [
    noteId,
    heardByLabel,
    rewriteUnheard,
    proposedRewrite,
  ];
}

/// Result of asking the server to rewrite the concept.
sealed class ConceptRewriteResult extends Equatable {
  const ConceptRewriteResult();
}

/// The server wrote nothing. The founder still has to confirm a label.
class ConceptRewriteNeedsHearer extends ConceptRewriteResult {
  const ConceptRewriteNeedsHearer({
    this.suggestedHearer,
    this.proposedRewrite = const {},
  });

  final String? suggestedHearer;
  final Map<String, dynamic> proposedRewrite;

  @override
  List<Object?> get props => [suggestedHearer, proposedRewrite];
}

class ConceptRewriteApplied extends ConceptRewriteResult {
  const ConceptRewriteApplied({this.rewriteNote});

  final String? rewriteNote;

  @override
  List<Object?> get props => [rewriteNote];
}
