import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:lunar/lunar.dart';

import '../models/event.dart';
import '../providers/event_provider.dart';
import '../utils/lunar_utils.dart';
import '../utils/event_display_utils.dart';

class AddEventPage extends HookConsumerWidget {
  const AddEventPage({super.key, this.initial});

  final Event? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = useTextEditingController(
      text: initial != null
          ? EventDisplayUtils.getLocalizedTitle(context, initial!)
          : '',
    );
    final noteController = useTextEditingController(text: initial?.note ?? '');
    final selectedDate = useState<DateTime>(initial?.date ?? DateTime.now());
    // 类型自动推断，不再提供手动切换
    final useLunar = useState<bool>(initial?.isLunar ?? false);
    final lunarFields =
        useState<({int year, int month, int day, bool isLeap})?>(
          (initial?.isLunar ?? false) &&
                  initial?.lunarYear != null &&
                  initial?.lunarMonth != null &&
                  initial?.lunarDay != null
              ? (
                  year: initial!.lunarYear!,
                  month: initial!.lunarMonth!,
                  day: initial!.lunarDay!,
                  isLeap: initial!.lunarLeap ?? false,
                )
              : null,
        );
    final recurrenceUnit = useState<RecurrenceUnit>(
      initial?.recurrenceUnit ?? RecurrenceUnit.none,
    );
    final recurrenceInterval = useState<int>(initial?.recurrenceInterval ?? 1);

    // 事件类型（默认倒数日）
    final kind = useState<EventKind>(initial?.kind ?? EventKind.countdown);

    // 创建独立的焦点节点
    final titleFocusNode = useFocusNode();
    final noteFocusNode = useFocusNode();
    final titleHasFocus = useState<bool>(false);
    final noteHasFocus = useState<bool>(false);

    Future<void> pickDate() async {
      if (!useLunar.value) {
        // 公历使用三级联选择
        final current = selectedDate.value;
        int y = current.year;
        int m = current.month;
        int d = current.day;

        final picked = await showDialog<DateTime>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.selectSolarDate),
              content: StatefulBuilder(
                builder: (ctx, setState) {
                  return SizedBox(
                    width: 300,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButton<int>(
                                isExpanded: true,
                                value: y,
                                items: [
                                  for (
                                    int yy = DateTime.now().year - 200;
                                    yy <= DateTime.now().year + 200;
                                    yy++
                                  )
                                    DropdownMenuItem(
                                      value: yy,
                                      child: Text(
                                        '$yy ${AppLocalizations.of(context)!.year}',
                                      ),
                                    ),
                                ],
                                onChanged: (v) => setState(() {
                                  y = v ?? y;
                                  // 调整日期，避免无效日期
                                  final daysInMonth = DateTime(y, m + 1, 0).day;
                                  if (d > daysInMonth) d = daysInMonth;
                                }),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButton<int>(
                                isExpanded: true,
                                value: m,
                                items: [
                                  for (int mm = 1; mm <= 12; mm++)
                                    DropdownMenuItem(
                                      value: mm,
                                      child: Text(
                                        '$mm ${AppLocalizations.of(context)!.month}',
                                      ),
                                    ),
                                ],
                                onChanged: (v) => setState(() {
                                  m = v ?? m;
                                  // 调整日期，避免无效日期
                                  final daysInMonth = DateTime(y, m + 1, 0).day;
                                  if (d > daysInMonth) d = daysInMonth;
                                }),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButton<int>(
                                isExpanded: true,
                                value: d,
                                items: () {
                                  final daysInMonth = DateTime(y, m + 1, 0).day;
                                  return [
                                    for (int dd = 1; dd <= daysInMonth; dd++)
                                      DropdownMenuItem(
                                        value: dd,
                                        child: Text(
                                          '$dd ${AppLocalizations.of(context)!.day}',
                                        ),
                                      ),
                                  ];
                                }(),
                                onChanged: (v) => setState(() => d = v ?? d),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, DateTime(y, m, d)),
                  child: Text(AppLocalizations.of(context)!.ok),
                ),
              ],
            );
          },
        );

        if (picked != null) {
          selectedDate.value = picked;
          lunarFields.value = LunarUtils.solarToLunar(selectedDate.value);
        }
        return;
      }

      // 阴历使用三级联选择
      final current =
          lunarFields.value ?? LunarUtils.solarToLunar(selectedDate.value);
      int y = current.year;
      int mSigned = current.isLeap ? -current.month.abs() : current.month.abs();
      int d = current.day;
      final picked = await showDialog<({int year, int month, int day, bool isLeap})>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.selectLunarDate),
            content: StatefulBuilder(
              builder: (ctx, setState) {
                return SizedBox(
                  width: 300,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButton<int>(
                              isExpanded: true,
                              value: y,
                              items: [
                                for (
                                  int yy = DateTime.now().year - 200;
                                  yy <= DateTime.now().year + 200;
                                  yy++
                                )
                                  DropdownMenuItem(
                                    value: yy,
                                    child: Text(
                                      '$yy ${AppLocalizations.of(context)!.year}',
                                    ),
                                  ),
                              ],
                              onChanged: (v) => setState(() {
                                y = v ?? y;
                                final int leapMonth = LunarYear.fromYear(
                                  y,
                                ).getLeapMonth();
                                if (leapMonth == 0 && mSigned < 0) {
                                  mSigned = -mSigned; // no leap this year
                                } else if (mSigned < 0 &&
                                    mSigned.abs() != leapMonth) {
                                  mSigned = mSigned.abs();
                                }
                              }),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButton<int>(
                              isExpanded: true,
                              value: mSigned,
                              items: () {
                                final List<DropdownMenuItem<int>> items = [];
                                final int leapMonth = LunarYear.fromYear(
                                  y,
                                ).getLeapMonth();
                                for (int mm = 1; mm <= 12; mm++) {
                                  items.add(
                                    DropdownMenuItem(
                                      value: mm,
                                      child: Text(
                                        '$mm ${AppLocalizations.of(context)!.month}',
                                      ),
                                    ),
                                  );
                                  if (leapMonth == mm) {
                                    items.add(
                                      DropdownMenuItem(
                                        value: -mm,
                                        child: Text(
                                          '${AppLocalizations.of(context)!.leapMonth}$mm ${AppLocalizations.of(context)!.month}',
                                        ),
                                      ),
                                    );
                                  }
                                }
                                return items;
                              }(),
                              onChanged: (v) =>
                                  setState(() => mSigned = (v ?? mSigned)),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButton<int>(
                              isExpanded: true,
                              value: d,
                              items: [
                                for (int dd = 1; dd <= 30; dd++)
                                  DropdownMenuItem(
                                    value: dd,
                                    child: Text(
                                      '$dd ${AppLocalizations.of(context)!.day}',
                                    ),
                                  ),
                              ],
                              onChanged: (v) => setState(() => d = v ?? d),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, (
                  year: y,
                  month: mSigned.abs(),
                  day: d,
                  isLeap: mSigned < 0,
                )),
                child: Text(AppLocalizations.of(context)!.ok),
              ),
            ],
          );
        },
      );
      if (picked != null) {
        try {
          final solar = LunarUtils.lunarToSolar(
            year: picked.year,
            month: picked.month,
            day: picked.day,
            isLeap: picked.isLeap,
          );
          selectedDate.value = DateTime(solar.year, solar.month, solar.day);
          lunarFields.value = picked;
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.invalidLunarDate),
              ),
            );
          }
        }
      }
    }

    Future<void> onSave() async {
      final title = titleController.text.trim();
      if (title.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.titleRequired)),
        );
        return;
      }

      if (initial == null) {
        await ref
            .read(eventsProvider.notifier)
            .addEvent(
              title: title,
              date: selectedDate.value,
              note: noteController.text.trim().isEmpty
                  ? null
                  : noteController.text.trim(),
              isLunar: useLunar.value,
              lunarYear: lunarFields.value?.year,
              lunarMonth: lunarFields.value?.month,
              lunarDay: lunarFields.value?.day,
              lunarLeap: lunarFields.value?.isLeap,
              recurrenceUnit: recurrenceUnit.value,
              recurrenceInterval: recurrenceInterval.value,
              kind: kind.value,
            );
      } else {
        // 检查是否是默认事件且标题被修改
        final isDefaultEvent = initial!.isDefaultEvent;
        final originalLocalizedTitle = EventDisplayUtils.getLocalizedTitle(
          context,
          initial!,
        );
        final isTitleChanged = title != originalLocalizedTitle;

        // 如果是默认事件且标题被修改，则保存为用户自定义事件
        // 如果是普通事件，直接使用用户输入的标题
        final finalTitle = isDefaultEvent && isTitleChanged
            ? title
            : isDefaultEvent
            ? initial!
                  .title // 默认事件且标题未修改，保持原样
            : title; // 普通事件，使用用户输入的标题

        final updated = Event(
          id: initial!.id,
          title: finalTitle,
          date: selectedDate.value,
          note: noteController.text.trim().isEmpty
              ? null
              : noteController.text.trim(),
          isLunar: useLunar.value,
          lunarYear: lunarFields.value?.year,
          lunarMonth: lunarFields.value?.month,
          lunarDay: lunarFields.value?.day,
          lunarLeap: lunarFields.value?.isLeap,
          recurrenceUnit: recurrenceUnit.value,
          recurrenceInterval: recurrenceInterval.value,
          kind: kind.value,
          isHidden: initial!.isHidden,
          isDefaultEvent: isDefaultEvent && !isTitleChanged, // 如果标题被修改，则不再是默认事件
          calendarEventId: initial!.calendarEventId, // 保留日历事件ID
          orderIndex: initial!.orderIndex,
        );
        await ref.read(eventsProvider.notifier).updateEvent(updated);
      }
      if (context.mounted) Navigator.of(context).pop();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          initial == null
              ? AppLocalizations.of(context)!.addEvent
              : AppLocalizations.of(context)!.editEvent,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // 类型选择：均匀分布，不留多余间隙
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      kind.value = EventKind.birthday;
                      recurrenceUnit.value = RecurrenceUnit.year;
                      recurrenceInterval.value = 1;
                    },
                    child: _KindTile(
                      label: AppLocalizations.of(context)!.eventKindBirthday,
                      icon: Icons.cake_outlined,
                      selected: kind.value == EventKind.birthday,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      kind.value = EventKind.anniversary;
                      // 纪念日不重复，不需要设置重复选项
                    },
                    child: _KindTile(
                      label: AppLocalizations.of(context)!.eventKindAnniversary,
                      icon: Icons.favorite_border,
                      selected: kind.value == EventKind.anniversary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      kind.value = EventKind.countdown;
                      recurrenceUnit.value = RecurrenceUnit.none;
                      recurrenceInterval.value = 1;
                    },
                    child: _KindTile(
                      label: AppLocalizations.of(context)!.eventKindCountdown,
                      icon: Icons.hourglass_bottom,
                      selected: kind.value == EventKind.countdown,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Focus(
              onFocusChange: (hasFocus) {
                titleHasFocus.value = hasFocus;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: titleHasFocus.value
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.3),
                    width: titleHasFocus.value ? 2 : 1.5,
                  ),
                  boxShadow: titleHasFocus.value
                      ? [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: TextField(
                    controller: titleController,
                    focusNode: titleFocusNode,
                    decoration: InputDecoration(
                      hintText: kind.value == EventKind.birthday
                          ? AppLocalizations.of(context)!.addEventBirthdayHint
                          : kind.value == EventKind.anniversary
                          ? AppLocalizations.of(
                              context,
                            )!.addEventAnniversaryHint
                          : AppLocalizations.of(context)!.addEventCountdownHint,
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 重复选择器将移动到日期选择下面
            // 公历/阴历切换在日期选择之前
            Row(
              children: [
                Text(AppLocalizations.of(context)!.solar),
                const SizedBox(width: 8),
                Switch(
                  value: useLunar.value,
                  onChanged: (v) {
                    useLunar.value = v;
                    if (v) {
                      // 切到阴历：将当前选择的公历转换为阴历显示
                      lunarFields.value = LunarUtils.solarToLunar(
                        selectedDate.value,
                      );
                    } else {
                      // 切到公历：若之前选择了阴历，则转换回对应的公历日期
                      final lf = lunarFields.value;
                      if (lf != null) {
                        final solar = LunarUtils.lunarToSolar(
                          year: lf.year,
                          month: lf.month,
                          day: lf.day,
                          isLeap: lf.isLeap,
                        );
                        selectedDate.value = DateTime(
                          solar.year,
                          solar.month,
                          solar.day,
                        );
                      }
                    }
                  },
                ),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.lunar),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 20,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.selectDate,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            useLunar.value
                                ? AppLocalizations.of(context)!.lunarCalendar
                                : AppLocalizations.of(context)!.solarCalendar,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      useLunar.value && lunarFields.value != null
                          ? LunarUtils.formatLunar(
                              year: lunarFields.value!.year,
                              month: lunarFields.value!.month,
                              day: lunarFields.value!.day,
                              isLeap: lunarFields.value!.isLeap,
                            )
                          : DateFormat('yyyy-MM-dd').format(selectedDate.value),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (useLunar.value && lunarFields.value != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${AppLocalizations.of(context)!.solarDate}：${DateFormat('yyyy-MM-dd').format(selectedDate.value)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 重复设置（仅生日和倒数日显示）
            if (kind.value != EventKind.anniversary) ...[
              _RecurrencePicker(
                initialUnit: recurrenceUnit.value,
                initialInterval: recurrenceInterval.value,
                onChanged: (unit, interval) {
                  recurrenceUnit.value = unit;
                  recurrenceInterval.value = interval;
                },
              ),
              const SizedBox(height: 16),
            ],
            Focus(
              onFocusChange: (hasFocus) {
                noteHasFocus.value = hasFocus;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: noteHasFocus.value
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.3),
                    width: noteHasFocus.value ? 2 : 1.5,
                  ),
                  boxShadow: noteHasFocus.value
                      ? [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: TextField(
                    controller: noteController,
                    focusNode: noteFocusNode,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.addEventNoteHint,
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: onSave,
                child: Text(AppLocalizations.of(context)!.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecurrencePicker extends HookWidget {
  const _RecurrencePicker({
    required this.onChanged,
    this.initialUnit = RecurrenceUnit.none,
    this.initialInterval = 1,
  });

  final void Function(RecurrenceUnit unit, int interval) onChanged;
  final RecurrenceUnit initialUnit;
  final int initialInterval;

  @override
  Widget build(BuildContext context) {
    final unit = useState<RecurrenceUnit>(initialUnit);
    final interval = useState<int>(initialInterval);

    // 当initialUnit或initialInterval改变时，更新内部状态
    useEffect(() {
      unit.value = initialUnit;
      interval.value = initialInterval;
      return null;
    }, [initialUnit, initialInterval]);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.repeat,
            size: 20,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<RecurrenceUnit>(
              value: unit.value,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              onChanged: (v) {
                if (v == null) return;
                unit.value = v;
                onChanged(unit.value, interval.value);
              },
              items: [
                DropdownMenuItem(
                  value: RecurrenceUnit.none,
                  child: Text(AppLocalizations.of(context)!.noRecurrence),
                ),
                DropdownMenuItem(
                  value: RecurrenceUnit.year,
                  child: Text(AppLocalizations.of(context)!.yearly),
                ),
                DropdownMenuItem(
                  value: RecurrenceUnit.month,
                  child: Text(AppLocalizations.of(context)!.monthly),
                ),
                DropdownMenuItem(
                  value: RecurrenceUnit.week,
                  child: Text(AppLocalizations.of(context)!.weekly),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KindTile extends StatelessWidget {
  const _KindTile({
    required this.label,
    required this.icon,
    required this.selected,
  });

  final String label;
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color borderColor = selected
        ? scheme.primary
        : scheme.outline.withValues(alpha: 0.3);
    final Color bgColor = selected
        ? scheme.primary.withValues(alpha: 0.08)
        : scheme.surface;
    final Color fgColor = selected ? scheme.primary : scheme.outline;

    return Container(
      constraints: const BoxConstraints(minHeight: 80),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: selected ? 2 : 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: fgColor),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: fgColor,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
