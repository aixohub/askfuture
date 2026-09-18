import 'package:divination/models/ganzhi.dart';
import 'package:divination/models/jieqi.dart';
import 'package:divination/models/lunar_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

/// 官方对照向量：由 `tools/reverse/extract_official_calendar.js` 从官方
/// RN bundle 模块 2111/2112/1898 直接运行导出（四柱 / 农历 / 节气）。
class _Vector {
  final DateTime date;
  final String sizhu;
  final String lunar;
  final String prevJq;
  final String prevJqTime;
  final String zq;
  final String zqTime;
  final String nextJq;
  final String nextJqTime;

  _Vector(
    this.date,
    this.sizhu,
    this.lunar,
    this.prevJq,
    this.prevJqTime,
    this.zq,
    this.zqTime,
    this.nextJq,
    this.nextJqTime,
  );
}

final List<_Vector> _vectors = <_Vector>[
    _Vector(
      DateTime.parse('2026-09-17T19:16'),
      '丙午 丁酉 甲午 甲戌',
      '八月初七',
      '白露', '2026-09-07 22:41',
      '秋分', '2026-09-23 08:05',
      '寒露', '2026-10-08 14:29',
    ),
    _Vector(
      DateTime.parse('2026-09-07T22:41'),
      '丙午 丙申 甲申 乙亥',
      '七月廿六',
      '立秋', '2026-08-07 19:42',
      '处暑', '2026-08-23 10:18',
      '白露', '2026-09-07 22:41',
    ),
    _Vector(
      DateTime.parse('2026-02-04T04:02'),
      '丙午 庚寅 己酉 丙寅',
      '腊月十七',
      '立春', '2026-02-04 04:01',
      '雨水', '2026-02-18 23:51',
      '惊蛰', '2026-03-05 21:58',
    ),
    _Vector(
      DateTime.parse('2024-02-10T00:30'),
      '甲辰 丙寅 甲辰 甲子',
      '正月初一',
      '立春', '2024-02-04 16:27',
      '雨水', '2024-02-19 12:13',
      '惊蛰', '2024-03-05 10:22',
    ),
    _Vector(
      DateTime.parse('2024-02-04T16:27'),
      '癸卯 乙丑 戊戌 庚申',
      '腊月廿五',
      '小寒', '2024-01-06 04:49',
      '大寒', '2024-01-20 22:07',
      '立春', '2024-02-04 16:27',
    ),
    _Vector(
      DateTime.parse('2023-12-22T11:27'),
      '癸卯 甲子 甲寅 庚午',
      '冬月初十',
      '大雪', '2023-12-07 17:32',
      '冬至', '2023-12-22 11:27',
      '小寒', '2024-01-06 04:49',
    ),
    _Vector(
      DateTime.parse('2000-01-01T00:00'),
      '己卯 丙子 戊午 壬子',
      '冬月廿五',
      '大雪', '1999-12-07 21:47',
      '冬至', '1999-12-22 15:43',
      '小寒', '2000-01-06 09:00',
    ),
    _Vector(
      DateTime.parse('1990-06-15T23:30'),
      '庚午 壬午 壬子 庚子',
      '五月廿三',
      '芒种', '1990-06-06 06:46',
      '夏至', '1990-06-21 23:32',
      '小暑', '1990-07-07 17:00',
    ),
    _Vector(
      DateTime.parse('1984-02-02T12:00'),
      '癸亥 乙丑 丙寅 甲午',
      '正月初一',
      '小寒', '1984-01-06 11:40',
      '大寒', '1984-01-21 05:05',
      '立春', '1984-02-04 23:18',
    ),
    _Vector(
      DateTime.parse('1970-10-01T08:05'),
      '庚戌 乙酉 甲寅 戊辰',
      '九月初二',
      '白露', '1970-09-08 09:37',
      '秋分', '1970-09-23 18:59',
      '寒露', '1970-10-09 01:01',
    ),
];

String _fmt(DateTime dt) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
}

void main() {
  group('干支历：与官方引擎逐条对照', () {
    for (final v in _vectors) {
      test('四柱 / 农历 / 节气 @ ${v.date}', () {
        final sizhu = computeSiZhu(v.date);
        expect(sizhu.text, v.sizhu, reason: '四柱不一致');

        final lunar = solar2Lunar(v.date.year, v.date.month, v.date.day);
        expect(lunar, isNotNull);
        expect(lunar!.text, v.lunar, reason: '农历不一致');

        final prev = currentJie(v.date);
        expect(prev?.name, v.prevJq);
        expect(_fmt(prev!.time), v.prevJqTime);

        final zq = currentZhongQi(v.date);
        expect(zq?.name, v.zq);
        expect(_fmt(zq!.time), v.zqTime);

        final next = nextJie(v.date);
        expect(next?.name, v.nextJq);
        expect(_fmt(next!.time), v.nextJqTime);
      });
    }
  });
}
