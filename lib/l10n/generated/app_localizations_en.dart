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
}
