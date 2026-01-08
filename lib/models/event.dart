import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

part 'event.g.dart';

// EventType removed; logic derives from date and recurrence

/// 事件类型：生日、纪念日、倒数日
@HiveType(typeId: 6)
enum EventKind {
  @HiveField(0)
  birthday,
  @HiveField(1)
  anniversary,
  @HiveField(2)
  countdown,
}

@HiveType(typeId: 3)
enum RecurrenceUnit {
  @HiveField(0)
  none,
  @HiveField(1)
  year,
  @HiveField(2)
  month,
  @HiveField(3)
  week,
}

@HiveType(typeId: 2)
class Event extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  DateTime date;

  // Deprecated: type removed

  @HiveField(4)
  String? note;

  // Whether the original selection uses Lunar calendar
  @HiveField(5)
  bool isLunar;

  // Optional raw lunar info for display
  @HiveField(6)
  int? lunarYear;
  @HiveField(7)
  int? lunarMonth;
  @HiveField(8)
  int? lunarDay;
  @HiveField(9)
  bool? lunarLeap;

  // Recurrence configuration
  @HiveField(10)
  RecurrenceUnit recurrenceUnit;
  @HiveField(11)
  int recurrenceInterval;

  // 新增：事件类型
  @HiveField(12)
  EventKind kind;

  // 新增：是否隐藏事件
  @HiveField(13)
  bool isHidden;

  // 新增：是否是默认事件（用于标识系统创建的默认星期六事件）
  @HiveField(14)
  bool isDefaultEvent;

  // 新增：日历事件ID（用于日历同步时更新和删除事件）
  @HiveField(15)
  String? calendarEventId;

  // 自定义排序索引（越小越靠前），为空则按日期排序
  int? orderIndex;

  Event({
    required this.id,
    required this.title,
    required this.date,
    this.note,
    this.isLunar = false,
    this.lunarYear,
    this.lunarMonth,
    this.lunarDay,
    this.lunarLeap,
    this.recurrenceUnit = RecurrenceUnit.none,
    this.recurrenceInterval = 1,
    this.kind = EventKind.countdown,
    this.isHidden = false,
    this.isDefaultEvent = false,
    this.calendarEventId,
    this.orderIndex,
  });

  factory Event.create({
    required String id,
    required String title,
    required DateTime date,
    String? note,
    bool isLunar = false,
    int? lunarYear,
    int? lunarMonth,
    int? lunarDay,
    bool? lunarLeap,
    RecurrenceUnit recurrenceUnit = RecurrenceUnit.none,
    int recurrenceInterval = 1,
    EventKind kind = EventKind.countdown,
    bool isHidden = false,
    bool isDefaultEvent = false,
    String? calendarEventId,
    int? orderIndex,
  }) {
    return Event(
      id: id,
      title: title,
      date: _dateOnly(date),
      note: note,
      isLunar: isLunar,
      lunarYear: lunarYear,
      lunarMonth: lunarMonth,
      lunarDay: lunarDay,
      lunarLeap: lunarLeap,
      recurrenceUnit: recurrenceUnit,
      recurrenceInterval: recurrenceInterval,
      kind: kind,
      isHidden: isHidden,
      isDefaultEvent: isDefaultEvent,
      calendarEventId: calendarEventId,
      orderIndex: orderIndex,
    );
  }

  static DateTime _dateOnly(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  int get dayDelta {
    final DateTime today = _dateOnly(DateTime.now());
    final DateTime target = _dateOnly(date);
    return target.difference(today).inDays;
  }

  DateTime addMonths(DateTime base, int months) {
    final int newYear = base.year + (base.month - 1 + months) ~/ 12;
    final int newMonth = (base.month - 1 + months) % 12 + 1;
    final int day = base.day;
    final lastDay = DateTime(newYear, newMonth + 1, 0).day;
    final safeDay = day > lastDay ? lastDay : day;
    return DateTime(newYear, newMonth, safeDay);
  }

  DateTime addYears(DateTime base, int years) {
    final int newYear = base.year + years;
    final int month = base.month;
    final int day = base.day;
    final lastDay = DateTime(newYear, month + 1, 0).day;
    final safeDay = day > lastDay ? lastDay : day;
    return DateTime(newYear, month, safeDay);
  }

  DateTime nextOccurrenceFrom(DateTime from) {
    if (recurrenceUnit == RecurrenceUnit.none) {
      return _dateOnly(date);
    }

    // 标准化日期，只比较日期部分
    final fromDateOnly = _dateOnly(from);
    DateTime candidate = _dateOnly(date);

    // 只有当候选日期严格在目标日期之前时，才增加周期
    while (_dateOnly(candidate).isBefore(fromDateOnly)) {
      switch (recurrenceUnit) {
        case RecurrenceUnit.week:
          final int days = 7 * recurrenceInterval;
          candidate = candidate.add(Duration(days: days));
          break;
        case RecurrenceUnit.month:
          int months = recurrenceInterval;
          candidate = addMonths(candidate, months);
          break;
        case RecurrenceUnit.year:
          int years = recurrenceInterval;
          candidate = addYears(candidate, years);
          break;
        case RecurrenceUnit.none:
          break;
      }
    }
    return candidate;
  }

  int dayDeltaToNextOccurrence() {
    final now = DateTime.now();
    final next = nextOccurrenceFrom(now);
    // 使用日期计算天数差，确保按天数计算而不是按时间计算
    return _dateOnly(next).difference(_dateOnly(now)).inDays;
  }

  // Removed birthday/anniversary specific helpers; handled via recurrence/dayDelta

  /// Formatted date using intl, e.g., 2025-08-08
  String formattedDate({String pattern = 'yyyy-MM-dd'}) {
    return DateFormat(pattern).format(_dateOnly(date));
  }

  /// Get display title with localization support for default events
  /// Note: For proper localization, use EventDisplayUtils.getLocalizedTitle() instead
  String getDisplayTitle() {
    // 只有当事件是默认事件且标题未被修改时，才返回特殊标识
    if (isDefaultEvent && title == '__DEFAULT_SATURDAY__') {
      // This will be handled by the UI layer with proper localization
      return title;
    }
    return title;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': _dateOnly(date).toIso8601String(),
    'note': note,
    'isLunar': isLunar,
    'lunarYear': lunarYear,
    'lunarMonth': lunarMonth,
    'lunarDay': lunarDay,
    'lunarLeap': lunarLeap,
    'recurrenceUnit': recurrenceUnit.name,
    'recurrenceInterval': recurrenceInterval,
    'kind': kind.name,
    'isHidden': isHidden,
    'isDefaultEvent': isDefaultEvent,
    'calendarEventId': calendarEventId,
    'orderIndex': orderIndex,
  };

  static Event fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
      isLunar: json['isLunar'] as bool? ?? false,
      lunarYear: json['lunarYear'] as int?,
      lunarMonth: json['lunarMonth'] as int?,
      lunarDay: json['lunarDay'] as int?,
      lunarLeap: json['lunarLeap'] as bool?,
      recurrenceUnit: _parseRecurrence(json['recurrenceUnit'] as String?),
      recurrenceInterval: (json['recurrenceInterval'] as int?) ?? 1,
      kind: _parseKind(json['kind'] as String?),
      isHidden: json['isHidden'] as bool? ?? false,
      isDefaultEvent: json['isDefaultEvent'] as bool? ?? false,
      calendarEventId: json['calendarEventId'] as String?,
      orderIndex: json['orderIndex'] as int?,
    );
  }

  static RecurrenceUnit _parseRecurrence(String? name) {
    switch (name) {
      case 'year':
        return RecurrenceUnit.year;
      case 'month':
        return RecurrenceUnit.month;
      case 'week':
        return RecurrenceUnit.week;
      default:
        return RecurrenceUnit.none;
    }
  }

  static EventKind _parseKind(String? name) {
    switch (name) {
      case 'birthday':
        return EventKind.birthday;
      case 'anniversary':
        return EventKind.anniversary;
      case 'countdown':
      default:
        return EventKind.countdown;
    }
  }
}
