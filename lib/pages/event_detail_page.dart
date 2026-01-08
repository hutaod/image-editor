import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../models/event_record.dart';
import '../providers/event_provider.dart';
import '../providers/event_record_provider.dart';
import '../utils/lunar_utils.dart';
import '../utils/event_display_utils.dart';
import '../services/vip_service.dart';
import '../services/revenue_cat_service.dart';
import '../services/image_storage_service.dart';
import '../widgets/vip_benefits_dialog.dart';
import 'add_event_page.dart';
import 'add_record_page.dart';
import 'dart:io';

class EventDetailPage extends ConsumerWidget {
  const EventDetailPage({super.key, required this.event, this.initialRecordId});

  final Event event;
  final String? initialRecordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final events = ref.watch(eventsProvider);
    final current = events.firstWhere(
      (e) => e.id == event.id,
      orElse: () => event,
    );

    final (icon, primaryColor, bgColor, borderColor) = _getEventTypeStyle(
      current.kind,
      colorScheme,
    );

    final now = DateTime.now();
    final eventDate = current.isLunar
        ? LunarUtils.lunarToSolar(
            year: current.lunarYear ?? DateTime.now().year,
            month: current.lunarMonth ?? 1,
            day: current.lunarDay ?? 1,
            isLeap: current.lunarLeap ?? false,
          )
        : current.date;

    final nextOccurrence = _getNextOccurrence(
      eventDate,
      event.recurrenceUnit,
      event.recurrenceInterval,
      event,
    );
    // 使用日期计算天数差，确保按天数计算而不是按时间计算
    final daysUntil = _dateOnly(
      nextOccurrence,
    ).difference(_dateOnly(now)).inDays;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.eventDetail),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddEventPage(initial: current),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'hide',
                child: Row(
                  children: [
                    Icon(
                      current.isHidden
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey[700],
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      current.isHidden ? l10n.showEvent : l10n.hideEvent,
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.delete,
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'hide') {
                _showHideEventDialog(context, ref, current);
              } else if (value == 'delete') {
                _showDeleteDialog(context, ref, current);
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildScrollableContent(
            current,
            eventDate,
            nextOccurrence,
            daysUntil,
            icon,
            primaryColor,
            theme,
            context,
            ref,
            l10n,
          ),
        ],
      ),
    );
  }

  /// 构建可滚动内容
  Widget _buildScrollableContent(
    Event current,
    DateTime eventDate,
    DateTime? nextOccurrence,
    int daysUntil,
    IconData icon,
    Color primaryColor,
    ThemeData theme,
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final records = ref.watch(eventRecordsByEventIdProvider(event.id));
    final scrollController = ScrollController();

    // 如果有初始记录ID，在构建完成后滚动到该记录
    if (initialRecordId != null && records.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final recordIndex = records.indexWhere((r) => r.id == initialRecordId);
        if (recordIndex != -1) {
          // 计算滚动位置，需要加上头部的高度
          final double headerHeight = 400; // 估算头部高度
          final double recordHeight = 200; // 估算单个记录高度
          final double targetOffset =
              headerHeight + (recordIndex * recordHeight);

          if (scrollController.hasClients) {
            scrollController.animateTo(
              targetOffset,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        }
      });
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const SizedBox(height: 24),
        _buildHeader(
          current,
          eventDate,
          nextOccurrence ?? eventDate,
          daysUntil,
          icon,
          primaryColor,
          theme,
          context,
        ),
        const SizedBox(height: 32),
        _buildInfoSection(
          current,
          eventDate,
          primaryColor,
          theme,
          nextOccurrence ?? eventDate,
          context,
          ref,
        ),
        const SizedBox(height: 24),
        _buildRecordsSection(current, primaryColor, theme, context, ref, l10n),
        const SizedBox(height: 24),
        _buildStatsSection(
          current,
          eventDate,
          DateTime.now(),
          nextOccurrence ?? eventDate,
          primaryColor,
          theme,
        ),
        const SizedBox(height: 100), // 底部间距
      ],
    );
  }

  Widget _buildHeader(
    Event event,
    DateTime eventDate,
    DateTime nextOccurrence,
    int daysUntil,
    IconData icon,
    Color primaryColor,
    ThemeData theme,
    BuildContext context,
  ) {
    return Column(
      children: [
        // 图标
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, color: primaryColor, size: 36),
        ),
        const SizedBox(height: 20),

        // 标题
        Text(
          EventDisplayUtils.getLocalizedTitle(context, event),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // 主要信息
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Text(
            _getMainDisplayText(event, daysUntil, eventDate, context),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(
    Event event,
    DateTime eventDate,
    Color primaryColor,
    ThemeData theme,
    DateTime nextOccurrence,
    BuildContext context,
    WidgetRef ref,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
          icon: Icons.calendar_today,
          label: AppLocalizations.of(context)!.eventDetailDate,
          value: event.isLunar
              ? '${AppLocalizations.of(context)!.lunarPrefix} ${LunarUtils.formatLunar(year: event.lunarYear ?? DateTime.now().year, month: event.lunarMonth ?? 1, day: event.lunarDay ?? 1, isLeap: event.lunarLeap ?? false)} (${DateFormat(AppLocalizations.of(context)!.dateFormatFull).format(eventDate)})'
              : DateFormat(
                  AppLocalizations.of(context)!.dateFormatFull,
                ).format(event.date),
          theme: theme,
          primaryColor: primaryColor,
        ),
        const SizedBox(height: 16),
        if (event.recurrenceUnit != RecurrenceUnit.none) ...[
          _buildInfoRow(
            icon: Icons.repeat,
            label: AppLocalizations.of(context)!.eventDetailRecurrence,
            value: _getRecurrenceText(event.recurrenceUnit, context),
            theme: theme,
            primaryColor: primaryColor,
          ),
          const SizedBox(height: 16),
        ],
        _buildInfoRow(
          icon: Icons.category,
          label: AppLocalizations.of(context)!.eventDetailType,
          value: _getEventTypeText(event.kind, context),
          theme: theme,
          primaryColor: primaryColor,
        ),
        if (event.kind == EventKind.birthday) ...[
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.cake,
            label: AppLocalizations.of(context)!.eventDetailCurrentAge,
            value:
                '${_calculateAge(eventDate, event)} ${AppLocalizations.of(context)!.eventDetailAgeUnit}',
            theme: theme,
            primaryColor: primaryColor,
          ),
        ],
        if (event.note != null && event.note!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.note,
            label: AppLocalizations.of(context)!.eventDetailNote,
            value: event.note ?? '',
            theme: theme,
            primaryColor: primaryColor,
          ),
        ],
      ],
    );
  }

  Widget _buildStatsSection(
    Event event,
    DateTime eventDate,
    DateTime now,
    DateTime nextOccurrence,
    Color primaryColor,
    ThemeData theme,
  ) {
    // 所有信息已经合并到基础信息列表中，这里返回空容器
    return const SizedBox.shrink();
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
    required Color primaryColor,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: primaryColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getMainDisplayText(
    Event event,
    int daysUntil,
    DateTime eventDate,
    BuildContext context,
  ) {
    switch (event.kind) {
      case EventKind.birthday:
        return daysUntil == 0
            ? AppLocalizations.of(context)!.countdownToday
            : '${AppLocalizations.of(context)!.countdownPrefix} $daysUntil ${AppLocalizations.of(context)!.countdownDays}';
      case EventKind.anniversary:
        return '${AppLocalizations.of(context)!.countdownOverduePrefix} ${_calculateDaysSince(eventDate, DateTime.now())} ${AppLocalizations.of(context)!.countdownDays}';
      case EventKind.countdown:
        return daysUntil == 0
            ? AppLocalizations.of(context)!.countdownToday
            : '${AppLocalizations.of(context)!.countdownPrefix} $daysUntil ${AppLocalizations.of(context)!.countdownDays}';
    }
  }

  int _calculateAge(DateTime birthDate, Event event) {
    if (event.isLunar) {
      // 对于农历生日，计算农历年龄
      return _calculateLunarAge(event);
    } else {
      // 对于公历生日，计算公历年龄
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return age;
    }
  }

  int _calculateLunarAge(Event event) {
    final now = DateTime.now();
    final currentLunar = LunarUtils.solarToLunar(now);

    // 获取生日的农历信息
    final birthLunarYear = event.lunarYear ?? now.year;
    final birthLunarMonth = event.lunarMonth ?? 1;
    final birthLunarDay = event.lunarDay ?? 1;
    final birthLunarLeap = event.lunarLeap ?? false;

    // 计算农历年龄
    int age = currentLunar.year - birthLunarYear;

    // 比较农历月份和日期
    bool isBeforeBirthday = false;

    if (currentLunar.month < birthLunarMonth) {
      isBeforeBirthday = true;
    } else if (currentLunar.month == birthLunarMonth) {
      // 处理闰月情况
      if (birthLunarLeap && !currentLunar.isLeap) {
        // 生日是闰月，当前不是闰月，说明还没到生日
        isBeforeBirthday = true;
      } else if (!birthLunarLeap && currentLunar.isLeap) {
        // 生日不是闰月，当前是闰月，说明已经过了生日
        isBeforeBirthday = false;
      } else {
        // 闰月情况相同，比较日期
        isBeforeBirthday = currentLunar.day < birthLunarDay;
      }
    }

    if (isBeforeBirthday) {
      age--;
    }

    return age;
  }

  (IconData, Color, Color, Color) _getEventTypeStyle(
    EventKind kind,
    ColorScheme colorScheme,
  ) {
    switch (kind) {
      case EventKind.birthday:
        return (
          Icons.cake,
          const Color(0xFFFB7185),
          const Color(0xFFFFF1F2),
          const Color(0xFFFB7185).withValues(alpha: 0.2),
        );
      case EventKind.anniversary:
        return (
          Icons.favorite,
          const Color(0xFFA78BFA),
          const Color(0xFFF5F3FF),
          const Color(0xFFA78BFA).withValues(alpha: 0.2),
        );
      case EventKind.countdown:
        return (
          Icons.hourglass_bottom,
          const Color(0xFF22C55E),
          const Color(0xFFF0FDF4),
          const Color(0xFF22C55E).withValues(alpha: 0.2),
        );
    }
  }

  DateTime _dateOnly(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  DateTime _getNextOccurrence(
    DateTime eventDate,
    RecurrenceUnit unit,
    int interval,
    Event event,
  ) {
    final now = DateTime.now();
    final nowDateOnly = _dateOnly(now);

    if (event.isLunar) {
      // 对于农历生日，计算下一个农历生日的公历日期
      return _getNextLunarBirthday(event, now);
    }

    if (unit == RecurrenceUnit.none) {
      return eventDate;
    }

    DateTime next = DateTime(eventDate.year, eventDate.month, eventDate.day);

    // 只有当候选日期严格在今天之前时，才增加周期
    while (_dateOnly(next).isBefore(nowDateOnly)) {
      switch (unit) {
        case RecurrenceUnit.year:
          next = DateTime(next.year + interval, next.month, next.day);
          break;
        case RecurrenceUnit.month:
          next = DateTime(next.year, next.month + interval, next.day);
          break;
        case RecurrenceUnit.week:
          next = next.add(Duration(days: 7 * interval));
          break;
        case RecurrenceUnit.none:
          return eventDate;
      }
    }

    return next;
  }

  DateTime _getNextLunarBirthday(Event event, DateTime from) {
    final birthLunarYear = event.lunarYear ?? from.year;
    final birthLunarMonth = event.lunarMonth ?? 1;
    final birthLunarDay = event.lunarDay ?? 1;
    final birthLunarLeap = event.lunarLeap ?? false;

    // 从当前年份开始查找下一个农历生日
    int year = from.year;
    DateTime? nextBirthday;

    // 查找未来3年内的农历生日
    for (int i = 0; i < 3; i++) {
      try {
        final candidate = LunarUtils.lunarToSolar(
          year: birthLunarYear + year - birthLunarYear,
          month: birthLunarMonth,
          day: birthLunarDay,
          isLeap: birthLunarLeap,
        );

        // 如果这个候选日期在from日期之后或等于from日期，就是我们要找的
        if (candidate.isAfter(from) ||
            _dateOnly(candidate).isAtSameMomentAs(_dateOnly(from))) {
          nextBirthday = candidate;
          break;
        }
      } catch (e) {
        // 如果转换失败（比如闰月问题），继续尝试下一年
        print('农历生日转换失败: $e');
      }
      year++;
    }

    // 如果没找到，返回当前日期（避免null）
    return nextBirthday ?? from;
  }

  int _calculateDaysSince(DateTime eventDate, DateTime now) {
    return now
        .difference(DateTime(eventDate.year, eventDate.month, eventDate.day))
        .inDays;
  }

  String _getRecurrenceText(RecurrenceUnit unit, BuildContext context) {
    switch (unit) {
      case RecurrenceUnit.year:
        return AppLocalizations.of(context)!.eventDetailRecurrenceYearly;
      case RecurrenceUnit.month:
        return AppLocalizations.of(context)!.eventDetailRecurrenceMonthly;
      case RecurrenceUnit.week:
        return AppLocalizations.of(context)!.eventDetailRecurrenceWeekly;
      case RecurrenceUnit.none:
        return AppLocalizations.of(context)!.eventDetailRecurrenceNone;
    }
  }

  String _getEventTypeText(EventKind kind, BuildContext context) {
    switch (kind) {
      case EventKind.birthday:
        return AppLocalizations.of(context)!.eventKindBirthday;
      case EventKind.anniversary:
        return AppLocalizations.of(context)!.eventKindAnniversary;
      case EventKind.countdown:
        return AppLocalizations.of(context)!.eventKindCountdown;
    }
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Event e) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmDeleteEvent),
        content: Text(
          AppLocalizations.of(context)!.confirmDeleteEventDesc(
            EventDisplayUtils.getLocalizedTitle(context, e),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              ref.read(eventsProvider.notifier).deleteEvent(e.id);
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  /// 构建记录部分
  Widget _buildRecordsSection(
    Event event,
    Color primaryColor,
    ThemeData theme,
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final records = ref.watch(eventRecordsByEventIdProvider(event.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 记录列表
        if (records.isEmpty)
          _buildEmptyRecords(theme, primaryColor, l10n)
        else
          _buildRecordsList(records, theme, primaryColor, context, ref, l10n),

        const SizedBox(height: 16),

        // 添加记录按钮 - 居中显示
        Center(
          child: TextButton.icon(
            onPressed: () => _addRecord(context, event.id, ref),
            icon: Icon(Icons.add_circle_outline, size: 20, color: primaryColor),
            label: Text(
              l10n.addRecord,
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
                side: BorderSide(color: primaryColor.withOpacity(0.3)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建空记录状态
  Widget _buildEmptyRecords(
    ThemeData theme,
    Color primaryColor,
    AppLocalizations l10n,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 40,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.noRecordsYet,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.addMemoriesForSpecialDay,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 构建记录列表
  Widget _buildRecordsList(
    List<EventRecord> records,
    ThemeData theme,
    Color primaryColor,
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    return Column(
      children: records.map((record) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: _buildRecordCard(
            record,
            theme,
            primaryColor,
            context,
            ref,
            l10n,
          ),
        );
      }).toList(),
    );
  }

  /// 构建记录卡片
  Widget _buildRecordCard(
    EventRecord record,
    ThemeData theme,
    Color primaryColor,
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 文字内容
          if (record.textContent != null && record.textContent!.isNotEmpty)
            _buildTextContent(record.textContent!, theme),

          // 图片内容
          if (record.imagePaths.isNotEmpty)
            _buildImageContent(record.imagePaths, theme, context, l10n),

          // 位置信息
          if (record.location != null && record.location!.isNotEmpty)
            _buildLocationContent(record.location!, theme),

          // 根据图片数量调整底部间距
          SizedBox(height: 8),

          // 底部操作栏（时间和操作按钮）
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 时间显示
              Text(
                record.formattedCreatedAt,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),

              // 操作按钮组
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 编辑按钮
                  GestureDetector(
                    onTap: () => _editRecord(context, record, ref),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 删除按钮
                  GestureDetector(
                    onTap: () =>
                        _showDeleteRecordDialog(context, record, ref, l10n),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建文字内容
  Widget _buildTextContent(String text, ThemeData theme) {
    return _ExpandableText(
      text: text,
      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16, height: 1.4),
    );
  }

  /// 构建图片内容
  Widget _buildImageContent(
    List<String> imagePaths,
    ThemeData theme,
    BuildContext context,
    AppLocalizations l10n,
  ) {
    if (imagePaths.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: _buildImageGrid(imagePaths, context, l10n),
    );
  }

  /// 构建图片网格
  Widget _buildImageGrid(
    List<String> imagePaths,
    BuildContext context,
    AppLocalizations l10n,
  ) {
    if (imagePaths.length == 1) {
      // 单张图片
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildImageWidgetWithPreview(
          imagePaths[0],
          l10n,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
          onTap: () => _showImagePreview(context, imagePaths, 0),
        ),
      );
    } else if (imagePaths.length <= 4) {
      // 2-4张图片，2列布局
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero, // 移除默认内边距
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 1,
        ),
        itemCount: imagePaths.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildImageWidgetWithPreview(
              imagePaths[index],
              l10n,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              onTap: () => _showImagePreview(context, imagePaths, index),
            ),
          );
        },
      );
    } else {
      // 5张以上图片，3列布局
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero, // 移除默认内边距
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 1,
        ),
        itemCount: imagePaths.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildImageWidgetWithPreview(
              imagePaths[index],
              l10n,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              onTap: () => _showImagePreview(context, imagePaths, index),
            ),
          );
        },
      );
    }
  }

  /// 构建带预览功能的图片组件，图片丢失时关闭预览功能
  Widget _buildImageWidgetWithPreview(
    String imagePath,
    AppLocalizations l10n, {
    double? width,
    double? height,
    BoxFit? fit,
    required VoidCallback onTap,
  }) {
    return FutureBuilder<bool>(
      future: ImageStorageService().imageExists(imagePath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[100],
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final exists = snapshot.data ?? false;
        if (!exists) {
          // 图片丢失时，不添加点击功能
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.image_not_supported,
                  color: Colors.grey,
                  size: 32,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.imageLost,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          );
        }

        // 图片存在时，添加点击预览功能
        return GestureDetector(
          onTap: onTap,
          child: Image.file(
            File(imagePath),
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: width,
                height: height,
                color: Colors.grey[200],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                      size: 32,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.imageLost,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// 构建位置内容
  Widget _buildLocationContent(String location, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              location,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示图片预览
  void _showImagePreview(
    BuildContext context,
    List<String> imagePaths,
    int initialIndex,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ImagePreviewPage(
          imagePaths: imagePaths,
          initialIndex: initialIndex,
          onDelete: null, // 在详情页不提供删除功能
        ),
      ),
    );
  }

  /// 添加记录
  void _addRecord(BuildContext context, String eventId, WidgetRef ref) {
    // 获取当前事件信息
    final events = ref.read(eventsProvider);
    final event = events.firstWhere((e) => e.id == eventId);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddRecordPage(eventId: eventId, event: event),
      ),
    );
  }

  /// 编辑记录
  void _editRecord(BuildContext context, EventRecord record, WidgetRef ref) {
    // 获取关联的事件信息
    final events = ref.read(eventsProvider);
    final event = events.firstWhere((e) => e.id == record.eventId);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddRecordPage(
          eventId: record.eventId,
          event: event,
          record: record, // 传入现有记录进行编辑
        ),
      ),
    );
  }

  /// 显示删除记录确认对话框
  void _showDeleteRecordDialog(
    BuildContext context,
    EventRecord record,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.deleteRecord),
          content: Text(l10n.deleteRecordConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteRecord(context, record, ref, l10n);
              },
              child: Text(
                l10n.delete,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 删除记录
  Future<void> _deleteRecord(
    BuildContext context,
    EventRecord record,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    try {
      // 删除记录
      await ref.read(eventRecordsProvider.notifier).deleteRecord(record.id);

      // 删除关联的图片文件
      if (record.imagePaths.isNotEmpty) {
        await ImageStorageService().deleteImages(record.imagePaths);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.recordDeleted),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.deleteFailed}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showHideEventDialog(BuildContext context, WidgetRef ref, Event event) {
    final l10n = AppLocalizations.of(context)!;
    final isCurrentlyHidden = event.isHidden;
    final theme = Theme.of(context);
    final (_, primaryColor, _, _) = _getEventTypeStyle(
      event.kind,
      theme.colorScheme,
    );

    // 如果是取消隐藏，直接执行
    if (isCurrentlyHidden) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.unhideEvent),
          content: Text(l10n.unhideEventDesc),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _toggleEventVisibility(ref, event);
              },
              child: Text(
                l10n.unhideEvent,
                style: TextStyle(color: primaryColor),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // 如果是隐藏事件，检查会员限制
    _checkHideEventPermission(context, ref, event, l10n, primaryColor);
  }

  Future<void> _checkHideEventPermission(
    BuildContext context,
    WidgetRef ref,
    Event event,
    AppLocalizations l10n,
    Color primaryColor,
  ) async {
    final vipService = VipService();
    final canHide = await vipService.canHideEvent();

    if (canHide) {
      // 可以隐藏，显示确认对话框
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.hideEvent),
          content: Text(l10n.hideEventDesc),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _toggleEventVisibility(ref, event);
              },
              child: Text(
                l10n.hideEvent,
                style: TextStyle(color: primaryColor),
              ),
            ),
          ],
        ),
      );
    } else {
      // 不能隐藏，显示会员提示
      _showMembershipPrompt(context, l10n, primaryColor);
    }
  }

  void _showMembershipPrompt(
    BuildContext context,
    AppLocalizations l10n,
    Color primaryColor,
  ) {
    final revenueCatService = RevenueCatService();

    // 检查RevenueCat是否已初始化
    if (!revenueCatService.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.paymentSystemInitializing),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => VipBenefitsDialog(
        onUpgrade: () => _purchaseVip(context, revenueCatService),
        onRestore: () => _restorePurchases(context, revenueCatService),
        revenueCatService: revenueCatService,
      ),
    );
  }

  Future<void> _purchaseVip(
    BuildContext context,
    RevenueCatService revenueCatService,
  ) async {
    try {
      Navigator.pop(context); // 关闭弹窗

      // 显示加载提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('正在跳转到支付页面...'),
          backgroundColor: Colors.blue,
        ),
      );

      // 调用RevenueCat购买
      await revenueCatService.showIAPPaywall();

      // 检查购买结果
      final isPremium = await revenueCatService.isPremiumUser();
      if (isPremium) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('恭喜！会员开通成功！'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('购买会员失败: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('购买失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _restorePurchases(
    BuildContext context,
    RevenueCatService revenueCatService,
  ) async {
    try {
      Navigator.pop(context); // 关闭弹窗

      // 显示加载提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('正在恢复购买...'),
          backgroundColor: Colors.blue,
        ),
      );

      // 调用RevenueCat恢复购买
      await revenueCatService.restorePurchases();

      // 检查恢复结果
      final isPremium = await revenueCatService.isPremiumUser();
      if (isPremium) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('购买恢复成功！'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('未找到可恢复的购买记录'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('恢复购买失败: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('恢复购买失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _toggleEventVisibility(WidgetRef ref, Event event) async {
    final vipService = VipService();

    // 如果是隐藏事件，增加计数
    if (!event.isHidden) {
      await vipService.incrementHiddenEventsCount();
    } else {
      // 如果是取消隐藏，减少计数
      await vipService.decrementHiddenEventsCount();
    }

    final updatedEvent = Event(
      id: event.id,
      title: event.title,
      date: event.date,
      note: event.note,
      isLunar: event.isLunar,
      lunarYear: event.lunarYear,
      lunarMonth: event.lunarMonth,
      lunarDay: event.lunarDay,
      lunarLeap: event.lunarLeap,
      recurrenceUnit: event.recurrenceUnit,
      recurrenceInterval: event.recurrenceInterval,
      kind: event.kind,
      isHidden: !event.isHidden,
      isDefaultEvent: event.isDefaultEvent, // 保留默认事件标记
      calendarEventId: event.calendarEventId, // 保留日历事件ID
      orderIndex: event.orderIndex,
    );

    ref.read(eventsProvider.notifier).updateEvent(updatedEvent);
  }
}

/// 可展开文本组件
class _ExpandableText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const _ExpandableText({required this.text, this.style});

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _isExpanded = false;
  late bool _needsExpansion;

  @override
  void initState() {
    super.initState();
    _needsExpansion = _needsExpansionCheck();
  }

  bool _needsExpansionCheck() {
    // 简单检查：如果文本长度超过一定字符数，就认为需要展开
    return widget.text.length > 100;
  }

  @override
  Widget build(BuildContext context) {
    if (!_needsExpansion) {
      return Text(widget.text, style: widget.style);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          style: widget.style,
          maxLines: _isExpanded ? null : 3,
          overflow: _isExpanded ? null : TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Text(
            _isExpanded ? '收起' : '展开',
            style: widget.style?.copyWith(color: Colors.blue, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

/// 图片预览页面
class _ImagePreviewPage extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;
  final Function(int)? onDelete;

  const _ImagePreviewPage({
    required this.imagePaths,
    required this.initialIndex,
    this.onDelete,
  });

  @override
  State<_ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<_ImagePreviewPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.imagePaths.length}'),
        actions: widget.onDelete != null
            ? [
                IconButton(
                  onPressed: () => _showDeleteDialog(),
                  icon: const Icon(Icons.delete),
                ),
              ]
            : null,
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemCount: widget.imagePaths.length,
        itemBuilder: (context, index) {
          return Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: Image.file(
                File(widget.imagePaths[index]),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 100,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteDialog() {
    if (widget.onDelete == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('删除图片'),
          content: const Text('确定要删除这张图片吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onDelete!(_currentIndex);
                Navigator.of(context).pop();
              },
              child: const Text('删除', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
