import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Days Reminder'**
  String get appTitle;

  /// No description provided for @appTitleChinese.
  ///
  /// In en, this message translates to:
  /// **'倒数日历'**
  String get appTitleChinese;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'A countdown calendar app for tracking important events and dates'**
  String get appDescription;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get languageDesc;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notification Reminders'**
  String get notificationsEnabled;

  /// No description provided for @notificationsEnabledDesc.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications when events are due'**
  String get notificationsEnabledDesc;

  /// No description provided for @advanceReminder.
  ///
  /// In en, this message translates to:
  /// **'Advance Reminder'**
  String get advanceReminder;

  /// No description provided for @advanceReminderDesc.
  ///
  /// In en, this message translates to:
  /// **'Remind {days} days before event'**
  String advanceReminderDesc(Object days);

  /// No description provided for @advanceReminderDays.
  ///
  /// In en, this message translates to:
  /// **'Advance Days'**
  String get advanceReminderDays;

  /// No description provided for @advanceReminderDaysDesc.
  ///
  /// In en, this message translates to:
  /// **'Set the number of days to remind in advance'**
  String get advanceReminderDaysDesc;

  /// No description provided for @privacyAndPermissions.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Permissions'**
  String get privacyAndPermissions;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @privacyPolicyDesc.
  ///
  /// In en, this message translates to:
  /// **'View app privacy policy and terms of use'**
  String get privacyPolicyDesc;

  /// No description provided for @notificationPermissions.
  ///
  /// In en, this message translates to:
  /// **'Notification Permissions'**
  String get notificationPermissions;

  /// No description provided for @notificationPermissionsDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage notification permission settings'**
  String get notificationPermissionsDesc;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get aboutApp;

  /// No description provided for @aboutAppDesc.
  ///
  /// In en, this message translates to:
  /// **'Version information and feature introduction'**
  String get aboutAppDesc;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @feedbackDesc.
  ///
  /// In en, this message translates to:
  /// **'Send us feedback or suggestions'**
  String get feedbackDesc;

  /// No description provided for @dataStatistics.
  ///
  /// In en, this message translates to:
  /// **'Data Statistics'**
  String get dataStatistics;

  /// No description provided for @totalEvents.
  ///
  /// In en, this message translates to:
  /// **'Total {count} events'**
  String totalEvents(Object count);

  /// No description provided for @dataBackup.
  ///
  /// In en, this message translates to:
  /// **'Data Backup'**
  String get dataBackup;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get importData;

  /// No description provided for @clearAllData.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get clearAllData;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// No description provided for @confirmDeleteDesc.
  ///
  /// In en, this message translates to:
  /// **'This action will delete all event data and cannot be undone.'**
  String get confirmDeleteDesc;

  /// No description provided for @currentEvents.
  ///
  /// In en, this message translates to:
  /// **'Current total: {count} events'**
  String currentEvents(Object count);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Exported to: {path}'**
  String exportSuccess(Object path);

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(Object error);

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Data imported successfully'**
  String get importSuccess;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Data import failed: {error}'**
  String importFailed(Object error);

  /// No description provided for @allDataDeleted.
  ///
  /// In en, this message translates to:
  /// **'All data has been deleted'**
  String get allDataDeleted;

  /// No description provided for @pleaseEnableNotificationPermission.
  ///
  /// In en, this message translates to:
  /// **'Please enable notification permissions in system settings'**
  String get pleaseEnableNotificationPermission;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get yesterday;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String daysAgo(Object days);

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @noEventsYet.
  ///
  /// In en, this message translates to:
  /// **'No events yet'**
  String get noEventsYet;

  /// No description provided for @noEventsYetDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap the + button in the top right to add one'**
  String get noEventsYetDesc;

  /// No description provided for @featuredEvent.
  ///
  /// In en, this message translates to:
  /// **'Featured Event'**
  String get featuredEvent;

  /// No description provided for @daysRemaining.
  ///
  /// In en, this message translates to:
  /// **'{days} days remaining'**
  String daysRemaining(Object days);

  /// No description provided for @daysOverdue.
  ///
  /// In en, this message translates to:
  /// **'{days} days overdue'**
  String daysOverdue(Object days);

  /// No description provided for @event.
  ///
  /// In en, this message translates to:
  /// **'event'**
  String get event;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'events'**
  String get events;

  /// No description provided for @addEvent.
  ///
  /// In en, this message translates to:
  /// **'Add Event'**
  String get addEvent;

  /// No description provided for @editEvent.
  ///
  /// In en, this message translates to:
  /// **'Edit Event'**
  String get editEvent;

  /// No description provided for @eventTitle.
  ///
  /// In en, this message translates to:
  /// **'Event Title'**
  String get eventTitle;

  /// No description provided for @eventTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Enter event title'**
  String get eventTitleHint;

  /// No description provided for @eventDate.
  ///
  /// In en, this message translates to:
  /// **'Event Date'**
  String get eventDate;

  /// No description provided for @eventType.
  ///
  /// In en, this message translates to:
  /// **'Event Type'**
  String get eventType;

  /// No description provided for @countdown.
  ///
  /// In en, this message translates to:
  /// **'Countdown'**
  String get countdown;

  /// No description provided for @pastEvent.
  ///
  /// In en, this message translates to:
  /// **'Past Event'**
  String get pastEvent;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'Optional notes'**
  String get notesHint;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @deleteEvent.
  ///
  /// In en, this message translates to:
  /// **'Delete Event'**
  String get deleteEvent;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequired;

  /// No description provided for @dateRequired.
  ///
  /// In en, this message translates to:
  /// **'Date is required'**
  String get dateRequired;

  /// No description provided for @eventDetail.
  ///
  /// In en, this message translates to:
  /// **'Event Details'**
  String get eventDetail;

  /// No description provided for @eventKindBirthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get eventKindBirthday;

  /// No description provided for @eventKindAnniversary.
  ///
  /// In en, this message translates to:
  /// **'Anniversary'**
  String get eventKindAnniversary;

  /// No description provided for @eventKindCountdown.
  ///
  /// In en, this message translates to:
  /// **'Countdown'**
  String get eventKindCountdown;

  /// No description provided for @remainingDays.
  ///
  /// In en, this message translates to:
  /// **'Remaining days'**
  String get remainingDays;

  /// No description provided for @overdueDays.
  ///
  /// In en, this message translates to:
  /// **'Overdue days'**
  String get overdueDays;

  /// No description provided for @confirmDeleteEvent.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDeleteEvent;

  /// No description provided for @confirmDeleteEventDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"? This action cannot be undone.'**
  String confirmDeleteEventDesc(Object title);

  /// No description provided for @selectSolarDate.
  ///
  /// In en, this message translates to:
  /// **'Select Solar Date'**
  String get selectSolarDate;

  /// No description provided for @selectLunarDate.
  ///
  /// In en, this message translates to:
  /// **'Select Lunar Date'**
  String get selectLunarDate;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @leapMonth.
  ///
  /// In en, this message translates to:
  /// **'Leap Month'**
  String get leapMonth;

  /// No description provided for @solar.
  ///
  /// In en, this message translates to:
  /// **'Solar'**
  String get solar;

  /// No description provided for @lunar.
  ///
  /// In en, this message translates to:
  /// **'Lunar'**
  String get lunar;

  /// No description provided for @features.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get features;

  /// No description provided for @featureLunar.
  ///
  /// In en, this message translates to:
  /// **'• Support solar and lunar dates'**
  String get featureLunar;

  /// No description provided for @featureRecurrence.
  ///
  /// In en, this message translates to:
  /// **'• Recurring event reminders'**
  String get featureRecurrence;

  /// No description provided for @featureImportExport.
  ///
  /// In en, this message translates to:
  /// **'• Data import/export'**
  String get featureImportExport;

  /// No description provided for @featureUI.
  ///
  /// In en, this message translates to:
  /// **'• Clean and beautiful interface'**
  String get featureUI;

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'User Agreement (Privacy Policy & Terms of Use)'**
  String get privacyPolicyTitle;

  /// No description provided for @privacyDataLocal.
  ///
  /// In en, this message translates to:
  /// **'1. Data & Privacy\n\nThis app does not collect, store, or share any personally identifiable information.\n\nCountdown events you create are stored only on your device.\n\nIf cloud sync or other features are added in the future, you will be notified and asked for consent.'**
  String get privacyDataLocal;

  /// No description provided for @privacyNoCollection.
  ///
  /// In en, this message translates to:
  /// **'2. Terms of Use\n\nThis app is for personal use only. Do not use it for illegal or abusive purposes.\n\nWhile we strive to keep the app stable, we are not responsible for any losses caused by its use.\n\nYou are responsible for securing your device and backing up your data.'**
  String get privacyNoCollection;

  /// No description provided for @privacyNoNetwork.
  ///
  /// In en, this message translates to:
  /// **'3. Disclaimer\n\nThe app is provided \"as is,\" without warranties of any kind.\n\nThe developer shall not be liable for any direct or indirect damages arising from the use of this app.'**
  String get privacyNoNetwork;

  /// No description provided for @privacyNoAccess.
  ///
  /// In en, this message translates to:
  /// **'4. Changes to Agreement\n\nWe may update this agreement from time to time. Updates will replace the previous version.\n\nContinued use of the app means you accept the updated agreement.'**
  String get privacyNoAccess;

  /// No description provided for @privacyContact.
  ///
  /// In en, this message translates to:
  /// **'For questions, contact the developer.'**
  String get privacyContact;

  /// No description provided for @privacyNoTracking.
  ///
  /// In en, this message translates to:
  /// **''**
  String get privacyNoTracking;

  /// No description provided for @privacyOpenSource.
  ///
  /// In en, this message translates to:
  /// **''**
  String get privacyOpenSource;

  /// No description provided for @aboutAppTitle.
  ///
  /// In en, this message translates to:
  /// **'About Days Reminder'**
  String get aboutAppTitle;

  /// No description provided for @aboutAppVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutAppVersion;

  /// No description provided for @aboutAppDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Independent Developer'**
  String get aboutAppDeveloper;

  /// No description provided for @aboutAppDescription.
  ///
  /// In en, this message translates to:
  /// **'Days Reminder - Countdown Calendar is a simple and practical tool to help you record and track every important day in life. Whether it\'s birthdays, anniversaries, exams, trips, or work milestones, you\'ll never miss a special moment again.'**
  String get aboutAppDescription;

  /// No description provided for @aboutAppFeatures.
  ///
  /// In en, this message translates to:
  /// **'Key Features:'**
  String get aboutAppFeatures;

  /// No description provided for @aboutAppFeatureLunar.
  ///
  /// In en, this message translates to:
  /// **'🗓️ Add unlimited countdowns and anniversaries'**
  String get aboutAppFeatureLunar;

  /// No description provided for @aboutAppFeatureRecurrence.
  ///
  /// In en, this message translates to:
  /// **'🔔 Flexible reminders for better planning'**
  String get aboutAppFeatureRecurrence;

  /// No description provided for @aboutAppFeatureImportExport.
  ///
  /// In en, this message translates to:
  /// **'🎨 Clean and elegant UI with multiple themes'**
  String get aboutAppFeatureImportExport;

  /// No description provided for @aboutAppFeatureUI.
  ///
  /// In en, this message translates to:
  /// **'🌍 Supports both English and Chinese'**
  String get aboutAppFeatureUI;

  /// No description provided for @aboutAppFeaturePrivacy.
  ///
  /// In en, this message translates to:
  /// **'\n\nMake Days Reminder your personal time manager and look forward to every important day!'**
  String get aboutAppFeaturePrivacy;

  /// No description provided for @aboutAppFeatureOpenSource.
  ///
  /// In en, this message translates to:
  /// **'• Open source code'**
  String get aboutAppFeatureOpenSource;

  /// No description provided for @aboutAppContact.
  ///
  /// In en, this message translates to:
  /// **'Contact Developer'**
  String get aboutAppContact;

  /// No description provided for @aboutAppEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get aboutAppEmail;

  /// No description provided for @aboutAppWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get aboutAppWebsite;

  /// No description provided for @aboutAppGitHub.
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get aboutAppGitHub;

  /// No description provided for @privacyCommitment.
  ///
  /// In en, this message translates to:
  /// **'We are committed to protecting your privacy:'**
  String get privacyCommitment;

  /// No description provided for @feedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedbackTitle;

  /// No description provided for @feedbackDescription.
  ///
  /// In en, this message translates to:
  /// **'We value your feedback to improve the app'**
  String get feedbackDescription;

  /// No description provided for @feedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Please share your suggestions, bug reports, or feature requests...'**
  String get feedbackHint;

  /// No description provided for @feedbackSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get feedbackSubmit;

  /// No description provided for @feedbackThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback!'**
  String get feedbackThanks;

  /// No description provided for @testNotification.
  ///
  /// In en, this message translates to:
  /// **'Test Notification'**
  String get testNotification;

  /// No description provided for @testNotificationDesc.
  ///
  /// In en, this message translates to:
  /// **'Send test notification to verify functionality'**
  String get testNotificationDesc;

  /// No description provided for @testEventNotification.
  ///
  /// In en, this message translates to:
  /// **'Test Event Notification'**
  String get testEventNotification;

  /// No description provided for @testEventNotificationDesc.
  ///
  /// In en, this message translates to:
  /// **'Send test notification using the first event'**
  String get testEventNotificationDesc;

  /// No description provided for @permissionGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Permission'**
  String get permissionGuideTitle;

  /// No description provided for @permissionGuideContent.
  ///
  /// In en, this message translates to:
  /// **'To remind you of important events in time, we recommend enabling notification permissions. You can turn them off anytime in settings.'**
  String get permissionGuideContent;

  /// No description provided for @enableNotification.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotification;

  /// No description provided for @laterSetup.
  ///
  /// In en, this message translates to:
  /// **'Set Up Later'**
  String get laterSetup;

  /// No description provided for @manualPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Manual Permission Required'**
  String get manualPermissionTitle;

  /// No description provided for @manualPermissionContent.
  ///
  /// In en, this message translates to:
  /// **'Please manually enable notification permissions in system settings to receive event reminders.'**
  String get manualPermissionContent;

  /// No description provided for @invalidLunarDate.
  ///
  /// In en, this message translates to:
  /// **'Selected lunar date is invalid, please try again'**
  String get invalidLunarDate;

  /// No description provided for @createdOn.
  ///
  /// In en, this message translates to:
  /// **'Created on'**
  String get createdOn;

  /// No description provided for @lastModified.
  ///
  /// In en, this message translates to:
  /// **'Last modified'**
  String get lastModified;

  /// No description provided for @recurrence.
  ///
  /// In en, this message translates to:
  /// **'Recurrence'**
  String get recurrence;

  /// No description provided for @noRecurrence.
  ///
  /// In en, this message translates to:
  /// **'No recurrence'**
  String get noRecurrence;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @dateFormatMonthDay.
  ///
  /// In en, this message translates to:
  /// **'M/d'**
  String get dateFormatMonthDay;

  /// No description provided for @dateFormatFull.
  ///
  /// In en, this message translates to:
  /// **'yyyy/M/d'**
  String get dateFormatFull;

  /// No description provided for @dateFormatShort.
  ///
  /// In en, this message translates to:
  /// **'yyyy-M-d'**
  String get dateFormatShort;

  /// No description provided for @lunarPrefix.
  ///
  /// In en, this message translates to:
  /// **'Lunar'**
  String get lunarPrefix;

  /// No description provided for @lunarDateWithBrackets.
  ///
  /// In en, this message translates to:
  /// **'({date})'**
  String lunarDateWithBrackets(Object date);

  /// No description provided for @countdownPrefix.
  ///
  /// In en, this message translates to:
  /// **'in'**
  String get countdownPrefix;

  /// No description provided for @countdownSuffix.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get countdownSuffix;

  /// No description provided for @countdownOverduePrefix.
  ///
  /// In en, this message translates to:
  /// **'overdue'**
  String get countdownOverduePrefix;

  /// No description provided for @countdownOverdueSuffix.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get countdownOverdueSuffix;

  /// No description provided for @countdownToday.
  ///
  /// In en, this message translates to:
  /// **'Today!'**
  String get countdownToday;

  /// No description provided for @countdownDays.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get countdownDays;

  /// No description provided for @countdownDay.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get countdownDay;

  /// No description provided for @countdownAfter.
  ///
  /// In en, this message translates to:
  /// **'after'**
  String get countdownAfter;

  /// No description provided for @countdownBefore.
  ///
  /// In en, this message translates to:
  /// **'before'**
  String get countdownBefore;

  /// No description provided for @ageUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Turning {age} soon'**
  String ageUpcoming(Object age);

  /// No description provided for @milestoneThousand.
  ///
  /// In en, this message translates to:
  /// **'1000 Days'**
  String get milestoneThousand;

  /// No description provided for @milestoneFiveHundred.
  ///
  /// In en, this message translates to:
  /// **'500 Days'**
  String get milestoneFiveHundred;

  /// No description provided for @milestoneHundred.
  ///
  /// In en, this message translates to:
  /// **'100 Days'**
  String get milestoneHundred;

  /// No description provided for @milestoneSweet.
  ///
  /// In en, this message translates to:
  /// **'Sweet Time'**
  String get milestoneSweet;

  /// No description provided for @recurrenceYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get recurrenceYearly;

  /// No description provided for @recurrenceMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get recurrenceMonthly;

  /// No description provided for @recurrenceWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get recurrenceWeekly;

  /// No description provided for @eventDetailDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get eventDetailDate;

  /// No description provided for @eventDetailRecurrence.
  ///
  /// In en, this message translates to:
  /// **'Recurrence'**
  String get eventDetailRecurrence;

  /// No description provided for @eventDetailType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get eventDetailType;

  /// No description provided for @eventDetailCurrentAge.
  ///
  /// In en, this message translates to:
  /// **'Current Age'**
  String get eventDetailCurrentAge;

  /// No description provided for @eventDetailNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get eventDetailNote;

  /// No description provided for @eventDetailAgeUnit.
  ///
  /// In en, this message translates to:
  /// **'years old'**
  String get eventDetailAgeUnit;

  /// No description provided for @eventDetailRecurrenceYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get eventDetailRecurrenceYearly;

  /// No description provided for @eventDetailRecurrenceMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get eventDetailRecurrenceMonthly;

  /// No description provided for @eventDetailRecurrenceWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get eventDetailRecurrenceWeekly;

  /// No description provided for @eventDetailRecurrenceNone.
  ///
  /// In en, this message translates to:
  /// **'No recurrence'**
  String get eventDetailRecurrenceNone;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @addEventNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Add note (optional)'**
  String get addEventNoteHint;

  /// No description provided for @addEventBirthdayHint.
  ///
  /// In en, this message translates to:
  /// **'Enter name/event title (e.g., John\'s Birthday)'**
  String get addEventBirthdayHint;

  /// No description provided for @addEventAnniversaryHint.
  ///
  /// In en, this message translates to:
  /// **'Enter anniversary title (e.g., Wedding Anniversary)'**
  String get addEventAnniversaryHint;

  /// No description provided for @addEventCountdownHint.
  ///
  /// In en, this message translates to:
  /// **'Enter event title'**
  String get addEventCountdownHint;

  /// No description provided for @lunarCalendar.
  ///
  /// In en, this message translates to:
  /// **'Lunar'**
  String get lunarCalendar;

  /// No description provided for @solarCalendar.
  ///
  /// In en, this message translates to:
  /// **'Solar'**
  String get solarCalendar;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get info;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @timeUnitsDays.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get timeUnitsDays;

  /// No description provided for @timeUnitsDay.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get timeUnitsDay;

  /// No description provided for @timeUnitsHours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get timeUnitsHours;

  /// No description provided for @timeUnitsHour.
  ///
  /// In en, this message translates to:
  /// **'hour'**
  String get timeUnitsHour;

  /// No description provided for @timeUnitsMinutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get timeUnitsMinutes;

  /// No description provided for @timeUnitsMinute.
  ///
  /// In en, this message translates to:
  /// **'minute'**
  String get timeUnitsMinute;

  /// No description provided for @lunarDate.
  ///
  /// In en, this message translates to:
  /// **'Lunar Date'**
  String get lunarDate;

  /// No description provided for @solarDate.
  ///
  /// In en, this message translates to:
  /// **'Solar Date'**
  String get solarDate;

  /// No description provided for @lunarMonth.
  ///
  /// In en, this message translates to:
  /// **'Lunar Month'**
  String get lunarMonth;

  /// No description provided for @lunarDay.
  ///
  /// In en, this message translates to:
  /// **'Lunar Day'**
  String get lunarDay;

  /// No description provided for @addRecord.
  ///
  /// In en, this message translates to:
  /// **'Add Record'**
  String get addRecord;

  /// No description provided for @editRecord.
  ///
  /// In en, this message translates to:
  /// **'Edit Record'**
  String get editRecord;

  /// No description provided for @recordContentHint.
  ///
  /// In en, this message translates to:
  /// **'Record this beautiful moment...'**
  String get recordContentHint;

  /// No description provided for @pleaseAddContent.
  ///
  /// In en, this message translates to:
  /// **'Please add record content'**
  String get pleaseAddContent;

  /// No description provided for @recordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Record updated'**
  String get recordUpdated;

  /// No description provided for @recordAdded.
  ///
  /// In en, this message translates to:
  /// **'Record added'**
  String get recordAdded;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String saveFailed(Object error);

  /// No description provided for @cameraPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera permission required to take photos'**
  String get cameraPermissionRequired;

  /// No description provided for @photoPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Photo permission required to select images'**
  String get photoPermissionRequired;

  /// No description provided for @cameraTimeout.
  ///
  /// In en, this message translates to:
  /// **'Camera timeout, please try again'**
  String get cameraTimeout;

  /// No description provided for @cameraNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Camera not available, please check if it\'s being used by another app'**
  String get cameraNotAvailable;

  /// No description provided for @photoFailed.
  ///
  /// In en, this message translates to:
  /// **'Photo failed: {error}'**
  String photoFailed(Object error);

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @selectFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Select from Gallery'**
  String get selectFromGallery;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get removePhoto;

  /// No description provided for @photoPreview.
  ///
  /// In en, this message translates to:
  /// **'Photo Preview'**
  String get photoPreview;

  /// No description provided for @photoBroken.
  ///
  /// In en, this message translates to:
  /// **'Image corrupted'**
  String get photoBroken;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission Denied'**
  String get permissionDenied;

  /// No description provided for @permissionDeniedDesc.
  ///
  /// In en, this message translates to:
  /// **'Please allow camera and photo permissions in settings'**
  String get permissionDeniedDesc;

  /// No description provided for @photoTimeout.
  ///
  /// In en, this message translates to:
  /// **'Photo selection timeout, please try again'**
  String get photoTimeout;

  /// No description provided for @selectPhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'Select photo failed: {error}'**
  String selectPhotoFailed(Object error);

  /// No description provided for @saveImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Save image failed: {error}'**
  String saveImageFailed(Object error);

  /// No description provided for @confirmLeave.
  ///
  /// In en, this message translates to:
  /// **'Confirm Leave'**
  String get confirmLeave;

  /// No description provided for @confirmLeaveDesc.
  ///
  /// In en, this message translates to:
  /// **'You have edited content, leaving will lose the edited content, are you sure you want to leave?'**
  String get confirmLeaveDesc;

  /// No description provided for @continueEditing.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueEditing;

  /// No description provided for @confirmLeaveAction.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get confirmLeaveAction;

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get permissionRequired;

  /// No description provided for @permissionRequiredDesc.
  ///
  /// In en, this message translates to:
  /// **'The app needs camera or photo permissions to add images. Please allow relevant permissions in settings.'**
  String get permissionRequiredDesc;

  /// No description provided for @deleteImage.
  ///
  /// In en, this message translates to:
  /// **'Delete Image'**
  String get deleteImage;

  /// No description provided for @deleteImageConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this image?'**
  String get deleteImageConfirm;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @noRecordsFound.
  ///
  /// In en, this message translates to:
  /// **'No records found'**
  String get noRecordsFound;

  /// No description provided for @noRecordsFoundDesc.
  ///
  /// In en, this message translates to:
  /// **'No records yet, go add the first one'**
  String get noRecordsFoundDesc;

  /// No description provided for @searchRecords.
  ///
  /// In en, this message translates to:
  /// **'Search Records'**
  String get searchRecords;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Enter event name to search...'**
  String get searchHint;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @deletedEvent.
  ///
  /// In en, this message translates to:
  /// **'Deleted Event'**
  String get deletedEvent;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear Search'**
  String get clearSearch;

  /// No description provided for @eventName.
  ///
  /// In en, this message translates to:
  /// **'Event Name'**
  String get eventName;

  /// No description provided for @recordTime.
  ///
  /// In en, this message translates to:
  /// **'Record Time'**
  String get recordTime;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @showEvent.
  ///
  /// In en, this message translates to:
  /// **'Show Event'**
  String get showEvent;

  /// No description provided for @hideEvent.
  ///
  /// In en, this message translates to:
  /// **'Hide Event'**
  String get hideEvent;

  /// No description provided for @imageLost.
  ///
  /// In en, this message translates to:
  /// **'Image lost'**
  String get imageLost;

  /// No description provided for @deleteRecord.
  ///
  /// In en, this message translates to:
  /// **'Delete Record'**
  String get deleteRecord;

  /// No description provided for @deleteRecordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this record? It cannot be recovered after deletion.'**
  String get deleteRecordConfirm;

  /// No description provided for @recordDeleted.
  ///
  /// In en, this message translates to:
  /// **'Record deleted'**
  String get recordDeleted;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get deleteFailed;

  /// No description provided for @paymentSystemInitializing.
  ///
  /// In en, this message translates to:
  /// **'Payment system is initializing, please try again later'**
  String get paymentSystemInitializing;

  /// No description provided for @noRecordsYet.
  ///
  /// In en, this message translates to:
  /// **'No records yet'**
  String get noRecordsYet;

  /// No description provided for @addMemoriesForSpecialDay.
  ///
  /// In en, this message translates to:
  /// **'Add memories for this special day'**
  String get addMemoriesForSpecialDay;

  /// No description provided for @unhideEvent.
  ///
  /// In en, this message translates to:
  /// **'Show Event'**
  String get unhideEvent;

  /// No description provided for @unhideEventDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to show this event?'**
  String get unhideEventDesc;

  /// No description provided for @hideEventDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to hide this event?'**
  String get hideEventDesc;

  /// No description provided for @recordCount.
  ///
  /// In en, this message translates to:
  /// **'Total {count} records'**
  String recordCount(Object count);

  /// No description provided for @viewAllRecords.
  ///
  /// In en, this message translates to:
  /// **'View All Records'**
  String get viewAllRecords;

  /// No description provided for @recordDetails.
  ///
  /// In en, this message translates to:
  /// **'Record Details'**
  String get recordDetails;

  /// No description provided for @recordContent.
  ///
  /// In en, this message translates to:
  /// **'Record Content'**
  String get recordContent;

  /// No description provided for @recordImages.
  ///
  /// In en, this message translates to:
  /// **'Record Images'**
  String get recordImages;

  /// No description provided for @recordLocation.
  ///
  /// In en, this message translates to:
  /// **'Record Location'**
  String get recordLocation;

  /// No description provided for @recordDate.
  ///
  /// In en, this message translates to:
  /// **'Record Date'**
  String get recordDate;

  /// No description provided for @confirmDeleteRecord.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete Record'**
  String get confirmDeleteRecord;

  /// No description provided for @confirmDeleteRecordDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this record? This action cannot be undone.'**
  String get confirmDeleteRecordDesc;

  /// No description provided for @personalCenter.
  ///
  /// In en, this message translates to:
  /// **'Personal Center'**
  String get personalCenter;

  /// No description provided for @vipStatus.
  ///
  /// In en, this message translates to:
  /// **'VIP Status'**
  String get vipStatus;

  /// No description provided for @vipExpired.
  ///
  /// In en, this message translates to:
  /// **'VIP Expired'**
  String get vipExpired;

  /// No description provided for @vipActive.
  ///
  /// In en, this message translates to:
  /// **'VIP Active'**
  String get vipActive;

  /// No description provided for @vipExpireDate.
  ///
  /// In en, this message translates to:
  /// **'Expires: {date}'**
  String vipExpireDate(Object date);

  /// No description provided for @upgradeToVip.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to VIP'**
  String get upgradeToVip;

  /// No description provided for @vipBenefits.
  ///
  /// In en, this message translates to:
  /// **'VIP Benefits'**
  String get vipBenefits;

  /// No description provided for @unlimitedHideEvents.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Hide Events'**
  String get unlimitedHideEvents;

  /// No description provided for @unlimitedHideEventsDesc.
  ///
  /// In en, this message translates to:
  /// **'Free users can only hide 3 events, premium users can hide unlimited events'**
  String get unlimitedHideEventsDesc;

  /// No description provided for @vipFeatures.
  ///
  /// In en, this message translates to:
  /// **'VIP Features'**
  String get vipFeatures;

  /// No description provided for @vipFeature1.
  ///
  /// In en, this message translates to:
  /// **'• Unlimited hide events'**
  String get vipFeature1;

  /// No description provided for @vipFeature2.
  ///
  /// In en, this message translates to:
  /// **'• Priority customer support'**
  String get vipFeature2;

  /// No description provided for @vipFeature3.
  ///
  /// In en, this message translates to:
  /// **'• Exclusive themes'**
  String get vipFeature3;

  /// No description provided for @vipFeature4.
  ///
  /// In en, this message translates to:
  /// **'• More features coming soon'**
  String get vipFeature4;

  /// No description provided for @purchaseVip.
  ///
  /// In en, this message translates to:
  /// **'Purchase VIP'**
  String get purchaseVip;

  /// No description provided for @restorePurchase.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchase'**
  String get restorePurchase;

  /// No description provided for @vipPurchaseSuccess.
  ///
  /// In en, this message translates to:
  /// **'VIP purchase successful!'**
  String get vipPurchaseSuccess;

  /// No description provided for @vipPurchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'VIP purchase failed'**
  String get vipPurchaseFailed;

  /// No description provided for @vipRestoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Purchase restored successfully'**
  String get vipRestoreSuccess;

  /// No description provided for @vipRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase restore failed'**
  String get vipRestoreFailed;

  /// No description provided for @paymentInitializing.
  ///
  /// In en, this message translates to:
  /// **'Payment system is initializing, please try again later'**
  String get paymentInitializing;

  /// No description provided for @notificationPermissionSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Permission Settings'**
  String get notificationPermissionSettings;

  /// No description provided for @domesticPhonePermissionSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Permission Settings'**
  String get domesticPhonePermissionSettings;

  /// No description provided for @setUpLater.
  ///
  /// In en, this message translates to:
  /// **'Set Up Later'**
  String get setUpLater;

  /// No description provided for @goToSettings.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings'**
  String get goToSettings;

  /// No description provided for @notificationPermissionAuthorized.
  ///
  /// In en, this message translates to:
  /// **'Notification permission authorized'**
  String get notificationPermissionAuthorized;

  /// No description provided for @defaultUserName.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get defaultUserName;

  /// No description provided for @checkingPermissionStatus.
  ///
  /// In en, this message translates to:
  /// **'Checking permission status...'**
  String get checkingPermissionStatus;

  /// No description provided for @unableToGetPermissionStatus.
  ///
  /// In en, this message translates to:
  /// **'Unable to get permission status'**
  String get unableToGetPermissionStatus;

  /// No description provided for @authorized.
  ///
  /// In en, this message translates to:
  /// **'Authorized'**
  String get authorized;

  /// No description provided for @notAuthorized.
  ///
  /// In en, this message translates to:
  /// **'Not Authorized'**
  String get notAuthorized;

  /// No description provided for @permanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Permanently Denied'**
  String get permanentlyDenied;

  /// No description provided for @unknownStatus.
  ///
  /// In en, this message translates to:
  /// **'Unknown Status'**
  String get unknownStatus;

  /// No description provided for @vipDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to VIP'**
  String get vipDialogTitle;

  /// No description provided for @upgradeNow.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgradeNow;

  /// No description provided for @unlimitedHideEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Hide Events'**
  String get unlimitedHideEventsTitle;

  /// No description provided for @vipDialogDesc.
  ///
  /// In en, this message translates to:
  /// **'Unlock more features and enjoy a better experience'**
  String get vipDialogDesc;

  /// No description provided for @monthlySubscription.
  ///
  /// In en, this message translates to:
  /// **'Monthly Subscription'**
  String get monthlySubscription;

  /// No description provided for @yearlySubscription.
  ///
  /// In en, this message translates to:
  /// **'Yearly Subscription'**
  String get yearlySubscription;

  /// No description provided for @bestValue.
  ///
  /// In en, this message translates to:
  /// **'Best Value'**
  String get bestValue;

  /// No description provided for @subscriptionPrice.
  ///
  /// In en, this message translates to:
  /// **'¥{price}/month'**
  String subscriptionPrice(Object price);

  /// No description provided for @yearlyPrice.
  ///
  /// In en, this message translates to:
  /// **'¥{price}/year'**
  String yearlyPrice(Object price);

  /// No description provided for @subscriptionFeatures.
  ///
  /// In en, this message translates to:
  /// **'Subscription Features'**
  String get subscriptionFeatures;

  /// No description provided for @subscriptionTerms.
  ///
  /// In en, this message translates to:
  /// **'Subscription Terms'**
  String get subscriptionTerms;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restorePurchases;

  /// No description provided for @purchaseNow.
  ///
  /// In en, this message translates to:
  /// **'Purchase Now'**
  String get purchaseNow;

  /// No description provided for @subscriptionNote.
  ///
  /// In en, this message translates to:
  /// **'Subscription will auto-renew, can be cancelled anytime in settings'**
  String get subscriptionNote;

  /// No description provided for @trialPeriod.
  ///
  /// In en, this message translates to:
  /// **'Trial Period'**
  String get trialPeriod;

  /// No description provided for @freeTrial.
  ///
  /// In en, this message translates to:
  /// **'Free Trial'**
  String get freeTrial;

  /// No description provided for @trialDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days free trial'**
  String trialDays(Object days);

  /// No description provided for @afterTrial.
  ///
  /// In en, this message translates to:
  /// **'After trial'**
  String get afterTrial;

  /// No description provided for @subscriptionRenewal.
  ///
  /// In en, this message translates to:
  /// **'Subscription will auto-renew'**
  String get subscriptionRenewal;

  /// No description provided for @uidCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'UID copied to clipboard'**
  String get uidCopiedToClipboard;

  /// No description provided for @processingPurchase.
  ///
  /// In en, this message translates to:
  /// **'Processing purchase...'**
  String get processingPurchase;

  /// No description provided for @purchaseCancelledOrFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase cancelled or failed'**
  String get purchaseCancelledOrFailed;

  /// No description provided for @purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed'**
  String get purchaseFailed;

  /// No description provided for @purchaseRestoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Purchase restore successful!'**
  String get purchaseRestoreSuccess;

  /// No description provided for @noPurchasesToRestore.
  ///
  /// In en, this message translates to:
  /// **'No purchases to restore'**
  String get noPurchasesToRestore;

  /// No description provided for @restorePurchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore purchase failed'**
  String get restorePurchaseFailed;

  /// No description provided for @validUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until'**
  String get validUntil;

  /// No description provided for @vipUser.
  ///
  /// In en, this message translates to:
  /// **'VIP User'**
  String get vipUser;

  /// No description provided for @backupManagement.
  ///
  /// In en, this message translates to:
  /// **'Backup Management'**
  String get backupManagement;

  /// No description provided for @backupManagementDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage data backup and restore'**
  String get backupManagementDesc;

  /// No description provided for @createBackup.
  ///
  /// In en, this message translates to:
  /// **'Create Backup'**
  String get createBackup;

  /// No description provided for @importDataWarning.
  ///
  /// In en, this message translates to:
  /// **'Importing data will overwrite existing data, continue?'**
  String get importDataWarning;

  /// No description provided for @restoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup'**
  String get restoreBackup;

  /// No description provided for @restoreBackupWarning.
  ///
  /// In en, this message translates to:
  /// **'Restoring backup will overwrite existing data, continue?'**
  String get restoreBackupWarning;

  /// No description provided for @restoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Restore successful'**
  String get restoreSuccess;

  /// No description provided for @deleteBackup.
  ///
  /// In en, this message translates to:
  /// **'Delete Backup'**
  String get deleteBackup;

  /// No description provided for @deleteBackupWarning.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this backup file?'**
  String get deleteBackupWarning;

  /// No description provided for @deleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Delete successful'**
  String get deleteSuccess;

  /// No description provided for @noBackupFiles.
  ///
  /// In en, this message translates to:
  /// **'No backup files'**
  String get noBackupFiles;

  /// No description provided for @noBackupFilesDesc.
  ///
  /// In en, this message translates to:
  /// **'No backup files yet'**
  String get noBackupFilesDesc;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created at'**
  String get createdAt;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @dataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get dataManagement;

  /// No description provided for @clearAllDataDesc.
  ///
  /// In en, this message translates to:
  /// **'Clear all events and records data'**
  String get clearAllDataDesc;

  /// No description provided for @biometricAuthReason.
  ///
  /// In en, this message translates to:
  /// **'Use biometric authentication to verify identity'**
  String get biometricAuthReason;

  /// No description provided for @biometricAuthCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get biometricAuthCancel;

  /// No description provided for @biometricAuthGoToSettings.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings'**
  String get biometricAuthGoToSettings;

  /// No description provided for @biometricAuthGoToSettingsDesc.
  ///
  /// In en, this message translates to:
  /// **'Please enable biometric authentication in settings'**
  String get biometricAuthGoToSettingsDesc;

  /// No description provided for @biometricAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication failed'**
  String get biometricAuthFailed;

  /// No description provided for @hideEvents.
  ///
  /// In en, this message translates to:
  /// **'Hide Events'**
  String get hideEvents;

  /// No description provided for @showHiddenEvents.
  ///
  /// In en, this message translates to:
  /// **'Show Hidden Events'**
  String get showHiddenEvents;

  /// No description provided for @photosCount.
  ///
  /// In en, this message translates to:
  /// **'Total {count} photos'**
  String photosCount(Object count);

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @timeInfo.
  ///
  /// In en, this message translates to:
  /// **'Time Information'**
  String get timeInfo;

  /// No description provided for @createdTime.
  ///
  /// In en, this message translates to:
  /// **'Created Time'**
  String get createdTime;

  /// No description provided for @updatedTime.
  ///
  /// In en, this message translates to:
  /// **'Updated Time'**
  String get updatedTime;

  /// No description provided for @photoRecord.
  ///
  /// In en, this message translates to:
  /// **'Photo Record'**
  String get photoRecord;

  /// No description provided for @textRecord.
  ///
  /// In en, this message translates to:
  /// **'Text Record'**
  String get textRecord;

  /// No description provided for @mixedRecord.
  ///
  /// In en, this message translates to:
  /// **'Mixed Record'**
  String get mixedRecord;

  /// No description provided for @notificationPermission.
  ///
  /// In en, this message translates to:
  /// **'Notification Permission'**
  String get notificationPermission;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @refreshPermissionStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh Permission Status'**
  String get refreshPermissionStatus;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
