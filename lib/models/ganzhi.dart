/// 天干地支与四柱推算。
///
/// 天干、地支、偏移取干支、日干支、时干支、年干支、月干支全部 1:1 移植自官方
/// RN bundle 模块 2111（`GanZhi`），保持相同取值：
///   * `getGanByOffset` / `getZhiByOffset` —— 注意 JS 取余保留符号，Dart 用
///     `remainder()` 对齐
///   * `getDayGanZhi` —— 以 1899-12-21 为基准，`differentDays(目标, 基准) - 1`
///   * `getHourGanZhi` —— 时支表 `hour_zhi` + 日干起时干表 `rigan_shigan10`
///   * `getYearGanZhi(jqYear)` / `getMonthGanZhi(jqMonth, 年干)`
///
/// 年 / 月干支的分界取自官方模块 2112（`SolarTerm`）导出的精确节气表，
/// 见 `jieqi_data.dart` 与 [jieQiMonthOf]，因此与官方 App 完全一致。
library;

import 'jieqi.dart';

const List<String> kTianGan = <String>['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
const List<String> kDiZhi = <String>['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];

/// 节气月支顺序：寅月为一年之首（立春起）。
const List<String> kYueZhi = <String>['寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥', '子', '丑'];

/// 时支表，索引为 0~23 时（官方 `hour_zhi`）。
const List<String> kHourZhi = <String>[
  '子', '丑', '丑', '寅', '寅', '卯', '卯', '辰', '辰', '巳', '巳', '午',
  '午', '未', '未', '申', '申', '酉', '酉', '戌', '戌', '亥', '亥', '子',
];

/// 日干起时干表（甲己起甲子，官方 `rigan_shigan10`）。
const List<String> kRiGanShiGan10 = <String>['甲', '丙', '戊', '庚', '壬', '甲', '丙', '戊', '庚', '壬'];

/// 干支（天干 + 地支）。
class GanZhi {
  final String gan;
  final String zhi;

  const GanZhi(this.gan, this.zhi);

  String get text => '$gan$zhi';

  @override
  String toString() => text;

  @override
  bool operator ==(Object other) => other is GanZhi && other.gan == gan && other.zhi == zhi;

  @override
  int get hashCode => Object.hash(gan, zhi);
}

int ganIndexOf(String gan) {
  final index = kTianGan.indexOf(gan);
  return index < 0 ? -1 : index + 1;
}

int zhiIndexOf(String zhi) {
  final index = kDiZhi.indexOf(zhi);
  return index < 0 ? -1 : index + 1;
}

/// 官方 `getGanByOffset`：以天干为基准偏移取干（偏移可为负）。
String ganByOffset(String gan, int offset) {
  var o = ganIndexOf(gan) + offset.remainder(10);
  if (o <= 0) o = 10 + o;
  if (o > 10) o %= 10;
  return kTianGan[o - 1];
}

/// 官方 `getZhiByOffset`：以地支为基准偏移取支（偏移可为负）。
String zhiByOffset(String zhi, int offset) {
  var o = zhiIndexOf(zhi) + offset.remainder(12);
  if (o <= 0) o = 12 + o;
  if (o > 12) o %= 12;
  return kDiZhi[o - 1];
}

bool _isLeapYear(int year) => (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

int _dayOfYear(DateTime date) {
  final start = DateTime.utc(date.year, 1, 1);
  final target = DateTime.utc(date.year, date.month, date.day);
  return target.difference(start).inDays + 1;
}

/// 官方 `SolarDay.differentDays(e, t)`：目标日期与基准日期的天数差。
int differentDays(DateTime target, DateTime base) {
  final baseDay = _dayOfYear(base);
  final targetDay = _dayOfYear(target);
  if (base.year != target.year) {
    var sum = 0;
    for (var year = base.year; year < target.year; year++) {
      sum += _isLeapYear(year) ? 366 : 365;
    }
    return sum + (targetDay - baseDay);
  }
  return targetDay - baseDay;
}

DateTime _dateOnly(DateTime t) => DateTime.utc(t.year, t.month, t.day);

/// 日干支（官方 `GanZhi.getDayGanZhi`）。
GanZhi dayGanZhi(DateTime date) {
  final base = DateTime.utc(1899, 12, 21);
  final offset = differentDays(_dateOnly(date), base) - 1;
  return GanZhi(ganByOffset('甲', offset), zhiByOffset('子', offset));
}

/// 时干支（官方 `GanZhi.getHourGanZhi`）。
GanZhi hourGanZhi(DateTime time, GanZhi dayGanZhiValue) {
  final zhi = kHourZhi[time.hour];
  final shiGan = kRiGanShiGan10[ganIndexOf(dayGanZhiValue.gan) - 1];
  final gan = ganByOffset(shiGan, zhiIndexOf(zhi) - 1);
  return GanZhi(gan, zhi);
}

/// 年干支（官方 `GanZhi.getYearGanZhi`，入参为立春年）。
GanZhi yearGanZhi(int jqYear) {
  final n = jqYear - 1864;
  return GanZhi(ganByOffset('甲', n), zhiByOffset('子', n));
}

/// 月干支（官方 `GanZhi.getMonthGanZhi`，`jqMonth` 1 为寅月 … 12 为丑月）。
GanZhi monthGanZhi(int jqMonth, GanZhi yearGz) {
  var o = (2 * ganIndexOf(yearGz.gan) + jqMonth) % 10;
  if (o == 0) o = 10;
  return GanZhi(kTianGan[o - 1], kYueZhi[jqMonth - 1]);
}

/// 十二"节"对应的节气月序：立春为寅月(1) … 小寒为丑月(12)。
const List<String> _jieOrder = <String>[
  '立春', '惊蛰', '清明', '立夏', '芒种', '小暑',
  '立秋', '白露', '寒露', '立冬', '大雪', '小寒',
];

/// 节气月：返回立春年（`jqYear`）与节气月序（`jqMonth`，1 寅月 … 12 丑月）。
///
/// 边界取官方模块 2112 导出的精确节气时刻（见 [jieQiAtOrBefore]），
/// 与官方 App 的年柱 / 月柱完全一致；超出 1901–2099 节气表范围时才按公历月估算。
({int jqYear, int jqMonth}) jieQiMonthOf(DateTime date) {
  // 与官方一致：恰好等于节气时刻时仍算上一个节气月
  final jie = jieQiAtOrBefore(date, jieOnly: true, strict: true);
  if (jie == null) {
    final month = date.month;
    final jqMonth = month == 1 ? 12 : month - 1;
    return (jqYear: month < 2 ? date.year - 1 : date.year, jqMonth: jqMonth);
  }
  final jqMonth = _jieOrder.indexOf(jie.name) + 1;
  // 干支年以立春为界：须"严格晚于"立春才算新年（与官方边界判断一致）
  final liChun = _liChunOf(date.year);
  final jqYear = date.isAfter(liChun) ? date.year : date.year - 1;
  return (jqYear: jqYear, jqMonth: jqMonth);
}

/// 当年立春时刻；超出节气表范围时退回 2 月 4 日。
DateTime _liChunOf(int year) {
  for (final moment in jieQiMomentsOfYear(year)) {
    if (moment.name == '立春') return moment.time;
  }
  return DateTime(year, 2, 4);
}

/// 四柱。
class SiZhu {
  final GanZhi year;
  final GanZhi month;
  final GanZhi day;
  final GanZhi hour;

  const SiZhu({required this.year, required this.month, required this.day, required this.hour});

  /// 官方展示顺序：年 月 日 时。
  String get text => '${year.text} ${month.text} ${day.text} ${hour.text}';
}

/// 推算四柱。
///
/// 官方 `SolarTerm.getSizhu()` 对 23:00–23:59 有特殊处理：年柱 / 月柱仍按当天，
/// 日柱 / 时柱取次日子时（"夜子时"归次日）。
SiZhu computeSiZhu(DateTime time) {
  final jq = jieQiMonthOf(time);
  final year = yearGanZhi(jq.jqYear);
  final month = monthGanZhi(jq.jqMonth, year);
  final dayTime = time.hour == 23
      ? time.add(const Duration(hours: 1))
      : time;
  final day = dayGanZhi(dayTime);
  return SiZhu(
    year: year,
    month: month,
    day: day,
    hour: hourGanZhi(dayTime, day),
  );
}

/// 旬空：由日干支推出（甲子旬中戌亥空 …）。
String xunKongOf(GanZhi day) {
  final gan = ganIndexOf(day.gan) - 1;
  final zhi = zhiIndexOf(day.zhi) - 1;
  final first = (zhi - gan + 10) % 12;
  final second = (first + 1) % 12;
  return '${kDiZhi[first]}${kDiZhi[second]}';
}
