import 'package:divination/models/ganzhi.dart';
import 'package:divination/models/lunar_and_shensha.dart';
import 'package:flutter_test/flutter_test.dart';

/// 六爻神煞（贵人 / 驿马 / 桃花 / 日禄）校正测试。
///
/// 口径来自参考实现 sixyao-main `src/main/resources/static/liuyaodata.js`：
///
/// ```js
/// var riGan = bzpp.iRiJZ % 10;
/// var riZhi = bzpp.iRiJZ % 12;
/// "神煞：贵人→" + TGGuiRenStrs[riGan]
///      + "，驿马→" + DZYiMaStrs[riZhi%4]
///      + "，桃花→" + DZTaoHuaStrs[riZhi%4]
///      + "，日禄→" + TGLuStrs[riGan]
/// ```
///
/// 期望值在测试中按**传统口诀/三合局**重新推导（而非复制实现里的数组），
/// 另加参考工程 `templates/home.ftl` 中的现成排盘样例作为端到端对照。
void main() {
  /// 驿马：申子辰马在寅、巳酉丑马在亥、寅午戌马在申、亥卯未马在巳。
  const List<String> yiMaOfGroup = <String>['寅', '亥', '申', '巳'];

  /// 桃花（咸池）：申子辰在酉、巳酉丑在午、寅午戌在卯、亥卯未在子。
  const List<String> taoHuaOfGroup = <String>['酉', '午', '卯', '子'];

  int groupOf(String zhi) {
    final index = kDiZhi.indexOf(zhi);
    expect(index >= 0, isTrue, reason: '未知地支 $zhi');
    return index % 4;
  }

  /// 天乙贵人歌：甲戊兼牛羊，乙己鼠猴乡，丙丁猪鸡位，壬癸兔蛇藏，庚辛逢马虎。
  const Map<String, String> guiRenByGan = <String, String>{
    '甲': '丑、未',
    '戊': '丑、未',
    '乙': '子、申',
    '己': '子、申',
    '丙': '亥、酉',
    '丁': '亥、酉',
    '庚': '午、寅',
    '辛': '午、寅',
    '壬': '卯、巳',
    '癸': '卯、巳',
  };

  /// 日禄：甲寅乙卯丙戊巳，丁己午，庚申辛酉，壬亥癸子。
  const Map<String, String> riLuByGan = <String, String>{
    '甲': '寅',
    '乙': '卯',
    '丙': '巳',
    '丁': '午',
    '戊': '巳',
    '己': '午',
    '庚': '申',
    '辛': '酉',
    '壬': '亥',
    '癸': '子',
  };

  group('神煞口径（对齐 sixyao-main liuyaodata.js）', () {
    test('10 日干 × 12 日支 共 120 组全部一致', () {
      final diffs = <String>[];
      for (final gan in kTianGan) {
        for (final zhi in kDiZhi) {
          final shenSha = calculateShenSha(dayGan: gan, dayZhi: zhi);
          final group = groupOf(zhi);
          final expected = <String, String>{
            '贵人': guiRenByGan[gan]!,
            '驿马': yiMaOfGroup[group],
            '桃花': taoHuaOfGroup[group],
            '日禄': riLuByGan[gan]!,
          };
          final actual = <String, String>{
            '贵人': shenSha.guiRen,
            '驿马': shenSha.yiMa,
            '桃花': shenSha.taoHua,
            '日禄': shenSha.riLu,
          };
          if (actual.toString() != expected.toString()) {
            diffs.add('$gan$zhi 期望 $expected 实际 $actual');
          }
        }
      }
      expect(diffs, isEmpty, reason: diffs.take(10).join('\n'));
    });

    test('参考工程样例：2023-06-04 09:49（癸巳日）', () {
      // home.ftl 原文：神煞：贵人→卯、巳，驿马→亥，桃花→午，日禄→子
      final siZhu = computeSiZhu(DateTime(2023, 6, 4, 9, 49));
      expect(siZhu.day.text, '癸巳');

      final shenSha = calculateShenSha(
        dayGan: siZhu.day.gan,
        dayZhi: siZhu.day.zhi,
      );
      expect(shenSha.guiRen, '卯、巳');
      expect(shenSha.yiMa, '亥');
      expect(shenSha.taoHua, '午');
      expect(shenSha.riLu, '子');
    });

    test('展示顺序与折叠规则：折叠 3 项、展开 4 项', () {
      final shenSha = calculateShenSha(dayGan: '癸', dayZhi: '巳');
      expect(
        shenSha.items.map((item) => item.name).toList(),
        <String>['贵人', '驿马', '桃花', '日禄'],
      );
      expect(shenSha.summary, '贵人 — 卯、巳  驿马 — 亥  桃花 — 午');
      expect(
        shenSha.detailText,
        '贵人 — 卯、巳  驿马 — 亥  桃花 — 午  日禄 — 子',
      );
    });

    test('非法干支返回空值', () {
      final shenSha = calculateShenSha(dayGan: 'X', dayZhi: 'Y');
      expect(shenSha.guiRen, isEmpty);
      expect(shenSha.yiMa, isEmpty);
      expect(shenSha.taoHua, isEmpty);
      expect(shenSha.riLu, isEmpty);
    });

    test('神煞表与参考实现四张表逐项一致', () {
      // TGGuiRenStrs / TGLuStrs 按甲0…癸9 顺序
      expect(kGuiRenByGan, <String>[
        '丑、未', '子、申', '亥、酉', '亥、酉', '丑、未',
        '子、申', '午、寅', '午、寅', '卯、巳', '卯、巳',
      ]);
      expect(kRiLuByGan, <String>['寅', '卯', '巳', '午', '巳', '午', '申', '酉', '亥', '子']);
      // DZYiMaStrs / DZTaoHuaStrs 按地支序号 % 4
      expect(kYiMaByZhiMod4, <String>['寅', '亥', '申', '巳']);
      expect(kTaoHuaByZhiMod4, <String>['酉', '午', '卯', '子']);
    });
  });
}
