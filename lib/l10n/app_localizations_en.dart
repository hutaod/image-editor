// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Days Reminder';

  @override
  String get appTitleChinese => '倒数日历';

  @override
  String get appDescription => 'A countdown calendar app for tracking important events and dates';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get languageDesc => 'Choose your preferred language';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsEnabled => 'Notification Reminders';

  @override
  String get notificationsEnabledDesc => 'Enable notifications when events are due';

  @override
  String get advanceReminder => 'Advance Reminder';

  @override
  String advanceReminderDesc(Object days) {
    return 'Remind $days days before event';
  }

  @override
  String get advanceReminderDays => 'Advance Days';

  @override
  String get advanceReminderDaysDesc => 'Set the number of days to remind in advance';

  @override
  String get privacyAndPermissions => 'Privacy & Permissions';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get privacyPolicyDesc => 'View app privacy policy and terms of use';

  @override
  String get notificationPermissions => 'Notification Permissions';

  @override
  String get notificationPermissionsDesc => 'Manage notification permission settings';

  @override
  String get about => 'About';

  @override
  String get aboutApp => 'About App';

  @override
  String get aboutAppDesc => 'Version information and feature introduction';

  @override
  String get feedback => 'Feedback';

  @override
  String get feedbackDesc => 'Send us feedback or suggestions';

  @override
  String get dataStatistics => 'Data Statistics';

  @override
  String totalEvents(Object count) {
    return 'Total $count events';
  }

  @override
  String get dataBackup => 'Data Backup';

  @override
  String get exportData => 'Export Data';

  @override
  String get importData => 'Import Data';

  @override
  String get clearAllData => 'Clear All Data';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String get confirmDeleteDesc => 'This action will delete all event data and cannot be undone.';

  @override
  String currentEvents(Object count) {
    return 'Current total: $count events';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String exportSuccess(Object path) {
    return 'Exported to: $path';
  }

  @override
  String exportFailed(Object error) {
    return 'Export failed: $error';
  }

  @override
  String get importSuccess => 'Data imported successfully';

  @override
  String importFailed(Object error) {
    return 'Data import failed: $error';
  }

  @override
  String get allDataDeleted => 'All data has been deleted';

  @override
  String get pleaseEnableNotificationPermission => 'Please enable notification permissions in system settings';

  @override
  String get days => 'days';

  @override
  String get day => 'Day';

  @override
  String get today => 'today';

  @override
  String get yesterday => 'yesterday';

  @override
  String daysAgo(Object days) {
    return '$days days ago';
  }

  @override
  String get home => 'Home';

  @override
  String get add => 'Add';

  @override
  String get noEventsYet => 'No events yet';

  @override
  String get noEventsYetDesc => 'Tap the + button in the top right to add one';

  @override
  String get featuredEvent => 'Featured Event';

  @override
  String daysRemaining(Object days) {
    return '$days days remaining';
  }

  @override
  String daysOverdue(Object days) {
    return '$days days overdue';
  }

  @override
  String get event => 'event';

  @override
  String get events => 'events';

  @override
  String get addEvent => 'Add Event';

  @override
  String get editEvent => 'Edit Event';

  @override
  String get eventTitle => 'Event Title';

  @override
  String get eventTitleHint => 'Enter event title';

  @override
  String get eventDate => 'Event Date';

  @override
  String get eventType => 'Event Type';

  @override
  String get countdown => 'Countdown';

  @override
  String get pastEvent => 'Past Event';

  @override
  String get notes => 'Notes';

  @override
  String get notesHint => 'Optional notes';

  @override
  String get save => 'Save';

  @override
  String get deleteEvent => 'Delete Event';

  @override
  String get titleRequired => 'Title is required';

  @override
  String get dateRequired => 'Date is required';

  @override
  String get eventDetail => 'Event Details';

  @override
  String get eventKindBirthday => 'Birthday';

  @override
  String get eventKindAnniversary => 'Anniversary';

  @override
  String get eventKindCountdown => 'Countdown';

  @override
  String get remainingDays => 'Remaining days';

  @override
  String get overdueDays => 'Overdue days';

  @override
  String get confirmDeleteEvent => 'Confirm Delete';

  @override
  String confirmDeleteEventDesc(Object title) {
    return 'Are you sure you want to delete \"$title\"? This action cannot be undone.';
  }

  @override
  String get selectSolarDate => 'Select Solar Date';

  @override
  String get selectLunarDate => 'Select Lunar Date';

  @override
  String get year => 'Year';

  @override
  String get month => 'Month';

  @override
  String get leapMonth => 'Leap Month';

  @override
  String get solar => 'Solar';

  @override
  String get lunar => 'Lunar';

  @override
  String get features => 'Features';

  @override
  String get featureLunar => '• Support solar and lunar dates';

  @override
  String get featureRecurrence => '• Recurring event reminders';

  @override
  String get featureImportExport => '• Data import/export';

  @override
  String get featureUI => '• Clean and beautiful interface';

  @override
  String get privacyPolicyTitle => 'User Agreement (Privacy Policy & Terms of Use)';

  @override
  String get privacyDataLocal => '1. Data & Privacy\n\nThis app does not collect, store, or share any personally identifiable information.\n\nCountdown events you create are stored only on your device.\n\nIf cloud sync or other features are added in the future, you will be notified and asked for consent.';

  @override
  String get privacyNoCollection => '2. Terms of Use\n\nThis app is for personal use only. Do not use it for illegal or abusive purposes.\n\nWhile we strive to keep the app stable, we are not responsible for any losses caused by its use.\n\nYou are responsible for securing your device and backing up your data.';

  @override
  String get privacyNoNetwork => '3. Disclaimer\n\nThe app is provided \"as is,\" without warranties of any kind.\n\nThe developer shall not be liable for any direct or indirect damages arising from the use of this app.';

  @override
  String get privacyNoAccess => '4. Changes to Agreement\n\nWe may update this agreement from time to time. Updates will replace the previous version.\n\nContinued use of the app means you accept the updated agreement.';

  @override
  String get privacyContact => 'For questions, contact the developer.';

  @override
  String get privacyNoTracking => '';

  @override
  String get privacyOpenSource => '';

  @override
  String get aboutAppTitle => 'About Days Reminder';

  @override
  String get aboutAppVersion => 'Version';

  @override
  String get aboutAppDeveloper => 'Independent Developer';

  @override
  String get aboutAppDescription => 'Days Reminder - Countdown Calendar is a simple and practical tool to help you record and track every important day in life. Whether it\'s birthdays, anniversaries, exams, trips, or work milestones, you\'ll never miss a special moment again.';

  @override
  String get aboutAppFeatures => 'Key Features:';

  @override
  String get aboutAppFeatureLunar => '🗓️ Add unlimited countdowns and anniversaries';

  @override
  String get aboutAppFeatureRecurrence => '🔔 Flexible reminders for better planning';

  @override
  String get aboutAppFeatureImportExport => '🎨 Clean and elegant UI with multiple themes';

  @override
  String get aboutAppFeatureUI => '🌍 Supports both English and Chinese';

  @override
  String get aboutAppFeaturePrivacy => '\n\nMake Days Reminder your personal time manager and look forward to every important day!';

  @override
  String get aboutAppFeatureOpenSource => '• Open source code';

  @override
  String get aboutAppContact => 'Contact Developer';

  @override
  String get aboutAppEmail => 'Email';

  @override
  String get aboutAppWebsite => 'Website';

  @override
  String get aboutAppGitHub => 'GitHub';

  @override
  String get privacyCommitment => 'We are committed to protecting your privacy:';

  @override
  String get feedbackTitle => 'Feedback';

  @override
  String get feedbackDescription => 'We value your feedback to improve the app';

  @override
  String get feedbackHint => 'Please share your suggestions, bug reports, or feature requests...';

  @override
  String get feedbackSubmit => 'Submit';

  @override
  String get feedbackThanks => 'Thank you for your feedback!';

  @override
  String get testNotification => 'Test Notification';

  @override
  String get testNotificationDesc => 'Send test notification to verify functionality';

  @override
  String get testEventNotification => 'Test Event Notification';

  @override
  String get testEventNotificationDesc => 'Send test notification using the first event';

  @override
  String get permissionGuideTitle => 'Notification Permission';

  @override
  String get permissionGuideContent => 'To remind you of important events in time, we recommend enabling notification permissions. You can turn them off anytime in settings.';

  @override
  String get enableNotification => 'Enable Notifications';

  @override
  String get laterSetup => 'Set Up Later';

  @override
  String get manualPermissionTitle => 'Manual Permission Required';

  @override
  String get manualPermissionContent => 'Please manually enable notification permissions in system settings to receive event reminders.';

  @override
  String get invalidLunarDate => 'Selected lunar date is invalid, please try again';

  @override
  String get createdOn => 'Created on';

  @override
  String get lastModified => 'Last modified';

  @override
  String get recurrence => 'Recurrence';

  @override
  String get noRecurrence => 'No recurrence';

  @override
  String get yearly => 'Yearly';

  @override
  String get monthly => 'Monthly';

  @override
  String get weekly => 'Weekly';

  @override
  String get daily => 'Daily';

  @override
  String get dateFormatMonthDay => 'M/d';

  @override
  String get dateFormatFull => 'yyyy/M/d';

  @override
  String get dateFormatShort => 'yyyy-M-d';

  @override
  String get lunarPrefix => 'Lunar';

  @override
  String lunarDateWithBrackets(Object date) {
    return '($date)';
  }

  @override
  String get countdownPrefix => 'in';

  @override
  String get countdownSuffix => 'days';

  @override
  String get countdownOverduePrefix => 'overdue';

  @override
  String get countdownOverdueSuffix => 'days';

  @override
  String get countdownToday => 'Today!';

  @override
  String get countdownDays => 'days';

  @override
  String get countdownDay => 'day';

  @override
  String get countdownAfter => 'after';

  @override
  String get countdownBefore => 'before';

  @override
  String ageUpcoming(Object age) {
    return 'Turning $age soon';
  }

  @override
  String get milestoneThousand => '1000 Days';

  @override
  String get milestoneFiveHundred => '500 Days';

  @override
  String get milestoneHundred => '100 Days';

  @override
  String get milestoneSweet => 'Sweet Time';

  @override
  String get recurrenceYearly => 'Yearly';

  @override
  String get recurrenceMonthly => 'Monthly';

  @override
  String get recurrenceWeekly => 'Weekly';

  @override
  String get eventDetailDate => 'Date';

  @override
  String get eventDetailRecurrence => 'Recurrence';

  @override
  String get eventDetailType => 'Type';

  @override
  String get eventDetailCurrentAge => 'Current Age';

  @override
  String get eventDetailNote => 'Note';

  @override
  String get eventDetailAgeUnit => 'years old';

  @override
  String get eventDetailRecurrenceYearly => 'Yearly';

  @override
  String get eventDetailRecurrenceMonthly => 'Monthly';

  @override
  String get eventDetailRecurrenceWeekly => 'Weekly';

  @override
  String get eventDetailRecurrenceNone => 'No recurrence';

  @override
  String get selectDate => 'Select Date';

  @override
  String get addEventNoteHint => 'Add note (optional)';

  @override
  String get addEventBirthdayHint => 'Enter name/event title (e.g., John\'s Birthday)';

  @override
  String get addEventAnniversaryHint => 'Enter anniversary title (e.g., Wedding Anniversary)';

  @override
  String get addEventCountdownHint => 'Enter event title';

  @override
  String get lunarCalendar => 'Lunar';

  @override
  String get solarCalendar => 'Solar';

  @override
  String get ok => 'OK';

  @override
  String get confirm => 'Confirm';

  @override
  String get close => 'Close';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get warning => 'Warning';

  @override
  String get info => 'Information';

  @override
  String get saturday => 'Saturday';

  @override
  String get timeUnitsDays => 'days';

  @override
  String get timeUnitsDay => 'day';

  @override
  String get timeUnitsHours => 'hours';

  @override
  String get timeUnitsHour => 'hour';

  @override
  String get timeUnitsMinutes => 'minutes';

  @override
  String get timeUnitsMinute => 'minute';

  @override
  String get lunarDate => 'Lunar Date';

  @override
  String get solarDate => 'Solar Date';

  @override
  String get lunarMonth => 'Lunar Month';

  @override
  String get lunarDay => 'Lunar Day';

  @override
  String get addRecord => 'Add Record';

  @override
  String get editRecord => 'Edit Record';

  @override
  String get recordContentHint => 'Record this beautiful moment...';

  @override
  String get pleaseAddContent => 'Please add record content';

  @override
  String get recordUpdated => 'Record updated';

  @override
  String get recordAdded => 'Record added';

  @override
  String saveFailed(Object error) {
    return 'Save failed: $error';
  }

  @override
  String get cameraPermissionRequired => 'Camera permission required to take photos';

  @override
  String get photoPermissionRequired => 'Photo permission required to select images';

  @override
  String get cameraTimeout => 'Camera timeout, please try again';

  @override
  String get cameraNotAvailable => 'Camera not available, please check if it\'s being used by another app';

  @override
  String photoFailed(Object error) {
    return 'Photo failed: $error';
  }

  @override
  String get addPhoto => 'Add Photo';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get selectFromGallery => 'Select from Gallery';

  @override
  String get removePhoto => 'Remove Photo';

  @override
  String get photoPreview => 'Photo Preview';

  @override
  String get photoBroken => 'Image corrupted';

  @override
  String get permissionDenied => 'Permission Denied';

  @override
  String get permissionDeniedDesc => 'Please allow camera and photo permissions in settings';

  @override
  String get photoTimeout => 'Photo selection timeout, please try again';

  @override
  String selectPhotoFailed(Object error) {
    return 'Select photo failed: $error';
  }

  @override
  String saveImageFailed(Object error) {
    return 'Save image failed: $error';
  }

  @override
  String get confirmLeave => 'Confirm Leave';

  @override
  String get confirmLeaveDesc => 'You have edited content, leaving will lose the edited content, are you sure you want to leave?';

  @override
  String get continueEditing => 'Continue';

  @override
  String get confirmLeaveAction => 'Leave';

  @override
  String get permissionRequired => 'Permission Required';

  @override
  String get permissionRequiredDesc => 'The app needs camera or photo permissions to add images. Please allow relevant permissions in settings.';

  @override
  String get deleteImage => 'Delete Image';

  @override
  String get deleteImageConfirm => 'Are you sure you want to delete this image?';

  @override
  String get community => 'Community';

  @override
  String get noRecordsFound => 'No records found';

  @override
  String get noRecordsFoundDesc => 'No records yet, go add the first one';

  @override
  String get searchRecords => 'Search Records';

  @override
  String get searchHint => 'Enter event name to search...';

  @override
  String get search => 'Search';

  @override
  String get deletedEvent => 'Deleted Event';

  @override
  String get clearSearch => 'Clear Search';

  @override
  String get eventName => 'Event Name';

  @override
  String get recordTime => 'Record Time';

  @override
  String get viewDetails => 'View Details';

  @override
  String get showEvent => 'Show Event';

  @override
  String get hideEvent => 'Hide Event';

  @override
  String get imageLost => 'Image lost';

  @override
  String get deleteRecord => 'Delete Record';

  @override
  String get deleteRecordConfirm => 'Are you sure you want to delete this record? It cannot be recovered after deletion.';

  @override
  String get recordDeleted => 'Record deleted';

  @override
  String get deleteFailed => 'Delete failed';

  @override
  String get paymentSystemInitializing => 'Payment system is initializing, please try again later';

  @override
  String get noRecordsYet => 'No records yet';

  @override
  String get addMemoriesForSpecialDay => 'Add memories for this special day';

  @override
  String get unhideEvent => 'Show Event';

  @override
  String get unhideEventDesc => 'Are you sure you want to show this event?';

  @override
  String get hideEventDesc => 'Are you sure you want to hide this event?';

  @override
  String recordCount(Object count) {
    return 'Total $count records';
  }

  @override
  String get viewAllRecords => 'View All Records';

  @override
  String get recordDetails => 'Record Details';

  @override
  String get recordContent => 'Record Content';

  @override
  String get recordImages => 'Record Images';

  @override
  String get recordLocation => 'Record Location';

  @override
  String get recordDate => 'Record Date';

  @override
  String get confirmDeleteRecord => 'Confirm Delete Record';

  @override
  String get confirmDeleteRecordDesc => 'Are you sure you want to delete this record? This action cannot be undone.';

  @override
  String get personalCenter => 'Personal Center';

  @override
  String get vipStatus => 'VIP Status';

  @override
  String get vipExpired => 'VIP Expired';

  @override
  String get vipActive => 'VIP Active';

  @override
  String vipExpireDate(Object date) {
    return 'Expires: $date';
  }

  @override
  String get upgradeToVip => 'Upgrade to VIP';

  @override
  String get vipBenefits => 'VIP Benefits';

  @override
  String get unlimitedHideEvents => 'Unlimited Hide Events';

  @override
  String get unlimitedHideEventsDesc => 'Free users can only hide 3 events, premium users can hide unlimited events';

  @override
  String get vipFeatures => 'VIP Features';

  @override
  String get vipFeature1 => '• Unlimited hide events';

  @override
  String get vipFeature2 => '• Priority customer support';

  @override
  String get vipFeature3 => '• Exclusive themes';

  @override
  String get vipFeature4 => '• More features coming soon';

  @override
  String get purchaseVip => 'Purchase VIP';

  @override
  String get restorePurchase => 'Restore Purchase';

  @override
  String get vipPurchaseSuccess => 'VIP purchase successful!';

  @override
  String get vipPurchaseFailed => 'VIP purchase failed';

  @override
  String get vipRestoreSuccess => 'Purchase restored successfully';

  @override
  String get vipRestoreFailed => 'Purchase restore failed';

  @override
  String get paymentInitializing => 'Payment system is initializing, please try again later';

  @override
  String get notificationPermissionSettings => 'Notification Permission Settings';

  @override
  String get domesticPhonePermissionSettings => 'Notification Permission Settings';

  @override
  String get setUpLater => 'Set Up Later';

  @override
  String get goToSettings => 'Go to Settings';

  @override
  String get notificationPermissionAuthorized => 'Notification permission authorized';

  @override
  String get defaultUserName => 'User';

  @override
  String get checkingPermissionStatus => 'Checking permission status...';

  @override
  String get unableToGetPermissionStatus => 'Unable to get permission status';

  @override
  String get authorized => 'Authorized';

  @override
  String get notAuthorized => 'Not Authorized';

  @override
  String get permanentlyDenied => 'Permanently Denied';

  @override
  String get unknownStatus => 'Unknown Status';

  @override
  String get vipDialogTitle => 'Upgrade to VIP';

  @override
  String get upgradeNow => 'Upgrade';

  @override
  String get unlimitedHideEventsTitle => 'Unlimited Hide Events';

  @override
  String get vipDialogDesc => 'Unlock more features and enjoy a better experience';

  @override
  String get monthlySubscription => 'Monthly Subscription';

  @override
  String get yearlySubscription => 'Yearly Subscription';

  @override
  String get bestValue => 'Best Value';

  @override
  String subscriptionPrice(Object price) {
    return '¥$price/month';
  }

  @override
  String yearlyPrice(Object price) {
    return '¥$price/year';
  }

  @override
  String get subscriptionFeatures => 'Subscription Features';

  @override
  String get subscriptionTerms => 'Subscription Terms';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get restorePurchases => 'Restore';

  @override
  String get purchaseNow => 'Purchase Now';

  @override
  String get subscriptionNote => 'Subscription will auto-renew, can be cancelled anytime in settings';

  @override
  String get trialPeriod => 'Trial Period';

  @override
  String get freeTrial => 'Free Trial';

  @override
  String trialDays(Object days) {
    return '$days days free trial';
  }

  @override
  String get afterTrial => 'After trial';

  @override
  String get subscriptionRenewal => 'Subscription will auto-renew';

  @override
  String get uidCopiedToClipboard => 'UID copied to clipboard';

  @override
  String get processingPurchase => 'Processing purchase...';

  @override
  String get purchaseCancelledOrFailed => 'Purchase cancelled or failed';

  @override
  String get purchaseFailed => 'Purchase failed';

  @override
  String get purchaseRestoreSuccess => 'Purchase restore successful!';

  @override
  String get noPurchasesToRestore => 'No purchases to restore';

  @override
  String get restorePurchaseFailed => 'Restore purchase failed';

  @override
  String get validUntil => 'Valid until';

  @override
  String get vipUser => 'VIP User';

  @override
  String get backupManagement => 'Backup Management';

  @override
  String get backupManagementDesc => 'Manage data backup and restore';

  @override
  String get createBackup => 'Create Backup';

  @override
  String get importDataWarning => 'Importing data will overwrite existing data, continue?';

  @override
  String get restoreBackup => 'Restore Backup';

  @override
  String get restoreBackupWarning => 'Restoring backup will overwrite existing data, continue?';

  @override
  String get restoreSuccess => 'Restore successful';

  @override
  String get deleteBackup => 'Delete Backup';

  @override
  String get deleteBackupWarning => 'Are you sure you want to delete this backup file?';

  @override
  String get deleteSuccess => 'Delete successful';

  @override
  String get noBackupFiles => 'No backup files';

  @override
  String get noBackupFilesDesc => 'No backup files yet';

  @override
  String get size => 'Size';

  @override
  String get createdAt => 'Created at';

  @override
  String get share => 'Share';

  @override
  String get export => 'Export';

  @override
  String get dataManagement => 'Data Management';

  @override
  String get clearAllDataDesc => 'Clear all events and records data';

  @override
  String get biometricAuthReason => 'Use biometric authentication to verify identity';

  @override
  String get biometricAuthCancel => 'Cancel';

  @override
  String get biometricAuthGoToSettings => 'Go to Settings';

  @override
  String get biometricAuthGoToSettingsDesc => 'Please enable biometric authentication in settings';

  @override
  String get biometricAuthFailed => 'Biometric authentication failed';

  @override
  String get hideEvents => 'Hide Events';

  @override
  String get showHiddenEvents => 'Show Hidden Events';

  @override
  String photosCount(Object count) {
    return 'Total $count photos';
  }

  @override
  String get location => 'Location';

  @override
  String get timeInfo => 'Time Information';

  @override
  String get createdTime => 'Created Time';

  @override
  String get updatedTime => 'Updated Time';

  @override
  String get photoRecord => 'Photo Record';

  @override
  String get textRecord => 'Text Record';

  @override
  String get mixedRecord => 'Mixed Record';

  @override
  String get notificationPermission => 'Notification Permission';

  @override
  String get status => 'Status';

  @override
  String get refreshPermissionStatus => 'Refresh Permission Status';
}
