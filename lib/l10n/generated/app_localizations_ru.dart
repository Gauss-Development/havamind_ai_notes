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
  String get signInSubtitle => 'Войдите, чтобы сохранять заметки и анализ.';

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
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get cancelRecording => 'Отменить запись';

  @override
  String get transcribingAndAnalyzing => 'Транскрибация и анализ...';

  @override
  String maxMinutes(int count) {
    return 'Максимум $count минут';
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
  String get paywallTitle => 'Откройте голос основателя';

  @override
  String get paywallSubtitle =>
      'Фиксируйте каждую идею. ИИ-анализ для каждой заметки.';

  @override
  String get paywallLimitReachedTitle => 'Минуты на этот месяц закончились';

  @override
  String get paywallLimitReachedSubtitle =>
      'Оформите подписку, чтобы продолжить без ограничений.';

  @override
  String get paywallEverythingYouGet => 'Что вы получаете';

  @override
  String get paywallTierFree => 'Бесплатно';

  @override
  String get paywallTierBasic => 'Базовый';

  @override
  String get paywallTierPro => 'Pro';

  @override
  String get paywallTagFree => 'Базовый набор для пробы.';

  @override
  String get paywallTagBasic =>
      'Для основателей, которые фиксируют идеи каждый день.';

  @override
  String get paywallTagPro =>
      'Для серьёзной работы со стратегией и аналитикой.';

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
}
