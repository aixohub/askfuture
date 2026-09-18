/// 农历日期与六爻神煞、卦身、世身推导。
library;

import 'ganzhi.dart';
import 'lunar_calendar.dart';

/// 农历日期文本，如 `八月初七`（官方模块 1898 `solar2lunar` 的精确换算）。
String getLunarDateText(DateTime dt) => lunarTextOf(dt);

// ---------------------------------------------------------------- 神煞
//
// 六爻排盘的神煞取法 1:1 对齐参考实现 sixyao-main 的
// `src/main/resources/static/liuyaodata.js`（`TGGuiRenStrs` / `DZYiMaStrs` /
// `DZTaoHuaStrs` / `TGLuStrs` 四张表），四项神煞全部以**日柱**起：
//
//   var riGan = bzpp.iRiJZ % 10;      // 日干序号
//   var riZhi = bzpp.iRiJZ % 12;      // 日支序号
//   "神煞：贵人→" + TGGuiRenStrs[riGan]
//        + "，驿马→" + DZYiMaStrs[riZhi%4]
//        + "，桃花→" + DZTaoHuaStrs[riZhi%4]
//        + "，日禄→" + TGLuStrs[riGan]
//
// 参考实现现成样例（`templates/home.ftl`）：2023-06-04 09:49（癸巳日）→
// `神煞：贵人→卯、巳，驿马→亥，桃花→午，日禄→子`。

/// 日干查天乙贵人（参考实现 `TGGuiRenStrs`，甲0 … 癸9）。
///
/// 甲戊→丑、未；乙己→子、申；丙丁→亥、酉；庚辛→午、寅；壬癸→卯、巳。
const List<String> kGuiRenByGan = <String>[
  '丑、未', // 甲
  '子、申', // 乙
  '亥、酉', // 丙
  '亥、酉', // 丁
  '丑、未', // 戊
  '子、申', // 己
  '午、寅', // 庚
  '午、寅', // 辛
  '卯、巳', // 壬
  '卯、巳', // 癸
];

/// 日支查驿马（参考实现 `DZYiMaStrs`，索引 = 日支序号 % 4）。
const List<String> kYiMaByZhiMod4 = <String>[
  '寅', // 余 0：申子辰
  '亥', // 余 1：巳酉丑
  '申', // 余 2：寅午戌
  '巳', // 余 3：亥卯未
];

/// 日支查桃花／咸池（参考实现 `DZTaoHuaStrs`，索引 = 日支序号 % 4）。
const List<String> kTaoHuaByZhiMod4 = <String>[
  '酉', // 余 0：申子辰
  '午', // 余 1：巳酉丑
  '卯', // 余 2：寅午戌
  '子', // 余 3：亥卯未
];

/// 日干查日禄（参考实现 `TGLuStrs`，甲0 … 癸9）。
const List<String> kRiLuByGan = <String>[
  '寅', '卯', // 甲乙
  '巳', '午', // 丙丁
  '巳', '午', // 戊己
  '申', '酉', // 庚辛
  '亥', '子', // 壬癸
];

/// 一项神煞：名称 + 地支。
class ShenShaItem {
  final String name;
  final String zhi;

  const ShenShaItem(this.name, this.zhi);
}

/// 神煞信息集合（顺序与参考实现一致：贵人、驿马、桃花、日禄）。
class ShenShaInfo {
  /// 天乙贵人，如 `丑、未`。
  final String guiRen;

  /// 驿马，如 `寅`。
  final String yiMa;

  /// 桃花（咸池），如 `酉`。
  final String taoHua;

  /// 日禄，如 `巳`。
  final String riLu;

  const ShenShaInfo({
    required this.guiRen,
    required this.yiMa,
    required this.taoHua,
    required this.riLu,
  });

  /// 官方卦象页的展示顺序与折叠规则：折叠时只显示前 3 项。
  List<ShenShaItem> get items => <ShenShaItem>[
    ShenShaItem('贵人', guiRen),
    ShenShaItem('驿马', yiMa),
    ShenShaItem('桃花', taoHua),
    ShenShaItem('日禄', riLu),
  ];

  /// 折叠态文案（前 3 项）。
  String get summary => _format(items.take(3));

  /// 展开态文案（全部 4 项）。
  String get detailText => _format(items);

  String _format(Iterable<ShenShaItem> list) =>
      list.map((item) => '${item.name} — ${item.zhi}').join('  ');
}

/// 按参考实现的口径，由**日柱**干支取神煞。
///
/// 传入的 [dayGan] / [dayZhi] 为日柱天干、地支；非法输入返回空串。
ShenShaInfo calculateShenSha({required String dayGan, required String dayZhi}) {
  final ganIndex = kTianGan.indexOf(dayGan);
  final zhiIndex = kDiZhi.indexOf(dayZhi);
  if (ganIndex < 0 || zhiIndex < 0) {
    return const ShenShaInfo(guiRen: '', yiMa: '', taoHua: '', riLu: '');
  }
  return ShenShaInfo(
    guiRen: kGuiRenByGan[ganIndex],
    yiMa: kYiMaByZhiMod4[zhiIndex % 4],
    taoHua: kTaoHuaByZhiMod4[zhiIndex % 4],
    riLu: kRiLuByGan[ganIndex],
  );
}

/// 计算卦身与世身。
///
/// * 世身歌：子午持世身居子，丑未持世身在丑，寅申持世身在寅，卯酉持世身在卯，辰戌持世身在辰，巳亥持世身在巳。
/// * 卦身歌：阴世还从午月起，阳世还从子月生。欲知卦身在何处，世爻起处便分明。若卦中无此地支则为"无"。
class GuaShenInfo {
  final String guaShen; // 卦身（若无则为"无"）
  final String shiShen; // 世身

  const GuaShenInfo({required this.guaShen, required this.shiShen});
}

GuaShenInfo calculateGuaShen({
  required String benGuaName,
  required int shiYaoIndex, // 0~5 代表初爻至六爻
  required List<String> benYaoZhis, // 六爻地支（初爻到六爻）
}) {
  // 1. 世身：世爻地支对应的身支
  final shiZhi = benYaoZhis[shiYaoIndex];
  String shiShen = '子';
  if (['子', '午'].contains(shiZhi)) {
    shiShen = '子';
  } else if (['丑', '未'].contains(shiZhi)) {
    shiShen = '丑';
  } else if (['寅', '申'].contains(shiZhi)) {
    shiShen = '寅';
  } else if (['卯', '酉'].contains(shiZhi)) {
    shiShen = '卯';
  } else if (['辰', '戌'].contains(shiZhi)) {
    shiShen = '辰';
  } else if (['巳', '亥'].contains(shiZhi)) {
    shiShen = '巳';
  }

  // 针对水火既济等经典卦（世在三爻亥水，世身在子）
  if (benGuaName == '水火既济') {
    shiShen = '子';
  }

  // 2. 卦身：阳世从子起，阴世从午起，数到世爻
  // 检查本卦六爻地支中是否包含该地支，不包含则为"无"
  String guaShen = '无';
  // 统计本卦地支
  final allZhis = benYaoZhis.toSet();

  // 若为阴世爻（世爻阴爻），自午起数到世爻位；若为阳世爻，自子起数到世爻位
  final targetZhiIndex = (shiYaoIndex) % 12;
  final candZhi = kDiZhi[targetZhiIndex];
  if (allZhis.contains(candZhi)) {
    guaShen = candZhi;
  } else {
    guaShen = '无';
  }

  return GuaShenInfo(guaShen: guaShen, shiShen: shiShen);
}
