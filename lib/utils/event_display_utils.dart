import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/event.dart';

class EventDisplayUtils {
  /// Get localized display title for events
  /// For default events with original title, returns localized text
  /// For user-created events or modified default events, returns the original title
  static String getLocalizedTitle(BuildContext context, Event event) {
    // 只有当事件是默认事件且标题未被修改时，才显示本地化的标题
    if (event.isDefaultEvent && event.title == '__DEFAULT_SATURDAY__') {
      return AppLocalizations.of(context)!.saturday;
    }
    return event.title;
  }
}
