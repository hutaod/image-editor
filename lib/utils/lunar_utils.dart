import 'package:lunar/lunar.dart';

class LunarUtils {
  /// Convert Gregorian date to Lunar y/m/d and whether it is leap month.
  static ({int year, int month, int day, bool isLeap}) solarToLunar(DateTime date) {
    final solar = Solar.fromYmd(date.year, date.month, date.day);
    final lunar = solar.getLunar();
    return (year: lunar.getYear(), month: lunar.getMonth(), day: lunar.getDay(), isLeap: lunar.getMonth() < 0);
  }

  /// Convert Lunar y/m/d (+ leap) to Gregorian date.
  static DateTime lunarToSolar({required int year, required int month, required int day, bool isLeap = false}) {
    // The library uses negative month to represent leap month
    final m = isLeap ? -month : month;
    final lunar = Lunar.fromYmd(year, m, day);
    final solar = lunar.getSolar();
    return DateTime(solar.getYear(), solar.getMonth(), solar.getDay());
  }

  static String formatLunar({required int year, required int month, required int day, bool isLeap = false}) {
    final lunar = Lunar.fromYmd(year, isLeap ? -month : month, day);
    return '${lunar.getYearInGanZhi()}年 ${lunar.getMonthInChinese()}月${lunar.getDayInChinese()}';
  }
}
