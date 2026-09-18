import 'package:divination/models/divination_models.dart';
import 'package:divination/models/hexagram.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('占事分类 / 起卦方式', () {
    test('占事分类共 16 项（已移除测手机号与消息联络）', () {
      expect(kDivinationCategories.length, 16);
      expect(kDivinationCategories.any((c) => c.name == '测手机号'), isFalse);
      expect(kDivinationCategories.any((c) => c.name == '消息联络'), isFalse);
      expect(kDivinationCategories.first.name, '疾病医药');
      expect(kDivinationCategories.first.value, 7);
      expect(kDivinationCategories.last.name, '其它杂占');
      expect(kDivinationCategories.last.value, 28);
    });

    test('对齐模块 2501：8 种起卦方式与取值', () {
      expect(kQiGuaMethods.length, 8);
      expect(
        kQiGuaMethods.map((m) => '${m.name}:${m.value}').join(','),
        '在线起卦:2,电脑自动:6,手工指定:1,时间起卦:5,单数起卦:3,双数起卦:4,汉字起卦:9,卦名起卦:8',
      );
    });

    test('占事分类换算：30 → 3，婚姻情感 + 男 → 2', () {
      expect(queTypeNameOf(3), '感情/婚姻(女)');
      expect(queTypeNameOf(2), '感情/婚姻(男)');
      expect(queTypeNameOf(4), '财运/生意');
    });
  });

  group('铜钱摇卦（coinYaogua）', () {
    test('0 正 → 老阳(3)，1 正 → 少阴(0)', () {
      expect(CoinCastResult.fromCoins(0, 0, 0).yaoValue, 3);
      expect(CoinCastResult.fromCoins(1, 0, 0).yaoValue, 0);
    });

    test('2 正 → 少阳(1)，3 正 → 老阴(2)', () {
      expect(CoinCastResult.fromCoins(1, 1, 0).yaoValue, 1);
      expect(CoinCastResult.fromCoins(1, 1, 1).yaoValue, 2);
    });

    test('爻属性与官方 qiguaMap 一致', () {
      expect(yaoTypeOf(0).name, '少阴');
      expect(yaoTypeOf(0).isYang, isFalse);
      expect(yaoTypeOf(1).name, '少阳');
      expect(yaoTypeOf(1).isYang, isTrue);
      expect(yaoTypeOf(2).isMoving, isTrue);
      expect(yaoTypeOf(2).mark, 'x');
      expect(yaoTypeOf(3).isMoving, isTrue);
      expect(yaoTypeOf(3).mark, 'o');
    });
  });

  group('卦象推算（模块 2293 卦码）', () {
    test('六爻皆阳 → 乾为天（静卦）', () {
      final result = buildGuaResult(const <int>[1, 1, 1, 1, 1, 1]);
      expect(result.benCode, '111111');
      expect(result.benGua.name, '乾为天');
      expect(result.benGua.palace, '乾宫');
      expect(result.isStatic, isTrue);
    });

    test('六爻皆阴 → 坤为地', () {
      final result = buildGuaResult(const <int>[0, 0, 0, 0, 0, 0]);
      expect(result.benGua.name, '坤为地');
      expect(result.bianGua.name, '坤为地');
    });

    test('上爻老阳动 → 乾为天 变 泽天夬', () {
      final result = buildGuaResult(const <int>[1, 1, 1, 1, 1, 3]);
      expect(result.benGua.name, '乾为天');
      expect(result.bianGua.name, '泽天夬');
      expect(result.bianCode, '011111');
      expect(result.movingLines, <int>[6]);
    });

    test('qiguaData 顺序为 [六爻, 五爻, 四爻, 三爻, 二爻, 一爻]', () {
      final result = buildGuaResult(const <int>[0, 1, 2, 3, 0, 1]);
      expect(result.qiguaData, '1,0,3,2,1,0');
    });

    test('双数起卦：1、1 → 乾为天 变 天火同人（二爻动）', () {
      final result = guaFromDoubleNumber(1, 1);
      expect(result.benGua.name, '乾为天');
      expect(result.bianGua.name, '天火同人');
      expect(result.movingLines, <int>[2]);
    });

    test('时间起卦：上卦 (年+月+日)%8，下卦 (年+月+日+时)%8', () {
      final time = DateTime(2026, 9, 17, 10, 30);
      final base = 2026 + 9 + 17;
      final shiChen = shiChenIndexOf(time);
      expect(shiChen, 6); // 10 时属巳时，序数 6
      final result = guaFromTime(time);
      expect(result.yaoValues.length, 6);
      expect((base + shiChen) % 6 == 0 ? 6 : (base + shiChen) % 6, result.movingLines.single);
    });

    test('卦名起卦：乾为天 → 泽天夬 反推上爻为动爻', () {
      final result = guaFromGuaCodes('111111', '011111');
      expect(result, isNotNull);
      expect(result!.benGua.name, '乾为天');
      expect(result.bianGua.name, '泽天夬');
      expect(result.movingLines, <int>[6]);
    });

    test('64 卦表与官方模块 2293 完全一致', () {
      expect(kDivineNameData.length, 64);
      expect(findGuaByCode('010111')!.name, '水天需');
      expect(findGuaByCode('010110')!.name, '水风井');
      expect(findGuaByCode('010111')!.palace, '坤宫');
    });
  });

  group('爻题与上下卦（传统规则）', () {
    test('爻题：初九/六二/九三/六四/九五/上六', () {
      expect(yaoTitleOf(1, true), '初九');
      expect(yaoTitleOf(1, false), '初六');
      expect(yaoTitleOf(2, false), '六二');
      expect(yaoTitleOf(3, true), '九三');
      expect(yaoTitleOf(4, false), '六四');
      expect(yaoTitleOf(5, true), '九五');
      expect(yaoTitleOf(6, false), '上六');
      expect(yaoTitleOf(6, true), '上九');
    });

    test('上下卦与官方卦名一致：水天需 = 上坎下乾', () {
      final xu = buildGuaResult(const <int>[1, 1, 1, 0, 1, 0]); // 水天需
      expect(xu.benGua.name, '水天需');
      expect(xu.benUpperTrigram, '坎');
      expect(xu.benLowerTrigram, '乾');
      expect(xu.benTrigramText, '上坎下乾');
    });

    test('动爻爻题：上爻老阳动 → 上九', () {
      final result = buildGuaResult(const <int>[1, 1, 1, 1, 1, 3]);
      expect(result.movingYaoTitles, <String>['上九']);
      expect(result.yaoTitleAt(5), '上九');
      expect(result.yaoTitleAt(0), '初九');
    });
  });
}
