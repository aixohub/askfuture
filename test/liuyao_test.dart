import 'package:divination/models/ganzhi.dart';
import 'package:divination/models/hexagram.dart';
import 'package:divination/models/liuyao.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('干支（对齐官方模块 2111）', () {
    test('基准日：1899-12-22 为甲子日', () {
      final gz = dayGanZhi(DateTime(1899, 12, 22));
      expect(gz.text, '甲子');
      expect(dayGanZhi(DateTime(1899, 12, 21)).text, '癸亥');
    });

    test('日干支连续递增：2000-01-01 为戊午日', () {
      expect(dayGanZhi(DateTime(2000, 1, 1)).text, '戊午');
      expect(dayGanZhi(DateTime(2000, 1, 2)).text, '己未');
    });

    test('时干支：甲日 0 时为甲子时', () {
      final day = dayGanZhi(DateTime(2026, 9, 17));
      // 甲/己日起甲子时
      final jiaDay = dayGanZhi(DateTime(1899, 12, 22));
      expect(jiaDay.text, '甲子');
      expect(hourGanZhi(DateTime(1899, 12, 22, 0), jiaDay).text, '甲子');
      expect(hourGanZhi(DateTime(1899, 12, 22, 1), jiaDay).text, '乙丑');
      expect(day.text.isNotEmpty, isTrue);
    });

    test('年干支：立春换年（2026-02-04 04:01 立春，之后为丙午年）', () {
      expect(jieQiMonthOf(DateTime(2026, 2, 3)).jqYear, 2025);
      // 立春前仍属上一年，立春后才进入丙午年
      expect(jieQiMonthOf(DateTime(2026, 2, 4, 3)).jqYear, 2025);
      expect(jieQiMonthOf(DateTime(2026, 2, 4, 5)).jqYear, 2026);
      expect(yearGanZhi(2026).text, '丙午');
      expect(yearGanZhi(2025).text, '乙巳');
    });

    test('月干支：丙午年酉月为丁酉月', () {
      final jq = jieQiMonthOf(DateTime(2026, 9, 17));
      expect(jq.jqMonth, 8); // 酉月
      expect(monthGanZhi(jq.jqMonth, yearGanZhi(jq.jqYear)).text, '丁酉');
    });

    test('旬空：甲子日旬空戌亥', () {
      expect(xunKongOf(GanZhi('甲', '子')), '戌亥');
      expect(xunKongOf(GanZhi('甲', '戌')), '申酉');
    });
  });

  group('装卦（纳甲 / 六亲 / 六神 / 世应）', () {
    /// 六爻皆少阳（静卦）→ 乾为天
    LiuYaoPan panOf(List<int> values) => buildLiuYaoPan(
          result: buildGuaResult(values),
          castTime: DateTime(2026, 9, 17, 10, 30),
        );

    test('乾为天：甲子水子孙 … 壬戌土父母，六冲，世六应三', () {
      final pan = panOf(const <int>[1, 1, 1, 1, 1, 1]);
      expect(pan.ben.gua.name, '乾为天');
      expect(pan.ben.gong, '乾宫');
      expect(pan.ben.chongHe, '六冲');
      expect(pan.ben.shiPosition, 6);
      expect(pan.ben.yingPosition, 3);
      expect(
        pan.ben.yaos.map((yao) => yao.detail).toList(),
        <String>['子孙甲子水', '妻财甲寅木', '父母甲辰土', '官鬼壬午火', '兄弟壬申金', '父母壬戌土'],
      );
      expect(pan.ben.yaos[5].shiYingText, '世');
      expect(pan.ben.yaos[2].shiYingText, '应');
    });

    test('坤为地：乙未土兄弟 … 癸酉金子孙，六冲，世六应三', () {
      final pan = panOf(const <int>[0, 0, 0, 0, 0, 0]);
      expect(pan.ben.gua.name, '坤为地');
      expect(pan.ben.gong, '坤宫');
      expect(pan.ben.chongHe, '六冲');
      expect(
        pan.ben.yaos.map((yao) => yao.detail).toList(),
        <String>['兄弟乙未土', '父母乙巳火', '官鬼乙卯木', '兄弟癸丑土', '妻财癸亥水', '子孙癸酉金'],
      );
    });

    test('水天需：坤宫游魂，世四应一，上卦坎纳戊', () {
      final pan = panOf(const <int>[1, 1, 1, 0, 1, 0]); // 水天需
      expect(pan.ben.gua.name, '水天需');
      expect(pan.ben.youHunGuiHun, '游魂');
      expect(pan.ben.shiPosition, 4);
      expect(pan.ben.yingPosition, 1);
      expect(pan.ben.yaos[3].ganZhi, '戊申');
      expect(pan.ben.yaos[5].ganZhi, '戊子');
    });

    test('六神：按日干起六神（甲乙起青龙）', () {
      // 2026-09-17 日干支为甲子（甲日）→ 初爻青龙
      final pan = panOf(const <int>[1, 1, 1, 1, 1, 1]);
      expect(pan.siZhu.day.gan, '甲');
      expect(pan.ben.yaos[0].liuShen, '青龙');
      expect(pan.ben.yaos[5].liuShen, '玄武');
    });

    test('伏神：乾为天后天风姤，伏神补全缺失六亲', () {
      // 天风姤（乾宫一世）：下巽上乾，乾宫金
      final gua = findGuaByCode('111110')!;
      expect(gua.name, '天风姤');
      final pan = buildLiuYaoPan(
        result: buildGuaResult(<int>[0, 1, 1, 1, 1, 1]),
        castTime: DateTime(2026, 9, 17, 10, 30),
      );
      expect(pan.ben.gua.name, '天风姤');
      expect(pan.ben.youHunGuiHun, '');
      // 本卦六亲：父母、子孙、兄弟、官鬼、兄弟、父母 — 妻财不上卦 → 伏神为妻财甲寅木
      final fuShen = pan.ben.yaos.where((yao) => yao.fuShen != null).toList();
      expect(fuShen, isNotEmpty);
      expect(fuShen.first.fuShen!.liuQin, '妻财');
    });
  });

  group('复制文本（对齐官方模块 2449）', () {
    test('包含标题 / 时间 / 占问 / 四柱旬空 / 本卦变卦 / 六爻行', () {
      final pan = buildLiuYaoPan(
        result: buildGuaResult(const <int>[1, 1, 1, 1, 1, 3]), // 乾为天 变 泽天夬
        castTime: DateTime(2026, 9, 17, 10, 30),
      );
      final text = buildCopyText(pan: pan, titleText: '易占师', question: '今年事业如何');

      expect(text.startsWith('易占师\n'), isTrue);
      expect(text.contains('2026年9月17日 10:30'), isTrue);
      expect(text.contains('占问：今年事业如何'), isTrue);
      // 2026-09-17 为甲午日 → 旬空辰巳
      expect(pan.siZhu.day.text, '甲午');
      expect(text.contains('(旬空：辰巳)'), isTrue);
      expect(text.contains('本卦：乾为天/乾宫六冲'), isTrue);
      expect(text.contains('变卦：泽天夬/坤宫'), isTrue);
      expect(text.split('\n').length, 12);
      // 上爻动（老阳）：本卦阳爻 + " o "，变卦阴爻
      final lines = text.split('\n');
      expect(lines.last.contains(' o '), isTrue);
    });
  });
}
