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

/// Maximum recording length in seconds (MVP).
const int kMaxRecordingDurationSeconds = 600;

/// Monthly usage limits per subscription tier (in seconds).
const int kFreeMonthlyLimitSeconds = 300; // 5 min
const int kBasicMonthlyLimitSeconds = 1200; // 20 min
const int kProMonthlyLimitSeconds = 3600; // 60 min
