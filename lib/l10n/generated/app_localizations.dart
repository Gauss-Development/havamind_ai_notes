import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Audio Notes'**
  String get appTitle;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signIn;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save your notes and analysis.'**
  String get signInSubtitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @newNote.
  ///
  /// In en, this message translates to:
  /// **'New Note'**
  String get newNote;

  /// No description provided for @record.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get record;

  /// No description provided for @noNotesYet.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get noNotesYet;

  /// No description provided for @noNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Record a voice note and it will appear here.'**
  String get noNotesHint;

  /// No description provided for @recordFirstNote.
  ///
  /// In en, this message translates to:
  /// **'Record your first note'**
  String get recordFirstNote;

  /// No description provided for @recentNotes.
  ///
  /// In en, this message translates to:
  /// **'Recent Notes'**
  String get recentNotes;

  /// No description provided for @notesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} notes'**
  String notesCount(int count);

  /// No description provided for @searchNotes.
  ///
  /// In en, this message translates to:
  /// **'Search your notes...'**
  String get searchNotes;

  /// No description provided for @searchNotesSemantics.
  ///
  /// In en, this message translates to:
  /// **'Search notes by title or transcript'**
  String get searchNotesSemantics;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @searchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search failed'**
  String get searchFailed;

  /// No description provided for @searchMatchInTranscript.
  ///
  /// In en, this message translates to:
  /// **'In transcript'**
  String get searchMatchInTranscript;

  /// No description provided for @searchNNotesPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search {count} notes...'**
  String searchNNotesPlaceholder(int count);

  /// No description provided for @results.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get results;

  /// No description provided for @found.
  ///
  /// In en, this message translates to:
  /// **'{count} found'**
  String found(int count);

  /// No description provided for @noMatchesFound.
  ///
  /// In en, this message translates to:
  /// **'No matches found'**
  String get noMatchesFound;

  /// No description provided for @noMatchesHint.
  ///
  /// In en, this message translates to:
  /// **'Try a shorter phrase or check spelling.'**
  String get noMatchesHint;

  /// No description provided for @voiceMemo.
  ///
  /// In en, this message translates to:
  /// **'Voice Memo'**
  String get voiceMemo;

  /// No description provided for @readyToCapture.
  ///
  /// In en, this message translates to:
  /// **'READY TO CAPTURE'**
  String get readyToCapture;

  /// No description provided for @recording.
  ///
  /// In en, this message translates to:
  /// **'RECORDING'**
  String get recording;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancelRecording.
  ///
  /// In en, this message translates to:
  /// **'Cancel recording'**
  String get cancelRecording;

  /// No description provided for @transcribingAndAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Transcribing & analyzing...'**
  String get transcribingAndAnalyzing;

  /// No description provided for @maxMinutes.
  ///
  /// In en, this message translates to:
  /// **'Max {count} minutes'**
  String maxMinutes(int count);

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @deleteNote.
  ///
  /// In en, this message translates to:
  /// **'Delete note?'**
  String get deleteNote;

  /// No description provided for @deleteNoteBody.
  ///
  /// In en, this message translates to:
  /// **'The file and record will be permanently deleted.'**
  String get deleteNoteBody;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteLocalFile.
  ///
  /// In en, this message translates to:
  /// **'Delete local file?'**
  String get deleteLocalFile;

  /// No description provided for @deleteLocalFileBody.
  ///
  /// In en, this message translates to:
  /// **'The audio will be removed from this device. The analysis will remain.'**
  String get deleteLocalFileBody;

  /// No description provided for @deleteFile.
  ///
  /// In en, this message translates to:
  /// **'Delete file'**
  String get deleteFile;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @analysis.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get analysis;

  /// No description provided for @transcript.
  ///
  /// In en, this message translates to:
  /// **'Transcript'**
  String get transcript;

  /// No description provided for @noAnalysisAvailable.
  ///
  /// In en, this message translates to:
  /// **'No analysis available'**
  String get noAnalysisAvailable;

  /// No description provided for @transcriptNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Transcript not available yet'**
  String get transcriptNotAvailable;

  /// No description provided for @rawTranscription.
  ///
  /// In en, this message translates to:
  /// **'Raw Transcription'**
  String get rawTranscription;

  /// No description provided for @editSummary.
  ///
  /// In en, this message translates to:
  /// **'Edit summary'**
  String get editSummary;

  /// No description provided for @renameNote.
  ///
  /// In en, this message translates to:
  /// **'Rename note'**
  String get renameNote;

  /// No description provided for @ventureIntelligence.
  ///
  /// In en, this message translates to:
  /// **'Venture Intelligence'**
  String get ventureIntelligence;

  /// No description provided for @marketPotential.
  ///
  /// In en, this message translates to:
  /// **'Market Potential'**
  String get marketPotential;

  /// No description provided for @technicalComplexity.
  ///
  /// In en, this message translates to:
  /// **'Technical Complexity'**
  String get technicalComplexity;

  /// No description provided for @localAudioSaved.
  ///
  /// In en, this message translates to:
  /// **'Local audio file saved on device'**
  String get localAudioSaved;

  /// No description provided for @audioNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Audio file not available'**
  String get audioNotAvailable;

  /// No description provided for @playbackError.
  ///
  /// In en, this message translates to:
  /// **'Playback error'**
  String get playbackError;

  /// No description provided for @copyToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy to clipboard'**
  String get copyToClipboard;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @startingProcessing.
  ///
  /// In en, this message translates to:
  /// **'Starting processing...'**
  String get startingProcessing;

  /// No description provided for @processingWait.
  ///
  /// In en, this message translates to:
  /// **'This may take a couple of minutes.\nThe page will refresh automatically.'**
  String get processingWait;

  /// No description provided for @processingFailed.
  ///
  /// In en, this message translates to:
  /// **'Processing failed'**
  String get processingFailed;

  /// No description provided for @retryHint.
  ///
  /// In en, this message translates to:
  /// **'Try again — this might be a temporary issue.'**
  String get retryHint;

  /// No description provided for @retryProcessing.
  ///
  /// In en, this message translates to:
  /// **'Retry processing'**
  String get retryProcessing;

  /// No description provided for @followUpQuestions.
  ///
  /// In en, this message translates to:
  /// **'FOLLOW-UP QUESTIONS'**
  String get followUpQuestions;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @theProblem.
  ///
  /// In en, this message translates to:
  /// **'THE PROBLEM'**
  String get theProblem;

  /// No description provided for @theSolution.
  ///
  /// In en, this message translates to:
  /// **'THE SOLUTION'**
  String get theSolution;

  /// No description provided for @targetAudience.
  ///
  /// In en, this message translates to:
  /// **'TARGET AUDIENCE'**
  String get targetAudience;

  /// No description provided for @businessModel.
  ///
  /// In en, this message translates to:
  /// **'BUSINESS MODEL'**
  String get businessModel;

  /// No description provided for @keyMetrics.
  ///
  /// In en, this message translates to:
  /// **'KEY METRICS'**
  String get keyMetrics;

  /// No description provided for @advantages.
  ///
  /// In en, this message translates to:
  /// **'ADVANTAGES'**
  String get advantages;

  /// No description provided for @risksAndGaps.
  ///
  /// In en, this message translates to:
  /// **'RISKS & GAPS'**
  String get risksAndGaps;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'PREFERENCES'**
  String get preferences;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light theme'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get darkTheme;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @smartAlertsOnly.
  ///
  /// In en, this message translates to:
  /// **'Smart alerts only'**
  String get smartAlertsOnly;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @englishUs.
  ///
  /// In en, this message translates to:
  /// **'English (US)'**
  String get englishUs;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @noFavoritesYet.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get noFavoritesYet;

  /// No description provided for @noFavoritesHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart icon on any note to save it here.'**
  String get noFavoritesHint;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'YESTERDAY'**
  String get yesterday;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'THIS WEEK'**
  String get thisWeek;

  /// No description provided for @earlier.
  ///
  /// In en, this message translates to:
  /// **'EARLIER'**
  String get earlier;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processing;

  /// No description provided for @statusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get statusDraft;

  /// No description provided for @statusUploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get statusUploaded;

  /// No description provided for @statusTranscribing.
  ///
  /// In en, this message translates to:
  /// **'Transcribing...'**
  String get statusTranscribing;

  /// No description provided for @statusAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get statusAnalyzing;

  /// No description provided for @statusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get statusReady;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get statusFailed;

  /// No description provided for @addTag.
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get addTag;

  /// No description provided for @paywallTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock your founder voice'**
  String get paywallTitle;

  /// No description provided for @paywallSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Capture every idea. Get AI-powered analysis on every note.'**
  String get paywallSubtitle;

  /// No description provided for @paywallLimitReachedTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used all your minutes'**
  String get paywallLimitReachedTitle;

  /// No description provided for @paywallLimitReachedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to keep capturing ideas without interruption.'**
  String get paywallLimitReachedSubtitle;

  /// No description provided for @paywallEverythingYouGet.
  ///
  /// In en, this message translates to:
  /// **'Everything you get'**
  String get paywallEverythingYouGet;

  /// No description provided for @paywallTierFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get paywallTierFree;

  /// No description provided for @paywallTierBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get paywallTierBasic;

  /// No description provided for @paywallTierPro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get paywallTierPro;

  /// No description provided for @paywallTagFree.
  ///
  /// In en, this message translates to:
  /// **'Try the essentials.'**
  String get paywallTagFree;

  /// No description provided for @paywallTagBasic.
  ///
  /// In en, this message translates to:
  /// **'For founders capturing daily ideas.'**
  String get paywallTagBasic;

  /// No description provided for @paywallTagPro.
  ///
  /// In en, this message translates to:
  /// **'For serious idea-mappers and operators.'**
  String get paywallTagPro;

  /// No description provided for @paywallBillingMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get paywallBillingMonthly;

  /// No description provided for @paywallBillingAnnual.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get paywallBillingAnnual;

  /// No description provided for @paywallSavePercent.
  ///
  /// In en, this message translates to:
  /// **'Save {percent}%'**
  String paywallSavePercent(int percent);

  /// No description provided for @paywallPerYear.
  ///
  /// In en, this message translates to:
  /// **'/ year'**
  String get paywallPerYear;

  /// No description provided for @paywallPerMonth.
  ///
  /// In en, this message translates to:
  /// **'/ month'**
  String get paywallPerMonth;

  /// No description provided for @paywallStartFor.
  ///
  /// In en, this message translates to:
  /// **'Start with {price}'**
  String paywallStartFor(String price);

  /// No description provided for @paywallContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get paywallContinue;

  /// No description provided for @paywallCurrent.
  ///
  /// In en, this message translates to:
  /// **'CURRENT'**
  String get paywallCurrent;

  /// No description provided for @paywallRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get paywallRestore;

  /// No description provided for @paywallTermsLine.
  ///
  /// In en, this message translates to:
  /// **'Subscription auto-renews. Cancel anytime in your account settings.'**
  String get paywallTermsLine;

  /// No description provided for @paywallCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load plans. Please try again.'**
  String get paywallCouldNotLoad;

  /// No description provided for @paywallTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get paywallTryAgain;

  /// No description provided for @paywallNoActivePurchases.
  ///
  /// In en, this message translates to:
  /// **'No active purchases to restore.'**
  String get paywallNoActivePurchases;

  /// No description provided for @planGapsTitle.
  ///
  /// In en, this message translates to:
  /// **'FILL IN THE GAPS'**
  String get planGapsTitle;

  /// No description provided for @planGapsHint.
  ///
  /// In en, this message translates to:
  /// **'These sections need more detail. Tap the mic to answer with a short voice note.'**
  String get planGapsHint;

  /// No description provided for @planReadinessTitle.
  ///
  /// In en, this message translates to:
  /// **'PLAN READINESS'**
  String get planReadinessTitle;

  /// No description provided for @planReadinessPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String planReadinessPercent(int percent);

  /// No description provided for @planReadinessSections.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} sections'**
  String planReadinessSections(int completed, int total);

  /// No description provided for @planReadinessComplete.
  ///
  /// In en, this message translates to:
  /// **'All core sections are filled in.'**
  String get planReadinessComplete;

  /// No description provided for @planReadinessHint.
  ///
  /// In en, this message translates to:
  /// **'Record short follow-ups to strengthen weak sections.'**
  String get planReadinessHint;

  /// No description provided for @planReadinessHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'STRENGTHEN YOUR PLAN'**
  String get planReadinessHomeTitle;

  /// No description provided for @planReadinessHomeBody.
  ///
  /// In en, this message translates to:
  /// **'{title} is {percent}% complete — {count, plural, =1{1 section} other{{count} sections}} still need detail.'**
  String planReadinessHomeBody(String title, int percent, int count);

  /// No description provided for @planReadinessUntitledNote.
  ///
  /// In en, this message translates to:
  /// **'Untitled note'**
  String get planReadinessUntitledNote;

  /// No description provided for @answerByVoice.
  ///
  /// In en, this message translates to:
  /// **'Answer by voice'**
  String get answerByVoice;

  /// No description provided for @planGapAskProblem.
  ///
  /// In en, this message translates to:
  /// **'What is the core problem you are solving, and who feels it most?'**
  String get planGapAskProblem;

  /// No description provided for @planGapAskSolution.
  ///
  /// In en, this message translates to:
  /// **'How does your product solve this problem in a unique way?'**
  String get planGapAskSolution;

  /// No description provided for @planGapAskTargetAudience.
  ///
  /// In en, this message translates to:
  /// **'Who is your ideal customer or early adopter?'**
  String get planGapAskTargetAudience;

  /// No description provided for @planGapAskBusinessModel.
  ///
  /// In en, this message translates to:
  /// **'How will you make money — pricing, model, or revenue streams?'**
  String get planGapAskBusinessModel;

  /// No description provided for @planGapAskKeyMetrics.
  ///
  /// In en, this message translates to:
  /// **'What metrics will you track to know you are making progress?'**
  String get planGapAskKeyMetrics;

  /// No description provided for @planGapAskAdvantages.
  ///
  /// In en, this message translates to:
  /// **'What is your unfair advantage or differentiator?'**
  String get planGapAskAdvantages;

  /// No description provided for @planGapAskRisksGaps.
  ///
  /// In en, this message translates to:
  /// **'What are the biggest risks or gaps in your plan right now?'**
  String get planGapAskRisksGaps;

  /// No description provided for @planGapAskShortSummary.
  ///
  /// In en, this message translates to:
  /// **'Give a one-minute elevator pitch summary of your startup.'**
  String get planGapAskShortSummary;

  /// No description provided for @planGapAskStartupTitle.
  ///
  /// In en, this message translates to:
  /// **'What would you call this startup or product?'**
  String get planGapAskStartupTitle;

  /// No description provided for @continueRecording.
  ///
  /// In en, this message translates to:
  /// **'Continue recording'**
  String get continueRecording;

  /// No description provided for @founderPitchGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Founder pitch guide'**
  String get founderPitchGuideTitle;

  /// No description provided for @founderPitchGuideSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Speak freely — hit these points and we will turn your memo into a structured plan.'**
  String get founderPitchGuideSubtitle;

  /// No description provided for @hideGuide.
  ///
  /// In en, this message translates to:
  /// **'Hide guide'**
  String get hideGuide;

  /// No description provided for @recordingGuideShowAllTopics.
  ///
  /// In en, this message translates to:
  /// **'Show all topics'**
  String get recordingGuideShowAllTopics;

  /// No description provided for @recordingGuideShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get recordingGuideShowLess;

  /// No description provided for @tryCoveringTitle.
  ///
  /// In en, this message translates to:
  /// **'Try covering: {title}'**
  String tryCoveringTitle(String title);

  /// No description provided for @founderPromptProblemTitle.
  ///
  /// In en, this message translates to:
  /// **'Problem'**
  String get founderPromptProblemTitle;

  /// No description provided for @founderPromptProblemHint.
  ///
  /// In en, this message translates to:
  /// **'What pain are you solving, and for whom?'**
  String get founderPromptProblemHint;

  /// No description provided for @founderPromptAudienceTitle.
  ///
  /// In en, this message translates to:
  /// **'Audience'**
  String get founderPromptAudienceTitle;

  /// No description provided for @founderPromptAudienceHint.
  ///
  /// In en, this message translates to:
  /// **'Who is your ideal customer or early adopter?'**
  String get founderPromptAudienceHint;

  /// No description provided for @founderPromptSolutionTitle.
  ///
  /// In en, this message translates to:
  /// **'Solution'**
  String get founderPromptSolutionTitle;

  /// No description provided for @founderPromptSolutionHint.
  ///
  /// In en, this message translates to:
  /// **'How does your product solve it differently?'**
  String get founderPromptSolutionHint;

  /// No description provided for @founderPromptMonetizationTitle.
  ///
  /// In en, this message translates to:
  /// **'Monetization'**
  String get founderPromptMonetizationTitle;

  /// No description provided for @founderPromptMonetizationHint.
  ///
  /// In en, this message translates to:
  /// **'How will you make money — pricing or model?'**
  String get founderPromptMonetizationHint;

  /// No description provided for @founderPromptTractionTitle.
  ///
  /// In en, this message translates to:
  /// **'Traction & next steps'**
  String get founderPromptTractionTitle;

  /// No description provided for @founderPromptTractionHint.
  ///
  /// In en, this message translates to:
  /// **'What have you tried, and what is the immediate next move?'**
  String get founderPromptTractionHint;

  /// No description provided for @recordingTemplateFounderPitch.
  ///
  /// In en, this message translates to:
  /// **'Founder pitch'**
  String get recordingTemplateFounderPitch;

  /// No description provided for @recordingTemplateCustomerDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Customer discovery'**
  String get recordingTemplateCustomerDiscovery;

  /// No description provided for @recordingTemplateInvestorUpdate.
  ///
  /// In en, this message translates to:
  /// **'Investor update'**
  String get recordingTemplateInvestorUpdate;

  /// No description provided for @recordingOnboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Before you record'**
  String get recordingOnboardingTitle;

  /// No description provided for @recordingOnboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a template and skim the prompts so your note lands with the right structure.'**
  String get recordingOnboardingSubtitle;

  /// No description provided for @recordingOnboardingTemplateLabel.
  ///
  /// In en, this message translates to:
  /// **'Recording type'**
  String get recordingOnboardingTemplateLabel;

  /// No description provided for @recordingOnboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue to recording'**
  String get recordingOnboardingContinue;

  /// No description provided for @recordingOnboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get recordingOnboardingSkip;

  /// No description provided for @customerDiscoveryGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer discovery guide'**
  String get customerDiscoveryGuideTitle;

  /// No description provided for @customerDiscoveryGuideSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Capture what you learned from users — we will structure it into insights and next interviews.'**
  String get customerDiscoveryGuideSubtitle;

  /// No description provided for @customerDiscoveryPromptWorkflowTitle.
  ///
  /// In en, this message translates to:
  /// **'Interview flow'**
  String get customerDiscoveryPromptWorkflowTitle;

  /// No description provided for @customerDiscoveryPromptWorkflowHint.
  ///
  /// In en, this message translates to:
  /// **'Who did you talk to and what did you ask?'**
  String get customerDiscoveryPromptWorkflowHint;

  /// No description provided for @customerDiscoveryPromptPainTitle.
  ///
  /// In en, this message translates to:
  /// **'Pain & urgency'**
  String get customerDiscoveryPromptPainTitle;

  /// No description provided for @customerDiscoveryPromptPainHint.
  ///
  /// In en, this message translates to:
  /// **'What problem came up, and how painful is it today?'**
  String get customerDiscoveryPromptPainHint;

  /// No description provided for @customerDiscoveryPromptSubjectTitle.
  ///
  /// In en, this message translates to:
  /// **'Who you spoke with'**
  String get customerDiscoveryPromptSubjectTitle;

  /// No description provided for @customerDiscoveryPromptSubjectHint.
  ///
  /// In en, this message translates to:
  /// **'Role, segment, or company type of the interviewee.'**
  String get customerDiscoveryPromptSubjectHint;

  /// No description provided for @customerDiscoveryPromptInsightTitle.
  ///
  /// In en, this message translates to:
  /// **'Key insight'**
  String get customerDiscoveryPromptInsightTitle;

  /// No description provided for @customerDiscoveryPromptInsightHint.
  ///
  /// In en, this message translates to:
  /// **'What surprised you or changed your thinking?'**
  String get customerDiscoveryPromptInsightHint;

  /// No description provided for @customerDiscoveryPromptNextTitle.
  ///
  /// In en, this message translates to:
  /// **'Next interviews'**
  String get customerDiscoveryPromptNextTitle;

  /// No description provided for @customerDiscoveryPromptNextHint.
  ///
  /// In en, this message translates to:
  /// **'Who else should you talk to, and what will you validate next?'**
  String get customerDiscoveryPromptNextHint;

  /// No description provided for @investorUpdateGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Investor update guide'**
  String get investorUpdateGuideTitle;

  /// No description provided for @investorUpdateGuideSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share progress honestly — we will turn your memo into a crisp update with metrics and asks.'**
  String get investorUpdateGuideSubtitle;

  /// No description provided for @investorUpdatePromptHighlightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get investorUpdatePromptHighlightsTitle;

  /// No description provided for @investorUpdatePromptHighlightsHint.
  ///
  /// In en, this message translates to:
  /// **'What shipped, closed, or moved the needle this period?'**
  String get investorUpdatePromptHighlightsHint;

  /// No description provided for @investorUpdatePromptMetricsTitle.
  ///
  /// In en, this message translates to:
  /// **'Metrics'**
  String get investorUpdatePromptMetricsTitle;

  /// No description provided for @investorUpdatePromptMetricsHint.
  ///
  /// In en, this message translates to:
  /// **'Revenue, users, growth, burn — numbers you can share.'**
  String get investorUpdatePromptMetricsHint;

  /// No description provided for @investorUpdatePromptProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get investorUpdatePromptProductTitle;

  /// No description provided for @investorUpdatePromptProductHint.
  ///
  /// In en, this message translates to:
  /// **'What changed in the product or roadmap?'**
  String get investorUpdatePromptProductHint;

  /// No description provided for @investorUpdatePromptChallengesTitle.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get investorUpdatePromptChallengesTitle;

  /// No description provided for @investorUpdatePromptChallengesHint.
  ///
  /// In en, this message translates to:
  /// **'Blockers, misses, or risks investors should know.'**
  String get investorUpdatePromptChallengesHint;

  /// No description provided for @investorUpdatePromptAskTitle.
  ///
  /// In en, this message translates to:
  /// **'The ask'**
  String get investorUpdatePromptAskTitle;

  /// No description provided for @investorUpdatePromptAskHint.
  ///
  /// In en, this message translates to:
  /// **'What help, intro, or decision do you need from investors?'**
  String get investorUpdatePromptAskHint;

  /// No description provided for @exportPlan.
  ///
  /// In en, this message translates to:
  /// **'Export plan…'**
  String get exportPlan;

  /// No description provided for @exportPlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Copy or share a formatted version of your analysis.'**
  String get exportPlanSubtitle;

  /// No description provided for @exportOnePager.
  ///
  /// In en, this message translates to:
  /// **'One-pager'**
  String get exportOnePager;

  /// No description provided for @exportOnePagerHint.
  ///
  /// In en, this message translates to:
  /// **'Markdown summary for docs or Notion.'**
  String get exportOnePagerHint;

  /// No description provided for @exportPitchBullets.
  ///
  /// In en, this message translates to:
  /// **'Pitch bullets'**
  String get exportPitchBullets;

  /// No description provided for @exportPitchBulletsHint.
  ///
  /// In en, this message translates to:
  /// **'Short bullet list for decks or messages.'**
  String get exportPitchBulletsHint;

  /// No description provided for @exportEmailIntro.
  ///
  /// In en, this message translates to:
  /// **'Email intro'**
  String get exportEmailIntro;

  /// No description provided for @exportEmailIntroHint.
  ///
  /// In en, this message translates to:
  /// **'Warm intro paragraph you can paste into email.'**
  String get exportEmailIntroHint;

  /// No description provided for @versionHistory.
  ///
  /// In en, this message translates to:
  /// **'Version history'**
  String get versionHistory;

  /// No description provided for @noVersionHistory.
  ///
  /// In en, this message translates to:
  /// **'No version history yet'**
  String get noVersionHistory;

  /// No description provided for @versionRound.
  ///
  /// In en, this message translates to:
  /// **'Round {round}'**
  String versionRound(int round);

  /// No description provided for @versionCurrent.
  ///
  /// In en, this message translates to:
  /// **'CURRENT'**
  String get versionCurrent;

  /// No description provided for @versionRestoredFromRound.
  ///
  /// In en, this message translates to:
  /// **'Restored from round {round}'**
  String versionRestoredFromRound(int round);

  /// No description provided for @versionChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'What changed'**
  String get versionChangesTitle;

  /// No description provided for @versionFieldUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get versionFieldUpdated;

  /// No description provided for @versionFieldNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get versionFieldNew;

  /// No description provided for @versionFieldBefore.
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get versionFieldBefore;

  /// No description provided for @versionFieldAfter.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get versionFieldAfter;

  /// No description provided for @versionRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore version?'**
  String get versionRestoreTitle;

  /// No description provided for @versionRestoreMessage.
  ///
  /// In en, this message translates to:
  /// **'This will create a new version based on round {round}. No history will be lost.'**
  String versionRestoreMessage(int round);

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @makeCurrentVersion.
  ///
  /// In en, this message translates to:
  /// **'Make this the current version'**
  String get makeCurrentVersion;

  /// No description provided for @restoring.
  ///
  /// In en, this message translates to:
  /// **'Restoring…'**
  String get restoring;

  /// No description provided for @planFieldStartupTitle.
  ///
  /// In en, this message translates to:
  /// **'STARTUP TITLE'**
  String get planFieldStartupTitle;

  /// No description provided for @planFieldSummary.
  ///
  /// In en, this message translates to:
  /// **'SUMMARY'**
  String get planFieldSummary;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
