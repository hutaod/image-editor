import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:async';
import 'dart:io';

import '../models/event.dart';
import '../providers/settings_provider.dart';
import '../utils/event_display_utils.dart';
import 'calendar_sync_service.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  CalendarSyncService? _calendarSyncService;
  bool _inited = false;

  /// 获取CalendarSyncService实例，只在需要时初始化
  Future<CalendarSyncService?> _getCalendarSyncService() async {
    // 在iOS上直接返回null，不初始化CalendarSyncService
    if (Platform.isIOS) {
      return null;
    }

    // 在Android上延迟初始化
    _calendarSyncService ??= CalendarSyncService();
    return _calendarSyncService;
  }

  /// 检查是否应该使用日历同步
  Future<bool> _shouldUseCalendarSync() async {
    // 在iOS上直接返回false，不使用日历同步
    if (Platform.isIOS) {
      return false;
    }

    // 在Android上检查是否应该使用日历同步
    final calendarSyncService = await _getCalendarSyncService();
    return calendarSyncService != null &&
        await calendarSyncService.shouldUseCalendarSync();
  }

  Future<void> init() async {
    if (_inited) return;

    // 注意：权限请求已移至设置页面处理，避免重复弹窗
    // 这里只初始化通知插件，不主动请求权限

    // Timezone
    try {
      tz.initializeTimeZones();

      // 简化时区处理，直接使用本地时区
      String localTz = 'UTC';

      // 尝试设置时区，如果失败则使用本地时区
      try {
        tz.setLocalLocation(tz.getLocation(localTz));
        if (kDebugMode) {
          print('Debug: 时区设置完成 - $localTz');
        }
      } catch (e) {
        // 如果时区设置失败，使用本地时区
        tz.setLocalLocation(tz.local);
        if (kDebugMode) {
          print('Debug: 使用本地时区 - $e');
        }
      }
    } catch (e) {
      // 兜底使用 UTC，避免因少数环境时区解析失败导致崩溃
      tz.setLocalLocation(tz.getLocation('UTC'));
      if (kDebugMode) {
        print('Debug: 时区设置失败，使用UTC: $e');
      }
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true, // 请求通知权限
      requestBadgePermission: false, // 禁用badge避免红点
      requestSoundPermission: false, // 请求声音权限
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    try {
      await _plugin.initialize(initSettings);
      if (kDebugMode) {
        print('Debug: 通知插件初始化成功');
      }
    } catch (e) {
      // 忽略初始化异常，后续安排时同样有兜底
      if (kDebugMode) {
        print('Debug: 通知插件初始化失败: $e');
      }
    }
    _inited = true;
  }

  Future<void> rescheduleAll(
    Iterable<Event> events, {
    BuildContext? context,
  }) async {
    await init();
    if (kDebugMode) {
      print('Debug: 开始重新安排所有通知，事件数量: ${events.length}');
    }

    // 检查是否应该使用日历同步
    final shouldUseCalendarSync = await _shouldUseCalendarSync();

    if (shouldUseCalendarSync) {
      // 在release包中也保留调试日志
      print('Debug: 设备使用日历同步，跳过重新安排所有事件（只在单个事件操作时同步）');
      return;
    } else {
      if (kDebugMode) {
        print('Debug: 使用推送通知方式安排提醒');
      }

      // 先取消所有现有通知
      await _plugin.cancelAll();

      for (final e in events) {
        await scheduleForEvent(e, context: context);
      }
    }

    if (kDebugMode) {
      print('Debug: 所有通知重新安排完成');
    }
  }

  int _idFor(Event e, {required bool advance}) {
    // 生成稳定的通知ID
    final base = e.id.hashCode & 0x7FFFFFFF; // 正整数
    return advance ? base ^ 0xABCDEF : base ^ 0x123456;
  }

  tz.TZDateTime _atNineLocal(tz.TZDateTime day) {
    return tz.TZDateTime(day.location, day.year, day.month, day.day, 9, 0);
  }

  Future<(bool enabled, int days)> _readAdvanceSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(SettingsKeys.advanceReminderEnabled) ?? true;
    final days = prefs.getInt(SettingsKeys.advanceReminderDays) ?? 1;
    return (enabled, days);
  }

  /// 为事件安排通知/日历同步
  /// 返回值：如果使用日历同步，返回日历事件ID；否则返回null
  Future<String?> scheduleForEvent(
    Event e, {
    BuildContext? context,
    bool isUpdate = false,
  }) async {
    await init();

    // 检查是否应该使用日历同步
    final shouldUseCalendarSync = await _shouldUseCalendarSync();

    if (shouldUseCalendarSync) {
      // 在release包中也保留调试日志
      print('Debug: 为事件 ${e.title} 使用日历同步方式安排提醒');

      // 获取CalendarSyncService实例
      final calendarSyncService = await _getCalendarSyncService();
      if (calendarSyncService == null) return null;

      // 根据是否为更新操作选择不同的同步方法
      final calendarEventId = isUpdate
          ? await calendarSyncService.syncEventUpdateToCalendar(e)
          : await calendarSyncService.syncEventToCalendar(e);

      // 在release包中也保留调试日志
      print('Debug: 日历同步结果 - 日历事件ID: $calendarEventId');
      return calendarEventId;
    }

    // 只有在有Google服务时才安排推送通知
    // 对于更新操作，先取消旧通知
    if (isUpdate) {
      if (kDebugMode) {
        print('Debug: 更新推送通知 - 先取消旧通知: ${e.title}');
      }
      await _plugin.cancel(e.id.hashCode);
      await _plugin.cancel(_idFor(e, advance: true));
    }

    // 检查是否已经安排过通知，避免重复
    final existingNotifications = await _plugin.pendingNotificationRequests();
    final notificationId = e.id.hashCode;
    final alreadyScheduled = existingNotifications.any(
      (n) => n.id == notificationId,
    );

    if (alreadyScheduled && !isUpdate) {
      if (kDebugMode) {
        print('Debug: 事件 ${e.title} 的通知已经安排过，跳过重复安排');
      }
      return null;
    }

    try {
      // 计算下一次发生日期（本地时区当天的9:00提醒）
      final now = tz.TZDateTime.now(tz.local);
      final nextDate = e.nextOccurrenceFrom(DateTime.now());
      final when = _atNineLocal(
        tz.TZDateTime(tz.local, nextDate.year, nextDate.month, nextDate.day),
      );

      // 确保通知时间在未来
      if (!when.isAfter(now)) {
        if (kDebugMode) {
          print('Debug: 跳过通知 - 时间已过: $when (当前: $now)');
        }
        return null;
      }

      // 调试信息
      if (kDebugMode) {
        print('Debug: 安排通知 - 事件: ${e.title}');
        print('Debug: 当前时间: $now');
        print('Debug: 事件日期: $nextDate');
        print('Debug: 提醒时间: $when');
        print('Debug: 是否在未来: ${when.isAfter(now)}');
      }

      final androidDetails = const AndroidNotificationDetails(
        'event_channel',
        '事件提醒',
        channelDescription: '事件到期与提前提醒',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        showWhen: true,
        enableLights: true,
        ledColor: Color(0xFF5A9BD5),
        ledOnMs: 1000,
        ledOffMs: 500,
        autoCancel: false,
        ongoing: false,
        visibility: NotificationVisibility.public,
        fullScreenIntent: false,
        category: AndroidNotificationCategory.reminder,
        channelShowBadge: false,
        icon: '@mipmap/ic_launcher',
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false, // 不显示badge，避免红点问题
        presentSound: true,
        sound: 'default',
      );
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      if (when.isAfter(now)) {
        // 获取本地化的标题和文案
        final localizedTitle = context != null
            ? EventDisplayUtils.getLocalizedTitle(context, e)
            : e.title;
        final notificationText = context != null
            ? '${e.formattedDate()} 即将到来'
            : '${e.formattedDate()} coming soon';

        if (kDebugMode) {
          print('Debug: 安排当天通知 - 标题: $localizedTitle, 内容: $notificationText');
        }

        await _plugin.zonedSchedule(
          _idFor(e, advance: false),
          localizedTitle,
          notificationText,
          when,
          details,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.wallClockTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dateAndTime,
          payload: 'event_${e.id}',
        );

        if (kDebugMode) {
          print('Debug: 当天通知已安排成功');
        }
      } else {
        if (kDebugMode) {
          print('Debug: 跳过当天通知 - 时间已过');
        }
      }

      // 提前提醒
      final (enabled, days) = await _readAdvanceSettings();
      if (kDebugMode) {
        print('Debug: 提前提醒设置 - 开启: $enabled, 天数: $days');
      }

      if (enabled) {
        final advanceWhen = when.subtract(Duration(days: days));
        if (kDebugMode) {
          print('Debug: 提前提醒时间: $advanceWhen');
          print('Debug: 提前提醒是否在未来: ${advanceWhen.isAfter(now)}');
        }

        if (advanceWhen.isAfter(now)) {
          // 获取本地化的标题和文案
          final localizedTitle = context != null
              ? EventDisplayUtils.getLocalizedTitle(context, e)
              : e.title;
          final advanceTitle = context != null
              ? '提前提醒 · $localizedTitle'
              : 'Advance reminder · $localizedTitle';
          final advanceText = context != null
              ? '还有 $days 天（${e.formattedDate()}）'
              : '$days days left (${e.formattedDate()})';

          if (kDebugMode) {
            print('Debug: 安排提前通知 - 标题: $advanceTitle, 内容: $advanceText');
          }

          await _plugin.zonedSchedule(
            _idFor(e, advance: true),
            advanceTitle,
            advanceText,
            advanceWhen,
            details,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.wallClockTime,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dateAndTime,
            payload: 'event_${e.id}_advance',
          );

          if (kDebugMode) {
            print('Debug: 提前通知已安排成功');
          }
        } else {
          if (kDebugMode) {
            print('Debug: 跳过提前通知 - 时间已过');
          }
        }
      } else {
        if (kDebugMode) {
          print('Debug: 提前提醒已关闭');
        }
      }
    } catch (_) {
      // 忽略安排异常，避免首次添加时报错
    }

    // 对于推送通知方式，不返回日历事件ID
    return null;
  }

  /// 检查今天或明天的事件，如果已过通知时间则立即发送通知
  Future<void> checkImmediateNotifications(
    Iterable<Event> events, {
    BuildContext? context,
  }) async {
    await init();
    if (kDebugMode) {
      print('Debug: 检查即时通知，事件数量: ${events.length}');
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final notificationTime = DateTime(now.year, now.month, now.day, 9, 0);

    // 如果当前时间已过今天的通知时间，检查今天和明天的事件
    if (now.isAfter(notificationTime)) {
      if (kDebugMode) {
        print('Debug: 当前时间已过通知时间，检查今天和明天的事件');
      }

      for (final event in events) {
        final nextOccurrence = event.nextOccurrenceFrom(DateTime.now());
        final eventDateOnly = DateTime(
          nextOccurrence.year,
          nextOccurrence.month,
          nextOccurrence.day,
        );

        // 检查是否是今天或明天的事件
        if (eventDateOnly == today || eventDateOnly == tomorrow) {
          if (kDebugMode) {
            print('Debug: 发现今天/明天的事件: ${event.title}, 日期: $eventDateOnly');
          }

          // 根据环境设置不同的延迟时间
          final delayDuration = kDebugMode
              ? const Duration(seconds: 10) // Debug模式：10秒
              : const Duration(minutes: 10); // Release模式：10分钟

          if (kDebugMode) {
            print('Debug: 将在${kDebugMode ? "10秒" : "10分钟"}后发送即时通知');
          }

          Timer(delayDuration, () async {
            await _sendImmediateNotification(event, context: context);
          });
        }
      }
    }
  }

  /// 发送即时通知
  Future<void> _sendImmediateNotification(
    Event event, {
    BuildContext? context,
  }) async {
    try {
      final localizedTitle = context != null
          ? EventDisplayUtils.getLocalizedTitle(context, event)
          : event.title;
      final notificationText = context != null
          ? '${event.formattedDate()} 即将到来'
          : '${event.formattedDate()} coming soon';

      const androidDetails = AndroidNotificationDetails(
        'immediate_channel',
        '即时提醒',
        channelDescription: '事件即将到来的即时提醒',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        showWhen: true,
        enableLights: true,
        ledColor: Color(0xFF5A9BD5),
        ledOnMs: 1000,
        ledOffMs: 500,
        autoCancel: false,
        ongoing: false,
        visibility: NotificationVisibility.public,
        fullScreenIntent: false,
        category: AndroidNotificationCategory.reminder,
        channelShowBadge: false,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false, // 不显示badge，避免红点问题
        presentSound: true,
        sound: 'default',
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.show(
        _idFor(event, advance: false) + 1000000, // 使用不同的ID避免冲突
        localizedTitle,
        notificationText,
        details,
        payload: 'immediate_event_${event.id}',
      );

      if (kDebugMode) {
        print('Debug: 即时通知已发送: $localizedTitle');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Debug: 发送即时通知失败: $e');
      }
    }
  }

  Future<void> cancelForEvent(Event e) async {
    await init();

    // 检查是否应该使用日历同步
    final shouldUseCalendarSync = await _shouldUseCalendarSync();

    if (shouldUseCalendarSync) {
      if (kDebugMode) {
        print('Debug: 使用日历同步模式，从日历中删除事件: ${e.title}');
      }

      // 获取CalendarSyncService实例
      final calendarSyncService = await _getCalendarSyncService();
      if (calendarSyncService == null) return;

      // 从日历中删除事件
      await calendarSyncService.syncEventDeleteFromCalendar(e);
      return;
    }

    // 只有在有Google服务时才取消推送通知

    try {
      // 取消当天通知
      await _plugin.cancel(_idFor(e, advance: false));
      // 取消提前通知
      await _plugin.cancel(_idFor(e, advance: true));
      // 取消即时通知（使用不同的ID）
      await _plugin.cancel(_idFor(e, advance: false) + 1000000);
      if (kDebugMode) {
        print('Debug: 已取消事件通知: ${e.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Debug: 取消事件通知失败: $e');
      }
    }
  }
}
