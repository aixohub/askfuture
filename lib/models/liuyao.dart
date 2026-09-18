/// 六爻装卦（纳甲、六亲、六神、世应、伏神、旬空）与复制文本生成。
///
/// 官方 `guaxiang` 由服务端下发（`zhugua.yaos[i]` 内含 liushen / liuqing /
/// zhi / wuxing / shiying / fushen 等字段，bundle 内无静态装卦表），
/// 此处按传统六爻装卦法在本地推导，用于卦象图展示与"复制"文本：
///   * 纳甲：八卦内三爻 / 外三爻干支（乾内甲子…壬戌 等）
///   * 六亲：以卦宫五行为"我"，同我兄弟、生我父母、我生子孙、克我官鬼、我克妻财
///   * 六神：按日干起（甲乙青龙、丙丁朱雀、戊勾陈、己螣蛇、庚辛白虎、壬癸玄武）
///   * 世应：按八宫卦序（首卦世六应三 … 游魂世四应一、归魂世三应六）
///   * 伏神：本宫首卦中不上卦的六亲，伏于本卦同爻位之下
///
/// 复制文本格式 1:1 对齐官方模块 2449 `copyPaiPanInfo`。
library;

import 'divination_models.dart';
import 'ganzhi.dart';
import 'hexagram.dart';

/// 卦宫五行。
const Map<String, String> kGongWuXing = <String, String>{
  '乾': '金',
  '兑': '金',
  '离': '火',
  '震': '木',
  '巽': '木',
  '坎': '水',
  '艮': '土',
  '坤': '土',
};

/// 地支五行。
const Map<String, String> kZhiWuXing = <String, String>{
  '子': '水',
  '丑': '土',
  '寅': '木',
  '卯': '木',
  '辰': '土',
  '巳': '火',
  '午': '火',
  '未': '土',
  '申': '金',
  '酉': '金',
  '戌': '土',
  '亥': '水',
};

/// 五行相生：木生火、火生土、土生金、金生水、水生木。
const Map<String, String> _sheng = <String, String>{
  '木': '火',
  '火': '土',
  '土': '金',
  '金': '水',
  '水': '木',
};

/// 五行相克：木克土、土克水、水克火、火克金、金克木。
const Map<String, String> _ke = <String, String>{
  '木': '土',
  '土': '水',
  '水': '火',
  '火': '金',
  '金': '木',
};

/// 纳甲：八卦内三爻（一爻→三爻）干支。
const Map<String, List<String>> kNajiaInner = <String, List<String>>{
  '乾': <String>['甲子', '甲寅', '甲辰'],
  '坤': <String>['乙未', '乙巳', '乙卯'],
  '震': <String>['庚子', '庚寅', '庚辰'],
  '巽': <String>['辛丑', '辛亥', '辛酉'],
  '坎': <String>['戊寅', '戊辰', '戊午'],
  '离': <String>['己卯', '己丑', '己亥'],
  '艮': <String>['丙辰', '丙午', '丙申'],
  '兑': <String>['丁巳', '丁卯', '丁丑'],
};

/// 纳甲：八卦外三爻（四爻→六爻）干支。
const Map<String, List<String>> kNajiaOuter = <String, List<String>>{
  '乾': <String>['壬午', '壬申', '壬戌'],
  '坤': <String>['癸丑', '癸亥', '癸酉'],
  '震': <String>['庚午', '庚申', '庚戌'],
  '巽': <String>['辛未', '辛巳', '辛卯'],
  '坎': <String>['戊申', '戊戌', '戊子'],
  '离': <String>['己酉', '己未', '己巳'],
  '艮': <String>['丙戌', '丙子', '丙寅'],
  '兑': <String>['丁亥', '丁酉', '丁未'],
};

/// 六冲卦。
const Set<String> kLiuChongGua = <String>{
  '乾为天', '兑为泽', '离为火', '震为雷', '巽为风', '坎为水', '艮为山', '坤为地',
  '天雷无妄', '雷天大壮',
};

/// 六合卦。
const Set<String> kLiuHeGua = <String>{
  '地天泰', '天地否', '雷地豫', '地雷复', '泽水困', '水泽节', '火山旅', '山火贲',
};

/// 八宫卦序（首卦、一世…五世、游魂、归魂）对应的世爻位置。
const List<int> _shiPositions = <int>[6, 1, 2, 3, 4, 5, 4, 3];

/// 六神顺序（自初爻起）。
const List<String> kLiuShenOrder = <String>['青龙', '朱雀', '勾陈', '螣蛇', '白虎', '玄武'];

/// 宫内八名（六爻参考实现 `YaoUtil.GongNeiBaGuaMingChen`）：
/// 纯卦 / 初世 / 二世 / 三世 / 四世 / 五世 / 游魂 / 归魂。
const List<String> kGongNeiNames = <String>[
  '纯卦', '初世', '二世', '三世', '四世', '五世', '游魂', '归魂',
];

/// 卦的世应关系（六爻参考实现 `YaoUtil.Array64Gua[i][3]`）。
///
/// 索引 `i` 对应卦码 = `i` 的 6 位二进制（`[六爻…一爻]`，1 阳 0 阴），
/// 例如 `111111`（乾为天）→ `六冲比`、`010111`（水天需）→ `世生应`。
const List<String> _kRelationByIndex = <String>[
  '六冲克', '六合克', '世克应', '应生世', '世克应', '应克世', '世应比', '六合生', // 上坤
  '六合生', '六冲比', '世生应', '世应比', '世生应', '应生世', '应生世', '六冲克', // 上震
  '应生世', '世克应', '六冲克', '六合克', '应生世', '世应比', '世克应', '世生应', // 上坎
  '世克应', '世应比', '六合生', '六冲比', '应生世', '世生应', '应克世', '世克应', // 上兑
  '世克应', '世克应', '应克世', '应克世', '六冲克', '六合克', '世克应', '应生世', // 上艮
  '应生世', '应克世', '世应比', '应克世', '六合生', '六冲克', '应克世', '应生世', // 上离
  '世应比', '应克世', '世生应', '应生世', '世克应', '应生世', '六冲克', '应克世', // 上巽
  '六合克', '六冲克', '应生世', '世克应', '世克应', '应克世', '应生世', '六冲比', // 上乾
];

/// 由卦码取世应关系；卦码非法时返回空串。
String relationOfGuaCode(String code) {
  if (code.length != 6) return '';
  final index = int.tryParse(code, radix: 2);
  if (index == null || index < 0 || index >= _kRelationByIndex.length) return '';
  return _kRelationByIndex[index];
}

/// 伏神。
class FuShen {
  final String liuQin;
  final String gan;
  final String zhi;

  const FuShen({required this.liuQin, required this.gan, required this.zhi});

  String get wuXing => kZhiWuXing[zhi] ?? '';

  /// 例：父母甲寅木
  String get detail => '$liuQin$gan$zhi$wuXing';
}

/// 一爻的装卦结果。
class YaoInfo {
  /// 爻位 1~6。
  final int position;
  final String liuShen;
  final String liuQin;
  final String gan;
  final String zhi;
  final bool isYang;
  final bool isMoving;

  /// 1 世爻、2 应爻、0 无。
  final int shiYing;
  final FuShen? fuShen;

  const YaoInfo({
    required this.position,
    required this.liuShen,
    required this.liuQin,
    required this.gan,
    required this.zhi,
    required this.isYang,
    required this.isMoving,
    required this.shiYing,
    this.fuShen,
  });

  String get ganZhi => '$gan$zhi';

  String get wuXing => kZhiWuXing[zhi] ?? '';

  /// 例：父母甲寅木
  String get detail => '$liuQin$ganZhi$wuXing';

  /// 动爻标记：阳动 O、阴动 X。
  String get moveMark => isMoving ? (isYang ? 'O' : 'X') : '';

  String get shiYingText => shiYing == 1 ? '世' : (shiYing == 2 ? '应' : '');
}

/// 一卦的装卦结果。
class GuaZhuang {
  final DivineGua gua;

  /// 在所属宫中的序号：0 首卦、1~5 一世~五世、6 游魂、7 归魂。
  final int palaceIndex;

  /// 六爻，自下而上（索引 0 为初爻）。
  final List<YaoInfo> yaos;

  const GuaZhuang({required this.gua, required this.palaceIndex, required this.yaos});

  String get gong => gua.palace;

  String get gongName => gua.palace.replaceAll('宫', '');

  String get wuXing => kGongWuXing[gongName] ?? '';

  String get youHunGuiHun => palaceIndex == 6 ? '游魂' : (palaceIndex == 7 ? '归魂' : '');

  /// 宫内八名：纯卦 / 初世 / 二世 / 三世 / 四世 / 五世 / 游魂 / 归魂。
  String get gongNeiName =>
      palaceIndex >= 0 && palaceIndex < kGongNeiNames.length
          ? kGongNeiNames[palaceIndex]
          : '';

  /// 世应关系（如 `六冲比` / `世生应` / `世应比`），取自六爻参考实现。
  String get relation => relationOfGuaCode(gua.code);

  /// 六爻参考实现的卦描述：宫内八名 + 世应关系，如 `坤宫游魂·世生应`。
  String get desc => '$gong$gongNeiName·$relation';

  String get chongHe => kLiuChongGua.contains(gua.name)
      ? '六冲'
      : (kLiuHeGua.contains(gua.name) ? '六合' : '');

  int get shiPosition => _shiPositions[palaceIndex];

  int get yingPosition => ((shiPosition + 2) % 6) + 1;

  /// 官方卦象图标题格式：`水火既济 (坎)`、`地雷复 (坤-六合)`、`乾为天 (乾-六冲)`。
  String get title {
    final buffer = StringBuffer('${gua.name} ($gongName');
    if (chongHe.isNotEmpty) buffer.write('-$chongHe');
    buffer.write(')');
    return buffer.toString();
  }
}

/// 一次起卦的完整排盘（本卦 + 变卦 + 四柱旬空）。
class LiuYaoPan {
  final GuaZhuang ben;
  final GuaZhuang bian;
  final SiZhu siZhu;
  final String xunKong;
  final DateTime castTime;

  const LiuYaoPan({
    required this.ben,
    required this.bian,
    required this.siZhu,
    required this.xunKong,
    required this.castTime,
  });
}

String _liuQinOf(String gongWuXing, String yaoWuXing) {
  if (gongWuXing == yaoWuXing) return '兄弟';
  if (_sheng[yaoWuXing] == gongWuXing) return '父母';
  if (_sheng[gongWuXing] == yaoWuXing) return '子孙';
  if (_ke[yaoWuXing] == gongWuXing) return '官鬼';
  if (_ke[gongWuXing] == yaoWuXing) return '妻财';
  return '';
}

int _liuShenStart(String dayGan) {
  switch (dayGan) {
    case '甲':
    case '乙':
      return 0;
    case '丙':
    case '丁':
      return 1;
    case '戊':
      return 2;
    case '己':
      return 3;
    case '庚':
    case '辛':
      return 4;
    default:
      return 5;
  }
}

/// 取某八卦宫的首卦（八纯卦）。
DivineGua _palaceHeadGua(String gong) =>
    kDivineNameData.firstWhere((gua) => gua.palace == gong);

/// 单卦装卦：纳甲 + 六亲 + 六神 + 世应（伏神由 [buildLiuYaoPan] 统一处理）。
///
/// [yaoValues] 为六爻爻值（自下而上，0 少阴 / 1 少阳 / 2 老阴 / 3 老阳），
/// 省略时表示六爻皆静。
GuaZhuang _zhuang(DivineGua gua, GanZhi dayGz, {List<int>? yaoValues}) {
  final code = gua.code; // [六爻 … 一爻]
  final upper = kTrigramNames[code.substring(0, 3)]!;
  final lower = kTrigramNames[code.substring(3)]!;
  final gongName = gua.palace.replaceAll('宫', '');
  final gongWuXing = kGongWuXing[gongName]!;
  final palaceIndex = kDivineNameData
      .where((item) => item.palace == gua.palace)
      .toList()
      .indexWhere((item) => item.code == gua.code);
  final shiPosition = _shiPositions[palaceIndex < 0 ? 0 : palaceIndex];
  final yingPosition = ((shiPosition + 2) % 6) + 1;
  final liuShenStart = _liuShenStart(dayGz.gan);

  final yaos = <YaoInfo>[];
  for (var i = 0; i < 6; i++) {
    final isInner = i < 3;
    final ganZhi = (isInner ? kNajiaInner[lower]! : kNajiaOuter[upper]!)[i % 3];
    final gan = ganZhi.substring(0, 1);
    final zhi = ganZhi.substring(1);
    final isYang = code[5 - i] == '1';
    final isMoving =
        yaoValues == null ? false : yaoTypeOf(yaoValues[i]).isMoving;
    final shiYing = (i + 1) == shiPosition ? 1 : ((i + 1) == yingPosition ? 2 : 0);
    yaos.add(
      YaoInfo(
        position: i + 1,
        liuShen: kLiuShenOrder[(liuShenStart + i) % 6],
        liuQin: _liuQinOf(gongWuXing, kZhiWuXing[zhi]!),
        gan: gan,
        zhi: zhi,
        isYang: isYang,
        isMoving: isMoving,
        shiYing: shiYing,
        fuShen: null,
      ),
    );
  }

  return GuaZhuang(gua: gua, palaceIndex: palaceIndex < 0 ? 0 : palaceIndex, yaos: yaos);
}

/// 组装完整排盘。
LiuYaoPan buildLiuYaoPan({required GuaResult result, required DateTime castTime}) {
  final siZhu = computeSiZhu(castTime);
  final ben = _withFuShen(
    _zhuang(result.benGua, siZhu.day, yaoValues: result.yaoValues),
    siZhu.day,
  );
  final bian = _withFuShen(_zhuang(result.bianGua, siZhu.day), siZhu.day);
  return LiuYaoPan(
    ben: ben,
    bian: bian,
    siZhu: siZhu,
    xunKong: xunKongOf(siZhu.day),
    castTime: castTime,
  );
}

/// 补全伏神：本宫首卦（八纯卦）中不出现在本卦的六亲，伏于同爻位之下。
///
/// 与参考实现 `GuaExecServiceImpl.genFullLiuYaoPaiPan()` 一致：本卦与变卦
/// **各自**按自身卦宫与六亲集合计算伏神。
GuaZhuang _withFuShen(GuaZhuang gua, GanZhi dayGz) {
  final head = _palaceHeadGua(gua.gong);
  final headZhuang = _zhuang(head, dayGz);
  final present = gua.yaos.map((yao) => yao.liuQin).toSet();
  return GuaZhuang(
    gua: gua.gua,
    palaceIndex: gua.palaceIndex,
    yaos: <YaoInfo>[
      for (var i = 0; i < gua.yaos.length; i++)
        YaoInfo(
          position: gua.yaos[i].position,
          liuShen: gua.yaos[i].liuShen,
          liuQin: gua.yaos[i].liuQin,
          gan: gua.yaos[i].gan,
          zhi: gua.yaos[i].zhi,
          isYang: gua.yaos[i].isYang,
          isMoving: gua.yaos[i].isMoving,
          shiYing: gua.yaos[i].shiYing,
          fuShen: present.contains(headZhuang.yaos[i].liuQin)
              ? null
              : FuShen(
                  liuQin: headZhuang.yaos[i].liuQin,
                  gan: headZhuang.yaos[i].gan,
                  zhi: headZhuang.yaos[i].zhi,
                ),
        ),
    ],
  );
}

// ------------------------------------------------------------------ 复制文本

String _simplifyLiuShen(String value) {
  switch (value) {
    case '青龙':
      return '龙';
    case '白虎':
      return '虎';
    case '朱雀':
      return '雀';
    case '玄武':
      return '玄';
    case '螣蛇':
      return '蛇';
    case '勾陈':
      return '勾';
    default:
      return '';
  }
}

String _simplifyLiuQin(String value) {
  switch (value) {
    case '兄弟':
      return '兄';
    case '子孙':
      return '孙';
    case '父母':
      return '父';
    case '妻财':
      return '财';
    case '官鬼':
      return '官';
    default:
      return '';
  }
}

/// 生成"复制"文本，格式 1:1 对齐官方模块 2449 `copyPaiPanInfo`。
String buildCopyText({
  required LiuYaoPan pan,
  required String titleText,
  required String question,
}) {
  final time = pan.castTime;
  final buffer = StringBuffer();
  buffer.writeln(titleText);
  buffer.writeln('${time.year}年${time.month}月${time.day}日 ${time.hour}:${time.minute}');
  buffer.writeln('占问：$question');
  buffer.writeln(
    '${pan.siZhu.year.text}年 ${pan.siZhu.month.text}月 ${pan.siZhu.day.text}日 '
    '${pan.siZhu.hour.text}时 (旬空：${pan.xunKong})',
  );
  buffer.writeln('本卦：${pan.ben.gua.name}/${pan.ben.gong}${pan.ben.youHunGuiHun}${pan.ben.chongHe}');
  buffer.writeln('变卦：${pan.bian.gua.name}/${pan.bian.gong}${pan.bian.youHunGuiHun}${pan.bian.chongHe}');

  for (var i = 0; i < 6; i++) {
    final yao = pan.ben.yaos[i];
    final bianYao = pan.bian.yaos[i];
    final row = StringBuffer();
    row.write('${_simplifyLiuShen(yao.liuShen)} ');
    row.write(
      yao.fuShen == null
          ? '　　 '
          : '${_simplifyLiuQin(yao.fuShen!.liuQin)}${yao.fuShen!.zhi} ',
    );
    row.write('${_simplifyLiuQin(yao.liuQin)}${yao.zhi} ');
    row.write(yao.isYang ? '—' : '--');
    row.write(yao.isMoving ? (yao.isYang ? ' o ' : ' x ') : '   ');
    row.write(yao.shiYing == 1 ? '世 ' : (yao.shiYing == 2 ? '应 ' : '　 '));
    row.write('${_simplifyLiuQin(bianYao.liuQin)}${bianYao.zhi} ');
    row.write(bianYao.isYang ? '—' : '--');
    row.write(bianYao.shiYing == 1 ? ' 世' : (bianYao.shiYing == 2 ? ' 应' : ' 　'));
    buffer.write(row.toString());
    if (i != 5) buffer.write('\n');
  }
  return buffer.toString();
}
