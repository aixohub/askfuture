import 'dart:convert';
import 'dart:io';

import 'package:divination/models/hexagram.dart';
import 'package:divination/models/liuyao.dart';
import 'package:flutter_test/flutter_test.dart';

/// 六爻装盘对照测试：逐字段比对开源参考实现 sixyao-main
/// （`com.aixohub.sixyao` 的 `GuaExecServiceImpl.queryGua`）。
///
/// 对照数据 `test/fixtures/sixyao_pan_reference.json` 由参考实现直接运行导出
/// （导出脚本见 `tools/reverse/sixyao_pan_reference/PanFixture.java`）：
///   * 64 卦 × 3 个起卦时刻（静卦）
///   * 64 卦 × {初爻动、上爻动}（含变卦）
/// 共 320 条记录，覆盖卦名 / 卦宫 / 宫内八名 / 世应关系 /
/// 六神 / 六亲 / 纳甲地支 / 五行 / 世应 / 伏神 / 动爻。
void main() {
  test('六爻装盘对照 sixyao-main 参考实现（320 条）', () {
    final raw = File('test/fixtures/sixyao_pan_reference.json').readAsStringSync();
    final records = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    final diffs = <String>[];
    var checked = 0;

    for (final record in records) {
      final values = (record['yaos'] as List).cast<String>().map(int.parse).toList();
      final time = DateTime.parse(
        (record['time'] as String).replaceFirst(' ', 'T'),
      );
      final pan = buildLiuYaoPan(
        result: buildGuaResult(values),
        castTime: time,
      );
      checked++;
      _compareGua(diffs, '${record['code']}@${record['time']}', pan.ben,
          record['main'] as Map<String, dynamic>);
      _compareGua(diffs, '${record['code']}@${record['time']}', pan.bian,
          record['bian'] as Map<String, dynamic>);
    }

    expect(checked, 320);
    expect(diffs, isEmpty, reason: diffs.take(20).join('\n'));
  });
}

void _compareGua(
  List<String> diffs,
  String tag,
  GuaZhuang mine,
  Map<String, dynamic> ref,
) {
  if (mine.gua.name != ref['name']) {
    diffs.add('$tag 卦名 ${mine.gua.name} != ${ref['name']}');
  }
  // 参考实现的 belong = 卦宫 + 宫内八名（纯卦 / 初世 / … / 归魂）
  final belong = ref['belong'] as String;
  final refGong = belong.substring(0, 2);
  final refGongNei = belong.substring(2);
  if (mine.gong != refGong) {
    diffs.add('$tag 卦宫 ${mine.gong} != $refGong');
  }
  if (mine.gongNeiName != refGongNei) {
    diffs.add('$tag 宫内八名 ${mine.gongNeiName} != $refGongNei');
  }
  if (mine.relation != ref['desc']) {
    diffs.add('$tag 世应关系 ${mine.relation} != ${ref['desc']}');
  }

  final refYaos = (ref['yaos'] as List).cast<Map<String, dynamic>>();
  for (var i = 0; i < 6; i++) {
    final yao = mine.yaos[i];
    final r = refYaos[i];
    final where = '$tag 第${i + 1}爻';
    if (yao.liuQin != r['liuQin']) {
      diffs.add('$where 六亲 ${yao.liuQin} != ${r['liuQin']}');
    }
    if (yao.zhi != r['zhi']) {
      diffs.add('$where 地支 ${yao.zhi} != ${r['zhi']}');
    }
    if (yao.wuXing != r['wuXing']) {
      diffs.add('$where 五行 ${yao.wuXing} != ${r['wuXing']}');
    }
    // 参考实现写作"腾蛇"，本工程沿用官方 App 的"螣蛇"
    final refShen = r['liuShen'] as String;
    final mineShen = yao.liuShen == '螣蛇' ? '腾蛇' : yao.liuShen;
    if (mineShen != refShen) {
      diffs.add('$where 六神 $mineShen != $refShen');
    }
    final refShiYing = (r['shiYing'] as String).replaceAll('&emsp;', '');
    if (yao.shiYingText != refShiYing) {
      diffs.add('$where 世应 ${yao.shiYingText} != $refShiYing');
    }
    final refFu = ((r['fuShen'] as String?) ?? '').replaceAll('&emsp;', '');
    if ((yao.fuShen?.detail ?? '') != refFu) {
      diffs.add('$where 伏神 "${yao.fuShen?.detail ?? ''}" != "$refFu"');
    }
    final refLaunch = r['launch'] as String?;
    final mineLaunch = yao.isMoving ? (yao.isYang ? '〇' : 'Ⅹ') : null;
    if (mineLaunch != refLaunch) {
      diffs.add('$where 动爻 $mineLaunch != $refLaunch');
    }
  }
}
