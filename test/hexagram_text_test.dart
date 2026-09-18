import 'package:divination/models/hexagram_text.dart';
import 'package:divination/models/lunar_and_shensha.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('六十四卦卦辞与卦辞诗', () {
    test('水火既济卦辞与卦辞诗完整匹配原型截图', () {
      final ci = getGuaCi('水火既济');
      expect(ci, '亨，小利贞，初吉终乱。');

      final poem = getGuaCiPoem('水火既济');
      expect(poem.length, 2);
      expect(poem[0], '功成既济事亨通，奋发依然莫放松。');
      expect(poem[1], '小利能求须谨慎，惟恐初吉变乱终。');
    });

    test('64 卦全覆盖', () {
      expect(kGuaCiData.length, 64);
      expect(kGuaCiPoemData.length, 64);
    });

    test('神煞计算与卦身世身', () {
      final shenSha = calculateShenSha(dayGan: '甲', dayZhi: '午');
      expect(shenSha.yiMa, '申');
      expect(shenSha.taoHua, '卯');
      expect(shenSha.guiRen, '丑、未');
      expect(shenSha.riLu, '寅');

      final guaShen = calculateGuaShen(
        benGuaName: '水火既济',
        shiYaoIndex: 2,
        benYaoZhis: ['卯', '丑', '亥', '申', '戌', '子'],
      );
      expect(guaShen.guaShen, '无');
      expect(guaShen.shiShen, '子');
    });
  });
}
