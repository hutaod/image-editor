// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '倒数日历';

  @override
  String get appTitleChinese => 'Days Reminder';

  @override
  String get appDescription => '倒数日历 - 一个简洁的日期提醒应用';

  @override
  String get settings => '设置';

  @override
  String get language => '语言';

  @override
  String get languageDesc => '选择您偏好的语言';

  @override
  String get notifications => '通知';

  @override
  String get notificationsEnabled => '通知提醒';

  @override
  String get notificationsEnabledDesc => '开启后将在事件到期时发送通知';

  @override
  String get advanceReminder => '提前提醒';

  @override
  String advanceReminderDesc(Object days) {
    return '在事件前$days天提醒';
  }

  @override
  String get advanceReminderDays => '提前天数';

  @override
  String get advanceReminderDaysDesc => '设置提前提醒的天数';

  @override
  String get privacyAndPermissions => '隐私与权限';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get privacyPolicyDesc => '查看应用隐私政策与使用条款';

  @override
  String get notificationPermissions => '通知权限';

  @override
  String get notificationPermissionsDesc => '管理通知权限设置';

  @override
  String get about => '关于';

  @override
  String get aboutApp => '关于应用';

  @override
  String get aboutAppDesc => '版本信息和功能介绍';

  @override
  String get feedback => '意见反馈';

  @override
  String get feedbackDesc => '向我们反馈问题或建议';

  @override
  String get dataStatistics => '数据统计';

  @override
  String totalEvents(Object count) {
    return '共 $count 个事件';
  }

  @override
  String get dataBackup => '数据备份';

  @override
  String get exportData => '导出数据';

  @override
  String get importData => '导入数据';

  @override
  String get clearAllData => '清除所有数据';

  @override
  String get confirmDelete => '确认删除';

  @override
  String get confirmDeleteDesc => '此操作将删除所有事件数据，且无法恢复。';

  @override
  String currentEvents(Object count) {
    return '当前共有 $count 个事件';
  }

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String exportSuccess(Object path) {
    return '已导出到: $path';
  }

  @override
  String exportFailed(Object error) {
    return '导出失败: $error';
  }

  @override
  String get importSuccess => '数据导入成功';

  @override
  String importFailed(Object error) {
    return '数据导入失败: $error';
  }

  @override
  String get allDataDeleted => '所有数据已删除';

  @override
  String get pleaseEnableNotificationPermission => '请在系统设置中开启通知权限';

  @override
  String get days => '天';

  @override
  String get day => '日';

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';

  @override
  String daysAgo(Object days) {
    return '$days天前';
  }

  @override
  String get home => '首页';

  @override
  String get add => '添加';

  @override
  String get noEventsYet => '还没有事件';

  @override
  String get noEventsYetDesc => '点击右上角 + 添加一个吧';

  @override
  String get featuredEvent => '精选事件';

  @override
  String daysRemaining(Object days) {
    return '还有 $days 天';
  }

  @override
  String daysOverdue(Object days) {
    return '已过 $days 天';
  }

  @override
  String get event => '事件';

  @override
  String get events => '事件';

  @override
  String get addEvent => '添加事件';

  @override
  String get editEvent => '编辑事件';

  @override
  String get eventTitle => '事件标题';

  @override
  String get eventTitleHint => '请输入事件标题';

  @override
  String get eventDate => '事件日期';

  @override
  String get eventType => '事件类型';

  @override
  String get countdown => '倒计时';

  @override
  String get pastEvent => '已过去';

  @override
  String get notes => '备注';

  @override
  String get notesHint => '可选备注';

  @override
  String get save => '保存';

  @override
  String get deleteEvent => '删除事件';

  @override
  String get titleRequired => '标题不能为空';

  @override
  String get dateRequired => '日期不能为空';

  @override
  String get eventDetail => '事件详情';

  @override
  String get eventKindBirthday => '生日';

  @override
  String get eventKindAnniversary => '纪念日';

  @override
  String get eventKindCountdown => '倒数日';

  @override
  String get remainingDays => '剩余天数';

  @override
  String get overdueDays => '已过天数';

  @override
  String get confirmDeleteEvent => '确认删除';

  @override
  String confirmDeleteEventDesc(Object title) {
    return '确定要删除\"$title\"吗？此操作无法撤销。';
  }

  @override
  String get selectSolarDate => '选择公历日期';

  @override
  String get selectLunarDate => '选择农历日期';

  @override
  String get year => '年';

  @override
  String get month => '月';

  @override
  String get leapMonth => '闰月';

  @override
  String get solar => '公历';

  @override
  String get lunar => '阴历';

  @override
  String get features => '功能特点';

  @override
  String get featureLunar => '• 支持公历和农历日期';

  @override
  String get featureRecurrence => '• 重复事件提醒';

  @override
  String get featureImportExport => '• 数据导入导出';

  @override
  String get featureUI => '• 简洁美观的界面';

  @override
  String get privacyPolicyTitle => '用户协议（隐私政策与使用条款）';

  @override
  String get privacyDataLocal => '1. 数据与隐私\n\n本应用不会收集、存储或分享任何个人可识别信息。\n\n您创建的倒数日事件仅保存在您的设备本地。\n\n如果未来增加云同步或其他功能，我们会在更新前明确告知，并征得您的同意。';

  @override
  String get privacyNoCollection => '2. 使用条款\n\n本应用仅供个人使用，请勿用于违法或滥用目的。\n\n我们会尽力保证应用的稳定性，但不对因使用本应用而产生的任何损失负责。\n\n您在使用过程中需要自行确保设备的安全与数据的备份。';

  @override
  String get privacyNoNetwork => '3. 免责声明\n\n本应用按\"现状\"提供，不保证无错误或完全满足所有需求。\n\n对因使用本应用导致的任何间接或直接损害，开发者不承担责任。';

  @override
  String get privacyNoAccess => '4. 协议修改\n\n我们可能会不时更新本协议。更新后将以新版本替换旧版本。\n\n您继续使用本应用即视为接受修改后的协议。';

  @override
  String get privacyContact => '如有疑问，请联系开发者。';

  @override
  String get privacyNoTracking => '';

  @override
  String get privacyOpenSource => '';

  @override
  String get aboutAppTitle => '关于 Days Reminder';

  @override
  String get aboutAppVersion => '版本';

  @override
  String get aboutAppDeveloper => '独立开发者';

  @override
  String get aboutAppDescription => 'Days Reminder - 倒数日历是一款简洁实用的工具应用，帮助你记录和提醒生活中每一个重要的日子。无论是生日、纪念日、考试、旅行，还是工作中的重要节点，都能轻松掌握，让你不错过任何一个值得期待的时刻。';

  @override
  String get aboutAppFeatures => '主要功能：';

  @override
  String get aboutAppFeatureLunar => '🗓️ 添加无限数量的倒数日和纪念日';

  @override
  String get aboutAppFeatureRecurrence => '🔔 灵活设置提醒，提前规划重要事件';

  @override
  String get aboutAppFeatureImportExport => '🎨 简洁清爽的界面，支持多种主题';

  @override
  String get aboutAppFeatureUI => '🌍 中英文支持，适合全球用户';

  @override
  String get aboutAppFeaturePrivacy => '\n\n让 Days Reminder 成为你的时间管家，记录生活，期待未来！';

  @override
  String get aboutAppFeatureOpenSource => '• 开源代码';

  @override
  String get aboutAppContact => '联系开发者';

  @override
  String get aboutAppEmail => '邮箱';

  @override
  String get aboutAppWebsite => '网站';

  @override
  String get aboutAppGitHub => 'GitHub';

  @override
  String get privacyCommitment => '我们承诺保护您的隐私：';

  @override
  String get feedbackTitle => '意见反馈';

  @override
  String get feedbackDescription => '我们重视您的反馈，以改进应用';

  @override
  String get feedbackHint => '请分享您的建议、问题报告或功能需求...';

  @override
  String get feedbackSubmit => '提交';

  @override
  String get feedbackThanks => '感谢您的反馈！';

  @override
  String get testNotification => '测试通知';

  @override
  String get testNotificationDesc => '发送测试通知验证功能';

  @override
  String get testEventNotification => '测试事件通知';

  @override
  String get testEventNotificationDesc => '使用第一个事件发送测试通知';

  @override
  String get permissionGuideTitle => '通知权限';

  @override
  String get permissionGuideContent => '为了及时提醒您重要的事件，建议开启通知权限。您可以在设置中随时关闭。';

  @override
  String get enableNotification => '开启通知';

  @override
  String get laterSetup => '稍后设置';

  @override
  String get manualPermissionTitle => '需要手动开启通知权限';

  @override
  String get manualPermissionContent => '请在系统设置中手动开启通知权限，以便接收事件提醒。';

  @override
  String get invalidLunarDate => '所选农历日期无效，请重试';

  @override
  String get createdOn => '创建时间';

  @override
  String get lastModified => '最后修改';

  @override
  String get recurrence => '重复';

  @override
  String get noRecurrence => '不重复';

  @override
  String get yearly => '每年';

  @override
  String get monthly => '每月';

  @override
  String get weekly => '每周';

  @override
  String get daily => '每天';

  @override
  String get dateFormatMonthDay => 'M月d日';

  @override
  String get dateFormatFull => 'yyyy年M月d日';

  @override
  String get dateFormatShort => 'yyyy-M-d';

  @override
  String get lunarPrefix => '农历';

  @override
  String lunarDateWithBrackets(Object date) {
    return '($date)';
  }

  @override
  String get countdownPrefix => '还有';

  @override
  String get countdownSuffix => '天';

  @override
  String get countdownOverduePrefix => '已经';

  @override
  String get countdownOverdueSuffix => '天';

  @override
  String get countdownToday => '就是今天！';

  @override
  String get countdownDays => '天';

  @override
  String get countdownDay => '天';

  @override
  String get countdownAfter => '后';

  @override
  String get countdownBefore => '前';

  @override
  String ageUpcoming(Object age) {
    return '即将 $age 岁';
  }

  @override
  String get milestoneThousand => '千日纪念';

  @override
  String get milestoneFiveHundred => '五百日';

  @override
  String get milestoneHundred => '百日纪念';

  @override
  String get milestoneSweet => '甜蜜时光';

  @override
  String get recurrenceYearly => '每年';

  @override
  String get recurrenceMonthly => '每月';

  @override
  String get recurrenceWeekly => '每周';

  @override
  String get eventDetailDate => '日期';

  @override
  String get eventDetailRecurrence => '重复';

  @override
  String get eventDetailType => '类型';

  @override
  String get eventDetailCurrentAge => '当前年龄';

  @override
  String get eventDetailNote => '备注';

  @override
  String get eventDetailAgeUnit => '岁';

  @override
  String get eventDetailRecurrenceYearly => '每年重复';

  @override
  String get eventDetailRecurrenceMonthly => '每月重复';

  @override
  String get eventDetailRecurrenceWeekly => '每周重复';

  @override
  String get eventDetailRecurrenceNone => '不重复';

  @override
  String get selectDate => '选择日期';

  @override
  String get addEventNoteHint => '添加备注（可选）';

  @override
  String get addEventBirthdayHint => '输入姓名/事件标题（如：张三生日）';

  @override
  String get addEventAnniversaryHint => '输入纪念日标题（如：结婚纪念日）';

  @override
  String get addEventCountdownHint => '输入事件标题';

  @override
  String get lunarCalendar => '阴历';

  @override
  String get solarCalendar => '公历';

  @override
  String get ok => '确定';

  @override
  String get confirm => '确认';

  @override
  String get close => '关闭';

  @override
  String get loading => '获取中...';

  @override
  String get error => '错误';

  @override
  String get success => '成功';

  @override
  String get warning => '警告';

  @override
  String get info => '信息';

  @override
  String get saturday => '星期六';

  @override
  String get timeUnitsDays => '天';

  @override
  String get timeUnitsDay => '天';

  @override
  String get timeUnitsHours => '小时';

  @override
  String get timeUnitsHour => '小时';

  @override
  String get timeUnitsMinutes => '分钟';

  @override
  String get timeUnitsMinute => '分钟';

  @override
  String get lunarDate => '农历日期';

  @override
  String get solarDate => '公历日期';

  @override
  String get lunarMonth => '农历月';

  @override
  String get lunarDay => '农历日';

  @override
  String get addRecord => '新增记录';

  @override
  String get editRecord => '编辑记录';

  @override
  String get recordContentHint => '记录这一刻的美好...';

  @override
  String get pleaseAddContent => '请添加记录内容';

  @override
  String get recordUpdated => '记录已更新';

  @override
  String get recordAdded => '记录已添加';

  @override
  String saveFailed(Object error) {
    return '保存失败：$error';
  }

  @override
  String get cameraPermissionRequired => '需要相机权限才能拍照';

  @override
  String get photoPermissionRequired => '需要相册权限才能选择图片';

  @override
  String get cameraTimeout => '拍照超时，请重试';

  @override
  String get cameraNotAvailable => '相机不可用，请检查相机是否被其他应用占用';

  @override
  String photoFailed(Object error) {
    return '拍照失败：$error';
  }

  @override
  String get addPhoto => '添加照片';

  @override
  String get takePhoto => '拍照';

  @override
  String get selectFromGallery => '从相册选择';

  @override
  String get removePhoto => '删除照片';

  @override
  String get photoPreview => '照片预览';

  @override
  String get photoBroken => '图片已损坏';

  @override
  String get permissionDenied => '权限被拒绝';

  @override
  String get permissionDeniedDesc => '请在设置中允许相机和相册权限';

  @override
  String get photoTimeout => '选择图片超时，请重试';

  @override
  String selectPhotoFailed(Object error) {
    return '选择图片失败：$error';
  }

  @override
  String saveImageFailed(Object error) {
    return '保存图片失败: $error';
  }

  @override
  String get confirmLeave => '确认离开';

  @override
  String get confirmLeaveDesc => '您已编辑了内容，离开将丢失已编辑的内容，确定要离开吗？';

  @override
  String get continueEditing => '继续';

  @override
  String get confirmLeaveAction => '离开';

  @override
  String get permissionRequired => '需要权限';

  @override
  String get permissionRequiredDesc => '应用需要相机或相册权限才能添加图片。请在设置中允许相关权限。';

  @override
  String get deleteImage => '删除图片';

  @override
  String get deleteImageConfirm => '确定要删除这张图片吗？';

  @override
  String get community => '社区';

  @override
  String get noRecordsFound => '暂无记录';

  @override
  String get noRecordsFoundDesc => '还没有任何记录，快去添加第一个吧';

  @override
  String get searchRecords => '搜索记录';

  @override
  String get searchHint => '输入事件名称进行搜索...';

  @override
  String get search => '搜索';

  @override
  String get deletedEvent => '已删除的事件';

  @override
  String get clearSearch => '清空搜索';

  @override
  String get eventName => '事件名称';

  @override
  String get recordTime => '记录时间';

  @override
  String get viewDetails => '查看详情';

  @override
  String get showEvent => '显示事件';

  @override
  String get hideEvent => '隐藏事件';

  @override
  String get imageLost => '图片已丢失';

  @override
  String get deleteRecord => '删除记录';

  @override
  String get deleteRecordConfirm => '确定要删除这条记录吗？删除后无法恢复。';

  @override
  String get recordDeleted => '记录已删除';

  @override
  String get deleteFailed => '删除失败';

  @override
  String get paymentSystemInitializing => '支付系统正在初始化中，请稍后再试';

  @override
  String get noRecordsYet => '还没有记录';

  @override
  String get addMemoriesForSpecialDay => '为这个特殊的日子添加回忆';

  @override
  String get unhideEvent => '显示事件';

  @override
  String get unhideEventDesc => '确定要显示这个事件吗？';

  @override
  String get hideEventDesc => '确定要隐藏这个事件吗？';

  @override
  String recordCount(Object count) {
    return '共 $count 条记录';
  }

  @override
  String get viewAllRecords => '查看所有记录';

  @override
  String get recordDetails => '记录详情';

  @override
  String get recordContent => '记录内容';

  @override
  String get recordImages => '记录图片';

  @override
  String get recordLocation => '记录位置';

  @override
  String get recordDate => '记录日期';

  @override
  String get confirmDeleteRecord => '确认删除记录';

  @override
  String get confirmDeleteRecordDesc => '确定要删除这条记录吗？此操作无法撤销。';

  @override
  String get personalCenter => '个人中心';

  @override
  String get vipStatus => '会员状态';

  @override
  String get vipExpired => '会员已过期';

  @override
  String get vipActive => '会员有效';

  @override
  String vipExpireDate(Object date) {
    return '到期时间：$date';
  }

  @override
  String get upgradeToVip => '升级会员';

  @override
  String get vipBenefits => '会员特权';

  @override
  String get unlimitedHideEvents => '无限制隐藏事件';

  @override
  String get unlimitedHideEventsDesc => '免费用户只能隐藏3个事件，会员可无限制隐藏';

  @override
  String get vipFeatures => '会员功能';

  @override
  String get vipFeature1 => '• 无限制隐藏事件';

  @override
  String get vipFeature2 => '• 优先客服支持';

  @override
  String get vipFeature3 => '• 专属主题';

  @override
  String get vipFeature4 => '• 更多功能即将推出';

  @override
  String get purchaseVip => '购买会员';

  @override
  String get restorePurchase => '恢复购买';

  @override
  String get vipPurchaseSuccess => '会员购买成功！';

  @override
  String get vipPurchaseFailed => '会员购买失败';

  @override
  String get vipRestoreSuccess => '购买恢复成功';

  @override
  String get vipRestoreFailed => '购买恢复失败';

  @override
  String get paymentInitializing => '支付系统正在初始化中，请稍后再试';

  @override
  String get notificationPermissionSettings => '通知权限设置';

  @override
  String get domesticPhonePermissionSettings => '通知权限设置';

  @override
  String get setUpLater => '稍后设置';

  @override
  String get goToSettings => '去设置';

  @override
  String get notificationPermissionAuthorized => '通知权限已授权';

  @override
  String get defaultUserName => '用户';

  @override
  String get checkingPermissionStatus => '正在检查权限状态...';

  @override
  String get unableToGetPermissionStatus => '无法获取权限状态';

  @override
  String get authorized => '已授权';

  @override
  String get notAuthorized => '未授权';

  @override
  String get permanentlyDenied => '永久拒绝';

  @override
  String get unknownStatus => '未知状态';

  @override
  String get vipDialogTitle => '开通会员';

  @override
  String get upgradeNow => '开通';

  @override
  String get unlimitedHideEventsTitle => '无限制隐藏事件';

  @override
  String get vipDialogDesc => '解锁更多功能，享受更好的使用体验';

  @override
  String get monthlySubscription => '月度订阅';

  @override
  String get yearlySubscription => '年度订阅';

  @override
  String get bestValue => '最划算';

  @override
  String subscriptionPrice(Object price) {
    return '¥$price/月';
  }

  @override
  String yearlyPrice(Object price) {
    return '¥$price/年';
  }

  @override
  String get subscriptionFeatures => '订阅功能';

  @override
  String get subscriptionTerms => '订阅条款';

  @override
  String get termsOfService => '服务条款';

  @override
  String get restorePurchases => '恢复';

  @override
  String get purchaseNow => '立即购买';

  @override
  String get subscriptionNote => '订阅将自动续费，可随时在设置中取消';

  @override
  String get trialPeriod => '试用期';

  @override
  String get freeTrial => '免费试用';

  @override
  String trialDays(Object days) {
    return '$days天免费试用';
  }

  @override
  String get afterTrial => '试用期后';

  @override
  String get subscriptionRenewal => '订阅将自动续费';

  @override
  String get uidCopiedToClipboard => 'UID已复制到剪贴板';

  @override
  String get processingPurchase => '正在处理购买...';

  @override
  String get purchaseCancelledOrFailed => '购买被取消或失败';

  @override
  String get purchaseFailed => '购买失败';

  @override
  String get purchaseRestoreSuccess => '购买恢复成功！';

  @override
  String get noPurchasesToRestore => '未找到可恢复的购买';

  @override
  String get restorePurchaseFailed => '恢复购买失败';

  @override
  String get validUntil => '有效期至';

  @override
  String get vipUser => '会员用户';

  @override
  String get backupManagement => '备份管理';

  @override
  String get backupManagementDesc => '管理数据备份和恢复';

  @override
  String get createBackup => '创建备份';

  @override
  String get importDataWarning => '导入数据将覆盖现有数据，确定继续吗？';

  @override
  String get restoreBackup => '恢复备份';

  @override
  String get restoreBackupWarning => '恢复备份将覆盖现有数据，确定继续吗？';

  @override
  String get restoreSuccess => '恢复成功';

  @override
  String get deleteBackup => '删除备份';

  @override
  String get deleteBackupWarning => '确定要删除这个备份文件吗？';

  @override
  String get deleteSuccess => '删除成功';

  @override
  String get noBackupFiles => '暂无备份文件';

  @override
  String get noBackupFilesDesc => '还没有任何备份文件';

  @override
  String get size => '大小';

  @override
  String get createdAt => '创建时间';

  @override
  String get share => '分享';

  @override
  String get export => '导出';

  @override
  String get dataManagement => '数据管理';

  @override
  String get clearAllDataDesc => '清除所有事件和记录数据';

  @override
  String get biometricAuthReason => '使用生物识别验证身份';

  @override
  String get biometricAuthCancel => '取消';

  @override
  String get biometricAuthGoToSettings => '去设置';

  @override
  String get biometricAuthGoToSettingsDesc => '请在设置中启用生物识别';

  @override
  String get biometricAuthFailed => '生物识别验证失败';

  @override
  String get hideEvents => '隐藏事件';

  @override
  String get showHiddenEvents => '显示隐藏事件';

  @override
  String photosCount(Object count) {
    return '共 $count 张照片';
  }

  @override
  String get location => '位置';

  @override
  String get timeInfo => '时间信息';

  @override
  String get createdTime => '创建时间';

  @override
  String get updatedTime => '更新时间';

  @override
  String get photoRecord => '照片记录';

  @override
  String get textRecord => '文字记录';

  @override
  String get mixedRecord => '混合记录';

  @override
  String get notificationPermission => '通知权限';

  @override
  String get status => '状态';

  @override
  String get refreshPermissionStatus => '刷新权限状态';
}
