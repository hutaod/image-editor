// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:days_reminder/models/event.dart';

void main() {
  test('Event dayDelta calculation', () {
    final today = DateTime.now();
    final eventTomorrow = Event.create(
      id: '1',
      title: 't',
      date: today.add(const Duration(days: 1)),
    );
    final eventYesterday = Event.create(
      id: '2',
      title: 't',
      date: today.subtract(const Duration(days: 1)),
    );
    expect(eventTomorrow.dayDelta, 1);
    expect(eventYesterday.dayDelta, -1);
  });
}
