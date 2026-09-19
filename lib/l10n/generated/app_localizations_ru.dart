// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Аудио Заметки';

  @override
  String get signIn => 'Войти через Google';

  @override
  String get signInWithGoogle => 'Войти через Google';

  @override
  String get signInWithApple => 'Войти через Apple';

  @override
  String get signInWithEmail => 'Войти';

  @override
  String get signUp => 'Создать аккаунт';

  @override
  String get signInSubtitle => 'Войдите, чтобы сохранять заметки и анализ.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Пароль';

  @override
  String get orContinueWith => 'или продолжить через';

  @override
  String get checkEmailToConfirm =>
      'Проверьте почту, чтобы подтвердить аккаунт, затем войдите.';

  @override
  String get emailRequired => 'Введите email';

  @override
  String get invalidEmail => 'Введите корректный email';

  @override
  String get passwordRequired => 'Введите пароль';

  @override
  String get passwordTooShort => 'Пароль должен быть не короче 6 символов';

  @override
  String get showPassword => 'Показать пароль';

  @override
  String get hidePassword => 'Скрыть пароль';

  @override
  String get alreadyHaveAccount => 'Уже есть аккаунт? Войти';

  @override
  String get dontHaveAccount => 'Нет аккаунта? Создать';

  @override
  String get home => 'Главная';

  @override
  String get notes => 'Записи';

  @override
  String get favorites => 'Избранное';

  @override
  String get profile => 'Профиль';

  @override
  String get newNote => 'Новая запись';

  @override
  String get record => 'Записать';

  @override
  String get noNotesYet => 'Пока нет заметок';

  @override
  String get noNotesHint => 'Запишите голосовую заметку, и она появится здесь.';

  @override
  String get recordFirstNote => 'Записать первую заметку';

  @override
  String get recentNotes => 'Недавние записи';

  @override
  String notesCount(int count) {
    return '$count записей';
  }

  @override
  String get searchNotes => 'Поиск заметок...';

  @override
  String get searchNotesSemantics => 'Поиск по названию или транскрипту';

  @override
  String get clearSearch => 'Очистить поиск';

  @override
  String get searchFailed => 'Ошибка поиска';

  @override
  String get searchMatchInTranscript => 'В транскрипте';

  @override
  String searchNNotesPlaceholder(int count) {
    return 'Поиск по $count записям...';
  }

  @override
  String get results => 'Результаты';

  @override
  String found(int count) {
    return '$count найдено';
  }

  @override
  String get noMatchesFound => 'Ничего не найдено';

  @override
  String get noMatchesHint => 'Попробуйте более короткую фразу.';

  @override
  String get voiceMemo => 'Голосовая запись';

  @override
  String get readyToCapture => 'ГОТОВО К ЗАПИСИ';

  @override
  String get recording => 'ЗАПИСЬ';

  @override
  String get paused => 'ПАУЗА';

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get cancelRecording => 'Отменить запись';

  @override
  String get pauseRecording => 'Пауза';

  @override
  String get resumeRecording => 'Продолжить';

  @override
  String get finishRecording => 'Готово';

  @override
  String get submitForAnalysis => 'Отправить на анализ';

  @override
  String get transcribingAndAnalyzing => 'Транскрибация и анализ...';

  @override
  String get answerQuestion => 'Ответить на вопрос';

  @override
  String get refinePlan => 'Уточнить план';

  @override
  String get reviewRecording => 'ПРОВЕРКА ЗАПИСИ';

  @override
  String get uploading => 'ЗАГРУЗКА...';

  @override
  String get refiningYourPlan => 'УТОЧНЯЕМ ПЛАН...';

  @override
  String get done => 'ГОТОВО';

  @override
  String get limitReached => 'ЛИМИТ ИСЧЕРПАН';

  @override
  String get refine => 'Уточнить';

  @override
  String maxMinutes(int count) {
    return 'Максимум $count минут';
  }

  @override
  String debriefAboutMinutes(int count) {
    return 'Хватит примерно $count минут';
  }

  @override
  String get note => 'Заметка';

  @override
  String get deleteNote => 'Удалить заметку?';

  @override
  String get deleteNoteBody =>
      'Файл и запись будут удалены без восстановления.';

  @override
  String get delete => 'Удалить';

  @override
  String get deleteLocalFile => 'Удалить локальный файл?';

  @override
  String get deleteLocalFileBody =>
      'Аудио будет удалено с устройства. Анализ сохранится.';

  @override
  String get deleteFile => 'Удалить файл';

  @override
  String get summary => 'Обзор';

  @override
  String get analysis => 'Анализ';

  @override
  String get transcript => 'Транскрипт';

  @override
  String get noAnalysisAvailable => 'Анализ недоступен';

  @override
  String get transcriptNotAvailable => 'Транскрипт пока недоступен';

  @override
  String get rawTranscription => 'Транскрипция';

  @override
  String get editSummary => 'Редактировать описание';

  @override
  String get renameNote => 'Переименовать заметку';

  @override
  String get ventureIntelligence => 'Аналитика';

  @override
  String get marketPotential => 'Рыночный потенциал';

  @override
  String get technicalComplexity => 'Техническая сложность';

  @override
  String get localAudioSaved => 'Локальный аудиофайл сохранён на устройстве';

  @override
  String get audioNotAvailable => 'Аудиофайл недоступен';

  @override
  String get playbackError => 'Ошибка воспроизведения';

  @override
  String get copyToClipboard => 'Скопировать в буфер';

  @override
  String get share => 'Поделиться';

  @override
  String get copiedToClipboard => 'Скопировано в буфер';

  @override
  String get startingProcessing => 'Запуск обработки...';

  @override
  String get processingWait =>
      'Это может занять пару минут.\nСтраница обновится автоматически.';

  @override
  String get processingFailed => 'Обработка не удалась';

  @override
  String get retryHint =>
      'Попробуйте повторить — возможно, это временная проблема.';

  @override
  String get retryProcessing => 'Повторить обработку';

  @override
  String get followUpQuestions => 'ДОПОЛНИТЕЛЬНЫЕ ВОПРОСЫ';

  @override
  String get noData => 'Недостаточно данных';

  @override
  String get edit => 'Редактировать';

  @override
  String get theProblem => 'ПРОБЛЕМА';

  @override
  String get theSolution => 'РЕШЕНИЕ';

  @override
  String get targetAudience => 'ЦЕЛЕВАЯ АУДИТОРИЯ';

  @override
  String get businessModel => 'БИЗНЕС-МОДЕЛЬ';

  @override
  String get keyMetrics => 'КЛЮЧЕВЫЕ МЕТРИКИ';

  @override
  String get advantages => 'ПРЕИМУЩЕСТВА';

  @override
  String get risksAndGaps => 'РИСКИ И ПРОБЕЛЫ';

  @override
  String get preferences => 'НАСТРОЙКИ';

  @override
  String get appearance => 'Оформление';

  @override
  String get lightTheme => 'Светлая тема';

  @override
  String get darkTheme => 'Тёмная тема';

  @override
  String get light => 'Светлая';

  @override
  String get dark => 'Тёмная';

  @override
  String get notifications => 'Уведомления';

  @override
  String get smartAlertsOnly => 'Только важные уведомления';

  @override
  String get disabled => 'Отключено';

  @override
  String get language => 'Язык';

  @override
  String get englishUs => 'English (US)';

  @override
  String get logOut => 'Выйти';

  @override
  String get noFavoritesYet => 'Нет избранных';

  @override
  String get noFavoritesHint =>
      'Нажмите сердечко на заметке, чтобы добавить сюда.';

  @override
  String get retry => 'Повторить';

  @override
  String get today => 'СЕГОДНЯ';

  @override
  String get yesterday => 'ВЧЕРА';

  @override
  String get thisWeek => 'НА ЭТОЙ НЕДЕЛЕ';

  @override
  String get earlier => 'РАНЕЕ';

  @override
  String get goodMorning => 'Доброе утро';

  @override
  String get goodAfternoon => 'Добрый день';

  @override
  String get goodEvening => 'Добрый вечер';

  @override
  String get total => 'Всего';

  @override
  String get ready => 'Готово';

  @override
  String get processing => 'Обработка';

  @override
  String get statusDraft => 'Черновик';

  @override
  String get statusUploaded => 'Загружено';

  @override
  String get statusTranscribing => 'Транскрибация...';

  @override
  String get statusAnalyzing => 'AI-анализ...';

  @override
  String get statusReady => 'Готово';

  @override
  String get statusFailed => 'Ошибка';

  @override
  String get addTag => 'Добавить тег';

  @override
  String get paywallTitle => 'Живой тезис. Не ещё одна заметка';

  @override
  String get paywallSubtitle =>
      'Дебриф только что закончившегося разговора. Что изменилось, какая ставка ещё без улик и с кем говорить дальше.';

  @override
  String get paywallLimitReachedTitle => 'Минуты на этот месяц закончились';

  @override
  String get paywallLimitReachedSubtitle =>
      'Оформите подписку, чтобы продолжить дебрифы в этом месяце — не чтобы оценить ещё одну заметку.';

  @override
  String get paywallEverythingYouGet => 'Что вы получаете';

  @override
  String get paywallTierFree => 'Бесплатно';

  @override
  String get paywallTierBasic => 'Базовый';

  @override
  String get paywallTierPro => 'Pro';

  @override
  String get paywallTagFree => 'Один короткий цикл на первой неделе.';

  @override
  String get paywallTagBasic => 'Тезис плюс дебрифы недели.';

  @override
  String get paywallTagPro =>
      'Полный недельный цикл: версии, артефакт, следующий разговор.';

  @override
  String get paywallBillingMonthly => 'Месяц';

  @override
  String get paywallBillingAnnual => 'Год';

  @override
  String paywallSavePercent(int percent) {
    return 'Экономия $percent%';
  }

  @override
  String get paywallPerYear => '/ год';

  @override
  String get paywallPerMonth => '/ месяц';

  @override
  String paywallStartFor(String price) {
    return 'Начать за $price';
  }

  @override
  String get paywallContinue => 'Продолжить';

  @override
  String get paywallCurrent => 'ТЕКУЩИЙ';

  @override
  String get paywallRestore => 'Восстановить покупки';

  @override
  String get paywallTermsLine =>
      'Подписка продлевается автоматически. Отменить можно в настройках аккаунта.';

  @override
  String get paywallCouldNotLoad =>
      'Не удалось загрузить тарифы. Попробуйте снова.';

  @override
  String get paywallTryAgain => 'Попробовать снова';

  @override
  String get paywallNoActivePurchases =>
      'Нет активных покупок для восстановления.';

  @override
  String paywallMinutesPerMonth(int count) {
    return '$count минут записи в месяц';
  }

  @override
  String get paywallValueThesisTitle => 'Живой тезис';

  @override
  String get paywallValueThesisBody =>
      'Один тезис, который становится острее после каждого разговора — не новый разбор каждой заметки.';

  @override
  String get paywallValueDebriefTitle => 'Дебриф после звонка';

  @override
  String get paywallValueDebriefBody =>
      'Двухминутная запись после реального разговора. Что умерло, что подтвердилось, что всё ещё без улик.';

  @override
  String get paywallValueNextTitle => 'Следующий разговор';

  @override
  String get paywallValueNextBody =>
      'С кем говорить дальше и о чём не спрашивать.';

  @override
  String get paywallValueArtifactTitle => 'Недельный артефакт';

  @override
  String get paywallValueArtifactBody =>
      'Highlights, метрики и ask из корпуса недели — можно сразу отправить.';

  @override
  String get paywallFeatureThesisDebriefs => 'Живой тезис и дебрифы';

  @override
  String get paywallFeatureWeeklyArtifact =>
      'Недельный артефакт, который можно отправить';

  @override
  String get paywallFeatureThesisFromDebriefs =>
      'Тезис, который обновляется из дебрифов';

  @override
  String get paywallFeatureSearchTags => 'Поиск, теги и избранное';

  @override
  String get paywallFeatureEverythingBasic => 'Всё из Базового';

  @override
  String get paywallFeatureThesisVersions =>
      'Версии тезиса без потолка в 5 раундов';

  @override
  String get paywallFeatureArtifactAndScript =>
      'Недельный артефакт и скрипт следующего разговора';

  @override
  String get planGapsTitle => 'ЗАПОЛНИТЕ ПРОБЕЛЫ';

  @override
  String get planGapsHint =>
      'В этих разделах не хватает деталей. Нажмите на микрофон и ответьте короткой голосовой заметкой.';

  @override
  String get planReadinessTitle => 'ГОТОВНОСТЬ ПЛАНА';

  @override
  String planReadinessPercent(int percent) {
    return '$percent%';
  }

  @override
  String planReadinessSections(int completed, int total) {
    return '$completed из $total разделов';
  }

  @override
  String get planReadinessComplete => 'Все ключевые разделы заполнены.';

  @override
  String get planReadinessHint =>
      'Запишите короткие дополнения, чтобы усилить слабые разделы.';

  @override
  String get planReadinessHomeTitle => 'УСИЛЬТЕ ПЛАН';

  @override
  String planReadinessHomeBody(String title, int percent, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# раздела',
      many: '# разделов',
      few: '# раздела',
      one: '# раздел',
    );
    return '«$title» заполнен на $percent% — ещё $_temp0 без деталей.';
  }

  @override
  String get planReadinessUntitledNote => 'Без названия';

  @override
  String get answerByVoice => 'Ответить голосом';

  @override
  String get planGapAskProblem =>
      'Какую ключевую проблему вы решаете и кто от неё страдает больше всего?';

  @override
  String get planGapAskSolution =>
      'Как ваш продукт решает эту проблему и чем отличается от альтернатив?';

  @override
  String get planGapAskTargetAudience =>
      'Кто ваш идеальный клиент или ранний последователь?';

  @override
  String get planGapAskBusinessModel =>
      'Как вы будете зарабатывать — цена, модель или источники дохода?';

  @override
  String get planGapAskKeyMetrics =>
      'Какие метрики покажут, что вы движетесь в правильном направлении?';

  @override
  String get planGapAskAdvantages =>
      'В чём ваше нечестное преимущество или отличие от конкурентов?';

  @override
  String get planGapAskRisksGaps =>
      'Какие главные риски или пробелы в плане прямо сейчас?';

  @override
  String get planGapAskShortSummary =>
      'Кратко опишите стартап за одну минуту — elevator pitch.';

  @override
  String get planGapAskStartupTitle =>
      'Как бы вы назвали этот стартап или продукт?';

  @override
  String get continueRecording => 'Продолжить запись';

  @override
  String get founderPitchGuideTitle => 'Гид для питча';

  @override
  String get founderPitchGuideSubtitle =>
      'Говорите свободно — раскройте эти темы, и мы превратим заметку в структурированный план.';

  @override
  String get hideGuide => 'Скрыть подсказки';

  @override
  String get recordingGuideShowAllTopics => 'Показать все темы';

  @override
  String get recordingGuideShowLess => 'Свернуть';

  @override
  String tryCoveringTitle(String title) {
    return 'Попробуйте раскрыть: $title';
  }

  @override
  String get founderPromptProblemTitle => 'Проблема';

  @override
  String get founderPromptProblemHint => 'Какую боль вы решаете и для кого?';

  @override
  String get founderPromptAudienceTitle => 'Аудитория';

  @override
  String get founderPromptAudienceHint =>
      'Кто ваш идеальный клиент или ранний пользователь?';

  @override
  String get founderPromptSolutionTitle => 'Решение';

  @override
  String get founderPromptSolutionHint => 'Как продукт решает проблему иначе?';

  @override
  String get founderPromptMonetizationTitle => 'Монетизация';

  @override
  String get founderPromptMonetizationHint =>
      'Как будете зарабатывать — цена или модель?';

  @override
  String get founderPromptTractionTitle => 'Движение и следующие шаги';

  @override
  String get founderPromptTractionHint =>
      'Что уже пробовали и какой ближайший шаг?';

  @override
  String get recordingTemplateFounderPitch => 'Питч';

  @override
  String get recordingTemplateCustomerDiscovery => 'Customer discovery';

  @override
  String get recordingTemplateInvestorUpdate => 'Апдейт инвесторам';

  @override
  String get recordingOnboardingTitle => 'Перед записью';

  @override
  String get recordingOnboardingSubtitle =>
      'Выберите шаблон и пробегитесь по подсказкам — так заметка получится структурированной.';

  @override
  String get recordingOnboardingTemplateLabel => 'Тип записи';

  @override
  String get recordingOnboardingContinue => 'Перейти к записи';

  @override
  String get recordingOnboardingSkip => 'Пропустить';

  @override
  String get customerDiscoveryGuideTitle => 'Гид customer discovery';

  @override
  String get customerDiscoveryGuideSubtitle =>
      'Дебриф только что закончившегося разговора — хватит примерно двух минут. Обновим, что изменилось и с кем говорить дальше.';

  @override
  String get customerDiscoveryPromptWorkflowTitle => 'Ход интервью';

  @override
  String get customerDiscoveryPromptWorkflowHint =>
      'С кем говорили и что спрашивали?';

  @override
  String get customerDiscoveryPromptPainTitle => 'Боль и срочность';

  @override
  String get customerDiscoveryPromptPainHint =>
      'Какая проблема всплыла и насколько она острая сейчас?';

  @override
  String get customerDiscoveryPromptSubjectTitle => 'С кем говорили';

  @override
  String get customerDiscoveryPromptSubjectHint =>
      'Роль, сегмент или тип компании собеседника.';

  @override
  String get customerDiscoveryPromptInsightTitle => 'Ключевой инсайт';

  @override
  String get customerDiscoveryPromptInsightHint =>
      'Что удивило или изменило ваше понимание?';

  @override
  String get customerDiscoveryPromptNextTitle => 'Следующие интервью';

  @override
  String get customerDiscoveryPromptNextHint =>
      'С кем ещё поговорить и что проверить дальше?';

  @override
  String get investorUpdateGuideTitle => 'Гид для апдейта';

  @override
  String get investorUpdateGuideSubtitle =>
      'Честно опишите прогресс — мы оформим апдейт с метриками и запросом.';

  @override
  String get investorUpdatePromptHighlightsTitle => 'Главное';

  @override
  String get investorUpdatePromptHighlightsHint =>
      'Что вышло, закрылось или сдвинуло метрики за период?';

  @override
  String get investorUpdatePromptMetricsTitle => 'Метрики';

  @override
  String get investorUpdatePromptMetricsHint =>
      'Выручка, пользователи, рост, burn — цифры, которыми можно делиться.';

  @override
  String get investorUpdatePromptProductTitle => 'Продукт';

  @override
  String get investorUpdatePromptProductHint =>
      'Что изменилось в продукте или на roadmap?';

  @override
  String get investorUpdatePromptChallengesTitle => 'Сложности';

  @override
  String get investorUpdatePromptChallengesHint =>
      'Блокеры, промахи или риски, о которых стоит знать инвесторам.';

  @override
  String get investorUpdatePromptAskTitle => 'Запрос';

  @override
  String get investorUpdatePromptAskHint =>
      'Какая помощь, интро или решение нужны от инвесторов?';

  @override
  String get exportPlan => 'Экспорт плана…';

  @override
  String get exportPlanSubtitle =>
      'Скопируйте или отправьте оформленную версию анализа.';

  @override
  String get exportOnePager => 'One-pager';

  @override
  String get exportOnePagerHint => 'Markdown для документов или Notion.';

  @override
  String get exportPitchBullets => 'Пitch-буллеты';

  @override
  String get exportPitchBulletsHint =>
      'Короткий список для деков или сообщений.';

  @override
  String get exportEmailIntro => 'Email-интро';

  @override
  String get exportEmailIntroHint => 'Тёплый абзац для письма.';

  @override
  String get versionHistory => 'История версий';

  @override
  String get noVersionHistory => 'История версий пока пуста';

  @override
  String versionRound(int round) {
    return 'Раунд $round';
  }

  @override
  String get versionCurrent => 'ТЕКУЩАЯ';

  @override
  String versionRestoredFromRound(int round) {
    return 'Восстановлено из раунда $round';
  }

  @override
  String get versionChangesTitle => 'Что изменилось';

  @override
  String get versionFieldUpdated => 'Обновлено';

  @override
  String get versionFieldNew => 'Новое';

  @override
  String get versionFieldBefore => 'Было';

  @override
  String get versionFieldAfter => 'Стало';

  @override
  String get versionRestoreTitle => 'Восстановить версию?';

  @override
  String versionRestoreMessage(int round) {
    return 'Будет создана новая версия на основе раунда $round. История не удалится.';
  }

  @override
  String get restore => 'Восстановить';

  @override
  String get makeCurrentVersion => 'Сделать текущей версией';

  @override
  String get restoring => 'Восстановление…';

  @override
  String get planFieldStartupTitle => 'НАЗВАНИЕ СТАРТАПА';

  @override
  String get planFieldSummary => 'РЕЗЮМЕ';

  @override
  String get homeGreetingMorning => 'Доброе утро';

  @override
  String get homeGreetingAfternoon => 'Добрый день';

  @override
  String get homeGreetingEvening => 'Добрый вечер';

  @override
  String get homeGreetingFallback => 'основатель';

  @override
  String get thesisLivingEyebrow => 'ЖИВОЙ ТЕЗИС';

  @override
  String get thesisLivingSlogan => 'Живой тезис. Не заметка.';

  @override
  String get thesisUntitled => 'Ваш тезис';

  @override
  String get thesisReadinessTitle => 'ГОТОВНОСТЬ ТЕЗИСА';

  @override
  String get thesisReadinessComplete => 'Все ключевые ставки заполнены.';

  @override
  String get thesisUnbackedGapsLabel => 'ЕЩЁ БЕЗ УЛИК';

  @override
  String get thesisDebriefCta => 'Дебриф только что закончившегося разговора';

  @override
  String get thesisDebriefBody =>
      'Девяносто секунд, пока свежо. Обновим тезис, а не новую карточку.';

  @override
  String get thesisDebriefAction => 'Дебриф';

  @override
  String get thesisDebriefFab => 'Дебриф';

  @override
  String get thesisColdPitchCta => 'Расскажи идею две минуты';

  @override
  String get thesisColdPitchBody =>
      'Единственный честный вход, пока ещё не было разговора.';

  @override
  String get thesisColdPitchAction => 'Холодный питч';

  @override
  String get thesisCollectWeekAction => 'Собрать неделю';

  @override
  String get thesisCollectWeekSoon =>
      'Недельный экспорт будет следующим шагом.';

  @override
  String get thesisLastDebriefEyebrow => 'ПОСЛЕДНЕЕ';

  @override
  String get thesisLastDebriefTitle => 'Последний дебриф';

  @override
  String get thesisLoadError => 'Не удалось загрузить тезис';

  @override
  String get thesisRetry => 'Попробовать снова';
}
