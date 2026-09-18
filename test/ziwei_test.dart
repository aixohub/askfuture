import 'dart:convert';
import 'dart:io';

import 'package:divination/models/ziwei.dart';
import 'package:flutter_test/flutter_test.dart';

/// 以开源紫微斗数实现 iztro 生成的命盘为基准，逐宫校验本地排盘。
///
/// 基准数据由 `tools/reverse/generate_ziwei_reference.mjs` 生成，
/// 覆盖 1901–2099 年、早子/晚子时、闰月、男/女等边界场景。
void main() {
  final fixtureFile = File('test/fixtures/ziwei_reference.json');
  final samples = (jsonDecode(fixtureFile.readAsStringSync()) as List)
      .cast<Map<String, dynamic>>();

  int hourOf(int timeIndex) {
    if (timeIndex == 0) return 0;
    if (timeIndex == 12) return 23;
    return timeIndex * 2 - 1;
  }

  test('基准数据包含 24 组样例', () {
    expect(samples.length, 24);
  });

  for (final sample in samples) {
    final note = sample['note'] as String;
    final input = sample['input'] as Map<String, dynamic>;
    final parts = (input['solar'] as String).split('-').map(int.parse).toList();
    final timeIndex = input['timeIndex'] as int;
    final genderText = input['gender'] as String;

    test('排盘对齐 iztro：$note', () {
      final chart = buildZiWeiChart(
        ZiWeiInput(
          dateTime: DateTime(parts[0], parts[1], parts[2], hourOf(timeIndex)),
          isLunar: false,
          gender: genderText == '男' ? 1 : 0,
        ),
      );
      expect(chart, isNotNull, reason: '排盘失败：$note');
      final result = chart!;

      expect(result.lunarText.isNotEmpty, isTrue);
      expect(result.lunarText, sample['lunarDate'], reason: '$note 农历');
      expect(result.siZhuText, sample['chineseDate'], reason: '$note 四柱');
      expect(result.fiveElementsClass, sample['fiveElementsClass'], reason: '$note 五行局');
      expect(result.soul, sample['soul'], reason: '$note 命主');
      expect(result.body, sample['body'], reason: '$note 身主');
      expect(
        result.palaces[result.soulIndex].earthlyBranch,
        sample['soulBranch'],
        reason: '$note 命宫地支',
      );
      expect(
        result.palaces[result.bodyIndex].earthlyBranch,
        sample['bodyBranch'],
        reason: '$note 身宫地支',
      );

      final palaces = (sample['palaces'] as List).cast<Map<String, dynamic>>();
      for (final expected in palaces) {
        final branch = expected['branch'] as String;
        final actual = result.palaces.firstWhere(
          (p) => p.earthlyBranch == branch,
          orElse: () => throw StateError('缺少宫位 $branch'),
        );
        // 官方 App 使用「交友」，iztro 使用「仆役」，为同一宫位
        final expectedName = (expected['name'] as String) == '仆役' ? '交友' : expected['name'];
        expect(actual.name, expectedName, reason: '$note $branch 宫名');
        expect(actual.heavenlyStem, expected['stem'], reason: '$note $branch 宫干');
        expect(
          actual.majorStars
              .map((s) => '${s.name}${s.brightness}${s.mutagen}')
              .toList()
            ..sort(),
          (expected['major'] as List)
              .map((s) => '${s['name']}${s['brightness']}${s['mutagen']}')
              .toList()
            ..sort(),
          reason: '$note $branch 主星',
        );
        expect(
          actual.minorStars.map((s) => '${s.name}${s.mutagen}').toList()..sort(),
          (expected['minor'] as List)
              .map((s) => '${s['name']}${s['mutagen'] ?? ''}')
              .toList()
            ..sort(),
          reason: '$note $branch 辅星',
        );
        expect(actual.changsheng12, expected['changsheng12'], reason: '$note $branch 长生十二神');
        expect(actual.boshi12, expected['boshi12'], reason: '$note $branch 博士十二神');
        expect(actual.jiangqian12, expected['jiangqian12'], reason: '$note $branch 将前十二神');
        expect(actual.suiqian12, expected['suiqian12'], reason: '$note $branch 岁前十二神');
        final decadal = expected['decadal'] as Map<String, dynamic>?;
        expect(actual.decadalRange, decadal?['range'], reason: '$note $branch 大限');
      }
    });
  }

  /// 边界场景（期望值取自 iztro）：晚子时跨日、闰月后半月、除夕跨年。
  test('边界样例：晚子时 / 闰月 / 跨年四柱', () {
    const cases = <List<Object>>[
      // 除夕晚子时：日柱进位到次日，年柱仍按农历年
      <Object>['2023-1-21', 12, '壬寅 癸丑 庚辰 丙子'],
      <Object>['2023-1-21', 11, '壬寅 癸丑 己卯 乙亥'],
      <Object>['2023-2-19', 12, '癸卯 甲寅 己酉 甲子'],
      // 闰八月十五晚子时：月柱不因数日进位而调整
      <Object>['1995-10-9', 12, '乙亥 乙酉 甲戌 甲子'],
      // 闰六月廿八：闰月过半月柱按下月，晚子时同样成立
      <Object>['1979-8-20', 12, '己未 壬申 庚申 丙子'],
      <Object>['1979-8-20', 2, '己未 壬申 己未 丙寅'],
    ];

    for (final item in cases) {
      final parts = (item[0] as String).split('-').map(int.parse).toList();
      final timeIndex = item[1] as int;
      final hour = hourOf(timeIndex);
      final chart = buildZiWeiChart(
        ZiWeiInput(
          dateTime: DateTime(parts[0], parts[1], parts[2], hour),
          isLunar: false,
          gender: 0,
        ),
      );
      expect(chart, isNotNull);
      expect(chart!.siZhuText, item[2], reason: '${item[0]} 时辰序号 $timeIndex');
    }
  });

  test('紫微星定位：五行局 × 日期（官方起紫微星诀）', () {
    // 水二局：初一丑、初二寅、初三寅、初四卯、初五卯、初六辰
    const water2 = <int>[11, 0, 0, 1, 1, 2];
    for (var day = 1; day <= water2.length; day++) {
      expect(ziweiIndexOf(day, 2), water2[day - 1], reason: '水二局 初$day');
    }
    // 火六局：初一酉、初二午、初三亥、初四辰、初五丑、初六寅
    const fire6 = <int>[7, 4, 9, 2, 11, 0];
    for (var day = 1; day <= fire6.length; day++) {
      expect(ziweiIndexOf(day, 6), fire6[day - 1], reason: '火六局 初$day');
    }
  });
}
