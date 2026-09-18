/// 紫微斗数排盘引擎。
///
/// 官方 App 的紫微命盘由服务端 `yjhapp/ziWeiQiGua` 生成（模块 2430 / 2568 / 2569
/// 只做表单与命盘渲染），本工程按传统安星诀在本地实现，并逐宫与开源实现
/// iztro 比对（见 `test/ziwei_test.dart`、`test/fixtures/ziwei_reference.json`、
/// `tools/reverse/generate_ziwei_reference.mjs`）。
///
/// 规则口径：
///   * 命宫 / 身宫、十四主星、六吉六煞、四化、大限、四组十二神均以**农历**
///     （年干支按正月初一为界、月按农历月、日按农历日）为基准，与官方
///     `typeData`/`ziWeiQiGua` 链路一致；
///   * 农历换算直接复用 `lunar_calendar.dart`（官方模块 1898 的移植），
///     日柱 / 时柱复用 `ganzhi.dart`；
///   * 宫位索引：寅 = 0，卯 = 1 … 丑 = 11（官方与 iztro 同口径）。
library;

import 'ganzhi.dart';
import 'lunar_calendar.dart';

/// 星曜：名称 + 庙旺 + 生年四化（禄 / 权 / 科 / 忌）。
class ZiWeiStar {
  final String name;
  final String brightness;
  final String mutagen;

  const ZiWeiStar(this.name, {this.brightness = '', this.mutagen = ''});

  bool get isMajor => kZiWeiMajorStars.contains(name);
}

/// 单个宫位（寅 = 0 口径）。
class ZiWeiPalace {
  final int index;

  /// 宫名：命宫 / 兄弟 / 夫妻 …
  final String name;
  final String heavenlyStem;
  final String earthlyBranch;

  /// 是否为身宫。
  final bool isBodyPalace;

  final List<ZiWeiStar> majorStars;
  final List<ZiWeiStar> minorStars;

  /// 长生十二神 / 博士十二神 / 将前十二神 / 岁前十二神。
  final String changsheng12;
  final String boshi12;
  final String jiangqian12;
  final String suiqian12;

  /// 大限年龄区间 [起, 止]。
  final List<int>? decadalRange;

  const ZiWeiPalace({
    required this.index,
    required this.name,
    required this.heavenlyStem,
    required this.earthlyBranch,
    required this.isBodyPalace,
    required this.majorStars,
    required this.minorStars,
    required this.changsheng12,
    required this.boshi12,
    required this.jiangqian12,
    required this.suiqian12,
    required this.decadalRange,
  });

  List<ZiWeiStar> get allStars => <ZiWeiStar>[...majorStars, ...minorStars];

  bool get isEmpty => allStars.isEmpty;

  String get decadalText =>
      decadalRange == null ? '' : '${decadalRange![0]}-${decadalRange![1]}';
}

/// 命盘。
class ZiWeiChart {
  /// 1 男 / 0 女。
  final int gender;

  /// 公历 / 农历文本。
  final String solarText;
  final String lunarText;
  final bool isLeapMonth;

  /// 四柱（年 月 日 时）。
  final List<String> siZhuGan;
  final List<String> siZhuZhi;

  /// 五行局，例如 `水二局`。
  final String fiveElementsClass;
  final int fiveElementsValue;

  /// 命主 / 身主。
  final String soul;
  final String body;

  /// 命宫 / 身宫索引（寅 = 0）。
  final int soulIndex;
  final int bodyIndex;

  /// 时辰名（早子时 / 丑时 … 晚子时）。
  final String timeName;

  /// 是否使用了真太阳时修正。
  final bool usedTrueSolarTime;

  /// 12 宫，按 寅 → 丑 排列。
  final List<ZiWeiPalace> palaces;

  const ZiWeiChart({
    required this.gender,
    required this.solarText,
    required this.lunarText,
    required this.isLeapMonth,
    required this.siZhuGan,
    required this.siZhuZhi,
    required this.fiveElementsClass,
    required this.fiveElementsValue,
    required this.soul,
    required this.body,
    required this.soulIndex,
    required this.bodyIndex,
    required this.timeName,
    required this.usedTrueSolarTime,
    required this.palaces,
  });

  String get siZhuText =>
      List<String>.generate(4, (i) => '${siZhuGan[i]}${siZhuZhi[i]}').join(' ');

  String get yinYangText => gender == 1 ? '阳男' : '阴女';

  ZiWeiPalace? palaceByName(String name) {
    for (final palace in palaces) {
      if (palace.name == name) return palace;
    }
    return null;
  }
}

/// 十四主星。
const List<String> kZiWeiMajorStars = <String>[
  '紫微', '天机', '太阳', '武曲', '天同', '廉贞',
  '天府', '太阴', '贪狼', '巨门', '天相', '天梁', '七杀', '破军',
];

/// 十二宫名（自命宫起逆行）。
const List<String> kZiWeiPalaceNames = <String>[
  '命宫', '父母', '福德', '田宅', '官禄', '交友',
  '迁移', '疾厄', '财帛', '子女', '夫妻', '兄弟',
];

/// 星曜亮度（寅 = 0 起，空串表示不显示）。
const Map<String, List<String>> kZiWeiBrightness = <String, List<String>>{
  '紫微': <String>['旺', '旺', '得', '旺', '庙', '庙', '旺', '旺', '得', '旺', '平', '庙'],
  '天机': <String>['得', '旺', '利', '平', '庙', '陷', '得', '旺', '利', '平', '庙', '陷'],
  '太阳': <String>['旺', '庙', '旺', '旺', '旺', '得', '得', '平', '不', '陷', '陷', '不'],
  '武曲': <String>['得', '利', '庙', '平', '旺', '庙', '得', '利', '庙', '平', '旺', '庙'],
  '天同': <String>['利', '平', '平', '庙', '陷', '不', '旺', '平', '平', '庙', '旺', '不'],
  '廉贞': <String>['庙', '平', '利', '陷', '平', '利', '庙', '平', '利', '陷', '平', '利'],
  '天府': <String>['庙', '得', '庙', '得', '旺', '庙', '得', '旺', '庙', '得', '庙', '庙'],
  '太阴': <String>['旺', '陷', '陷', '陷', '不', '不', '利', '旺', '旺', '庙', '庙', '庙'],
  '贪狼': <String>['平', '利', '庙', '陷', '旺', '庙', '平', '利', '庙', '陷', '旺', '庙'],
  '巨门': <String>['庙', '庙', '陷', '旺', '旺', '不', '庙', '庙', '陷', '旺', '旺', '不'],
  '天相': <String>['庙', '陷', '得', '得', '庙', '得', '庙', '陷', '得', '得', '庙', '庙'],
  '天梁': <String>['庙', '庙', '庙', '陷', '庙', '旺', '陷', '得', '庙', '陷', '庙', '旺'],
  '七杀': <String>['庙', '旺', '庙', '平', '旺', '庙', '庙', '旺', '庙', '平', '旺', '庙'],
  '破军': <String>['得', '陷', '旺', '平', '庙', '旺', '得', '陷', '旺', '平', '庙', '旺'],
  '文昌': <String>['陷', '利', '得', '庙', '陷', '利', '得', '庙', '陷', '利', '得', '庙'],
  '文曲': <String>['平', '旺', '得', '庙', '陷', '旺', '得', '庙', '陷', '旺', '得', '庙'],
  '擎羊': <String>['', '陷', '庙', '', '陷', '庙', '', '陷', '庙', '', '陷', '庙'],
  '陀罗': <String>['陷', '', '庙', '陷', '', '庙', '陷', '', '庙', '陷', '', '庙'],
  '火星': <String>['庙', '利', '陷', '得', '庙', '利', '陷', '得', '庙', '利', '陷', '得'],
  '铃星': <String>['庙', '利', '陷', '得', '庙', '利', '陷', '得', '庙', '利', '陷', '得'],
};

/// 十天干四化：顺序为 禄 / 权 / 科 / 忌。
const Map<String, List<String>> kZiWeiMutagenTable = <String, List<String>>{
  '甲': <String>['廉贞', '破军', '武曲', '太阳'],
  '乙': <String>['天机', '天梁', '紫微', '太阴'],
  '丙': <String>['天同', '天机', '文昌', '廉贞'],
  '丁': <String>['太阴', '天同', '天机', '巨门'],
  '戊': <String>['贪狼', '太阴', '右弼', '天机'],
  '己': <String>['武曲', '贪狼', '天梁', '文曲'],
  '庚': <String>['太阳', '武曲', '太阴', '天同'],
  '辛': <String>['巨门', '太阳', '文曲', '文昌'],
  '壬': <String>['天梁', '紫微', '左辅', '武曲'],
  '癸': <String>['破军', '巨门', '太阴', '贪狼'],
};

const List<String> _mutagenNames = <String>['禄', '权', '科', '忌'];

/// 命主（按命宫地支，子 = 0）。
const List<String> _soulTable = <String>[
  '贪狼', '巨门', '禄存', '文曲', '廉贞', '武曲',
  '破军', '武曲', '廉贞', '文曲', '禄存', '巨门',
];

/// 身主（按年支，子 = 0）。
const List<String> _bodyTable = <String>[
  '火星', '天相', '天梁', '天同', '文昌', '天机',
  '火星', '天相', '天梁', '天同', '文昌', '天机',
];

/// 地支阴阳（子 = 0）。
const List<String> _zhiYinYang = <String>[
  '阳', '阴', '阳', '阴', '阳', '阴', '阳', '阴', '阳', '阴', '阳', '阴',
];

const List<String> kZiWeiChineseTime = <String>[
  '早子时', '丑时', '寅时', '卯时', '辰时', '巳时',
  '午时', '未时', '申时', '酉时', '戌时', '亥时', '晚子时',
];

const List<String> _changsheng12Names = <String>[
  '长生', '沐浴', '冠带', '临官', '帝旺', '衰', '病', '死', '墓', '绝', '胎', '养',
];

const List<String> _boshi12Names = <String>[
  '博士', '力士', '青龙', '小耗', '将军', '奏书', '飞廉', '喜神', '病符', '大耗', '伏兵', '官府',
];

const List<String> _jiangqian12Names = <String>[
  '将星', '攀鞍', '岁驿', '息神', '华盖', '劫煞', '灾煞', '天煞', '指背', '咸池', '月煞', '亡神',
];

const List<String> _suiqian12Names = <String>[
  '岁建', '晦气', '丧门', '贯索', '官符', '小耗', '大耗', '龙德', '白虎', '天德', '吊客', '病符',
];

/// 五行局名（按局数）。
const Map<int, String> kFiveElementsClassName = <int, String>{
  2: '水二局',
  3: '木三局',
  4: '金四局',
  5: '土五局',
  6: '火六局',
};

int _fix(int index, [int max = 12]) {
  var value = index;
  while (value < 0) {
    value += max;
  }
  while (value > max - 1) {
    value -= max;
  }
  return value;
}

/// 小时 → 时辰序号（0 早子时 … 12 晚子时）。
int ziWeiTimeIndex(int hour) {
  if (hour == 0) return 0;
  if (hour == 23) return 12;
  return (hour + 1) ~/ 2;
}

/// 排盘参数。
class ZiWeiInput {
  /// 用户输入的出生日期时间；`isLunar` 为 true 时取年月日为农历。
  final DateTime dateTime;

  /// true 阴历 / false 阳历。
  final bool isLunar;

  /// 1 男 / 0 女。
  final int gender;

  /// 是否修正闰月（闰月前 15 天按本月、后 15 天按下月）。
  final bool fixLeap;

  /// 真太阳时修正（分钟，正数为提前）。
  final int trueSolarMinutes;

  const ZiWeiInput({
    required this.dateTime,
    required this.isLunar,
    required this.gender,
    this.fixLeap = true,
    this.trueSolarMinutes = 0,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'dateTime': dateTime.toIso8601String(),
        'isLunar': isLunar,
        'gender': gender,
        'fixLeap': fixLeap,
        'trueSolarMinutes': trueSolarMinutes,
      };

  factory ZiWeiInput.fromJson(Map<String, dynamic> json) => ZiWeiInput(
        dateTime: DateTime.tryParse(json['dateTime'] as String? ?? '') ??
            DateTime.now(),
        isLunar: json['isLunar'] as bool? ?? false,
        gender: json['gender'] as int? ?? 1,
        fixLeap: json['fixLeap'] as bool? ?? true,
        trueSolarMinutes: json['trueSolarMinutes'] as int? ?? 0,
      );
}

/// 排盘；输入超出农历历表（1900–2100）等情形返回 null。
ZiWeiChart? buildZiWeiChart(ZiWeiInput input) {
  final entered = input.dateTime;
  DateTime? solar;
  if (input.isLunar) {
    solar = lunar2Solar(entered.year, entered.month, entered.day);
    if (solar == null) return null;
  } else {
    solar = DateTime(entered.year, entered.month, entered.day);
  }
  solar = DateTime(solar.year, solar.month, solar.day, entered.hour, entered.minute);

  if (input.trueSolarMinutes != 0) {
    solar = solar.add(Duration(minutes: input.trueSolarMinutes));
  }

  final lunar = solar2Lunar(solar.year, solar.month, solar.day);
  if (lunar == null) return null;

  final timeIndex = ziWeiTimeIndex(solar.hour);
  final isLateRat = timeIndex == 12;

  // 晚子时按次日安星，与官方/iztro 一致
  final daySolar = isLateRat ? solar.add(const Duration(days: 1)) : solar;
  final dayLunar = solar2Lunar(daySolar.year, daySolar.month, daySolar.day);
  if (dayLunar == null) return null;

  // 年干支取农历年（正月初一为界）
  final yearGanZhi = lunar.ganZhiYear;
  final yearGan = yearGanZhi[0];
  final yearZhi = yearGanZhi[1];
  final yearBranchIndex = kDiZhi.indexOf(yearZhi);

  // 命身宫的农历月（闰月后半月按下月；晚子时不调整）
  var monthIndex = lunar.month - 1;
  if (lunar.isLeap && input.fixLeap && lunar.day > 15 && !isLateRat) {
    monthIndex += 1;
  }
  monthIndex = _fix(monthIndex);

  final timeBranchIndex = timeIndex % 12;
  final soulIndex = _fix(monthIndex - timeBranchIndex);
  final bodyIndex = _fix(monthIndex + timeBranchIndex);

  // 命宫干支（五虎遁起寅宫）
  final soulGanZhi = monthGanZhi(soulIndex + 1, GanZhi(yearGan, '寅'));
  final soulStem = soulGanZhi.gan;
  final soulBranch = soulGanZhi.zhi;

  // 五行局：纳音五行 → 局数
  final fiveElementsValue = _fiveElementsValueOf(soulStem, soulBranch);
  final fiveElementsClass = kFiveElementsClassName[fiveElementsValue]!;

  // 紫微 / 天府
  final ziweiIndex = ziweiIndexOf(dayLunar.day, fiveElementsValue);
  final tianfuIndex = _fix(-ziweiIndex);

  // 日柱（晚子时按次日）
  final dayGanZhiValue = dayGanZhi(daySolar);
  final hourGanZhiValue = hourGanZhi(solar, dayGanZhiValue);

  // 月柱：出生当日农历月配五虎遁，闰月后半月按下月
  var pillarMonthIndex = lunar.month - 1;
  if (lunar.isLeap && input.fixLeap && lunar.day > 15) {
    pillarMonthIndex += 1;
  }
  final monthGanZhiValue =
      monthGanZhi(_fix(pillarMonthIndex) + 1, GanZhi(yearGan, '寅'));

  // 安星
  final starMap = <int, List<ZiWeiStar>>{
    for (var i = 0; i < 12; i++) i: <ZiWeiStar>[],
  };
  final mutagens = kZiWeiMutagenTable[yearGan]!;

  void addStar(int index, String name) {
    if (name.isEmpty) return;
    final fixed = _fix(index);
    final mutagenIndex = mutagens.indexOf(name);
    starMap[fixed]!.add(
      ZiWeiStar(
        name,
        brightness: kZiWeiBrightness[name]?[fixed] ?? '',
        mutagen: mutagenIndex >= 0 ? _mutagenNames[mutagenIndex] : '',
      ),
    );
  }

  // 紫微系（逆布）
  addStar(ziweiIndex, '紫微');
  addStar(ziweiIndex - 1, '天机');
  addStar(ziweiIndex - 3, '太阳');
  addStar(ziweiIndex - 4, '武曲');
  addStar(ziweiIndex - 5, '天同');
  addStar(ziweiIndex - 8, '廉贞');
  // 天府系（顺布）
  addStar(tianfuIndex, '天府');
  addStar(tianfuIndex + 1, '太阴');
  addStar(tianfuIndex + 2, '贪狼');
  addStar(tianfuIndex + 3, '巨门');
  addStar(tianfuIndex + 4, '天相');
  addStar(tianfuIndex + 5, '天梁');
  addStar(tianfuIndex + 6, '七杀');
  addStar(tianfuIndex + 10, '破军');

  // 六吉六煞与禄马
  final fixedTime = _fix(timeIndex);
  addStar(2 + monthIndex, '左辅'); // 辰起正月顺行
  addStar(8 - monthIndex, '右弼'); // 戌起正月逆行
  addStar(2 + fixedTime, '文曲'); // 辰起子时顺行
  addStar(8 - fixedTime, '文昌'); // 戌起子时逆行
  addStar(9 - fixedTime, '地空'); // 亥起子时逆行
  addStar(9 + fixedTime, '地劫'); // 亥起子时顺行

  final luIndex = _luCunIndex(yearGan);
  addStar(luIndex, '禄存');
  addStar(luIndex + 1, '擎羊');
  addStar(luIndex - 1, '陀罗');
  addStar(_tianMaIndex(yearZhi), '天马');

  final kuiYue = _kuiYueIndex(yearGan);
  addStar(kuiYue[0], '天魁');
  addStar(kuiYue[1], '天钺');

  final huoLing = _huoLingIndex(yearZhi, fixedTime);
  addStar(huoLing[0], '火星');
  addStar(huoLing[1], '铃星');

  final changsheng = _changsheng12(soulStem, soulBranch, yearZhi, input.gender);
  final boshi = _boshi12(yearZhi, yearGan, input.gender);
  final jiangqian = _jiangqian12(yearZhi);
  final suiqian = _suiqian12(yearZhi);
  final decadals = _decadals(
    soulIndex: soulIndex,
    fiveElementsValue: fiveElementsValue,
    yearZhi: yearZhi,
    gender: input.gender,
  );

  final palaces = <ZiWeiPalace>[
    for (var i = 0; i < 12; i++)
      ZiWeiPalace(
        index: i,
        name: kZiWeiPalaceNames[_fix(i - soulIndex)],
        heavenlyStem: monthGanZhi(i + 1, GanZhi(yearGan, '寅')).gan,
        earthlyBranch: kDiZhi[_fix(i + 2)],
        isBodyPalace: bodyIndex == i,
        majorStars: starMap[i]!.where((s) => s.isMajor).toList(),
        minorStars: starMap[i]!.where((s) => !s.isMajor).toList(),
        changsheng12: changsheng[i],
        boshi12: boshi[i],
        jiangqian12: jiangqian[i],
        suiqian12: suiqian[i],
        decadalRange: decadals[i],
      ),
  ];

  return ZiWeiChart(
    gender: input.gender,
    solarText: _formatDateTime(solar),
    lunarText: '${_chinaYear(lunar.year)}${lunar.monthCn}${lunar.dayCn}',
    isLeapMonth: lunar.isLeap,
    siZhuGan: <String>[yearGan, monthGanZhiValue.gan, dayGanZhiValue.gan, hourGanZhiValue.gan],
    siZhuZhi: <String>[yearZhi, monthGanZhiValue.zhi, dayGanZhiValue.zhi, hourGanZhiValue.zhi],
    fiveElementsClass: fiveElementsClass,
    fiveElementsValue: fiveElementsValue,
    soul: _soulTable[_fix(soulIndex + 2)],
    body: _bodyTable[yearBranchIndex],
    soulIndex: soulIndex,
    bodyIndex: bodyIndex,
    timeName: kZiWeiChineseTime[timeIndex],
    usedTrueSolarTime: input.trueSolarMinutes != 0,
    palaces: palaces,
  );
}

String _formatDateTime(DateTime dt) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
}

/// 年 → 汉字写法，如 `二〇〇〇年`。
String _chinaYear(int year) {
  const digits = <String>['〇', '一', '二', '三', '四', '五', '六', '七', '八', '九'];
  final buffer = StringBuffer();
  for (final ch in year.toString().split('')) {
    buffer.write(digits[int.parse(ch)]);
  }
  return '$buffer年';
}

/// 五行局取数（纳音取数口诀）：
/// 甲乙丙丁一到五、子丑午未一，寅卯申酉二，辰巳戌亥三；
/// 干支相加，超过五者减五，木一 金二 水三 火四 土五 → 木三局 / 金四局 /
/// 水二局 / 火六局 / 土五局。
int _fiveElementsValueOf(String stem, String branch) {
  final stemNumber = kTianGan.indexOf(stem) ~/ 2 + 1;
  final branchNumber = _fix(kDiZhi.indexOf(branch), 6) ~/ 2 + 1;
  var index = stemNumber + branchNumber;
  while (index > 5) {
    index -= 5;
  }
  const table = <int>[3, 4, 2, 6, 5];
  return table[index - 1];
}

/// 起紫微星诀：局数除日数，商数宫前走；若见数无余，便要起虎口。
///
/// 返回紫微星所在宫位索引（寅 = 0）。口诀：从寅宫起顺数至商数，
/// 余数为偶则顺行余数、为奇则逆行余数。
int ziweiIndexOf(int day, int fiveElementsValue) {
  var offset = -1;
  var quotient = 0;
  var remainder = -1;
  do {
    offset++;
    final divisor = day + offset;
    quotient = divisor ~/ fiveElementsValue;
    remainder = divisor % fiveElementsValue;
  } while (remainder != 0);

  quotient %= 12;
  var ziweiIndex = quotient - 1;
  if (offset % 2 == 0) {
    ziweiIndex += offset;
  } else {
    ziweiIndex -= offset;
  }
  return _fix(ziweiIndex);
}

/// 禄存（按年干）。
int _luCunIndex(String yearGan) {
  const table = <int>[0, 1, 3, 4, 3, 4, 6, 7, 9, 10];
  return table[kTianGan.indexOf(yearGan)];
}

/// 天马（按年支三合）。
int _tianMaIndex(String yearZhi) {
  const yinWuXu = <String>['寅', '午', '戌'];
  const shenZiChen = <String>['申', '子', '辰'];
  const siYouChou = <String>['巳', '酉', '丑'];
  if (yinWuXu.contains(yearZhi)) return 6; // 申
  if (shenZiChen.contains(yearZhi)) return 0; // 寅
  if (siYouChou.contains(yearZhi)) return 9; // 亥
  return 3; // 巳（亥卯未）
}

/// 天魁 / 天钺（按年干）。
List<int> _kuiYueIndex(String yearGan) {
  switch (yearGan) {
    case '甲':
    case '戊':
    case '庚':
      return <int>[11, 5]; // 丑 / 未
    case '乙':
    case '己':
      return <int>[10, 6]; // 子 / 申
    case '辛':
      return <int>[4, 0]; // 午 / 寅
    case '丙':
    case '丁':
      return <int>[9, 7]; // 亥 / 酉
    default:
      return <int>[1, 3]; // 卯 / 巳（壬癸）
  }
}

/// 火星 / 铃星：按年支定子时起位，再顺数至生时。
List<int> _huoLingIndex(String yearZhi, int fixedTimeIndex) {
  const yinWuXu = <String>['寅', '午', '戌'];
  const shenZiChen = <String>['申', '子', '辰'];
  const siYouChou = <String>['巳', '酉', '丑'];
  int huoStart;
  int lingStart;
  if (yinWuXu.contains(yearZhi)) {
    huoStart = 11; // 丑
    lingStart = 1; // 卯
  } else if (shenZiChen.contains(yearZhi)) {
    huoStart = 0; // 寅
    lingStart = 8; // 戌
  } else if (siYouChou.contains(yearZhi)) {
    huoStart = 1; // 卯
    lingStart = 8; // 戌
  } else {
    huoStart = 7; // 酉
    lingStart = 8; // 戌
  }
  return <int>[_fix(huoStart + fixedTimeIndex), _fix(lingStart + fixedTimeIndex)];
}

List<String> _changsheng12(
  String soulStem,
  String soulBranch,
  String yearZhi,
  int gender,
) {
  final value = _fiveElementsValueOf(soulStem, soulBranch);
  final startIndex = switch (value) {
    2 => 6, // 水二局长生在申
    3 => 9, // 木三局长生在亥
    4 => 3, // 金四局长生在巳
    5 => 6, // 土五局长生在申
    _ => 0, // 火六局长生在寅
  };
  final forward = _isForward(yearZhi, gender);
  final result = List<String>.filled(12, '');
  for (var i = 0; i < 12; i++) {
    result[_fix(forward ? startIndex + i : startIndex - i)] = _changsheng12Names[i];
  }
  return result;
}

List<String> _boshi12(String yearZhi, String yearGan, int gender) {
  final luIndex = _luCunIndex(yearGan);
  final forward = _isForward(yearZhi, gender);
  final result = List<String>.filled(12, '');
  for (var i = 0; i < 12; i++) {
    result[_fix(forward ? luIndex + i : luIndex - i)] = _boshi12Names[i];
  }
  return result;
}

List<String> _jiangqian12(String yearZhi) {
  const yinWuXu = <String>['寅', '午', '戌'];
  const shenZiChen = <String>['申', '子', '辰'];
  const siYouChou = <String>['巳', '酉', '丑'];
  int start;
  if (yinWuXu.contains(yearZhi)) {
    start = 4; // 午
  } else if (shenZiChen.contains(yearZhi)) {
    start = 10; // 子
  } else if (siYouChou.contains(yearZhi)) {
    start = 7; // 酉
  } else {
    start = 1; // 卯
  }
  final result = List<String>.filled(12, '');
  for (var i = 0; i < 12; i++) {
    result[_fix(start + i)] = _jiangqian12Names[i];
  }
  return result;
}

List<String> _suiqian12(String yearZhi) {
  final start = _fix(kDiZhi.indexOf(yearZhi) - 2);
  final result = List<String>.filled(12, '');
  for (var i = 0; i < 12; i++) {
    result[_fix(start + i)] = _suiqian12Names[i];
  }
  return result;
}

/// 阳男阴女顺行，阴男阳女逆行。
bool _isForward(String yearZhi, int gender) {
  final branchYinYang = _zhiYinYang[kDiZhi.indexOf(yearZhi)];
  final genderYinYang = gender == 1 ? '阳' : '阴';
  return genderYinYang == branchYinYang;
}

List<List<int>?> _decadals({
  required int soulIndex,
  required int fiveElementsValue,
  required String yearZhi,
  required int gender,
}) {
  final forward = _isForward(yearZhi, gender);
  final result = List<List<int>?>.filled(12, null);
  for (var i = 0; i < 12; i++) {
    final index = _fix(forward ? soulIndex + i : soulIndex - i);
    final start = fiveElementsValue + 10 * i;
    result[index] = <int>[start, start + 9];
  }
  return result;
}
