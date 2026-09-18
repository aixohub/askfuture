import 'package:divination/models/bazi.dart';
import 'package:divination/models/ganzhi.dart';
import 'package:divination/models/lunar_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('八字：十神 / 纳音 / 长生 / 藏干（对齐官方模块 2472）', () {
    test('以甲木为日主的十神', () {
      expect(shiShenOf('甲', '甲'), '比肩');
      expect(shiShenOf('乙', '甲'), '劫财');
      expect(shiShenOf('丙', '甲'), '食神');
      expect(shiShenOf('丁', '甲'), '伤官');
      expect(shiShenOf('戊', '甲'), '偏财');
      expect(shiShenOf('己', '甲'), '正财');
      expect(shiShenOf('庚', '甲'), '七杀');
      expect(shiShenOf('辛', '甲'), '正官');
      expect(shiShenOf('壬', '甲'), '偏印');
      expect(shiShenOf('癸', '甲'), '正印');
    });

    test('纳音六十甲子', () {
      expect(nayinOf('甲', '子'), '海中金');
      expect(nayinOf('丙', '午'), '天河水');
      expect(nayinOf('甲', '午'), '沙中金');
      expect(nayinOf('癸', '亥'), '大海水');
      expect(kNayin.length, 60);
    });

    test('长生十二神：甲木长生在亥', () {
      expect(changSheng12Of('甲', '亥'), '长生');
      expect(changSheng12Of('甲', '子'), '沐浴');
      expect(changSheng12Of('甲', '卯'), '帝旺');
    });

    test('地支藏干', () {
      expect(kDiZhiCangGan['寅']!.map((c) => c.gan).join(), '甲丙戊');
      expect(kDiZhiCangGan['子']!.single.gan, '癸');
      expect(kDiZhiCangGan['戌']!.map((c) => c.gan).join(), '戊辛丁');
    });
  });

  group('八字排盘', () {
    final birth = DateTime(2026, 9, 17, 19, 16);

    test('四柱与十神 / 纳音 / 星运', () {
      final pan = buildBaZiPan(birth, male: true);
      expect(pan.siZhu.text, '丙午 丁酉 甲午 甲戌');
      expect(pan.dayMaster, '甲');
      expect(pan.animal, '马');

      final year = pan.pillarOf('年柱');
      expect(year.gan, '丙');
      expect(year.shiShen, '食神');
      expect(year.nayin, '天河水');

      final month = pan.pillarOf('月柱');
      expect(month.shiShen, '伤官');
      expect(month.nayin, '山下火');

      final day = pan.pillarOf('日柱');
      expect(day.shiShen, '日主');
      expect(day.nayin, '沙中金');

      final hour = pan.pillarOf('时柱');
      expect(hour.shiShen, '比肩');
      expect(hour.nayin, '山头火');
      expect(pan.pillarOf('月柱').cangGanText, '辛');
    });

    test('五行统计：木 2 火 4 土 1 金 1 水 0', () {
      final pan = buildBaZiPan(birth, male: true);
      expect(pan.wuXingCount['木'], 2);
      expect(pan.wuXingCount['火'], 4);
      expect(pan.wuXingCount['土'], 1);
      expect(pan.wuXingCount['金'], 1);
      expect(pan.wuXingCount['水'], 0);
    });

    test('大运：阳年男顺排，起运约 7 岁，自月柱顺推十步', () {
      final pan = buildBaZiPan(birth, male: true);
      expect(pan.forward, isTrue);
      // 2026-09-17 → 寒露 2026-10-08 约 20.8 天，三天折一年
      expect(pan.qiYunAge, greaterThan(6.5));
      expect(pan.qiYunAge, lessThan(7.2));
      expect(pan.daYun.length, 10);
      // 月柱为丁酉，顺排下一步为戊戌
      expect(pan.daYun.first.ganZhi.text, '戊戌');
      expect(pan.daYun[1].ganZhi.text, '己亥');
    });

    test('大运：阳年女逆排，自月柱逆推', () {
      final pan = buildBaZiPan(birth, male: false);
      expect(pan.forward, isFalse);
      // 月柱丁酉逆排为丙申
      expect(pan.daYun.first.ganZhi.text, '丙申');
    });

    test('旬空取自日柱（甲午旬空辰巳）', () {
      final pan = buildBaZiPan(birth, male: true);
      expect(xunKongOf(pan.siZhu.day), '辰巳');
    });

    test('农历换公历：2026 年八月初七 = 2026-09-17', () {
      final solar = lunar2Solar(2026, 8, 7);
      expect(solar, DateTime(2026, 9, 17));
      // 反查一致
      expect(lunarTextOf(DateTime(2026, 9, 17)), '八月初七');
    });

    test('截图案例 2026-10-27 06:38 男命排盘', () {
      final pan = buildBaZiPan(DateTime(2026, 10, 27, 6, 38), male: true);
      expect(pan.siZhu.text, '丙午 戊戌 甲戌 丁卯');
      expect(pan.daYun.first.ganZhi.text, '己亥');
      expect(pan.qiYunDetail.text, '命主出生 3 年 9 个月 26 天 11 小时后开始起运');
      expect(pan.qiYunDetail.jiaoYunText, '命主于公历 2030 年 08 月 22 日交运');
    });
  });

  group('专业命盘：当前大运 / 当前流年定位（官方模块 2489）', () {
    test('getInitDaYunIndex：以起运年份为基准每 10 年一步', () {
      // 起运年 1994：1994-2003 → 第 0 步、2004-2013 → 第 1 步、2024-2033 → 第 3 步
      expect(initialDaYunIndex(firstDaYunYear: 1994, currentYear: 2024), 3);
      expect(initialDaYunIndex(firstDaYunYear: 1994, currentYear: 2026), 3);
      expect(initialDaYunIndex(firstDaYunYear: 1994, currentYear: 2033), 3);
      expect(initialDaYunIndex(firstDaYunYear: 1994, currentYear: 2034), 4);
      expect(initialDaYunIndex(firstDaYunYear: 1994, currentYear: 2003), 0);
      expect(initialDaYunIndex(firstDaYunYear: 1994, currentYear: 2004), 1);
      // 尚未起运 → 第 0 步
      expect(initialDaYunIndex(firstDaYunYear: 1994, currentYear: 1993), 0);
      // 十步大运（100 年）之外 → 回到第 0 步
      expect(initialDaYunIndex(firstDaYunYear: 1994, currentYear: 2093), 9);
      expect(initialDaYunIndex(firstDaYunYear: 1994, currentYear: 2094), 0);
    });

    test('getInitLiuNianIndex：当前大运十年内的当前流年', () {
      // 第 3 步大运 2024-2033
      expect(
        initialLiuNianIndex(firstDaYunYear: 1994, currentYear: 2024, daYunIndex: 3),
        0,
      );
      expect(
        initialLiuNianIndex(firstDaYunYear: 1994, currentYear: 2026, daYunIndex: 3),
        2,
      );
      expect(
        initialLiuNianIndex(firstDaYunYear: 1994, currentYear: 2033, daYunIndex: 3),
        9,
      );
      // 未进入 / 已越过该步大运 → 回到该步的第 0 个流年
      expect(
        initialLiuNianIndex(firstDaYunYear: 1994, currentYear: 2023, daYunIndex: 3),
        0,
      );
      expect(
        initialLiuNianIndex(firstDaYunYear: 1994, currentYear: 2034, daYunIndex: 3),
        0,
      );
    });

    test('1990-06-15 06:20 男命：当前年份落在正确的大运与流年', () {
      final pan = buildBaZiPan(DateTime(1990, 6, 15, 6, 20), male: true);
      final firstYear = pan.qiYunDetail.jiaoYunDate.year;

      // 用固定年份验证与大运列表的对应关系（避免依赖运行时刻）
      for (final year in <int>[firstYear, firstYear + 9, firstYear + 10, firstYear + 25]) {
        final index = initialDaYunIndex(firstDaYunYear: firstYear, currentYear: year);
        final startYear = firstYear + index * 10;
        final liuNian = initialLiuNianIndex(
          firstDaYunYear: firstYear,
          currentYear: year,
          daYunIndex: index,
        );
        expect(startYear <= year && year < startYear + 10, isTrue);
        expect(startYear + liuNian, year);
        expect(index < pan.daYun.length, isTrue);
      }
    });
  });
}
