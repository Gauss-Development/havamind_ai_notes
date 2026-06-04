// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Audio Notes';

  @override
  String get signIn => 'Sign in with Google';

  @override
  String get signInSubtitle => 'Sign in to save your notes and analysis.';

  @override
  String get home => 'Home';

  @override
  String get notes => 'Notes';

  @override
  String get favorites => 'Favorites';

  @override
  String get profile => 'Profile';

  @override
  String get newNote => 'New Note';

  @override
  String get record => 'Record';

  @override
  String get noNotesYet => 'No notes yet';

  @override
  String get noNotesHint => 'Record a voice note and it will appear here.';

  @override
  String get recordFirstNote => 'Record your first note';

  @override
  String get recentNotes => 'Recent Notes';

  @override
  String notesCount(int count) {
    return '$count notes';
  }

  @override
  String get searchNotes => 'Search your notes...';

  @override
  String get searchNotesSemantics => 'Search notes by title or transcript';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get searchFailed => 'Search failed';

  @override
  String get searchMatchInTranscript => 'In transcript';

  @override
  String searchNNotesPlaceholder(int count) {
    return 'Search $count notes...';
  }

  @override
  String get results => 'Results';

  @override
  String found(int count) {
    return '$count found';
  }

  @override
  String get noMatchesFound => 'No matches found';

  @override
  String get noMatchesHint => 'Try a shorter phrase or check spelling.';

  @override
  String get voiceMemo => 'Voice Memo';

  @override
  String get readyToCapture => 'READY TO CAPTURE';

  @override
  String get recording => 'RECORDING';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get cancelRecording => 'Cancel recording';

  @override
  String get transcribingAndAnalyzing => 'Transcribing & analyzing...';

  @override
  String maxMinutes(int count) {
    return 'Max $count minutes';
  }

  @override
  String get note => 'Note';

  @override
  String get deleteNote => 'Delete note?';

  @override
  String get deleteNoteBody =>
      'The file and record will be permanently deleted.';

  @override
  String get delete => 'Delete';

  @override
  String get deleteLocalFile => 'Delete local file?';

  @override
  String get deleteLocalFileBody =>
      'The audio will be removed from this device. The analysis will remain.';

  @override
  String get deleteFile => 'Delete file';

  @override
  String get summary => 'Summary';

  @override
  String get analysis => 'Analysis';

  @override
  String get transcript => 'Transcript';

  @override
  String get noAnalysisAvailable => 'No analysis available';

  @override
  String get transcriptNotAvailable => 'Transcript not available yet';

  @override
  String get rawTranscription => 'Raw Transcription';

  @override
  String get editSummary => 'Edit summary';

  @override
  String get renameNote => 'Rename note';

  @override
  String get ventureIntelligence => 'Venture Intelligence';

  @override
  String get marketPotential => 'Market Potential';

  @override
  String get technicalComplexity => 'Technical Complexity';

  @override
  String get localAudioSaved => 'Local audio file saved on device';

  @override
  String get audioNotAvailable => 'Audio file not available';

  @override
  String get playbackError => 'Playback error';

  @override
  String get copyToClipboard => 'Copy to clipboard';

  @override
  String get share => 'Share';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get startingProcessing => 'Starting processing...';

  @override
  String get processingWait =>
      'This may take a couple of minutes.\nThe page will refresh automatically.';

  @override
  String get processingFailed => 'Processing failed';

  @override
  String get retryHint => 'Try again — this might be a temporary issue.';

  @override
  String get retryProcessing => 'Retry processing';

  @override
  String get followUpQuestions => 'FOLLOW-UP QUESTIONS';

  @override
  String get noData => 'No data available';

  @override
  String get edit => 'Edit';

  @override
  String get theProblem => 'THE PROBLEM';

  @override
  String get theSolution => 'THE SOLUTION';

  @override
  String get targetAudience => 'TARGET AUDIENCE';

  @override
  String get businessModel => 'BUSINESS MODEL';

  @override
  String get keyMetrics => 'KEY METRICS';

  @override
  String get advantages => 'ADVANTAGES';

  @override
  String get risksAndGaps => 'RISKS & GAPS';

  @override
  String get preferences => 'PREFERENCES';

  @override
  String get appearance => 'Appearance';

  @override
  String get lightTheme => 'Light theme';

  @override
  String get darkTheme => 'Dark theme';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get notifications => 'Notifications';

  @override
  String get smartAlertsOnly => 'Smart alerts only';

  @override
  String get disabled => 'Disabled';

  @override
  String get language => 'Language';

  @override
  String get englishUs => 'English (US)';

  @override
  String get logOut => 'Log Out';

  @override
  String get noFavoritesYet => 'No favorites yet';

  @override
  String get noFavoritesHint =>
      'Tap the heart icon on any note to save it here.';

  @override
  String get retry => 'Retry';

  @override
  String get today => 'TODAY';

  @override
  String get yesterday => 'YESTERDAY';

  @override
  String get thisWeek => 'THIS WEEK';

  @override
  String get earlier => 'EARLIER';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get total => 'Total';

  @override
  String get ready => 'Ready';

  @override
  String get processing => 'Processing';

  @override
  String get statusDraft => 'Draft';

  @override
  String get statusUploaded => 'Uploaded';

  @override
  String get statusTranscribing => 'Transcribing...';

  @override
  String get statusAnalyzing => 'Analyzing...';

  @override
  String get statusReady => 'Ready';

  @override
  String get statusFailed => 'Failed';

  @override
  String get addTag => 'Add tag';

  @override
  String get paywallTitle => 'Unlock your founder voice';

  @override
  String get paywallSubtitle =>
      'Capture every idea. Get AI-powered analysis on every note.';

  @override
  String get paywallLimitReachedTitle => 'You\'ve used all your minutes';

  @override
  String get paywallLimitReachedSubtitle =>
      'Upgrade to keep capturing ideas without interruption.';

  @override
  String get paywallEverythingYouGet => 'Everything you get';

  @override
  String get paywallTierFree => 'Free';

  @override
  String get paywallTierBasic => 'Basic';

  @override
  String get paywallTierPro => 'Pro';

  @override
  String get paywallTagFree => 'Try the essentials.';

  @override
  String get paywallTagBasic => 'For founders capturing daily ideas.';

  @override
  String get paywallTagPro => 'For serious idea-mappers and operators.';

  @override
  String get paywallBillingMonthly => 'Monthly';

  @override
  String get paywallBillingAnnual => 'Annual';

  @override
  String paywallSavePercent(int percent) {
    return 'Save $percent%';
  }

  @override
  String get paywallPerYear => '/ year';

  @override
  String get paywallPerMonth => '/ month';

  @override
  String paywallStartFor(String price) {
    return 'Start with $price';
  }

  @override
  String get paywallContinue => 'Continue';

  @override
  String get paywallCurrent => 'CURRENT';

  @override
  String get paywallRestore => 'Restore purchases';

  @override
  String get paywallTermsLine =>
      'Subscription auto-renews. Cancel anytime in your account settings.';

  @override
  String get paywallCouldNotLoad => 'Could not load plans. Please try again.';

  @override
  String get paywallTryAgain => 'Try again';

  @override
  String get paywallNoActivePurchases => 'No active purchases to restore.';

  @override
  String get planGapsTitle => 'FILL IN THE GAPS';

  @override
  String get planGapsHint =>
      'These sections need more detail. Tap the mic to answer with a short voice note.';

  @override
  String get planReadinessTitle => 'PLAN READINESS';

  @override
  String planReadinessPercent(int percent) {
    return '$percent%';
  }

  @override
  String planReadinessSections(int completed, int total) {
    return '$completed of $total sections';
  }

  @override
  String get planReadinessComplete => 'All core sections are filled in.';

  @override
  String get planReadinessHint =>
      'Record short follow-ups to strengthen weak sections.';

  @override
  String get planReadinessHomeTitle => 'STRENGTHEN YOUR PLAN';

  @override
  String planReadinessHomeBody(String title, int percent, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sections',
      one: '1 section',
    );
    return '$title is $percent% complete — $_temp0 still need detail.';
  }

  @override
  String get planReadinessUntitledNote => 'Untitled note';

  @override
  String get answerByVoice => 'Answer by voice';

  @override
  String get planGapAskProblem =>
      'What is the core problem you are solving, and who feels it most?';

  @override
  String get planGapAskSolution =>
      'How does your product solve this problem in a unique way?';

  @override
  String get planGapAskTargetAudience =>
      'Who is your ideal customer or early adopter?';

  @override
  String get planGapAskBusinessModel =>
      'How will you make money — pricing, model, or revenue streams?';

  @override
  String get planGapAskKeyMetrics =>
      'What metrics will you track to know you are making progress?';

  @override
  String get planGapAskAdvantages =>
      'What is your unfair advantage or differentiator?';

  @override
  String get planGapAskRisksGaps =>
      'What are the biggest risks or gaps in your plan right now?';

  @override
  String get planGapAskShortSummary =>
      'Give a one-minute elevator pitch summary of your startup.';

  @override
  String get planGapAskStartupTitle =>
      'What would you call this startup or product?';

  @override
  String get continueRecording => 'Continue recording';

  @override
  String get founderPitchGuideTitle => 'Founder pitch guide';

  @override
  String get founderPitchGuideSubtitle =>
      'Speak freely — hit these points and we will turn your memo into a structured plan.';

  @override
  String get hideGuide => 'Hide guide';

  @override
  String get recordingGuideShowAllTopics => 'Show all topics';

  @override
  String get recordingGuideShowLess => 'Show less';

  @override
  String tryCoveringTitle(String title) {
    return 'Try covering: $title';
  }

  @override
  String get founderPromptProblemTitle => 'Problem';

  @override
  String get founderPromptProblemHint =>
      'What pain are you solving, and for whom?';

  @override
  String get founderPromptAudienceTitle => 'Audience';

  @override
  String get founderPromptAudienceHint =>
      'Who is your ideal customer or early adopter?';

  @override
  String get founderPromptSolutionTitle => 'Solution';

  @override
  String get founderPromptSolutionHint =>
      'How does your product solve it differently?';

  @override
  String get founderPromptMonetizationTitle => 'Monetization';

  @override
  String get founderPromptMonetizationHint =>
      'How will you make money — pricing or model?';

  @override
  String get founderPromptTractionTitle => 'Traction & next steps';

  @override
  String get founderPromptTractionHint =>
      'What have you tried, and what is the immediate next move?';

  @override
  String get recordingTemplateFounderPitch => 'Founder pitch';

  @override
  String get recordingTemplateCustomerDiscovery => 'Customer discovery';

  @override
  String get recordingTemplateInvestorUpdate => 'Investor update';

  @override
  String get recordingOnboardingTitle => 'Before you record';

  @override
  String get recordingOnboardingSubtitle =>
      'Pick a template and skim the prompts so your note lands with the right structure.';

  @override
  String get recordingOnboardingTemplateLabel => 'Recording type';

  @override
  String get recordingOnboardingContinue => 'Continue to recording';

  @override
  String get recordingOnboardingSkip => 'Skip';

  @override
  String get customerDiscoveryGuideTitle => 'Customer discovery guide';

  @override
  String get customerDiscoveryGuideSubtitle =>
      'Capture what you learned from users — we will structure it into insights and next interviews.';

  @override
  String get customerDiscoveryPromptWorkflowTitle => 'Interview flow';

  @override
  String get customerDiscoveryPromptWorkflowHint =>
      'Who did you talk to and what did you ask?';

  @override
  String get customerDiscoveryPromptPainTitle => 'Pain & urgency';

  @override
  String get customerDiscoveryPromptPainHint =>
      'What problem came up, and how painful is it today?';

  @override
  String get customerDiscoveryPromptSubjectTitle => 'Who you spoke with';

  @override
  String get customerDiscoveryPromptSubjectHint =>
      'Role, segment, or company type of the interviewee.';

  @override
  String get customerDiscoveryPromptInsightTitle => 'Key insight';

  @override
  String get customerDiscoveryPromptInsightHint =>
      'What surprised you or changed your thinking?';

  @override
  String get customerDiscoveryPromptNextTitle => 'Next interviews';

  @override
  String get customerDiscoveryPromptNextHint =>
      'Who else should you talk to, and what will you validate next?';

  @override
  String get investorUpdateGuideTitle => 'Investor update guide';

  @override
  String get investorUpdateGuideSubtitle =>
      'Share progress honestly — we will turn your memo into a crisp update with metrics and asks.';

  @override
  String get investorUpdatePromptHighlightsTitle => 'Highlights';

  @override
  String get investorUpdatePromptHighlightsHint =>
      'What shipped, closed, or moved the needle this period?';

  @override
  String get investorUpdatePromptMetricsTitle => 'Metrics';

  @override
  String get investorUpdatePromptMetricsHint =>
      'Revenue, users, growth, burn — numbers you can share.';

  @override
  String get investorUpdatePromptProductTitle => 'Product';

  @override
  String get investorUpdatePromptProductHint =>
      'What changed in the product or roadmap?';

  @override
  String get investorUpdatePromptChallengesTitle => 'Challenges';

  @override
  String get investorUpdatePromptChallengesHint =>
      'Blockers, misses, or risks investors should know.';

  @override
  String get investorUpdatePromptAskTitle => 'The ask';

  @override
  String get investorUpdatePromptAskHint =>
      'What help, intro, or decision do you need from investors?';

  @override
  String get exportPlan => 'Export plan…';

  @override
  String get exportPlanSubtitle =>
      'Copy or share a formatted version of your analysis.';

  @override
  String get exportOnePager => 'One-pager';

  @override
  String get exportOnePagerHint => 'Markdown summary for docs or Notion.';

  @override
  String get exportPitchBullets => 'Pitch bullets';

  @override
  String get exportPitchBulletsHint =>
      'Short bullet list for decks or messages.';

  @override
  String get exportEmailIntro => 'Email intro';

  @override
  String get exportEmailIntroHint =>
      'Warm intro paragraph you can paste into email.';

  @override
  String get versionHistory => 'Version history';

  @override
  String get noVersionHistory => 'No version history yet';

  @override
  String versionRound(int round) {
    return 'Round $round';
  }

  @override
  String get versionCurrent => 'CURRENT';

  @override
  String versionRestoredFromRound(int round) {
    return 'Restored from round $round';
  }

  @override
  String get versionChangesTitle => 'What changed';

  @override
  String get versionFieldUpdated => 'Updated';

  @override
  String get versionFieldNew => 'New';

  @override
  String get versionFieldBefore => 'Before';

  @override
  String get versionFieldAfter => 'After';

  @override
  String get versionRestoreTitle => 'Restore version?';

  @override
  String versionRestoreMessage(int round) {
    return 'This will create a new version based on round $round. No history will be lost.';
  }

  @override
  String get restore => 'Restore';

  @override
  String get makeCurrentVersion => 'Make this the current version';

  @override
  String get restoring => 'Restoring…';

  @override
  String get planFieldStartupTitle => 'STARTUP TITLE';

  @override
  String get planFieldSummary => 'SUMMARY';
}
