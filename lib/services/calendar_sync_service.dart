import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:device_calendar/device_calendar.dart' as device_calendar;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/event.dart';

/// 日历同步服务
/// 专门为无Google服务或非iPhone设备提供日历同步功能
class CalendarSyncService {
  static final CalendarSyncService _instance = CalendarSyncService._internal();
  factory CalendarSyncService() => _instance;
  CalendarSyncService._internal();

  bool? _shouldUseCalendarSync;
  bool? _isGoogleServicesAvailable;

  /// 检查是否应该使用日历同步
  /// 返回true表示应该使用日历同步（无Google服务或非iPhone设备）
  Future<bool> shouldUseCalendarSync() async {
    // 在release包中也保留调试日志
    print('🔍 设备检测: 开始检查是否应该使用日历同步');

    if (_shouldUseCalendarSync != null) {
      // 在release包中也保留调试日志
      print('🔍 设备检测: 使用缓存结果 - $_shouldUseCalendarSync');
      return _shouldUseCalendarSync!;
    }

    try {
      // 检查是否为iPhone
      if (Platform.isIOS) {
        _shouldUseCalendarSync = false;
        if (kDebugMode) {
          print('📱 设备检测: iPhone设备，不使用日历同步');
        }
        return false;
      }

      // 检查是否为Android设备
      if (Platform.isAndroid) {
        // 在release包中也保留调试日志
        print('🔍 设备检测: Android设备，检查Google服务可用性...');

        // 检查Google服务是否可用
        final hasGoogleServices = await _checkGoogleServicesAvailability();
        _shouldUseCalendarSync = !hasGoogleServices;

        if (hasGoogleServices) {
          // 在release包中也保留调试日志
          print('📱 设备检测: Android设备，Google服务可用，不使用日历同步');
        } else {
          // 在release包中也保留调试日志
          print('📱 设备检测: Android设备，Google服务不可用，使用日历同步');
        }

        return _shouldUseCalendarSync!;
      }

      // 其他平台默认不使用日历同步
      _shouldUseCalendarSync = false;
      if (kDebugMode) {
        print('📱 设备检测: 其他平台，不使用日历同步');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 设备检测失败: $e，默认不使用日历同步');
      }
      _shouldUseCalendarSync = false;
      return false;
    }
  }

  /// 检查Google服务是否可用
  /// 通过实际尝试使用Google相关服务来判断
  Future<bool> _checkGoogleServicesAvailability() async {
    if (_isGoogleServicesAvailable != null) {
      return _isGoogleServicesAvailable!;
    }

    try {
      // 尝试检查Google Play服务
      final hasGooglePlay = await _checkGooglePlayServices();
      if (hasGooglePlay) {
        _isGoogleServicesAvailable = true;
        if (kDebugMode) {
          print('✅ Google服务检测: Google Play服务可用');
        }
        return true;
      }

      // 如果Google Play服务不可用，则假设Google服务不可用
      _isGoogleServicesAvailable = false;
      if (kDebugMode) {
        print('❌ Google服务检测: Google Play服务不可用');
      }
      return false;
    } catch (e) {
      // 如果检测失败，默认假设Google服务不可用，使用日历同步
      _isGoogleServicesAvailable = false;
      if (kDebugMode) {
        print('❌ Google服务检测: 检测失败，默认Google服务不可用 - $e');
      }
      return false;
    }
  }

  /// 检查Google Play服务是否可用
  /// 通过尝试访问Google Play服务相关功能来判断
  Future<bool> _checkGooglePlayServices() async {
    try {
      // 方法1: 检查设备信息中的Google Play服务相关字段
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      // 检查是否有Google Play服务相关的标识
      final brand = androidInfo.brand.toLowerCase();
      final manufacturer = androidInfo.manufacturer.toLowerCase();

      // 检查是否为Google设备或包含Google Play服务
      final hasGooglePlayServices =
          brand.contains('google') || manufacturer.contains('google');

      if (hasGooglePlayServices) {
        return true;
      }

      // 方法2: 检查是否为国产设备（通常没有Google服务）
      final isChineseBrand =
          brand.contains('huawei') ||
          brand.contains('xiaomi') ||
          brand.contains('oppo') ||
          brand.contains('vivo') ||
          brand.contains('oneplus') ||
          brand.contains('meizu') ||
          brand.contains('realme') ||
          brand.contains('honor') ||
          brand.contains('nubia') ||
          manufacturer.contains('huawei') ||
          manufacturer.contains('xiaomi') ||
          manufacturer.contains('oppo') ||
          manufacturer.contains('vivo') ||
          manufacturer.contains('oneplus') ||
          manufacturer.contains('meizu') ||
          manufacturer.contains('realme') ||
          manufacturer.contains('honor') ||
          manufacturer.contains('nubia');

      // 如果是国产设备，通常没有Google服务
      if (isChineseBrand) {
        return false;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('检查Google Play服务时出错: $e');
      }
      return false;
    }
  }

  /// 为事件标题添加应用标识
  String _addAppIdentifierToTitle(String title) {
    const appIdentifier = ' [DaysReminder]';

    // 检查标题是否已经包含应用标识
    if (title.endsWith(appIdentifier)) {
      return title;
    }

    // 添加应用标识
    return '$title$appIdentifier';
  }

  /// 创建带有提醒的日历事件
  /// 返回值：日历事件ID（如果成功），否则返回null
  Future<String?> _createCalendarEventWithReminders(Event event) async {
    try {
      // 在release包中也保留调试日志
      print('🔍 创建日历事件: 开始创建事件 - ${event.title}');

      final device_calendar.DeviceCalendarPlugin deviceCalendar =
          device_calendar.DeviceCalendarPlugin();

      // 获取可用日历
      // 在release包中也保留调试日志
      print('🔍 创建日历事件: 正在获取可用日历...');

      final calendars = await deviceCalendar.retrieveCalendars();
      // 在release包中也保留调试日志
      print(
        '🔍 创建日历事件: 获取日历结果 - success: ${calendars.isSuccess}, count: ${calendars.data?.length ?? 0}',
      );

      if (!calendars.isSuccess || calendars.data!.isEmpty) {
        // 在release包中也保留调试日志
        print('❌ 创建日历事件: 没有可用的日历');
        throw Exception('No calendar available');
      }

      // 查找第一个有效的日历
      String? calendarId;
      String? calendarName;

      // 在release包中也保留调试日志
      print('🔍 创建日历事件: 检查所有可用日历...');
      for (int i = 0; i < calendars.data!.length; i++) {
        final calendar = calendars.data![i];
        // 在release包中也保留调试日志
        print(
          '🔍 创建日历事件: 日历[$i] - ID: ${calendar.id}, 名称: ${calendar.name}, 可写: ${calendar.isReadOnly == false}',
        );

        if (calendar.id != null && calendar.id!.isNotEmpty) {
          calendarId = calendar.id;
          calendarName = calendar.name;
          // 在release包中也保留调试日志
          print(
            '🔍 创建日历事件: 找到日历 - ID: $calendarId, 名称: $calendarName, 可写: ${calendar.isReadOnly == false}',
          );
          break;
        }
      }

      // 如果没有找到任何日历，尝试创建新日历
      // 在release包中也保留调试日志
      print('🔍 创建日历事件: 循环结束，calendarId = $calendarId');
      if (calendarId == null || calendarId.isEmpty) {
        // 在release包中也保留调试日志
        print('🔍 创建日历事件: 没有找到现有日历，尝试创建新日历...');

        try {
          final createResult = await deviceCalendar.createCalendar(
            'DaysReminder',
          );
          if (createResult.isSuccess && createResult.data != null) {
            calendarId = createResult.data!;
            calendarName = 'DaysReminder';
            // 在release包中也保留调试日志
            print('✅ 创建日历事件: 成功创建新日历 - ID: $calendarId, 名称: $calendarName');
          } else {
            // 在release包中也保留调试日志
            print('❌ 创建日历事件: 创建新日历失败 - ${createResult.errors}');
          }
        } catch (e) {
          // 在release包中也保留调试日志
          print('❌ 创建日历事件: 创建新日历时发生错误 - $e');
        }
      }

      // 在release包中也保留调试日志
      print('🔍 创建日历事件: 使用日历ID - $calendarId');
      print('🔍 创建日历事件: 日历名称 - $calendarName');

      // 检查日历ID是否有效
      if (calendarId == null || calendarId.isEmpty) {
        // 在release包中也保留调试日志
        print('❌ 创建日历事件: 没有找到有效的日历ID');
        throw Exception('No valid calendar ID found');
      }

      // 计算事件时间
      final eventDate = event.nextOccurrenceFrom(DateTime.now());
      final startTime = DateTime(
        eventDate.year,
        eventDate.month,
        eventDate.day,
        9,
        0,
      );
      final endTime = DateTime(
        eventDate.year,
        eventDate.month,
        eventDate.day,
        10,
        0,
      );

      // 在release包中也保留调试日志
      print('🔍 创建日历事件: 事件时间 - 开始: $startTime, 结束: $endTime');

      // 创建提醒规则：提前1天和15分钟前提醒
      final reminders = <device_calendar.Reminder>[
        device_calendar.Reminder(
          minutes: 24 * 60, // 提前1天提醒
        ),
        device_calendar.Reminder(
          minutes: 15, // 15分钟前提醒
        ),
        device_calendar.Reminder(
          minutes: 0, // 发生时提醒
        ),
      ];

      // 创建日历事件
      final calendarEvent = device_calendar.Event(
        calendarId,
        title: _addAppIdentifierToTitle(event.title),
        description: event.note ?? '来自DaysReminder的提醒',
        start: tz.TZDateTime.from(startTime, tz.local),
        end: tz.TZDateTime.from(endTime, tz.local),
        allDay: false,
        reminders: reminders,
      );

      // 在release包中也保留调试日志
      print('🔍 创建日历事件: 准备创建事件 - 标题: ${calendarEvent.title}');

      final result = await deviceCalendar.createOrUpdateEvent(calendarEvent);

      // 在release包中也保留调试日志
      print(
        '🔍 创建日历事件: 创建结果 - success: ${result?.isSuccess}, eventId: ${result?.data}, error: ${result?.errors}',
      );

      if (result?.isSuccess == true && result?.data != null) {
        return result!.data as String;
      }
      return null;
    } catch (e) {
      // 在release包中也保留调试日志
      print('❌ 创建日历事件失败: $e');
      print('❌ 错误堆栈: ${e.toString()}');
      return null;
    }
  }

  /// 更新带有提醒的日历事件
  /// 返回值：日历事件ID（如果成功），否则返回null
  Future<String?> _updateCalendarEventWithReminders(Event event) async {
    try {
      final device_calendar.DeviceCalendarPlugin deviceCalendar =
          device_calendar.DeviceCalendarPlugin();

      // 获取可用日历
      final calendars = await deviceCalendar.retrieveCalendars();
      if (!calendars.isSuccess || calendars.data!.isEmpty) {
        throw Exception('No calendar available');
      }

      final calendarId = calendars.data!.first.id;

      // 计算事件时间
      final eventDate = event.nextOccurrenceFrom(DateTime.now());
      final startTime = DateTime(
        eventDate.year,
        eventDate.month,
        eventDate.day,
        9,
        0,
      );
      final endTime = DateTime(
        eventDate.year,
        eventDate.month,
        eventDate.day,
        10,
        0,
      );

      // 如果事件有保存的日历事件ID，先删除旧事件再创建新事件
      // 注意：由于 device_calendar 插件的更新功能有bug，我们使用删除+创建的方式
      if (event.calendarEventId != null && event.calendarEventId!.isNotEmpty) {
        print('🔍 更新日历事件: 使用保存的日历事件ID - ${event.calendarEventId}');
        print('🔍 更新日历事件: 采用删除+创建方式（避免插件更新bug）');

        // 先删除旧事件
        try {
          final deleteResult = await deviceCalendar.deleteEvent(
            calendarId,
            event.calendarEventId!,
          );

          if (deleteResult.isSuccess) {
            print('✅ 更新日历事件: 旧事件删除成功');
          } else {
            print('⚠️ 更新日历事件: 旧事件删除失败（可能已被删除） - ${deleteResult.errors}');
          }
        } catch (e) {
          print('⚠️ 更新日历事件: 删除旧事件时异常 - $e');
          // 继续创建新事件
        }

        // 创建新事件
        print('🔍 更新日历事件: 准备创建新事件');
        return await _createCalendarEventWithReminders(event);
      }

      // 如果没有保存的日历事件ID，尝试查找现有事件（兼容旧数据）
      print('⚠️ 更新日历事件: 没有保存的日历事件ID，尝试查找现有事件');

      // 查找现有事件
      final events = await deviceCalendar.retrieveEvents(
        calendarId,
        device_calendar.RetrieveEventsParams(
          startDate: tz.TZDateTime.from(
            startTime.subtract(const Duration(days: 1)),
            tz.local,
          ),
          endDate: tz.TZDateTime.from(
            endTime.add(const Duration(days: 1)),
            tz.local,
          ),
        ),
      );

      if (events.isSuccess && events.data != null && events.data!.isNotEmpty) {
        // 查找匹配的事件 - 通过标题精确匹配
        device_calendar.Event? existingEvent;
        final expectedTitle = _addAppIdentifierToTitle(event.title);

        print('🔍 更新日历事件: 搜索标题 - $expectedTitle');
        print('🔍 更新日历事件: 找到 ${events.data!.length} 个日历事件');

        for (final calendarEvent in events.data!) {
          print('🔍 更新日历事件: 检查事件 - ${calendarEvent.title}');

          // 通过标题精确匹配
          if (calendarEvent.title == expectedTitle) {
            existingEvent = calendarEvent;
            print(
              '✅ 更新日历事件: 找到匹配事件 - ${calendarEvent.title}, ID: ${calendarEvent.eventId}',
            );
            break;
          }
        }

        if (existingEvent == null) {
          print('⚠️ 更新日历事件: 未找到标题匹配的事件');
        }

        if (existingEvent != null) {
          // 创建提醒规则：提前1天和15分钟前提醒
          final reminders = <device_calendar.Reminder>[
            device_calendar.Reminder(
              minutes: 24 * 60, // 提前1天提醒
            ),
            device_calendar.Reminder(
              minutes: 15, // 15分钟前提醒
            ),
            device_calendar.Reminder(
              minutes: 0, // 发生时提醒
            ),
          ];

          // 更新现有事件
          final updatedEvent = device_calendar.Event(
            calendarId,
            eventId: existingEvent.eventId,
            title: _addAppIdentifierToTitle(event.title),
            description: event.note ?? '来自DaysReminder的提醒',
            start: tz.TZDateTime.from(startTime, tz.local),
            end: tz.TZDateTime.from(endTime, tz.local),
            allDay: false,
            reminders: reminders,
          );

          final result = await deviceCalendar.createOrUpdateEvent(updatedEvent);

          if (result?.isSuccess == true) {
            print('✅ 更新日历事件: 更新成功 - ${event.title}');
            return existingEvent.eventId;
          }
        }
      }

      // 如果没有找到现有事件，创建新事件
      print('⚠️ 更新日历事件: 未找到现有事件，创建新事件');
      return await _createCalendarEventWithReminders(event);
    } catch (e) {
      if (kDebugMode) {
        print('更新日历事件失败: $e');
      }
      return null;
    }
  }

  /// 删除日历事件
  Future<bool> _deleteCalendarEvent(Event event) async {
    try {
      final device_calendar.DeviceCalendarPlugin deviceCalendar =
          device_calendar.DeviceCalendarPlugin();

      // 获取可用日历
      final calendars = await deviceCalendar.retrieveCalendars();
      if (!calendars.isSuccess || calendars.data!.isEmpty) {
        throw Exception('No calendar available');
      }

      final calendarId = calendars.data!.first.id;

      // 如果事件有保存的日历事件ID，直接删除
      if (event.calendarEventId != null && event.calendarEventId!.isNotEmpty) {
        print('🔍 删除日历事件: 使用保存的日历事件ID - ${event.calendarEventId}');
        final result = await deviceCalendar.deleteEvent(
          calendarId,
          event.calendarEventId!,
        );

        if (result.isSuccess) {
          print('✅ 删除日历事件: 删除成功 - ${event.title}');
        } else {
          print('❌ 删除日历事件: 删除失败 - ${result.errors}');
        }

        return result.isSuccess;
      }

      print('⚠️ 删除日历事件: 没有保存的日历事件ID，尝试查找现有事件');

      // 计算事件时间
      final eventDate = event.nextOccurrenceFrom(DateTime.now());
      final startTime = DateTime(
        eventDate.year,
        eventDate.month,
        eventDate.day,
        9,
        0,
      );
      final endTime = DateTime(
        eventDate.year,
        eventDate.month,
        eventDate.day,
        10,
        0,
      );

      // 查找要删除的事件（兼容旧数据）
      final events = await deviceCalendar.retrieveEvents(
        calendarId,
        device_calendar.RetrieveEventsParams(
          startDate: tz.TZDateTime.from(
            startTime.subtract(const Duration(days: 1)),
            tz.local,
          ),
          endDate: tz.TZDateTime.from(
            endTime.add(const Duration(days: 1)),
            tz.local,
          ),
        ),
      );

      if (events.isSuccess && events.data != null && events.data!.isNotEmpty) {
        final eventTitle = _addAppIdentifierToTitle(event.title);
        for (final calendarEvent in events.data!) {
          if (calendarEvent.title == eventTitle) {
            print('🔍 删除日历事件: 找到现有事件 - ${calendarEvent.title}');
            final result = await deviceCalendar.deleteEvent(
              calendarId,
              calendarEvent.eventId!,
            );
            return result.isSuccess;
          }
        }
      }

      print('⚠️ 删除日历事件: 未找到事件');
      return true; // 事件未找到，认为删除成功
    } catch (e) {
      if (kDebugMode) {
        print('删除日历事件失败: $e');
      }
      return false;
    }
  }

  /// 同步事件到日历（创建）
  /// 返回值：日历事件ID（如果成功），否则返回null
  Future<String?> syncEventToCalendar(Event event) async {
    try {
      // 在release包中也保留调试日志
      print('🔍 日历同步调试: 开始处理事件 - ${event.title}');
      print('🔍 事件详情: ID=${event.id}, 日期=${event.date}, 类型=${event.kind}');

      // 检查是否应该使用日历同步
      final shouldSync = await shouldUseCalendarSync();
      // 在release包中也保留调试日志
      print('🔍 日历同步调试: shouldUseCalendarSync = $shouldSync');

      if (!shouldSync) {
        // 在release包中也保留调试日志
        print('📅 日历同步: 跳过同步（设备支持本地推送）');
        return null;
      }

      // 检查日历权限
      final calendarPermission = await Permission.calendarWriteOnly.status;
      // 在release包中也保留调试日志
      print('🔍 日历同步调试: 日历权限状态 = ${calendarPermission.name}');

      if (!calendarPermission.isGranted) {
        // 在release包中也保留调试日志
        print('📅 日历同步: 日历权限未授权，无法同步事件');
        return null;
      }

      // 在release包中也保留调试日志
      print('📅 日历同步: 开始同步事件到日历 - ${event.title}');

      // 创建带有提醒的日历事件
      final calendarEventId = await _createCalendarEventWithReminders(event);

      if (calendarEventId != null) {
        // 在release包中也保留调试日志
        print('✅ 日历同步: 事件同步成功 - ${event.title}, 日历事件ID: $calendarEventId');
      } else {
        // 在release包中也保留调试日志
        print('❌ 日历同步: 事件同步失败 - ${event.title}');
      }

      return calendarEventId;
    } catch (e) {
      // 在release包中也保留调试日志
      print('❌ 日历同步: 同步事件时发生错误 - $e');
      print('❌ 错误堆栈: ${e.toString()}');
      return null;
    }
  }

  /// 同步事件到日历（更新）
  /// 返回值：日历事件ID（如果成功），否则返回null
  Future<String?> syncEventUpdateToCalendar(Event event) async {
    try {
      // 检查是否应该使用日历同步
      final shouldSync = await shouldUseCalendarSync();
      if (!shouldSync) {
        if (kDebugMode) {
          print('📅 日历同步: 跳过更新同步（设备支持本地推送）');
        }
        return null;
      }

      // 检查日历权限
      final calendarPermission = await Permission.calendarWriteOnly.status;
      if (!calendarPermission.isGranted) {
        if (kDebugMode) {
          print('📅 日历同步: 日历权限未授权，无法更新事件');
        }
        return null;
      }

      if (kDebugMode) {
        print('📅 日历同步: 开始更新日历中的事件 - ${event.title}');
      }

      // 更新带有提醒的日历事件
      final calendarEventId = await _updateCalendarEventWithReminders(event);

      if (calendarEventId != null) {
        if (kDebugMode) {
          print('✅ 日历同步: 事件更新成功 - ${event.title}, 日历事件ID: $calendarEventId');
        }
      } else {
        if (kDebugMode) {
          print('❌ 日历同步: 事件更新失败 - ${event.title}');
        }
      }

      return calendarEventId;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 日历同步: 更新事件时发生错误 - $e');
      }
      return null;
    }
  }

  /// 从日历中删除事件
  Future<bool> syncEventDeleteFromCalendar(Event event) async {
    try {
      // 检查是否应该使用日历同步
      final shouldSync = await shouldUseCalendarSync();
      if (!shouldSync) {
        if (kDebugMode) {
          print('📅 日历同步: 跳过删除同步（设备支持本地推送）');
        }
        return true;
      }

      // 检查日历权限
      final calendarPermission = await Permission.calendarWriteOnly.status;
      if (!calendarPermission.isGranted) {
        if (kDebugMode) {
          print('📅 日历同步: 日历权限未授权，无法删除事件');
        }
        return false;
      }

      if (kDebugMode) {
        print('📅 日历同步: 开始从日历中删除事件 - ${event.title}');
      }

      // 删除日历事件
      final success = await _deleteCalendarEvent(event);

      if (success) {
        if (kDebugMode) {
          print('✅ 日历同步: 事件删除成功 - ${event.title}');
        }
      } else {
        if (kDebugMode) {
          print('❌ 日历同步: 事件删除失败 - ${event.title}');
        }
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 日历同步: 删除事件时发生错误 - $e');
      }
      return false;
    }
  }

  /// 获取设备信息摘要
  Future<Map<String, dynamic>> getDeviceInfoSummary() async {
    try {
      final shouldSync = await shouldUseCalendarSync();
      final hasGoogleServices = await _checkGoogleServicesAvailability();

      return {
        'platform': Platform.operatingSystem,
        'shouldUseCalendarSync': shouldSync,
        'hasGoogleServices': hasGoogleServices,
        'isIOS': Platform.isIOS,
        'isAndroid': Platform.isAndroid,
      };
    } catch (e) {
      return {
        'platform': 'Unknown',
        'shouldUseCalendarSync': false,
        'hasGoogleServices': false,
        'isIOS': Platform.isIOS,
        'isAndroid': Platform.isAndroid,
        'error': e.toString(),
      };
    }
  }

  /// 清理所有日历事件（避免重复）
  Future<void> clearAllCalendarEvents() async {
    try {
      // 检查是否应该使用日历同步
      final shouldSync = await shouldUseCalendarSync();
      if (!shouldSync) {
        return;
      }

      // 检查日历权限
      final calendarPermission = await Permission.calendarWriteOnly.status;
      if (!calendarPermission.isGranted) {
        return;
      }

      // 在release包中也保留调试日志
      print('🧹 日历同步: 开始清理所有现有事件');

      final device_calendar.DeviceCalendarPlugin deviceCalendar =
          device_calendar.DeviceCalendarPlugin();

      // 获取可用日历
      final calendars = await deviceCalendar.retrieveCalendars();
      if (!calendars.isSuccess || calendars.data!.isEmpty) {
        return;
      }

      final calendarId = calendars.data!.first.id;

      // 获取所有事件
      final events = await deviceCalendar.retrieveEvents(
        calendarId,
        device_calendar.RetrieveEventsParams(
          startDate: tz.TZDateTime.from(
            DateTime.now().subtract(const Duration(days: 365)),
            tz.local,
          ),
          endDate: tz.TZDateTime.from(
            DateTime.now().add(const Duration(days: 365)),
            tz.local,
          ),
        ),
      );

      if (events.isSuccess && events.data != null && events.data!.isNotEmpty) {
        // 在release包中也保留调试日志
        print('🔍 日历同步: 找到 ${events.data!.length} 个事件，开始检查...');

        int deletedCount = 0;
        // 删除所有包含 [DaysReminder] 标识的事件
        for (final calendarEvent in events.data!) {
          if (calendarEvent.title != null &&
              calendarEvent.title!.contains('[DaysReminder]')) {
            try {
              await deviceCalendar.deleteEvent(
                calendarId,
                calendarEvent.eventId!,
              );
              deletedCount++;
              // 在release包中也保留调试日志
              print('🗑️ 日历同步: 删除事件 - ${calendarEvent.title}');
            } catch (e) {
              // 在release包中也保留调试日志
              print('❌ 日历同步: 删除事件失败 - ${calendarEvent.title}, 错误: $e');
            }
          }
        }

        // 在release包中也保留调试日志
        print('📊 日历同步: 共删除了 $deletedCount 个事件');
      } else {
        // 在release包中也保留调试日志
        print('🔍 日历同步: 没有找到任何事件');
      }

      // 在release包中也保留调试日志
      print('✅ 日历同步: 清理完成');
    } catch (e) {
      // 在release包中也保留调试日志
      print('❌ 日历同步: 清理事件失败 - $e');
    }
  }

  /// 重置缓存（用于测试或重新检测）
  void resetCache() {
    _shouldUseCalendarSync = null;
    _isGoogleServicesAvailable = null;
    if (kDebugMode) {
      print('🔄 日历同步: 缓存已重置');
    }
  }
}
