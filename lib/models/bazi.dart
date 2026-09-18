/// 八字（四柱）排盘：十神、藏干、纳音、长生十二神、五行统计与大运流年。
///
/// 表格与算法 1:1 移植自官方 RN bundle 模块 2472（十神 / 纳音 / 藏干 / 长生十二神），
/// 四柱本身沿用 [computeSiZhu]（官方模块 2111 + 2112 精确节气），因此结果与官方一致。
library;

import 'ganzhi.dart';
import 'jieqi.dart';
import 'lunar_calendar.dart';

/// 天干属性（官方 `tianGan`）。
class BaZiGan {
  final String name;
  final String wuXing;

  /// 官方编号：甲 1 … 癸 10。
  final int num;
  final bool yang;

  /// 长生起点地支（官方 `changshen`）。
  final String changSheng;

  const BaZiGan(this.name, this.wuXing, this.num, this.yang, this.changSheng);
}

/// 地支属性（官方 `diZhi`）。
class BaZiZhi {
  final String name;
  final String wuXing;

  /// 官方编号：子 1 … 亥 12。
  final int num;
  final bool yang;

  const BaZiZhi(this.name, this.wuXing, this.num, this.yang);
}

/// 地支藏干（官方 `dizhiCangGan` 的 `{gan, days}`）。
class CangGan {
  final String gan;

  /// 官方权重（本气 30 / 中气 / 余气）。
  final int days;

  const CangGan(this.gan, this.days);
}

const Map<String, BaZiGan> kBaziTianGan = <String, BaZiGan>{
  '甲': BaZiGan('甲', '木', 1, true, '亥'),
  '乙': BaZiGan('乙', '木', 2, false, '午'),
  '丙': BaZiGan('丙', '火', 3, true, '寅'),
  '丁': BaZiGan('丁', '火', 4, false, '酉'),
  '戊': BaZiGan('戊', '土', 5, true, '寅'),
  '己': BaZiGan('己', '土', 6, false, '酉'),
  '庚': BaZiGan('庚', '金', 7, true, '巳'),
  '辛': BaZiGan('辛', '金', 8, false, '子'),
  '壬': BaZiGan('壬', '水', 9, true, '申'),
  '癸': BaZiGan('癸', '水', 10, false, '卯'),
};

const Map<String, BaZiZhi> kBaziDiZhi = <String, BaZiZhi>{
  '子': BaZiZhi('子', '水', 1, true),
  '丑': BaZiZhi('丑', '土', 2, false),
  '寅': BaZiZhi('寅', '木', 3, true),
  '卯': BaZiZhi('卯', '木', 4, false),
  '辰': BaZiZhi('辰', '土', 5, true),
  '巳': BaZiZhi('巳', '火', 6, false),
  '午': BaZiZhi('午', '火', 7, true),
  '未': BaZiZhi('未', '土', 8, false),
  '申': BaZiZhi('申', '金', 9, true),
  '酉': BaZiZhi('酉', '金', 10, false),
  '戌': BaZiZhi('戌', '土', 11, true),
  '亥': BaZiZhi('亥', '水', 12, false),
};

/// 十神映射（官方 `shishen_s`）：键为「五行关系 + 阴阳是否相同」。
const Map<String, String> kShiShenMap = <String, String>{
  '1true': '正印',
  '0true': '劫财',
  '-1true': '伤官',
  '-2true': '正财',
  '-3true': '正官',
  '1false': '偏印',
  '0false': '比肩',
  '-1false': '食神',
  '-2false': '偏财',
  '-3false': '七杀',
};

/// 六十甲子纳音（官方 `nayin`）。
const Map<String, String> kNayin = <String, String>{
  '甲子': '海中金', '乙丑': '海中金', '丙寅': '炉中火', '丁卯': '炉中火',
  '戊辰': '大林木', '己巳': '大林木', '庚午': '路旁土', '辛未': '路旁土',
  '壬申': '剑锋金', '癸酉': '剑锋金', '甲戌': '山头火', '乙亥': '山头火',
  '丙子': '涧下水', '丁丑': '涧下水', '戊寅': '城头土', '己卯': '城头土',
  '庚辰': '白蜡金', '辛巳': '白蜡金', '壬午': '杨柳木', '癸未': '杨柳木',
  '甲申': '泉中水', '乙酉': '泉中水', '丙戌': '屋上土', '丁亥': '屋上土',
  '戊子': '霹雳火', '己丑': '霹雳火', '庚寅': '松柏木', '辛卯': '松柏木',
  '壬辰': '长流水', '癸巳': '长流水', '甲午': '沙中金', '乙未': '沙中金',
  '丙申': '山下火', '丁酉': '山下火', '戊戌': '平地木', '己亥': '平地木',
  '庚子': '壁上土', '辛丑': '壁上土', '壬寅': '金箔金', '癸卯': '金箔金',
  '甲辰': '佛灯火', '乙巳': '佛灯火', '丙午': '天河水', '丁未': '天河水',
  '戊申': '大驿土', '己酉': '大驿土', '庚戌': '钗钏金', '辛亥': '钗钏金',
  '壬子': '桑柘木', '癸丑': '桑柘木', '甲寅': '大溪水', '乙卯': '大溪水',
  '丙辰': '沙中土', '丁巳': '沙中土', '戊午': '天上火', '己未': '天上火',
  '庚申': '石榴木', '辛酉': '石榴木', '壬戌': '大海水', '癸亥': '大海水',
};

/// 长生十二神（官方 `status12`）。
const List<String> kChangSheng12 = <String>[
  '长生', '沐浴', '冠带', '临官', '帝旺', '衰', '病', '死', '墓', '绝', '胎', '养',
];

/// 地支藏干（官方 `dizhiCangGan`）。
const Map<String, List<CangGan>> kDiZhiCangGan = <String, List<CangGan>>{
  '子': <CangGan>[CangGan('癸', 30)],
  '丑': <CangGan>[CangGan('己', 18), CangGan('癸', 9), CangGan('辛', 3)],
  '寅': <CangGan>[CangGan('甲', 16), CangGan('丙', 7), CangGan('戊', 7)],
  '卯': <CangGan>[CangGan('乙', 30)],
  '辰': <CangGan>[CangGan('戊', 18), CangGan('乙', 9), CangGan('癸', 3)],
  '巳': <CangGan>[CangGan('丙', 16), CangGan('庚', 9), CangGan('戊', 5)],
  '午': <CangGan>[CangGan('丁', 21), CangGan('己', 9)],
  '未': <CangGan>[CangGan('己', 18), CangGan('丁', 9), CangGan('乙', 3)],
  '申': <CangGan>[CangGan('庚', 17), CangGan('壬', 3), CangGan('戊', 10)],
  '酉': <CangGan>[CangGan('辛', 30)],
  '戌': <CangGan>[CangGan('戊', 18), CangGan('辛', 9), CangGan('丁', 3)],
  '亥': <CangGan>[CangGan('壬', 20), CangGan('甲', 10)],
};

/// 五行编号（官方 `getWuxingId`）：水 1 → 木 2 → 火 3 → 土 4 → 金 5（相生顺序）。
int wuXingIdOf(String wuXing) {
  switch (wuXing) {
    case '水':
      return 1;
    case '木':
      return 2;
    case '火':
      return 3;
    case '土':
      return 4;
    case '金':
      return 5;
    default:
      return 0;
  }
}

/// 官方 `getRelationOfWuxing`：从 [from] 到 [to] 的五行关系（0 同类，负数为被克/泄）。
int relationOfWuXing(String from, String to) {
  final start = wuXingIdOf(from);
  final target = wuXingIdOf(to);
  var steps = 0;
  var current = start;
  while (current < 6 && current != target) {
    steps += 1;
    if (current == 5) current = 0;
    current += 1;
  }
  if (steps > 1) steps -= 5;
  return steps;
}

/// 官方 `getShiShen(gan, dayGan)`：以日干为「我」判断十神。
String shiShenOf(String gan, String dayGan) {
  final other = kBaziTianGan[gan];
  final self = kBaziTianGan[dayGan];
  if (other == null || self == null) return '';
  final relation = relationOfWuXing(other.wuXing, self.wuXing);
  // 官方 `c = h.yingyang !== y.yingyang`：键的后缀表示「阴阳是否不同」
  final differentYinYang = self.yang != other.yang;
  return kShiShenMap['$relation$differentYinYang'] ?? '';
}

/// 官方 `getZhiShiShen(zhi, dayGan)`：地支按本气五行判断十神。
String zhiShiShenOf(String zhi, String dayGan) {
  final other = kBaziDiZhi[zhi];
  final self = kBaziTianGan[dayGan];
  if (other == null || self == null) return '';
  final relation = relationOfWuXing(other.wuXing, self.wuXing);
  final differentYinYang = self.yang != other.yang;
  return kShiShenMap['$relation$differentYinYang'] ?? '';
}

/// 官方 `getNayin(gan, zhi)`。
String nayinOf(String gan, String zhi) => kNayin['$gan$zhi'] ?? '';

/// 官方 `getChangShen12(gan, zhi)`：长生十二神。
String changSheng12Of(String gan, String zhi) {
  final ganInfo = kBaziTianGan[gan];
  final zhiInfo = kBaziDiZhi[zhi];
  if (ganInfo == null || zhiInfo == null) return '';
  final start = kBaziDiZhi[ganInfo.changSheng]!.num;
  final current = zhiInfo.num;
  var offset = ganInfo.yang
      ? (current >= start ? current - start : 12 - start + current)
      : (current >= start ? -12 - start + current : -(current - start));
  if (offset < 0) offset = -offset;
  if (offset == 12) offset = 0;
  return kChangSheng12[offset % 12];
}

/// 五行对应的官方配色（模块 2472 `getColorByWx`）。
int wuXingColorValue(String wuXing) {
  switch (wuXing) {
    case '金':
      return 0xFFEA873A;
    case '木':
      return 0xFF439B31;
    case '水':
      return 0xFF3A80EA;
    case '火':
      return 0xFFE12F26;
    case '土':
      return 0xFF905322;
    default:
      return 0xFF333333;
  }
}

/// 一柱（年/月/日/时）的排盘结果。
class BaZiPillar {
  /// 柱名：年柱 / 月柱 / 日柱 / 时柱。
  final String name;
  final GanZhi ganZhi;

  /// 天干十神（日柱为「日主」）。
  final String shiShen;

  /// 地支十神（本气）。
  final String zhiShiShen;
  final String nayin;
  final String changSheng;

  /// 藏干及其十神。
  final List<({String gan, String shiShen, int days})> cangGan;

  const BaZiPillar({
    required this.name,
    required this.ganZhi,
    required this.shiShen,
    required this.zhiShiShen,
    required this.nayin,
    required this.changSheng,
    required this.cangGan,
  });

  String get gan => ganZhi.gan;
  String get zhi => ganZhi.zhi;
  String get text => ganZhi.text;

  /// 藏干展示文本，如「丁己」。
  String get cangGanText => cangGan.map((item) => item.gan).join();
}

/// 一步大运。
class DaYunStep {
  final int index;
  final int startAge;
  final int endAge;
  final GanZhi ganZhi;

  const DaYunStep({
    required this.index,
    required this.startAge,
    required this.endAge,
    required this.ganZhi,
  });

  String get ageText => '$startAge-$endAge岁';
}

/// 胎元 / 命宫。
class TaiYuanMingGong {
  /// 胎元：月柱天干进一位、地支进三位。
  final String taiYuan;

  /// 命宫：以月支、时支定宫支，再按年干起五虎遁定宫干。
  final String mingGong;

  const TaiYuanMingGong({required this.taiYuan, required this.mingGong});
}

/// 起运与交运详细信息。
class QiYunDetail {
  final int years;
  final int months;
  final int days;
  final int hours;
  final DateTime jiaoYunDate;

  const QiYunDetail({
    required this.years,
    required this.months,
    required this.days,
    required this.hours,
    required this.jiaoYunDate,
  });

  /// 例如 `命主出生 3 年 9 个月 26 天 11 小时后开始起运`
  String get text => '命主出生 $years 年 $months 个月 $days 天 $hours 小时后开始起运';

  /// 例如 `命主于公历 2030 年 08 月 22 日交运`
  String get jiaoYunText {
    String two(int v) => v.toString().padLeft(2, '0');
    return '命主于公历 ${jiaoYunDate.year} 年 ${two(jiaoYunDate.month)} 月 ${two(jiaoYunDate.day)} 日交运';
  }
}

/// 官方 `getInitDaYunIndex()`：定位"当前所处大运"。
///
/// 官方模块 2489（专业命盘）：
/// ```js
/// var t = parseInt(this.props.guaxiang.jiaoyunYear[0], 10); // 第一步大运交运年份
/// var n = new Date().getFullYear();
/// return n >= t && n < t + 100 ? parseInt(String((n - t) / 10), 10) : 0;
/// ```
/// 即：以**起运年份**为基准，每 10 年一步；未起运或超出十步大运时回到第 0 步。
int initialDaYunIndex({
  required int firstDaYunYear,
  required int currentYear,
}) {
  if (currentYear >= firstDaYunYear && currentYear < firstDaYunYear + 100) {
    return (currentYear - firstDaYunYear) ~/ 10;
  }
  return 0;
}

/// 官方 `getInitLiuNianIndex()`：在当前大运的十年内定位"当前流年"。
///
/// 官方模块 2489：
/// ```js
/// var t = parseInt(this.props.guaxiang.jiaoyunYear[this.getInitDaYunIndex()], 10);
/// var n = new Date().getFullYear();
/// return n >= t && n < t + 10 ? n - t : 0;
/// ```
int initialLiuNianIndex({
  required int firstDaYunYear,
  required int currentYear,
  required int daYunIndex,
}) {
  final startYear = firstDaYunYear + daYunIndex * 10;
  if (currentYear >= startYear && currentYear < startYear + 10) {
    return currentYear - startYear;
  }
  return 0;
}

/// 五行力量（官方由服务端给出，本地按藏干权重估算）。
class WuXingPower {
  /// 五行 → 百分比（0~100，合计约 100）。
  final Map<String, double> percent;

  /// 日主同类力量占比（比劫 + 印）。
  final double supportPercent;

  /// 日主衰旺：身强 / 身弱。
  final String strength;

  /// 后天喜用五行。
  final List<String> favorable;

  const WuXingPower({
    required this.percent,
    required this.supportPercent,
    required this.strength,
    required this.favorable,
  });
}

/// 八字排盘结果。
class BaZiPan {
  /// 出生时间（公历）。
  final DateTime birthTime;
  final SiZhu siZhu;
  final List<BaZiPillar> pillars;

  /// 大运（自月柱顺/逆排，每步 10 年）。
  final List<DaYunStep> daYun;

  /// 起运年龄（岁，官方以 `jiaoyunYear` 表示，本地按"三天折一年"换算）。
  final double qiYunAge;

  /// 顺排 / 逆排。
  final bool forward;

  /// 五行统计（木火土金水）。
  final Map<String, int> wuXingCount;

  /// 胎元与命宫。
  final TaiYuanMingGong taiYuanMingGong;

  /// 小运（出生后逐年，自时柱顺/逆排）。
  final List<GanZhi> xiaoYun;

  /// 五行力量与喜用。
  final WuXingPower wuXingPower;

  /// 起运与交运详细信息。
  final QiYunDetail qiYunDetail;

  const BaZiPan({
    required this.birthTime,
    required this.siZhu,
    required this.pillars,
    required this.daYun,
    required this.qiYunAge,
    required this.forward,
    required this.wuXingCount,
    required this.taiYuanMingGong,
    required this.xiaoYun,
    required this.wuXingPower,
    required this.qiYunDetail,
  });

  /// 日主（日柱天干）。
  String get dayMaster => siZhu.day.gan;

  /// 生肖。
  String get animal => animalOfYear(birthTime.year);

  BaZiPillar pillarOf(String name) =>
      pillars.firstWhere((pillar) => pillar.name == name);
}

/// 十神单字简称（与官方一致：偏财->财，正财->才，偏印->枭）。
String shiShenShort(String shiShen) {
  switch (shiShen) {
    case '比肩':
      return '比';
    case '劫财':
      return '劫';
    case '食神':
      return '食';
    case '伤官':
      return '伤';
    case '偏财':
      return '财';
    case '正财':
      return '才';
    case '七杀':
      return '杀';
    case '正官':
      return '官';
    case '偏印':
      return '枭';
    case '正印':
      return '印';
    default:
      return shiShen.isNotEmpty ? shiShen[0] : '';
  }
}

/// 干支对应的十神双字缩写（如「己亥」->「才印」）。
String ganZhiShiShenShort(GanZhi gz, String dayMaster) {
  final stem = shiShenShort(shiShenOf(gz.gan, dayMaster));
  final branch = shiShenShort(zhiShiShenOf(gz.zhi, dayMaster));
  return '$stem$branch';
}

/// 计算起运年月天小时与交运公历日期。
QiYunDetail calculateQiYunDetail(DateTime birthTime, {required bool forward}) {
  final boundary = forward
      ? (nextJie(birthTime)?.time ?? birthTime)
      : (currentJie(birthTime)?.time ?? birthTime);
  final diffMinutes = boundary.difference(birthTime).inMinutes.abs();

  // 传统算命：3 天折 1 年（4320 分钟），1 天折 4 个月（360 分钟折 1 月），1 小时折 5 天（12 分钟折 1 天）
  final years = diffMinutes ~/ 4320;
  final rem1 = diffMinutes % 4320;
  final months = rem1 ~/ 360;
  final rem2 = rem1 % 360;
  final days = rem2 ~/ 12;
  final hours = (boundary.hour - birthTime.hour + 24) % 24;

  // 交运时间：出生时间顺延起运年、月、日、小时
  var y = birthTime.year + years;
  var m = birthTime.month + months;
  while (m > 12) {
    y += 1;
    m -= 12;
  }
  final baseDt = DateTime(y, m, birthTime.day, birthTime.hour);
  final jiaoYunDate = baseDt.add(Duration(days: days, hours: hours));

  return QiYunDetail(
    years: years,
    months: months,
    days: days,
    hours: hours,
    jiaoYunDate: jiaoYunDate,
  );
}

/// 计算八字排盘。
///
/// 大运规则（传统子平法）：
///   * 阳年男 / 阴年女顺排，阴年男 / 阳年女逆排；
///   * 顺排取「出生 → 下一个节」的天数、逆排取「上一个节 → 出生」的天数，
///     三天折一年、一天折四个月、一时辰折十天，得到起运岁数（官方由服务端下发）；///
///   * 自月柱起顺/逆推，每步十年，共十步。
BaZiPan buildBaZiPan(DateTime birthTime, {bool male = true}) {
  final siZhu = computeSiZhu(birthTime);
  final dayMaster = siZhu.day.gan;

  final pillars = <BaZiPillar>[
    for (final entry in <({String name, GanZhi gz})>[
      (name: '年柱', gz: siZhu.year),
      (name: '月柱', gz: siZhu.month),
      (name: '日柱', gz: siZhu.day),
      (name: '时柱', gz: siZhu.hour),
    ])
      BaZiPillar(
        name: entry.name,
        ganZhi: entry.gz,
        shiShen: entry.name == '日柱' ? '日主' : shiShenOf(entry.gz.gan, dayMaster),
        zhiShiShen: zhiShiShenOf(entry.gz.zhi, dayMaster),
        nayin: nayinOf(entry.gz.gan, entry.gz.zhi),
        changSheng: changSheng12Of(entry.gz.gan, entry.gz.zhi),
        cangGan: <({String gan, String shiShen, int days})>[
          for (final cang in kDiZhiCangGan[entry.gz.zhi] ?? const <CangGan>[])
            (
              gan: cang.gan,
              shiShen: shiShenOf(cang.gan, dayMaster),
              days: cang.days,
            ),
        ],
      ),
  ];

  // 顺/逆排：阳年男、阴年女顺排
  final yearGanYang = kBaziTianGan[siZhu.year.gan]?.yang ?? true;
  final forward = (yearGanYang == male);

  // 起运岁数：三天折一年
  final boundary = forward
      ? (nextJie(birthTime)?.time ?? birthTime)
      : (currentJie(birthTime)?.time ?? birthTime);
  final diffHours = birthTime.difference(boundary).inHours.abs();
  final qiYunAge = diffHours / 72.0;

  final monthIndex = kBaziTianGan.keys.toList().indexOf(siZhu.month.gan);
  final monthZhiIndex = kBaziDiZhi.keys.toList().indexOf(siZhu.month.zhi);
  final daYun = <DaYunStep>[
    for (var step = 1; step <= 10; step++)
      DaYunStep(
        index: step,
        startAge: (qiYunAge + (step - 1) * 10).floor(),
        endAge: (qiYunAge + step * 10).floor() - 1,
        ganZhi: _shiftGanZhi(
          siZhu.month,
          forward ? step : -step,
          monthIndex,
          monthZhiIndex,
        ),
      ),
  ];

  final counts = <String, int>{'木': 0, '火': 0, '土': 0, '金': 0, '水': 0};
  for (final pillar in pillars) {
    final ganWuXing = kBaziTianGan[pillar.gan]?.wuXing;
    if (ganWuXing != null) counts[ganWuXing] = (counts[ganWuXing] ?? 0) + 1;
    final zhiWuXing = kBaziDiZhi[pillar.zhi]?.wuXing;
    if (zhiWuXing != null) counts[zhiWuXing] = (counts[zhiWuXing] ?? 0) + 1;
  }

  // 十神五行归类：比劫=同类，印=生我，食伤=我生，财=我克，官杀=克我
  final dayWuXing = kBaziTianGan[dayMaster]?.wuXing ?? '木';
  final sameWuXing = dayWuXing; // 比劫
  final yinWuXing = _wuXingOfRelation(dayWuXing, -1); // 印：生我者
  final shiShangWuXing = _wuXingOfRelation(dayWuXing, 1); // 食伤：我生者
  final caiWuXing = _wuXingOfRelation(dayWuXing, 2); // 财：我克者
  final guanWuXing = _wuXingOfRelation(dayWuXing, -2); // 官杀：克我者

  // 五行力量：天干各 1，地支按藏干天数折算（合计 8 份 → 百分比）
  final power = <String, double>{'木': 0, '火': 0, '土': 0, '金': 0, '水': 0};
  for (final pillar in pillars) {
    final ganWuXing = kBaziTianGan[pillar.gan]?.wuXing;
    if (ganWuXing != null) power[ganWuXing] = (power[ganWuXing] ?? 0) + 1;
    for (final cang in pillar.cangGan) {
      final wx = kBaziTianGan[cang.gan]?.wuXing;
      if (wx != null) {
        power[wx] = (power[wx] ?? 0) + cang.days / 30;
      }
    }
  }
  final powerTotal = power.values.fold<double>(0, (sum, value) => sum + value);
  final powerPercent = <String, double>{
    for (final entry in power.entries)
      entry.key: powerTotal == 0 ? 0.0 : entry.value / powerTotal * 100,
  };

  final support = (power[sameWuXing] ?? 0) + (power[yinWuXing] ?? 0);
  final supportPercent = powerTotal == 0 ? 0.0 : support / powerTotal * 100;
  final strong = supportPercent >= 50;
  // 身强取克泄耗（食伤 / 财 / 官），身弱取生扶（印 / 比劫），各取力量较大者
  final favorable = strong
      ? _topWuXing(powerPercent, <String>[shiShangWuXing, caiWuXing, guanWuXing], 2)
      : _topWuXing(powerPercent, <String>[yinWuXing, sameWuXing], 2);

  final taiYuan = _taiYuanOf(siZhu);
  final mingGong = _mingGongOf(siZhu);
  final hourGanIndex = kTianGan.indexOf(siZhu.hour.gan);
  final hourZhiIndex = kDiZhi.indexOf(siZhu.hour.zhi);
  final xiaoYun = <GanZhi>[
    for (var year = 1; year <= 10; year++)
      _shiftGanZhi(
        siZhu.hour,
        forward ? year : -year,
        hourGanIndex,
        hourZhiIndex,
      ),
  ];

  final qiYunDetail = calculateQiYunDetail(birthTime, forward: forward);

  return BaZiPan(
    birthTime: birthTime,
    siZhu: siZhu,
    pillars: pillars,
    daYun: daYun,
    qiYunAge: qiYunAge,
    forward: forward,
    wuXingCount: counts,
    taiYuanMingGong: TaiYuanMingGong(taiYuan: taiYuan, mingGong: mingGong),
    xiaoYun: xiaoYun,
    wuXingPower: WuXingPower(
      percent: powerPercent,
      supportPercent: supportPercent,
      strength: strong ? '身强' : '身弱',
      favorable: favorable,
    ),
    qiYunDetail: qiYunDetail,
  );
}

/// 相生顺序（水→木→火→土→金）上相对 [wuXing] 偏移 [steps] 的五行。
String _wuXingOfRelation(String wuXing, int steps) {
  const order = <String>['水', '木', '火', '土', '金'];
  final start = order.indexOf(wuXing);
  if (start < 0) return wuXing;
  final index = ((start + steps) % order.length + order.length) % order.length;
  return order[index];
}

List<String> _topWuXing(Map<String, double> percent, List<String> candidates, int count) {
  final unique = candidates.toSet().toList()
    ..sort((a, b) => (percent[b] ?? 0).compareTo(percent[a] ?? 0));
  return unique.take(count).toList();
}

/// 胎元：月柱天干进一位、地支进三位。
String _taiYuanOf(SiZhu siZhu) {
  final ganIndex = kTianGan.indexOf(siZhu.month.gan);
  final zhiIndex = kDiZhi.indexOf(siZhu.month.zhi);
  return '${kTianGan[(ganIndex + 1) % 10]}${kDiZhi[(zhiIndex + 3) % 12]}';
}

/// 命宫：以月支数与时支数求和（不足 14 则加 12），用 26 减去得宫支；
/// 宫干按年干起五虎遁（寅月天干）顺推。
String _mingGongOf(SiZhu siZhu) {
  final monthNum = kYueZhi.indexOf(siZhu.month.zhi) + 1; // 寅月 = 1
  final hourNum = kDiZhi.indexOf(siZhu.hour.zhi) + 1; // 子 = 1
  var sum = monthNum + hourNum;
  if (sum < 14) sum += 12;
  final gongZhiIndex = (26 - sum) % 12; // 0 = 子
  final gongZhi = kDiZhi[gongZhiIndex];

  // 年干起五虎遁：甲己丙作首、乙庚戊为头、丙辛庚寅起、丁壬壬位流、戊癸甲寅求
  final yearGanIndex = kTianGan.indexOf(siZhu.year.gan);
  final yinMonthGanIndex = (yearGanIndex % 5) * 2 + 2; // 寅月天干下标
  final offsetFromYin = (gongZhiIndex - 2 + 12) % 12; // 寅 → 0
  final gongGan = kTianGan[(yinMonthGanIndex + offsetFromYin) % 10];
  return '$gongGan$gongZhi';
}

GanZhi _shiftGanZhi(GanZhi base, int offset, int ganIndex, int zhiIndex) {
  final gan = kTianGan[((ganIndex + offset) % 10 + 10) % 10];
  final zhi = kDiZhi[((zhiIndex + offset) % 12 + 12) % 12];
  return GanZhi(gan, zhi);
}
