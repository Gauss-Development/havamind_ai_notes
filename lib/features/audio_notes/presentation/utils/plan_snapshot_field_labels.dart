import 'package:sample/l10n/generated/app_localizations.dart';

/// Localized labels for plan snapshot field keys from refine-plan.
String planSnapshotFieldLabel(AppLocalizations l10n, String fieldKey) {
  switch (fieldKey) {
    case 'startup_title':
      return l10n.planFieldStartupTitle;
    case 'short_summary':
      return l10n.planFieldSummary;
    case 'problem':
      return l10n.theProblem;
    case 'solution':
      return l10n.theSolution;
    case 'target_audience':
      return l10n.targetAudience;
    case 'business_model':
      return l10n.businessModel;
    case 'key_metrics':
      return l10n.keyMetrics;
    case 'advantages':
      return l10n.advantages;
    case 'risks_gaps':
      return l10n.risksAndGaps;
    case 'market_potential_score':
      return l10n.marketPotential;
    case 'technical_complexity_score':
      return l10n.technicalComplexity;
    default:
      return fieldKey;
  }
}
