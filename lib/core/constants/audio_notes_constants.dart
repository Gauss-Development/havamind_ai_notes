/// Supabase Storage bucket id (must match migration SQL).
const String kAudioNotesBucketId = 'audio-notes';

/// Edge Function name in Supabase (Dashboard → Edge Functions).
/// Folder `process-audio-note` deploys as `process-audio-note` by default;
/// if you renamed the deployment (e.g. `OpenAI_Convecter`), set it here.
const String kProcessAudioNoteEdgeFunction = 'process-audio-note';

/// Edge Function for iterative plan refinement (GAU-94).
const String kRefinePlanEdgeFunction = 'refine-plan';

/// Maximum number of refinement rounds per plan (MVP, feature flag).
const int kMaxRefinementRounds = 5;

/// Maximum recording length in seconds (MVP). Technical ceiling — do not
/// treat this as the debrief hint; see [kDebriefSuggestedDurationSeconds].
const int kMaxRecordingDurationSeconds = 600;

/// UI hint for a customer-discovery / debrief take. Not a hard stop;
/// [kMaxRecordingDurationSeconds] remains the recorder ceiling.
const int kDebriefSuggestedDurationSeconds = 120; // ~2 min

/// Monthly usage limits per subscription tier (in seconds).
///
/// Free is 15 minutes so one short week-one loop survives testers:
/// 1 cold pitch + 2 debriefs (~2 min) + a voice gap + retry.
/// Preferred over a 4×2-minute count cap: both limit sources stay one
/// integer, no new limiter, and gpt-4o-mini cost for a 10-founder sprint
/// is negligible versus the extra product complexity.
/// MUST stay in sync with `TIER_MONTHLY_LIMIT_SECONDS` in
/// `supabase/functions/process-audio-note/index.ts`.
const int kFreeMonthlyLimitSeconds = 900; // 15 min
const int kBasicMonthlyLimitSeconds = 1200; // 20 min
const int kProMonthlyLimitSeconds = 3600; // 60 min
