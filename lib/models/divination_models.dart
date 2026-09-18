/// 起卦领域模型。
///
/// 本文件中的常量全部 1:1 对齐官方 RN bundle（`RN0615.app/main.jsbundle`）
/// 中对应的模块，禁止随意改动文案与取值：
///   * 占事分类   → 模块 2419 `typeDataNew`
///   * 占事类型名 → 模块 2325 `typeData`（顶层分类名）
///   * 起卦方式   → 模块 2501 排盘方式选择页内的方式列表
///   * 爻定义     → 模块 2501 `qiguaMap` / `qiguaMapStr`
///   * 手工指定   → 模块 430 `Config.yaoMap`
library;

/// 占事分类（首页"占事分类"网格）。
class DivinationCategory {
  final String name;
  final int value;

  const DivinationCategory(this.name, this.value);
}

/// 占事分类，共 16 项（已移除「测手机号」与「消息联络」）。
const List<DivinationCategory> kDivinationCategories = <DivinationCategory>[
  DivinationCategory('疾病医药', 7),
  DivinationCategory('找寻失物', 13),
  DivinationCategory('求职应聘', 15),
  DivinationCategory('婚姻情感', 3),
  DivinationCategory('单身姻缘', 30),
  DivinationCategory('股票期货', 26),
  DivinationCategory('财运生意', 4),
  DivinationCategory('事业官运', 1),
  DivinationCategory('怀孕子女', 5),
  DivinationCategory('学业考试', 6),
  DivinationCategory('年运终身', 9),
  DivinationCategory('短期运势', 10),
  DivinationCategory('官司诉讼', 11),
  DivinationCategory('家宅风水', 18),
  DivinationCategory('出行平安', 12),
  DivinationCategory('其它杂占', 28),
];

/// 起卦方式。
class QiGuaMethod {
  final String name;
  final int value;

  const QiGuaMethod(this.name, this.value);
}

/// 起卦方式取值（服务端 `qigua` 字段）：
/// 1 手工指定、2 在线起卦、3 单数起卦、4 双数起卦、
/// 5 时间起卦、6 电脑自动、8 卦名起卦、9 汉字起卦。
const int kQiGuaTypeManual = 1;
const int kQiGuaTypeOnline = 2;
const int kQiGuaTypeSingleNumber = 3;
const int kQiGuaTypeDoubleNumber = 4;
const int kQiGuaTypeTime = 5;
const int kQiGuaTypeAuto = 6;
const int kQiGuaTypeGuaName = 8;
const int kQiGuaTypeChinese = 9;

/// 展示顺序对齐模块 2501 的 FlatList 数据源。
const List<QiGuaMethod> kQiGuaMethods = <QiGuaMethod>[
  QiGuaMethod('在线起卦', kQiGuaTypeOnline),
  QiGuaMethod('电脑自动', kQiGuaTypeAuto),
  QiGuaMethod('手工指定', kQiGuaTypeManual),
  QiGuaMethod('时间起卦', kQiGuaTypeTime),
  QiGuaMethod('单数起卦', kQiGuaTypeSingleNumber),
  QiGuaMethod('双数起卦', kQiGuaTypeDoubleNumber),
  QiGuaMethod('汉字起卦', kQiGuaTypeChinese),
  QiGuaMethod('卦名起卦', kQiGuaTypeGuaName),
];

/// 占事类型名（模块 2325 顶层分类，首页选中分类经换算后用于展示）。
const Map<int, String> kQueTypeNames = <int, String>{
  0: '忽略',
  2: '感情/婚姻(男)',
  3: '感情/婚姻(女)',
  4: '财运/生意',
  25: '号码预测',
  1: '事业官运',
  10: '周运势/短期运',
  9: '终身运/年运',
  6: '学业/考试',
  28: '杂占/其它',
  15: '求职应聘',
  7: '疾病/医药',
  26: '股票期货外汇',
  5: '怀孕/子女缘',
  11: '官司诉讼',
  18: '家宅风水',
  13: '找寻失物',
  12: '出行平安',
  27: '姓名',
  8: '天气',
  17: '消息联络',
  16: '行人归来',
};

String queTypeNameOf(int value) => kQueTypeNames[value] ?? '';

/// 爻（0 少阴、1 少阳、2 老阴、3 老阳），对齐模块 2501 `qiguaMap`。
class YaoType {
  final int value;
  final String name;

  /// 是否为阳爻（老阳、少阳为阳）。
  final bool isYang;

  /// 是否为动爻（老阳、老阴为动）。
  final bool isMoving;

  /// 动爻标记（"x" 老阴 / "o" 老阳），静爻为空字符串。
  final String mark;

  /// 铜钱正反说明，例如 "(1正2背)"。
  final String detail;

  const YaoType(this.value, this.name, this.isYang, this.isMoving, this.mark, this.detail);
}

/// 顺序与官方 `getYaoData()` 的查找表
/// `["1正2背","2正1背","3正0背","0正3背"]` 完全一致。
const List<YaoType> kYaoTypes = <YaoType>[
  YaoType(0, '少阴', false, false, '', '(1正2背)'),
  YaoType(1, '少阳', true, false, '', '(2正1背)'),
  YaoType(2, '老阴', false, true, 'x', '(3正0背)'),
  YaoType(3, '老阳', true, true, 'o', '(0正3背)'),
];

YaoType yaoTypeOf(int value) => kYaoTypes[value < 0 || value > 3 ? 0 : value];

/// 爻的简写文案，如 "少阳(2正1背)"。
String yaoShortLabel(int value) {
  final yao = yaoTypeOf(value);
  return '${yao.name}${yao.detail}';
}

/// 手工指定下拉选项，对齐模块 430 `Config.yaoMap`。
class ManualYaoOption {
  final String label;

  /// 对应的爻值；`null` 表示"请选择"。
  final int? yaoValue;

  const ManualYaoOption(this.label, this.yaoValue);
}

const List<ManualYaoOption> kManualYaoOptions = <ManualYaoOption>[
  ManualYaoOption('请选择', null),
  ManualYaoOption('老阴 ██    ██ x （3正0背）', 2),
  ManualYaoOption('老阳 █████ o （0正3背）', 3),
  ManualYaoOption('少阳 █████    （2正1背）', 1),
  ManualYaoOption('少阴 ██    ██    （1正2背）', 0),
];

/// 爻名，索引 0 为一爻（初爻）。
const List<String> kYaoNames = <String>['一爻', '二爻', '三爻', '四爻', '五爻', '六爻'];

/// 官方 `Config.yaoGuaProIdSet`，首页起卦默认带入的产品 ID。
const String kYaoGuaProIdSet = '169';

/// 首页填写完成后交给"排盘方式选择页"的参数。
///
/// 字段对齐首页 `_checkInput()` 组装的对象
/// `{sex, question, quetitle, quetype, type}`。
class QiGuaRequest {
  /// 1 男 / 0 女。
  final int sex;

  /// 求测标题（占卜问题）。
  final String quetitle;

  /// 占事分类（已按官方规则换算：30 → 3，婚姻情感 + 男 → 2）。
  final int quetype;

  /// 求测备注，首页入口固定为空串。
  final String remark;

  /// 产品 ID（官方 `Config.yaoGuaProIdSet`）。
  final String productId;

  const QiGuaRequest({
    required this.sex,
    required this.quetitle,
    required this.quetype,
    this.remark = '',
    this.productId = kYaoGuaProIdSet,
  });

  String get sexName => sex == 1 ? '男' : '女';

  String get quetypeName => queTypeNameOf(quetype);
}

/// 三次抛掷铜钱得到的结果，复刻模块 1897 `coinYaogua()`：
/// 每枚铜钱 1 为正（字/面）、0 为背；三枚求和后
/// 0 正 → 老阳(3)、1 正 → 少阴(0)、2 正 → 少阳(1)、3 正 → 老阴(2)。
class CoinCastResult {
  /// 三枚铜钱的正反（1 正 / 0 背）。
  final List<int> coins;

  /// 爻值 0~3。
  final int yaoValue;

  const CoinCastResult(this.coins, this.yaoValue);

  static CoinCastResult fromCoins(int a, int b, int c) {
    final sum = a + b + c;
    final value = sum == 0 ? 3 : sum - 1;
    return CoinCastResult(<int>[a, b, c], value);
  }
}
