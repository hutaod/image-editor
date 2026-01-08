import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/event.dart';
import '../services/notification_service.dart';
import '../utils/lunar_utils.dart';

const String eventsBoxName = 'eventsBox';

final hiveBoxProvider = Provider<Box<Event>>(
  (ref) => throw UnimplementedError('Hive box not initialized'),
);

final eventsProvider = StateNotifierProvider<EventsNotifier, List<Event>>((
  ref,
) {
  final box = ref.watch(hiveBoxProvider);
  return EventsNotifier(box);
});

class EventsNotifier extends StateNotifier<List<Event>> {
  EventsNotifier(this._box) : super(_sorted(_box.values.toList())) {
    // 确保存在默认的“星期六”倒数日
    Future.microtask(_ensureDefaultSaturday);
  }

  final Box<Event> _box;

  static List<Event> _sorted(List<Event> list) {
    list.sort(_smartCompare);
    return list;
  }

  Future<void> _ensureDefaultSaturday() async {
    final prefs = await SharedPreferences.getInstance();

    // 数据迁移：为老用户的默认事件设置 isDefaultEvent = true
    final migrated = prefs.getBool('_migrated_default_event_flag') ?? false;
    if (!migrated) {
      for (final event in _box.values) {
        if (event.title == '__DEFAULT_SATURDAY__' &&
            event.kind == EventKind.countdown &&
            !event.isDefaultEvent) {
          // 找到老的默认事件，更新 isDefaultEvent 标志
          event.isDefaultEvent = true;
          await _box.put(event.id, event);
          print('Debug: 已为老用户的默认事件设置 isDefaultEvent 标志');
        }
      }
      await _box.flush();
      await prefs.setBool('_migrated_default_event_flag', true);
    }

    // 检查是否刚刚重建了数据库，如果是则不创建默认事件
    final bool databaseRebuilt = prefs.getBool('_database_rebuilt') ?? false;
    if (databaseRebuilt) {
      print('Debug: 数据库刚刚重建，跳过创建默认事件');
      // 清除标记，避免下次启动时仍然跳过
      await prefs.remove('_database_rebuilt');
      return;
    }

    // 检查用户是否已经删除了默认事件
    final userDeletedDefault =
        prefs.getBool('user_deleted_default_saturday') ?? false;

    // 如果用户已经删除过默认事件，则不再创建
    if (userDeletedDefault) return;

    // 检查是否已经创建过默认事件（即使用户修改了标题）
    final hasCreatedDefault =
        prefs.getBool('has_created_default_saturday') ?? false;

    // 如果已经创建过默认事件，则不再创建
    if (hasCreatedDefault) return;

    // 检查是否已经存在默认事件（使用 isDefaultEvent 字段判断，而不是标题）
    final hasDefault = _box.values.any((e) => e.isDefaultEvent);
    if (hasDefault) {
      // 如果已经存在默认事件，标记为已创建，避免重复创建
      await prefs.setBool('has_created_default_saturday', true);
      return;
    }

    final DateTime today = DateTime.now();
    final DateTime base = DateTime(today.year, today.month, today.day);
    // Monday=1..Sunday=7, Saturday=6
    final int daysToAdd = (6 - base.weekday + 7) % 7;
    final DateTime nextSaturday = base.add(Duration(days: daysToAdd));
    final Event saturday = Event.create(
      id: const Uuid().v4(),
      title: '__DEFAULT_SATURDAY__',
      date: nextSaturday,
      kind: EventKind.countdown,
      recurrenceUnit: RecurrenceUnit.week,
      recurrenceInterval: 1,
      isDefaultEvent: true, // 标记为默认事件
    );
    await _box.put(saturday.id, saturday);
    // 确保默认事件创建立即持久化到磁盘
    await _box.flush();
    state = _sorted([..._box.values]);
    await NotificationService.instance.scheduleForEvent(saturday);

    // 标记已经创建过默认事件，即使用户修改了标题也不再创建
    await prefs.setBool('has_created_default_saturday', true);
  }

  static int _smartCompare(Event a, Event b) {
    final _SortKey ga = _groupKeyOf(a);
    final _SortKey gb = _groupKeyOf(b);
    // group: 0 -> birthday/countdown, 1 -> anniversary
    if (ga.group != gb.group) return ga.group.compareTo(gb.group);
    // within same group compare key
    return ga.compareTo(gb);
  }

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  static DateTime _eventBaseDate(Event e) {
    if (e.isLunar) {
      return LunarUtils.lunarToSolar(
        year: e.lunarYear ?? DateTime.now().year,
        month: e.lunarMonth ?? 1,
        day: e.lunarDay ?? 1,
        isLeap: e.lunarLeap ?? false,
      );
    }
    return e.date;
  }

  static DateTime _nextOccurrenceFor(Event e, DateTime base) {
    DateTime next = DateTime(base.year, base.month, base.day);
    if (e.recurrenceUnit == RecurrenceUnit.none) return base;
    final now = _dateOnly(DateTime.now());
    while (next.isBefore(now)) {
      switch (e.recurrenceUnit) {
        case RecurrenceUnit.year:
          next = DateTime(
            next.year + e.recurrenceInterval,
            next.month,
            next.day,
          );
          break;
        case RecurrenceUnit.month:
          final int y =
              next.year + (next.month - 1 + e.recurrenceInterval) ~/ 12;
          final int m = (next.month - 1 + e.recurrenceInterval) % 12 + 1;
          final int lastDay = DateTime(y, m + 1, 0).day;
          final int d = next.day > lastDay ? lastDay : next.day;
          next = DateTime(y, m, d);
          break;
        case RecurrenceUnit.week:
          next = next.add(Duration(days: 7 * e.recurrenceInterval));
          break;
        case RecurrenceUnit.none:
          return base;
      }
    }
    return next;
  }

  static _SortKey _groupKeyOf(Event e) {
    final now = _dateOnly(DateTime.now());
    switch (e.kind) {
      case EventKind.birthday:
      case EventKind.countdown:
        final base = _dateOnly(_eventBaseDate(e));
        final next = _nextOccurrenceFor(e, base);
        final int delta = _dateOnly(next).difference(now).inDays;
        final bool isPast = delta < 0;
        final int value = isPast ? -delta : delta;
        // Future first (isPast=false), then smaller delta
        return _SortKey(
          group: 0,
          isPast: isPast,
          value: value,
          tiebreaker: base.millisecondsSinceEpoch,
        );
      case EventKind.anniversary:
        final base = _dateOnly(_eventBaseDate(e));
        int since = now.difference(base).inDays;
        if (since < 0)
          since = 0; // future anniversaries treated as 0 days passed
        return _SortKey(
          group: 1,
          isPast: false,
          value: since,
          tiebreaker: base.millisecondsSinceEpoch,
        );
    }
  }

  Future<Event> addEvent({
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
  }) async {
    // 新增到顶部：找出现有最小 orderIndex，然后设置为 min-1
    int? minOrder;
    for (final e in _box.values) {
      if (e.orderIndex != null) {
        final int candidate = e.orderIndex!;
        if (minOrder == null || candidate < minOrder) {
          minOrder = candidate;
        }
      }
    }
    final int nextIndex = (minOrder ?? 0) - 1;

    final event = Event.create(
      id: const Uuid().v4(),
      title: title,
      date: date,
      note: note,
      isLunar: isLunar,
      lunarYear: lunarYear,
      lunarMonth: lunarMonth,
      lunarDay: lunarDay,
      lunarLeap: lunarLeap,
      recurrenceUnit: recurrenceUnit,
      recurrenceInterval: recurrenceInterval,
      kind: kind,
      orderIndex: nextIndex,
    );
    await _box.put(event.id, event);
    // 确保添加操作立即持久化到磁盘
    await _box.flush();
    state = _sorted([..._box.values]);

    print('🔍 EventProvider.addEvent: 准备安排通知 - ${event.title}');

    // 安排通知（只在需要时）并获取日历事件ID
    final calendarEventId = await NotificationService.instance.scheduleForEvent(
      event,
    );

    print('🔍 EventProvider.addEvent: 收到日历事件ID - $calendarEventId');

    // 如果返回了日历事件ID，更新事件
    if (calendarEventId != null && calendarEventId.isNotEmpty) {
      event.calendarEventId = calendarEventId;
      await _box.put(event.id, event);
      await _box.flush();
      state = _sorted([..._box.values]);
      print('✅ EventProvider.addEvent: 已保存日历事件ID - $calendarEventId');
    } else {
      print('⚠️ EventProvider.addEvent: 没有收到日历事件ID（可能使用推送通知）');
    }

    return event;
  }

  Future<void> deleteEvent(String id) async {
    final current = _box.get(id);
    if (current != null) {
      await NotificationService.instance.cancelForEvent(current);

      // 如果删除的是默认事件，记录用户已删除标记
      if (current.isDefaultEvent) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('user_deleted_default_saturday', true);
      }
    }
    await _box.delete(id);
    // 确保删除操作立即持久化到磁盘
    await _box.flush();
    state = _sorted([..._box.values]);
  }

  Future<void> updateEvent(Event event) async {
    print('🔍 EventProvider.updateEvent: 开始更新事件 - ${event.title}');
    print('🔍 EventProvider.updateEvent: 当前日历事件ID - ${event.calendarEventId}');

    await _box.put(event.id, event);
    // 确保更新操作立即持久化到磁盘
    await _box.flush();
    state = _sorted([..._box.values]);

    print('🔍 EventProvider.updateEvent: 准备重新安排通知');

    // 对于更新操作，直接调用 scheduleForEvent with isUpdate=true
    // NotificationService 会根据是否使用日历同步来决定是删除+创建 还是 直接更新
    final calendarEventId = await NotificationService.instance.scheduleForEvent(
      event,
      isUpdate: true,
    );

    print('🔍 EventProvider.updateEvent: 收到日历事件ID - $calendarEventId');

    // 如果返回了日历事件ID，更新事件
    if (calendarEventId != null && calendarEventId.isNotEmpty) {
      event.calendarEventId = calendarEventId;
      await _box.put(event.id, event);
      await _box.flush();
      state = _sorted([..._box.values]);
      print('✅ EventProvider.updateEvent: 已更新日历事件ID - $calendarEventId');
    } else {
      print('⚠️ EventProvider.updateEvent: 没有收到日历事件ID（可能使用推送通知或更新失败）');
    }
  }

  // 拖动排序功能已移除，保留占位以避免上层误调用

  String exportToJson() {
    final list = state.map((e) => e.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert(list);
  }

  Future<void> importFromJson(String jsonString) async {
    final dynamic parsed = json.decode(jsonString);
    if (parsed is! List) return;
    for (final item in parsed) {
      final event = Event.fromJson(Map<String, dynamic>.from(item as Map));
      await _box.put(event.id, event);
    }
    state = _sorted([..._box.values]);
    // 批量重排通知
    await NotificationService.instance.rescheduleAll(state);
  }

  Future<void> clearAllEvents() async {
    await _box.clear();
    state = [];
    // 清空后无通知可排
  }

  /// 刷新事件列表（从数据库重新加载）
  void refresh() {
    state = _sorted([..._box.values]);
  }
}

class _SortKey implements Comparable<_SortKey> {
  _SortKey({
    required this.group,
    required this.isPast,
    required this.value,
    required this.tiebreaker,
  });
  final int group; // 0 -> birthday/countdown, 1 -> anniversary
  final bool isPast; // group 0: future=false first; group 1: unused
  final int value; // group 0: abs(days to next), group 1: days since
  final int tiebreaker; // base date millis

  @override
  int compareTo(_SortKey other) {
    if (group != other.group) return group.compareTo(other.group);
    if (group == 0) {
      // future first (isPast=false < true)
      if (isPast != other.isPast)
        return (isPast ? 1 : 0) - (other.isPast ? 1 : 0);
      if (value != other.value) return value.compareTo(other.value);
      return tiebreaker.compareTo(other.tiebreaker);
    }
    if (value != other.value) return value.compareTo(other.value);
    return tiebreaker.compareTo(other.tiebreaker);
  }
}
