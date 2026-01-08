import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:days_reminder/models/event.dart';
import 'package:days_reminder/models/event.g.dart';
import 'package:days_reminder/providers/event_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EventsNotifier', () {
    late ProviderContainer container;
    late Box<Event> box;

    setUp(() async {
      await Hive.initFlutter();
      Hive.registerAdapter(EventAdapter());
      box = await Hive.openBox<Event>('eventsBox_test');
      await box.clear();
      container = ProviderContainer(
        overrides: [hiveBoxProvider.overrideWithValue(box)],
      );
    });

    tearDown(() async {
      await box.clear();
      await box.close();
    });

    test('add and delete event', () async {
      final notifier = container.read(eventsProvider.notifier);
      final added = await notifier.addEvent(
        title: 'Hello',
        date: DateTime(2025, 1, 1),
      );
      expect(container.read(eventsProvider).length, 1);
      await notifier.deleteEvent(added.id);
      expect(container.read(eventsProvider).isEmpty, true);
    });

    test('export and import json', () async {
      final notifier = container.read(eventsProvider.notifier);
      await notifier.addEvent(title: 'A', date: DateTime(2025, 1, 1));
      final jsonStr = notifier.exportToJson();
      final list = json.decode(jsonStr) as List;
      expect(list.length, 1);

      await box.clear();
      await notifier.importFromJson(jsonStr);
      expect(container.read(eventsProvider).length, 1);
    });
  });
}
