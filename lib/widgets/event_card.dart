import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../utils/lunar_utils.dart';
import '../utils/event_display_utils.dart';
import '../l10n/app_localizations.dart';

class EventCard extends ConsumerWidget {
  const EventCard({super.key, required this.event, required this.onTap});

  final Event event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 根据事件类型设置不同的样式
    final (icon, primaryColor, bgColor, _) = _getEventTypeStyle(
      event.kind,
      colorScheme,
    );

    final now = DateTime.now();
    final eventDate = event.isLunar
        ? LunarUtils.lunarToSolar(
            year: event.lunarYear ?? DateTime.now().year,
            month: event.lunarMonth ?? 1,
            day: event.lunarDay ?? 1,
            isLeap: event.lunarLeap ?? false,
          )
        : event.date;

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

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: bgColor,
            border: Border(
              left: BorderSide(
                color: primaryColor.withValues(alpha: 0.5),
                width: 3,
              ),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 左侧图标区域
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primaryColor, size: 24),
              ),
              const SizedBox(width: 12),

              // 中间内容区域
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    Text(
                      EventDisplayUtils.getLocalizedTitle(context, event),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // 日期信息
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event.isLunar
                              ? '${AppLocalizations.of(context)!.lunarPrefix} ${LunarUtils.formatLunar(year: event.lunarYear ?? DateTime.now().year, month: event.lunarMonth ?? 1, day: event.lunarDay ?? 1, isLeap: event.lunarLeap ?? false)}'
                              : DateFormat(
                                  AppLocalizations.of(context)!.dateFormatFull,
                                ).format(event.date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                      ],
                    ),

                    // 类型特定信息
                    if (event.kind == EventKind.birthday) ...[
                      const SizedBox(height: 4),
                      _buildBirthdayInfo(
                        eventDate,
                        nextOccurrence,
                        theme,
                        context,
                      ),
                    ] else if (event.kind == EventKind.anniversary) ...[
                      const SizedBox(height: 4),
                      _buildAnniversaryInfo(eventDate, now, theme, context),
                    ],
                  ],
                ),
              ),

              // 右侧倒计时区域
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (event.kind == EventKind.countdown ||
                      event.kind == EventKind.birthday) ...[
                    Text(
                      daysUntil == 0
                          ? AppLocalizations.of(context)!.today
                          : daysUntil > 0
                          ? '$daysUntil'
                          : '${daysUntil.abs()}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: primaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      daysUntil == 0
                          ? ''
                          : daysUntil > 0
                          ? '${AppLocalizations.of(context)!.countdownSuffix} ${AppLocalizations.of(context)!.countdownAfter}'
                          : '${AppLocalizations.of(context)!.countdownDays} ${AppLocalizations.of(context)!.countdownBefore}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                        fontSize: 12,
                      ),
                    ),
                  ] else if (event.kind == EventKind.anniversary) ...[
                    Text(
                      '${_calculateDaysSince(eventDate, now)}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: primaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.countdownDays,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                        fontSize: 12,
                      ),
                    ),
                  ],

                  // 重复标识
                  if (event.recurrenceUnit != RecurrenceUnit.none) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getRecurrenceText(event.recurrenceUnit, context),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  (IconData, Color, Color, Color) _getEventTypeStyle(
    EventKind kind,
    ColorScheme colorScheme,
  ) {
    switch (kind) {
      case EventKind.birthday:
        return (
          Icons.cake,
          const Color(0xFFFB7185), // 玫瑰粉（柔和）
          const Color(0xFFFFF1F2), // 玫瑰粉浅色背景
          const Color(0xFFFB7185).withValues(alpha: 0.2),
        );
      case EventKind.anniversary:
        return (
          Icons.favorite,
          const Color(0xFFA78BFA), // 柔和淡紫
          const Color(0xFFF5F3FF), // 淡紫浅色背景
          const Color(0xFFA78BFA).withValues(alpha: 0.2),
        );
      case EventKind.countdown:
        return (
          Icons.hourglass_bottom,
          const Color(0xFF22C55E), // 绿色（与主题一致）
          const Color(0xFFF0FDF4), // 浅绿背景
          const Color(0xFF22C55E).withValues(alpha: 0.2),
        );
    }
  }

  Widget _buildBirthdayInfo(
    DateTime eventDate,
    DateTime nextOccurrence,
    ThemeData theme,
    BuildContext context,
  ) {
    final age = nextOccurrence.year - eventDate.year;
    return Row(
      children: [
        Icon(Icons.person_outline, size: 14, color: theme.colorScheme.outline),
        const SizedBox(width: 4),
        Text(
          '即将 $age 岁',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildAnniversaryInfo(
    DateTime eventDate,
    DateTime now,
    ThemeData theme,
    BuildContext context,
  ) {
    final daysSince = _calculateDaysSince(eventDate, now);
    String milestone = '';
    if (daysSince >= 1000) {
      milestone = AppLocalizations.of(context)!.milestoneThousand;
    } else if (daysSince >= 500) {
      milestone = AppLocalizations.of(context)!.milestoneFiveHundred;
    } else if (daysSince >= 100) {
      milestone = AppLocalizations.of(context)!.milestoneHundred;
    }

    return Row(
      children: [
        Icon(Icons.celebration, size: 14, color: theme.colorScheme.outline),
        const SizedBox(width: 4),
        Text(
          milestone.isNotEmpty
              ? milestone
              : AppLocalizations.of(context)!.milestoneSweet,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
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
        return AppLocalizations.of(context)!.recurrenceYearly;
      case RecurrenceUnit.month:
        return AppLocalizations.of(context)!.recurrenceMonthly;
      case RecurrenceUnit.week:
        return AppLocalizations.of(context)!.recurrenceWeekly;
      case RecurrenceUnit.none:
        return '';
    }
  }
}
