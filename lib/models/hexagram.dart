/// 六十四卦数据与卦象推算。
///
/// 卦名与卦码 1:1 复制自官方 RN bundle 模块 2293 `divineNameData`
/// （八宫 × 八卦 = 64 条）。
///
/// 卦码为 6 位字符串，顺序与官方 `qiguaData` 完全一致：
/// [六爻, 五爻, 四爻, 三爻, 二爻, 一爻]，`1` 为阳爻、`0` 为阴爻。
library;

import 'divination_models.dart';

/// 一卦（宫名 + 卦名 + 卦码）。
class DivineGua {
  final String palace;
  final String name;
  final String code;

  const DivineGua(this.palace, this.name, this.code);
}

/// 对齐模块 2293 `divineNameData`。
const List<DivineGua> kDivineNameData = <DivineGua>[
  // 乾宫
  DivineGua('乾宫', '乾为天', '111111'),
  DivineGua('乾宫', '天风姤', '111110'),
  DivineGua('乾宫', '天山遁', '111100'),
  DivineGua('乾宫', '天地否', '111000'),
  DivineGua('乾宫', '风地观', '110000'),
  DivineGua('乾宫', '山地剥', '100000'),
  DivineGua('乾宫', '火地晋', '101000'),
  DivineGua('乾宫', '火天大有', '101111'),
  // 兑宫
  DivineGua('兑宫', '兑为泽', '011011'),
  DivineGua('兑宫', '泽水困', '011010'),
  DivineGua('兑宫', '泽地萃', '011000'),
  DivineGua('兑宫', '泽山咸', '011100'),
  DivineGua('兑宫', '水山蹇', '010100'),
  DivineGua('兑宫', '地山谦', '000100'),
  DivineGua('兑宫', '雷山小过', '001100'),
  DivineGua('兑宫', '雷泽归妹', '001011'),
  // 离宫
  DivineGua('离宫', '离为火', '101101'),
  DivineGua('离宫', '火山旅', '101100'),
  DivineGua('离宫', '火风鼎', '101110'),
  DivineGua('离宫', '火水未济', '101010'),
  DivineGua('离宫', '山水蒙', '100010'),
  DivineGua('离宫', '风水涣', '110010'),
  DivineGua('离宫', '天水讼', '111010'),
  DivineGua('离宫', '天火同人', '111101'),
  // 震宫
  DivineGua('震宫', '震为雷', '001001'),
  DivineGua('震宫', '雷地豫', '001000'),
  DivineGua('震宫', '雷水解', '001010'),
  DivineGua('震宫', '雷风恒', '001110'),
  DivineGua('震宫', '地风升', '000110'),
  DivineGua('震宫', '水风井', '010110'),
  DivineGua('震宫', '泽风大过', '011110'),
  DivineGua('震宫', '泽雷随', '011001'),
  // 巽宫
  DivineGua('巽宫', '巽为风', '110110'),
  DivineGua('巽宫', '风天小畜', '110111'),
  DivineGua('巽宫', '风火家人', '110101'),
  DivineGua('巽宫', '风雷益', '110001'),
  DivineGua('巽宫', '天雷无妄', '111001'),
  DivineGua('巽宫', '火雷噬嗑', '101001'),
  DivineGua('巽宫', '山雷颐', '100001'),
  DivineGua('巽宫', '山风蛊', '100110'),
  // 坎宫
  DivineGua('坎宫', '坎为水', '010010'),
  DivineGua('坎宫', '水泽节', '010011'),
  DivineGua('坎宫', '水雷屯', '010001'),
  DivineGua('坎宫', '水火既济', '010101'),
  DivineGua('坎宫', '泽火革', '011101'),
  DivineGua('坎宫', '雷火丰', '001101'),
  DivineGua('坎宫', '地火明夷', '000101'),
  DivineGua('坎宫', '地水师', '000010'),
  // 艮宫
  DivineGua('艮宫', '艮为山', '100100'),
  DivineGua('艮宫', '山火贲', '100101'),
  DivineGua('艮宫', '山天大畜', '100111'),
  DivineGua('艮宫', '山泽损', '100011'),
  DivineGua('艮宫', '火泽睽', '101011'),
  DivineGua('艮宫', '天泽履', '111011'),
  DivineGua('艮宫', '风泽中孚', '110011'),
  DivineGua('艮宫', '风山渐', '110100'),
  // 坤宫
  DivineGua('坤宫', '坤为地', '000000'),
  DivineGua('坤宫', '地雷复', '000001'),
  DivineGua('坤宫', '地泽临', '000011'),
  DivineGua('坤宫', '地天泰', '000111'),
  DivineGua('坤宫', '雷天大壮', '001111'),
  DivineGua('坤宫', '泽天夬', '011111'),
  DivineGua('坤宫', '水天需', '010111'),
  DivineGua('坤宫', '水地比', '010000'),
];

final Map<String, DivineGua> _guaByCode = <String, DivineGua>{
  for (final gua in kDivineNameData) gua.code: gua,
};

DivineGua? findGuaByCode(String code) => _guaByCode[code];

/// 八卦名（卦码按 [上爻, 中爻, 初爻] 自上而下三位，`1` 阳 `0` 阴）。
///
/// 例：`010` → 坎，`111` → 乾，因此 `010111`（水天需）= 上坎下乾。
const Map<String, String> kTrigramNames = <String, String>{
  '111': '乾',
  '011': '兑',
  '101': '离',
  '001': '震',
  '110': '巽',
  '010': '坎',
  '100': '艮',
  '000': '坤',
};

/// 八卦对应的自然象。
const Map<String, String> kTrigramImages = <String, String>{
  '111': '天',
  '011': '泽',
  '101': '火',
  '001': '雷',
  '110': '风',
  '010': '水',
  '100': '山',
  '000': '地',
};

/// 六爻爻题（初九/六二/九三/六四/九五/上六）。
///
/// `position` 为 1~6（1 初爻、6 上爻），`isYang` 为该爻阴阳。
String yaoTitleOf(int position, bool isYang) {
  const ordinal = <String>['初', '二', '三', '四', '五', '上'];
  final index = position < 1 || position > 6 ? 1 : position;
  final number = isYang ? '九' : '六';
  // 初爻与上爻把"九/六"放在前，其余放在爻位后
  if (index == 1) return '初$number';
  if (index == 6) return '上$number';
  return '$number${ordinal[index - 1]}';
}

/// 先天八卦数（1 乾 … 8 坤）对应的三爻，自下而上（初爻 → 三爻）。
const Map<int, List<int>> _trigramLines = <int, List<int>>{
  1: <int>[1, 1, 1], // 乾 ☰
  2: <int>[1, 1, 0], // 兑 ☱
  3: <int>[1, 0, 1], // 离 ☲
  4: <int>[1, 0, 0], // 震 ☳
  5: <int>[0, 1, 1], // 巽 ☴
  6: <int>[0, 1, 0], // 坎 ☵
  7: <int>[0, 0, 1], // 艮 ☶
  8: <int>[0, 0, 0], // 坤 ☷
};

/// `n % 8` 取卦数：余 0 视作 8（坤）。
int _trigramNumberOf(int n) {
  final r = n % 8;
  return r == 0 ? 8 : r;
}

/// `n % 6` 取动爻：余 0 视作 6（上爻）。
int _movingLineOf(int n) {
  final r = n % 6;
  return r == 0 ? 6 : r;
}

/// 时辰序数（子 1 … 亥 12）。
int shiChenIndexOf(DateTime time) {
  // 子时 23:00-00:59、丑时 01:00-02:59 …… 每两小时一个时辰。
  return ((time.hour + 1) ~/ 2) % 12 + 1;
}

/// 一次起卦的完整卦象。
class GuaResult {
  /// 六爻爻值，自下而上：索引 0 为一爻（初爻），索引 5 为六爻（上爻）。
  final List<int> yaoValues;

  /// 由爻值推出的本卦（上卦在前，即 [六爻…一爻]）。
  final DivineGua benGua;

  /// 由动爻变出的变卦。
  final DivineGua bianGua;

  /// 动爻位置，1 表示初爻，6 表示上爻。
  final List<int> movingLines;

  const GuaResult({
    required this.yaoValues,
    required this.benGua,
    required this.bianGua,
    required this.movingLines,
  });

  /// 是否六爻皆为静爻。
  bool get isStatic => movingLines.isEmpty;

  /// 提交给服务端的 `qiguaData` 字符串：[六爻, 五爻, 四爻, 三爻, 二爻, 一爻]。
  String get qiguaData =>
      yaoValues.reversed.map((v) => v.toString()).join(',');

  /// 六爻（自下而上）对应的 6 位卦码，顺序同官方：上卦在上。
  String get benCode => _codeOf(yaoValues, flipMoving: false);

  String get bianCode => _codeOf(yaoValues, flipMoving: true);

  /// 本卦上卦（外卦）名，如 "坎"。
  String get benUpperTrigram => kTrigramNames[benCode.substring(0, 3)] ?? '';

  /// 本卦下卦（内卦）名，如 "乾"。
  String get benLowerTrigram => kTrigramNames[benCode.substring(3)] ?? '';

  String get bianUpperTrigram => kTrigramNames[bianCode.substring(0, 3)] ?? '';

  String get bianLowerTrigram => kTrigramNames[bianCode.substring(3)] ?? '';

  /// 本卦的上下卦组合，如 "上坎下乾"。
  String get benTrigramText => '上$benUpperTrigram下$benLowerTrigram';

  String get bianTrigramText => '上$bianUpperTrigram下$bianLowerTrigram';

  /// 动爻爻题列表（自下而上），如 ["九三", "上六"]。
  List<String> get movingYaoTitles => movingLines
      .map((line) => yaoTitleOf(line, yaoTypeOf(yaoValues[line - 1]).isYang))
      .toList();

  /// 指定爻位的爻题（自下而上，index 0 为初爻）。
  String yaoTitleAt(int index) => yaoTitleOf(index + 1, yaoTypeOf(yaoValues[index]).isYang);
}

String _codeOf(List<int> yaoValues, {required bool flipMoving}) {
  final buffer = StringBuffer();
  for (final value in yaoValues.reversed) {
    final yao = yaoTypeOf(value);
    var yang = yao.isYang;
    if (flipMoving && yao.isMoving) yang = !yang;
    buffer.write(yang ? '1' : '0');
  }
  return buffer.toString();
}

/// 由六爻爻值（自下而上）生成卦象。
GuaResult buildGuaResult(List<int> yaoValuesBottomUp) {
  assert(yaoValuesBottomUp.length == 6, '六爻必须为 6 个爻值');
  final benCode = _codeOf(yaoValuesBottomUp, flipMoving: false);
  final bianCode = _codeOf(yaoValuesBottomUp, flipMoving: true);
  final moving = <int>[
    for (var i = 0; i < yaoValuesBottomUp.length; i++)
      if (yaoTypeOf(yaoValuesBottomUp[i]).isMoving) i + 1,
  ];
  return GuaResult(
    yaoValues: List<int>.unmodifiable(yaoValuesBottomUp),
    benGua: findGuaByCode(benCode) ?? DivineGua('', '未知卦', benCode),
    bianGua: findGuaByCode(bianCode) ?? DivineGua('', '未知卦', bianCode),
    movingLines: moving,
  );
}

/// 由上下卦（先天八卦数 1~8）与动爻（1~6）生成六爻爻值。
List<int> yaoValuesFromTrigrams({
  required int shangGua,
  required int xiaGua,
  required int movingLine,
}) {
  final xia = _trigramLines[xiaGua]!; // 一爻、二爻、三爻
  final shang = _trigramLines[shangGua]!; // 四爻、五爻、六爻
  final values = <int>[];
  for (final line in <int>[...xia, ...shang]) {
    final isMoving = values.length + 1 == movingLine;
    if (isMoving) {
      // 动爻：阳动变阴（老阳 3），阴动变阳（老阴 2）
      values.add(line == 1 ? 3 : 2);
    } else {
      values.add(line == 1 ? 1 : 0);
    }
  }
  return values;
}

/// 时间起卦。规则取自官方排盘方式页"时间起卦"面板的"起卦原理"文案：
/// 1、（年 + 月 + 日）除以 8 取余数做上卦；
/// 2、（年 + 月 + 日 + 时）除以 8 取余数做下卦；
/// 3、（年 + 月 + 日 + 时）除以 6 取余数做动爻。
GuaResult guaFromTime(DateTime time) {
  final base = time.year + time.month + time.day;
  final total = base + shiChenIndexOf(time);
  return buildGuaResult(
    yaoValuesFromTrigrams(
      shangGua: _trigramNumberOf(base),
      xiaGua: _trigramNumberOf(total),
      movingLine: _movingLineOf(total),
    ),
  );
}

/// 单数起卦（本地规则，服务端原实现不下发）：
/// 上卦 = 数字对 8 取余；下卦 = 时辰数对 8 取余；动爻 = (数字 + 时辰数) 对 6 取余。
GuaResult guaFromSingleNumber(int number, DateTime time) {
  final n = number.abs();
  final shichen = shiChenIndexOf(time);
  return buildGuaResult(
    yaoValuesFromTrigrams(
      shangGua: _trigramNumberOf(n),
      xiaGua: _trigramNumberOf(shichen),
      movingLine: _movingLineOf(n + shichen),
    ),
  );
}

/// 双数起卦：两数分别取余做上卦、下卦，两数之和取余做动爻。
GuaResult guaFromDoubleNumber(int first, int second) {
  final a = first.abs();
  final b = second.abs();
  return buildGuaResult(
    yaoValuesFromTrigrams(
      shangGua: _trigramNumberOf(a),
      xiaGua: _trigramNumberOf(b),
      movingLine: _movingLineOf(a + b),
    ),
  );
}

/// 汉字起卦（本地近似规则，服务端原实现不下发）：
/// 上卦 = 汉字个数对 8 取余；下卦 = 各字 Unicode 码点之和对 8 取余；
/// 动爻 = (汉字个数 + 码点和) 对 6 取余。
GuaResult guaFromChinese(String text) {
  final chars = text.runes.toList();
  var sum = 0;
  for (final rune in chars) {
    sum += rune;
  }
  return buildGuaResult(
    yaoValuesFromTrigrams(
      shangGua: _trigramNumberOf(chars.length),
      xiaGua: _trigramNumberOf(sum),
      movingLine: _movingLineOf(chars.length + sum),
    ),
  );
}

/// 卦名起卦：直接指定本卦与变卦卦码，由两者差异反推动爻。
GuaResult? guaFromGuaCodes(String benCode, String bianCode) {
  if (benCode.length != 6 || bianCode.length != 6) return null;
  final values = <int>[];
  for (var i = 0; i < 6; i++) {
    // 卦码顺序为 [六爻…一爻]，转换为自下而上的爻值
    final ben = benCode[5 - i];
    final bian = bianCode[5 - i];
    if (ben == bian) {
      values.add(ben == '1' ? 1 : 0);
    } else {
      // 本卦为阴、变卦为阳 → 老阴(2)；反之为老阳(3)
      values.add(ben == '0' ? 2 : 3);
    }
  }
  return buildGuaResult(values);
}
