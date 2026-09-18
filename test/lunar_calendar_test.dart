import 'dart:convert';
import 'dart:io';

import 'package:divination/models/lunar_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

/// 农历 / 公历日期转换测试。
///
/// 对照数据 `test/fixtures/official_lunar_reference.json` 由
/// `tools/reverse/extract_official_calendar.js` 从官方 RN bundle 模块 1898
/// （`calendar.solar2lunar`）直接运行导出，含 1736 条：
///   * 2023-01-01 ~ 2026-12-31 逐日（覆盖 2023 闰二月、2025 闰六月）
///   * 1900–2100 每年春节（正月初一）与每个闰月的初一
void main() {
  group('公历 → 农历（对照官方模块 1898）', () {
    test('1736 条官方对照全部一致，且可反推回公历', () {
      final raw = File('test/fixtures/official_lunar_reference.json')
          .readAsStringSync();
      final rows = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      final diffs = <String>[];

      for (final row in rows) {
        final y = row['y'] as int;
        final m = row['m'] as int;
        final d = row['d'] as int;
        final lunar = solar2Lunar(y, m, d);
        if (lunar == null) {
          diffs.add('$y-$m-$d 换算失败');
          continue;
        }
        if (lunar.year != row['ly'] ||
            lunar.month != row['lm'] ||
            lunar.day != row['ld'] ||
            lunar.isLeap != row['leap']) {
          diffs.add(
            '$y-$m-$d 农历不一致：'
            '${lunar.year}-${lunar.month}${lunar.isLeap ? "闰" : ""}-${lunar.day}'
            ' != ${row['ly']}-${row['lm']}${row['leap'] == true ? "闰" : ""}-${row['ld']}',
          );
          continue;
        }
        // 官方 `toChinaMonth` 不带"闰"字，本工程展示时补上"闰"前缀
        final expectedText = '${lunar.isLeap ? '闰' : ''}${row['text']}';
        if (lunar.text != expectedText) {
          diffs.add('$y-$m-$d 农历文案 ${lunar.text} != $expectedText');
        }
        // 反向：官方的农历日期必须能换算回同一天公历
        final back = solarDateOfLunar(
          lunar.year,
          lunar.month,
          lunar.day,
          isLeap: lunar.isLeap,
        );
        if (back == null ||
            back.year != y ||
            back.month != m ||
            back.day != d) {
          diffs.add('$y-$m-$d 反推失败：$back');
        }
      }

      expect(rows.length, 1736);
      expect(diffs, isEmpty, reason: diffs.take(20).join('\n'));
    });
  });

  group('农历 → 公历', () {
    test('春节与闰月初一', () {
      // 2024 春节：农历正月初一 = 2024-02-10
      expect(solarDateOfLunar(2024, 1, 1), DateTime(2024, 2, 10));
      // 2023 闰二月初一 = 2023-03-22；三月初一 = 2023-04-20
      expect(solarDateOfLunar(2023, 2, 1, isLeap: true), DateTime(2023, 3, 22));
      expect(solarDateOfLunar(2023, 3, 1), DateTime(2023, 4, 20));
      // 2025 闰六月初一 = 2025-07-25
      expect(solarDateOfLunar(2025, 6, 1, isLeap: true), DateTime(2025, 7, 25));
      // 农历 1900 年正月初一 = 1900-01-31（历表起点）
      expect(solarDateOfLunar(1900, 1, 1), DateTime(1900, 1, 31));
    });

    test('非法输入返回 null', () {
      expect(solarDateOfLunar(2023, 2, 1), isNotNull); // 平月
      expect(solarDateOfLunar(2023, 2, 1, isLeap: true), isNotNull); // 闰月
      expect(solarDateOfLunar(2024, 2, 1, isLeap: true), isNull); // 2024 无闰二月
      expect(solarDateOfLunar(2023, 13, 1), isNull);
      expect(solarDateOfLunar(2023, 1, 31), isNull); // 正月只有 29 天
      expect(solarDateOfLunar(1899, 12, 1), isNull);
      expect(solarDateOfLunar(2101, 1, 1), isNull);
    });

    test('闰月列表与大小月', () {
      final months2023 = lunarMonthsOf(2023);
      expect(months2023.length, 13); // 含闰二月
      expect(months2023[2].name, '闰二月');
      expect(months2023[2].isLeap, isTrue);
      expect(months2023[2].dayCount, 29);
      expect(lunarMonthsOf(2024).length, 12);

      // 2023 年正月 29 天、闰二月 29 天
      expect(lunarDaysInMonth(2023, 1), 29);
      expect(lunarDaysInMonth(2023, 2, isLeap: true), 29);
      expect(lunarDaysInMonth(2023, 2, isLeap: false), 30);
    });
  });

  group('农历展示与时辰', () {
    test('农历文案', () {
      final lunar = lunarDateOf(DateTime(2026, 9, 18));
      expect(lunar, isNotNull);
      expect(lunar!.monthCn, '八月');
      expect(lunar.dayCn, matches(RegExp(r'^初|^十|^廿|^三')));
      expect(lunar.fullText, startsWith('丙午年八月'));
      expect(lunar.solarDate, DateTime(2026, 9, 18));
    });

    test('时辰滚轮：子时 0 → 0 点，亥时 11 → 22 点', () {
      expect(kLunarHourNames.length, 12);
      expect(kLunarHourNames.first, '子时23:00-00:59');
      expect(kLunarHourNames.last, '亥时21:00-22:59');
      expect(lunarHourIndex(0), 0);
      expect(lunarHourIndex(23), 0);
      expect(lunarHourIndex(2), 1);
      expect(lunarHourIndex(10), 5); // 巳时
      expect(hourOfLunarHourIndex(0), 0);
      expect(hourOfLunarHourIndex(11), 22);
      for (var i = 0; i < 12; i++) {
        expect(lunarHourIndex(hourOfLunarHourIndex(i)), i);
      }
    });
  });
}
