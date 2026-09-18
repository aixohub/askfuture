/// 精确节气查询。
///
/// 数据来源为官方 RN bundle 模块 2112（`SolarTerm`）导出的 [kJieQiTable]，
/// 精确到秒，因此"节"的边界时刻与官方 App 完全一致（四柱年柱 / 月柱随之精确）。
library;

import 'jieqi_data.dart';

/// 一个节气发生的时刻。
class JieQiMoment {
  /// 节气名，如 `立春` `白露`。
  final String name;

  /// 在 24 节气中的序号（0 小寒 … 23 冬至）。
  final int index;

  /// 发生时刻（本地时间）。
  final DateTime time;

  const JieQiMoment({required this.name, required this.index, required this.time});

  /// 是否为"节"（月首）；false 表示"中气"。
  bool get isJie => kJieIndexes.contains(index);

  @override
  String toString() => '$name@$time';
}

final Map<int, List<JieQiMoment>> _cache = <int, List<JieQiMoment>>{};

/// 某公历年的 24 个节气（按时间升序）。
List<JieQiMoment> jieQiMomentsOfYear(int year) {
  final cached = _cache[year];
  if (cached != null) return cached;

  final raw = kJieQiTable[year];
  if (raw == null) return const <JieQiMoment>[];

  final moments = <JieQiMoment>[];
  final parts = raw.split(',');
  for (var i = 0; i < parts.length; i++) {
    final code = parts[i];
    moments.add(
      JieQiMoment(
        name: kJieQiNames[i],
        index: i,
        time: DateTime(
          year,
          int.parse(code.substring(0, 2)),
          int.parse(code.substring(2, 4)),
          int.parse(code.substring(4, 6)),
          int.parse(code.substring(6, 8)),
          int.parse(code.substring(8, 10)),
        ),
      ),
    );
  }
  moments.sort((a, b) => a.time.compareTo(b.time));
  _cache[year] = moments;
  return moments;
}

/// 最近的节气（含"节"与"中气"），不晚于 [time]。
///
/// [strict] 为 true 时改为"严格早于 [time]"，用于对齐官方
/// `fillJqNlAndLeap()` 的边界判断（恰好等于节气时刻时仍算上一个节气月）。
JieQiMoment? jieQiAtOrBefore(DateTime time, {bool jieOnly = false, bool strict = false}) {
  for (var year = time.year; year >= time.year - 1 && year >= kJieQiStartYear; year--) {
    final moments = jieQiMomentsOfYear(year)
        .where((m) => !jieOnly || m.isJie)
        .where((m) => strict ? m.time.isBefore(time) : !m.time.isAfter(time))
        .toList();
    if (moments.isNotEmpty) return moments.last;
  }
  return null;
}

/// 下一个节气，晚于 [time]。
JieQiMoment? jieQiAfter(DateTime time, {bool jieOnly = false}) {
  for (var year = time.year; year <= time.year + 1 && year <= kJieQiEndYear; year++) {
    final moments = jieQiMomentsOfYear(year)
        .where((m) => !jieOnly || m.isJie)
        .where((m) => m.time.isAfter(time))
        .toList();
    if (moments.isNotEmpty) return moments.first;
  }
  return null;
}

/// 下一个"节"（月首），包含恰好等于 [time] 的节气时刻。
///
/// 官方 `fillJqNlAndLeap()` 把"恰好等于节气时刻"归给上一个节气月（[currentJie]），
/// 同时该时刻仍是 `nextJq`，因此这里使用"不早于"的判断。
JieQiMoment? nextJie(DateTime time) {
  for (var year = time.year; year <= time.year + 1 && year <= kJieQiEndYear; year++) {
    final moments = jieQiMomentsOfYear(year)
        .where((m) => m.isJie)
        .where((m) => !m.time.isBefore(time))
        .toList();
    if (moments.isNotEmpty) return moments.first;
  }
  return null;
}

/// 当天的节气（官方万年历用它对日期格标色）。
JieQiMoment? jieQiOnDay(DateTime day) {
  for (final moment in jieQiMomentsOfYear(day.year)) {
    if (moment.time.year == day.year &&
        moment.time.month == day.month &&
        moment.time.day == day.day) {
      return moment;
    }
  }
  return null;
}

/// 当前所处的"节"（月首）。
///
/// 采用"严格晚于"的边界判断，与官方 `fillJqNlAndLeap()` 一致：
/// 恰好等于节气时刻时仍算上一个节气月。
JieQiMoment? currentJie(DateTime time) =>
    jieQiAtOrBefore(time, jieOnly: true, strict: true);

/// 当前节气月内的"中气"。
///
/// 官方 `SolarTerm.getSizhu().zqName / zqDate` 取的是当前节气月内的中气，
/// 因此可能晚于传入时刻（例如白露之后、秋分之前，中气为秋分）。
JieQiMoment? currentZhongQi(DateTime time) {
  final jie = currentJie(time);
  if (jie == null) return null;
  final zhongQiIndex = (jie.index + 1) % 24;
  final after = jieQiAfter(jie.time);
  if (after != null && after.index == zhongQiIndex) return after;
  // 跨年兜底：直接按索引取下一年的中气
  return jieQiAfter(jie.time.subtract(const Duration(days: 1)));
}
