import 'package:intl/intl.dart';

class AppDateUtils {
  const AppDateUtils._();

  static String dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  static String koreanDate(DateTime date) {
    const weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    return '${date.month}월 ${date.day}일 ${weekdays[date.weekday - 1]}';
  }

  static DateTime fromDateKey(String key) => DateTime.parse(key);
}
