import 'package:divination/models/lunar_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round trip solar->lunar->solar 1900-2100', () {
    final bad = <String>[];
    for (var y = 1900; y <= 2100; y++) {
      for (var m = 1; m <= 12; m++) {
        final dim = DateTime.utc(y, m + 1, 0).day;
        for (var d = 1; d <= dim; d++) {
          if (y == 1900 && m == 1 && d < 31) continue;
          final lunar = solar2Lunar(y, m, d);
          if (lunar == null) { bad.add('solar2lunar null $y-$m-$d'); continue; }
          final back = lunar2Solar(lunar.year, lunar.month, lunar.day, isLeap: lunar.isLeap);
          if (back == null || back.year != y || back.month != m || back.day != d) {
            bad.add('$y-$m-$d -> 农历${lunar.year}-${lunar.month}${lunar.isLeap ? "闰" : ""}-${lunar.day} -> $back');
          }
        }
      }
    }
    if (bad.isNotEmpty) {
      for (final b in bad) {
        debugPrint('  $b');
      }
    }
    expect(bad.length, 0);
  });
}
