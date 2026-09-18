/// 农历换算（官方 RN bundle 模块 1898 `calendar` 的 1:1 移植）。
///
/// 官方实现要点：
///   * `lunarInfo` 为 1900–2100 年逐年压缩位表（共 201 项）；
///   * `lYearDays` / `leapMonth` / `leapDays` / `monthDays` 负责拆表；
///   * `solar2lunar(y, m, d)` 以 1900-01-31 为基准逐日推进；
///   * `toChinaMonth` / `toChinaDay` 输出"八月""初七"这类中文写法；
///   * `toGanZhiYear` 给出农历年的干支（如丙午）。
///
/// 本文件只移植"公历 → 农历"所需部分，节气与四柱改用精确表
/// （见 `jieqi.dart` / `ganzhi.dart`），以保证与官方 App 一致。
library;

import 'ganzhi.dart';

/// 官方 `lunarInfo`（1900–2100 年，索引 0 对应 1900 年）。
const List<int> kLunarInfo = <int>[
  19416, 19168, 42352, 21717, 53856, 55632, 91476, 22176, 39632, 21970, 19168, 42422,
  42192, 53840, 119381, 46400, 54944, 44450, 38320, 84343, 18800, 42160, 46261, 27216,
  27968, 109396, 11104, 38256, 21234, 18800, 25958, 54432, 59984, 354965, 23248, 11104,
  100067, 37600, 116951, 51536, 54432, 120998, 46416, 22176, 107956, 9680, 37584, 53938,
  43344, 46423, 27808, 46416, 86869, 19872, 42416, 83315, 21200, 43432, 59728, 27296,
  44710, 43856, 19296, 43748, 42352, 21088, 62051, 55632, 23383, 22176, 38608, 19925,
  19152, 42192, 54484, 53840, 54616, 46400, 46752, 103846, 38320, 18864, 43380, 42160,
  45690, 27216, 27968, 44870, 43872, 38256, 19189, 18800, 25776, 29859, 59984, 27480,
  23232, 43872, 38613, 37600, 51552, 55636, 54432, 55888, 30034, 22176, 43959, 9680,
  37584, 51893, 43344, 46240, 47780, 44368, 21977, 19360, 42416, 86390, 21168, 43312,
  31060, 27296, 44368, 23378, 19296, 42726, 42208, 53856, 60005, 54576, 23200, 30371,
  38608, 19195, 19152, 42192, 118966, 53840, 54560, 56645, 46496, 22224, 21938, 18864,
  42359, 42160, 43600, 111189, 27936, 44448, 84835, 37744, 18936, 18800, 25776, 92326,
  59984, 27424, 108228, 43744, 41696, 53987, 51552, 54615, 54432, 55888, 23893, 22176,
  42704, 21972, 21200, 43448, 43344, 46240, 46758, 44368, 21920, 43940, 42416, 21168,
  45683, 26928, 29495, 27296, 44368, 84821, 19296, 42352, 21732, 53600, 59752, 54560,
  55968, 92838, 22224, 19168, 43476, 41680, 53584, 62034, 54560,
];

const List<String> _nStr1 = <String>['日', '一', '二', '三', '四', '五', '六', '七', '八', '九', '十'];
const List<String> _nStr2 = <String>['初', '十', '廿', '卅'];
const List<String> _nStr3 = <String>['正', '二', '三', '四', '五', '六', '七', '八', '九', '十', '冬', '腊'];
const List<String> _animals = <String>['鼠', '牛', '虎', '兔', '龙', '蛇', '马', '羊', '猴', '鸡', '狗', '猪'];

/// 官方 `lYearDays`：农历一年天数。
int lunarYearDays(int year) {
  var sum = 348;
  for (var i = 0x8000; i > 0x8; i >>= 1) {
    sum += (kLunarInfo[year - 1900] & i) != 0 ? 1 : 0;
  }
  return sum + lunarLeapDays(year);
}

/// 官方 `leapMonth`：闰月月份，0 表示无闰月。
int lunarLeapMonth(int year) => kLunarInfo[year - 1900] & 0xf;

/// 官方 `leapDays`：闰月天数。
int lunarLeapDays(int year) {
  if (lunarLeapMonth(year) == 0) return 0;
  return (kLunarInfo[year - 1900] & 0x10000) != 0 ? 30 : 29;
}

/// 官方 `monthDays`：某农历月天数。
int lunarMonthDays(int year, int month) {
  if (month > 12 || month < 1) return -1;
  return (kLunarInfo[year - 1900] & (0x10000 >> month)) != 0 ? 30 : 29;
}

/// 官方 `toChinaMonth`：`1` → `正月`。
String toChinaMonth(int month) {
  if (month > 12 || month < 1) return '';
  return '${_nStr3[month - 1]}月';
}

/// 官方 `toChinaDay`：`7` → `初七`。
String toChinaDay(int day) {
  switch (day) {
    case 10:
      return '初十';
    case 20:
      return '二十';
    case 30:
      return '三十';
    default:
      return '${_nStr2[day ~/ 10]}${_nStr1[day % 10]}';
  }
}

/// 官方 `getAnimal`：按公历年取生肖。
String animalOfYear(int year) => _animals[(year - 4) % 12];

/// 官方模块 2235 `lunarMonthData`：农历月名。
const List<String> kLunarMonthNames = <String>[
  '正月', '二月', '三月', '四月', '五月', '六月',
  '七月', '八月', '九月', '十月', '冬月', '腊月',
];

/// 官方模块 2235 `lunarHourData`：十二时辰（滚轮展示文案）。
const List<String> kLunarHourNames = <String>[
  '子时23:00-00:59', '丑时01:00-02:59', '寅时03:00-04:59', '卯时05:00-06:59',
  '辰时07:00-08:59', '巳时09:00-10:59', '午时11:00-12:59', '未时13:00-14:59',
  '申时15:00-16:59', '酉时17:00-18:59', '戌时19:00-20:59', '亥时21:00-22:59',
];

/// 十二时辰名（不含时段），索引 0 为子时。
const List<String> kLunarHourZhiNames = <String>[
  '子时', '丑时', '寅时', '卯时', '辰时', '巳时',
  '午时', '未时', '申时', '酉时', '戌时', '亥时',
];

/// 小时 → 时辰滚轮序号（官方 `getSelectHour`：子时 0 … 亥时 11）。
///
/// 注意官方实现把"时辰"折算为偶数小时：子时取 0 点、丑时取 2 点 … 亥时取 22 点。
int lunarHourIndex(int hour) {
  final h = hour.clamp(0, 23);
  return ((h + 1) ~/ 2) % 12;
}

/// 时辰滚轮序号 → 小时（官方 `updateLunarTime`：`2 * position`）。
int hourOfLunarHourIndex(int index) => (index.clamp(0, 11)) * 2;

/// 官方 `toGanZhiYear`：农历年干支（如丙午）。
String ganZhiOfLunarYear(int year) {
  var gan = (year - 3) % 10;
  var zhi = (year - 3) % 12;
  if (gan == 0) gan = 10;
  if (zhi == 0) zhi = 12;
  return '${kTianGan[gan - 1]}${kDiZhi[zhi - 1]}';
}

/// 农历日期（对应官方 `solar2lunar` 返回值中的常用字段）。
class LunarDate {
  final int year;
  final int month;
  final int day;
  final bool isLeap;
  final String animal;

  const LunarDate({
    required this.year,
    required this.month,
    required this.day,
    required this.isLeap,
    required this.animal,
  });

  /// 如 `八月` / `闰八月`。
  String get monthCn => '${isLeap ? '闰' : ''}${toChinaMonth(month)}';

  /// 如 `初七`。
  String get dayCn => toChinaDay(day);

  /// 如 `八月初七`。
  String get text => '$monthCn$dayCn';

  /// 农历年干支，如 `丙午`。
  String get ganZhiYear => ganZhiOfLunarYear(year);

  /// `八月大` / `八月小`（官方农历库按 29/30 天区分）。
  String get monthSizeCn =>
      lunarMonthDays(year, month) >= 30 ? '$monthCn大' : '$monthCn小';

  /// 该农历日期对应的公历日期。
  DateTime? get solarDate =>
      lunar2Solar(year, month, day, isLeap: isLeap);

  /// 如 `丙午年八月初六`。
  String get fullText => '$ganZhiYear年$text';
}

/// 农历年中的一个月（含闰月），供日期选择器使用。
class LunarMonthOption {
  /// 农历年。
  final int year;

  /// 月序号 1~12。
  final int month;

  /// 是否为闰月。
  final bool isLeap;

  const LunarMonthOption(this.year, this.month, this.isLeap);

  /// 如 `正月` / `闰二月`。
  String get name => '${isLeap ? '闰' : ''}${kLunarMonthNames[month - 1]}';

  /// 该月名称（不含"闰"字）。
  String get plainName => kLunarMonthNames[month - 1];

  /// 该月天数（29 / 30）。
  int get dayCount =>
      lunarDaysInMonth(year, month, isLeap: isLeap);

  @override
  bool operator ==(Object other) =>
      other is LunarMonthOption && other.month == month && other.isLeap == isLeap;

  @override
  int get hashCode => Object.hash(month, isLeap);
}

/// 某农历年的月份列表（闰月紧随其前一个月）。
List<LunarMonthOption> lunarMonthsOf(int year) {
  final leap = lunarLeapMonth(year);
  final months = <LunarMonthOption>[
    for (var m = 1; m <= 12; m++) LunarMonthOption(year, m, false),
  ];
  if (leap > 0 && leap <= 12) {
    months.insert(leap, LunarMonthOption(year, leap, true));
  }
  return months;
}

/// 农历某月的天数（29 / 30）。
///
/// 闰月需要传 [isLeap]；若该年没有闰月或与 [month] 不符则返回 0。
int lunarDaysInMonth(int year, int month, {bool isLeap = false}) {
  if (month < 1 || month > 12) return 0;
  if (isLeap) {
    return lunarLeapMonth(year) == month ? lunarLeapDays(year) : 0;
  }
  return lunarMonthDays(year, month);
}

/// 官方 `solar2lunar`：公历 → 农历；超出 1900–2100 返回 null。
LunarDate? solar2Lunar(int year, int month, int day) {
  if (year < 1900 || year > 2100) return null;
  if (year == 1900 && month == 1 && day < 31) return null;

  // 官方 `Date.UTC(1900, 0, 31)` —— JS 月份从 0 起算，即 1900-01-31
  final base = DateTime.utc(1900, 1, 31);
  final target = DateTime.utc(year, month, day);
  var offset = target.difference(base).inDays;

  var lunarYear = 1900;
  var daysInYear = 0;
  for (; lunarYear < 2101 && offset > 0; lunarYear++) {
    daysInYear = lunarYearDays(lunarYear);
    offset -= daysInYear;
  }
  if (offset < 0) {
    offset += daysInYear;
    lunarYear--;
  }

  final leap = lunarLeapMonth(lunarYear);
  var isLeap = false;
  var lunarMonth = 1;
  var daysInMonth = 0;
  for (; lunarMonth < 13 && offset > 0; lunarMonth++) {
    if (leap > 0 && lunarMonth == leap + 1 && !isLeap) {
      lunarMonth--;
      isLeap = true;
      daysInMonth = lunarLeapDays(lunarYear);
    } else {
      daysInMonth = lunarMonthDays(lunarYear, lunarMonth);
    }
    if (isLeap && lunarMonth == leap + 1) isLeap = false;
    offset -= daysInMonth;
  }

  if (offset == 0 && leap > 0 && lunarMonth == leap + 1) {
    if (isLeap) {
      isLeap = false;
    } else {
      isLeap = true;
      lunarMonth--;
    }
  }
  if (offset < 0) {
    offset += daysInMonth;
    lunarMonth--;
  }

  return LunarDate(
    year: lunarYear,
    month: lunarMonth,
    day: offset + 1,
    isLeap: isLeap,
    animal: animalOfYear(lunarYear),
  );
}

/// 便捷入口：`2026-09-17` → `八月初七`。
String lunarTextOf(DateTime date) {
  final lunar = solar2Lunar(date.year, date.month, date.day);
  return lunar?.text ?? '';
}

/// 公历日期（含时间）→ 农历日期。
LunarDate? lunarDateOf(DateTime date) =>
    solar2Lunar(date.year, date.month, date.day);

/// 农历日期 → 公历日期（[isLeap] 表示闰月）。
DateTime? solarDateOfLunar(int year, int month, int day, {bool isLeap = false}) =>
    lunar2Solar(year, month, day, isLeap: isLeap);

/// 官方 `lunar2solar`：农历 → 公历（[isLeap] 表示闰月），超出范围返回 null。
///
/// 用于八字轻测勾选「阴历」时把输入的农历日期换算成公历再排盘。
DateTime? lunar2Solar(int year, int month, int day, {bool isLeap = false}) {
  if (year < 1900 || year > 2100) return null;
  if (month < 1 || month > 12 || day < 1) return null;
  final leap = lunarLeapMonth(year);
  // 闰月必须与该年真正的闰月一致，否则视为非法输入
  if (isLeap && leap != month) return null;
  if (year == 2100 && month == 12 && day > 1) return null;

  final monthDays = lunarMonthDays(year, month);
  final maxDay = isLeap ? lunarLeapDays(year) : monthDays;
  if (day > maxDay) return null;

  var offset = 0;
  for (var y = 1900; y < year; y++) {
    offset += lunarYearDays(y);
  }
  var addedLeap = false;
  for (var m = 1; m < month; m++) {
    final leapMonth = lunarLeapMonth(year);
    if (!addedLeap && leapMonth > 0 && leapMonth <= m) {
      offset += lunarLeapDays(year);
      addedLeap = true;
    }
    offset += lunarMonthDays(year, m);
  }
  if (isLeap) offset += monthDays;

  // 官方以 `Date.UTC(1900, 1, 30)`（即 1900-03-02）为基准偏移 `offset + day - 31` 天
  final base = DateTime.utc(1900, 2, 30);
  final solar = base.add(Duration(days: offset + day - 31));
  return DateTime(solar.year, solar.month, solar.day);
}
