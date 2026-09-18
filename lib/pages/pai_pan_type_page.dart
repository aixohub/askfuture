import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/divination_models.dart';
import '../models/hexagram.dart';
import '../models/lunar_calendar.dart';
import '../widgets/app_toast.dart';
import '../widgets/copper_coin.dart';
import '../widgets/date_time_picker.dart';
import '../widgets/yao_line.dart';
import 'gua_xiang_page.dart';

/// 排盘方式选择页（官方路由名 `paiPanType`，模块 2501）。
///
/// 首页"开 始 起 卦"按钮携带 `{sex, question, quetitle, quetype, type}`
/// 跳转到本页；本页负责：
///   1. 展示占事信息（占卜问题 / 占事分类 / 卦主性别 / 起卦时间）
///   2. 选择 8 种起卦方式之一
///   3. 校验输入并起卦（官方提交 `yjhapp/qigua`，本地按同一规则推卦）
class PaiPanTypePage extends StatefulWidget {
  final QiGuaRequest request;

  const PaiPanTypePage({super.key, required this.request});

  @override
  State<PaiPanTypePage> createState() => _PaiPanTypePageState();
}

/// 一爻的摇卦记录：`index` 为爻序（0 一爻 … 5 六爻）。
class _YaoRecord {
  final int index;
  final int value;

  const _YaoRecord(this.index, this.value);
}

class _PaiPanTypePageState extends State<PaiPanTypePage>
    with SingleTickerProviderStateMixin {
  /// 当前起卦方式。
  ///
  /// 官方 `paiPanType` 页默认"在线起卦"(2)；本工程按需求默认"手工指定"(1)，
  /// 即进入排盘页即可直接指定六爻起卦。
  int _qiGuaType = kQiGuaTypeManual;

  /// 起卦时间，官方默认取当前时间。
  late DateTime _castingTime;

  // ---- 在线起卦 ----
  int _num = 0;
  bool _isShaking = false;
  final List<_YaoRecord> _records = <_YaoRecord>[];
  late final AnimationController _shakeController;
  final math.Random _random = math.Random();
  List<bool> _coins = <bool>[true, true, true];

  // ---- 手工指定 ----
  /// 索引 0 为一爻，值对应 `kManualYaoOptions`。
  final List<int?> _manualYao = List<int?>.filled(6, null);

  // ---- 数字 / 汉字 / 卦名起卦 ----
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _number1Controller = TextEditingController();
  final TextEditingController _number2Controller = TextEditingController();
  final TextEditingController _hanziController = TextEditingController();
  String? _benGuaCode;
  String? _bianGuaCode;

  @override
  void initState() {
    super.initState();
    _castingTime = DateTime.now();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _numberController.dispose();
    _number1Controller.dispose();
    _number2Controller.dispose();
    _hanziController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    return CastingTimeField.format(dt);
  }

  /// `_setQiGuaTypeId()`：切换起卦方式时清空上一方式的输入。
  void _setQiGuaType(int value) {
    if (value == _qiGuaType) return;
    _clearInput();
    setState(() => _qiGuaType = value);
  }

  void _clearInput() {
    _shakeController.stop();
    _num = 0;
    _isShaking = false;
    _records.clear();
    _coins = <bool>[true, true, true];
    for (var i = 0; i < _manualYao.length; i++) {
      _manualYao[i] = null;
    }
    _numberController.clear();
    _number1Controller.clear();
    _number2Controller.clear();
    _hanziController.clear();
    _benGuaCode = null;
    _bianGuaCode = null;
  }

  // ---------------------------------------------------------------- 在线起卦

  /// 点击铜钱：未摇时开始摇动，摇动中再点击则停止并产生一爻。
  void _onTapCoins() {
    if (_num >= 6) {
      AppToast.show(context, '请开始起卦');
      return;
    }
    if (_isShaking) {
      _stopCoin();
    } else {
      _startCoin();
    }
  }

  void _startCoin() {
    _shakeController.repeat(reverse: true);
    setState(() => _isShaking = true);
  }

  /// 复刻模块 1897 `coinYaogua()`：三枚铜钱各随机正/背，
  /// 0 正 → 老阳、1 正 → 少阴、2 正 → 少阳、3 正 → 老阴。
  void _stopCoin() {
    _shakeController.stop();
    final result = CoinCastResult.fromCoins(
      _random.nextInt(2),
      _random.nextInt(2),
      _random.nextInt(2),
    );
    setState(() {
      _isShaking = false;
      _coins = result.coins.map((c) => c == 1).toList();
      _records.add(_YaoRecord(_num, result.yaoValue));
      _num += 1;
    });
  }

  // --------------------------------------------------------------- 起卦入口

  void _onQiGua() {
    switch (_qiGuaType) {
      case kQiGuaTypeOnline:
        if (_records.length != 6) {
          AppToast.show(context, '摇卦数据不正确，请重新摇卦！');
          _clearInput();
          setState(() {});
          return;
        }
        _cast(buildGuaResult(_onlineYaoValues()));
        return;
      case kQiGuaTypeManual:
        if (_manualYao.any((v) => v == null)) {
          AppToast.show(context, '摇卦不能为空，每一次摇卦都需要记录~');
          return;
        }
        _cast(buildGuaResult(_manualYao.cast<int>()));
        return;
      case kQiGuaTypeAuto:
        // 官方：`Math.round(3 * Math.random())` 连取 6 次。
        _cast(buildGuaResult(
          List<int>.generate(6, (_) => (3 * _random.nextDouble()).round()),
        ));
        return;
      case kQiGuaTypeTime:
        if (_castingTime.isAfter(DateTime.now())) {
          AppToast.show(context, '您选择的时间大于当前时间');
          return;
        }
        _cast(guaFromTime(_castingTime));
        return;
      case kQiGuaTypeSingleNumber:
        final text = _numberController.text.trim();
        if (text.isEmpty) {
          AppToast.show(context, '请输入一组数字');
          return;
        }
        if (!RegExp(r'^[0-9]{1,10}$').hasMatch(text)) {
          AppToast.show(context, '请输入纯数字(10位以内)');
          return;
        }
        _cast(guaFromSingleNumber(int.parse(text), _castingTime));
        return;
      case kQiGuaTypeDoubleNumber:
        final first = _number1Controller.text.trim();
        final second = _number2Controller.text.trim();
        if (first.isEmpty) {
          AppToast.show(context, '请输入第一组数字');
          return;
        }
        if (second.isEmpty) {
          AppToast.show(context, '请输入第二组数字');
          return;
        }
        final pattern = RegExp(r'^[0-9]{1,10}$');
        if (!pattern.hasMatch(first) || !pattern.hasMatch(second)) {
          AppToast.show(context, '请输入纯数字(10位以内)');
          return;
        }
        _cast(guaFromDoubleNumber(int.parse(first), int.parse(second)));
        return;
      case kQiGuaTypeChinese:
        final text = _hanziController.text.trim();
        if (text.isEmpty) {
          AppToast.show(context, '请输入起卦汉字');
          return;
        }
        if (!RegExp(r'^[\u4e00-\u9fa5]{1,10}$').hasMatch(text)) {
          AppToast.show(context, '请输入纯汉字(10位以内)');
          return;
        }
        _cast(guaFromChinese(text));
        return;
      case kQiGuaTypeGuaName:
        final ben = _benGuaCode;
        final bian = _bianGuaCode;
        if (ben == null || ben.isEmpty) {
          AppToast.show(context, '请选择本卦卦名');
          return;
        }
        if (bian == null || bian.isEmpty) {
          AppToast.show(context, '请选择变卦卦名');
          return;
        }
        final result = guaFromGuaCodes(ben, bian);
        if (result == null) {
          AppToast.show(context, '起卦失败，请重试');
          return;
        }
        _cast(result);
        return;
      default:
        return;
    }
  }

  /// 摇卦记录按爻序（一爻 → 六爻，自下而上）整理为爻值数组。
  List<int> _onlineYaoValues() {
    final sorted = List<_YaoRecord>.from(_records)
      ..sort((a, b) => a.index.compareTo(b.index));
    return sorted.map((r) => r.value).toList();
  }

  void _cast(GuaResult result) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GuaXiangPage(
          request: widget.request,
          result: result,
          methodName: _methodName(_qiGuaType),
          castingTime: _castingTime,
          inputSummary: _inputSummary(_qiGuaType, result),
        ),
      ),
    );
  }

  String _methodName(int type) =>
      kQiGuaMethods.firstWhere((m) => m.value == type).name;

  String _inputSummary(int type, GuaResult result) {
    switch (type) {
      case kQiGuaTypeOnline:
        final sorted = List<_YaoRecord>.from(_records)
          ..sort((a, b) => a.index.compareTo(b.index));
        return sorted
            .map((r) => '${kYaoNames[r.index]} ${yaoTypeOf(r.value).name}')
            .join('，');
      case kQiGuaTypeManual:
        return _manualYao
            .asMap()
            .entries
            .map((e) => '${kYaoNames[e.key]} ${yaoTypeOf(e.value!).name}')
            .join('，');
      case kQiGuaTypeTime:
        return '起卦时间 ${_formatDateTime(_castingTime)}';
      case kQiGuaTypeSingleNumber:
        return '数字起卦 ${_numberController.text.trim()}';
      case kQiGuaTypeDoubleNumber:
        return '数字起卦 ${_number1Controller.text.trim()}、${_number2Controller.text.trim()}';
      case kQiGuaTypeChinese:
        return '汉字起卦 ${_hanziController.text.trim()}';
      case kQiGuaTypeGuaName:
        return '本卦 ${result.benGua.name}，变卦 ${result.bianGua.name}';
      default:
        return '电脑自动起卦';
    }
  }

  // ------------------------------------------------------------------ 渲染

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1CB49D),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '排盘方式选择',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildInfoCard(),
            ..._buildMethodPanels(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return _card(
      margin: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _row(
            label: '占卜问题：',
            child: Expanded(
              child: Text(widget.request.quetitle, style: const TextStyle(fontSize: 15)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '占事分类：${widget.request.quetypeName}',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Text(
                    '卦主性别：${widget.request.sexName}',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const Text('起卦时间：', style: TextStyle(fontSize: 15)),
                const SizedBox(width: 6),
                Expanded(
                  child: CastingTimeField(
                    fieldKey: const Key('castingTimeField'),
                    value: _castingTime,
                    onTap: _pickCastingTime,
                    lunarText: lunarDateOf(_castingTime)?.text,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('起卦方式：', style: TextStyle(fontSize: 15)),
          ),
          const SizedBox(height: 6),
          _buildMethodGrid(),
        ],
      ),
    );
  }

  Widget _buildMethodGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 3;
        final itemWidth = constraints.maxWidth * 0.30;
        final gap = (constraints.maxWidth - itemWidth * columns) / (columns - 1);
        return Wrap(
          spacing: gap,
          runSpacing: 10,
          children: [
            for (final method in kQiGuaMethods)
              SizedBox(
                width: itemWidth,
                height: 30,
                child: GestureDetector(
                  onTap: () => _setQiGuaType(method.value),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _qiGuaType == method.value
                          ? const Color(0xFF00ABAE)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: _qiGuaType == method.value
                          ? null
                          : Border.all(color: const Color(0xFF999999)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      method.name,
                      style: TextStyle(
                        fontSize: 13,
                        color: _qiGuaType == method.value
                            ? Colors.white
                            : const Color(0xFF999999),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  List<Widget> _buildMethodPanels() {
    switch (_qiGuaType) {
      case kQiGuaTypeOnline:
        return _onlinePanels();
      case kQiGuaTypeManual:
        return _manualPanels();
      case kQiGuaTypeAuto:
        return [
          _panel(
            title: '电脑自动',
            children: [
              const _SectionTip('点击下方按钮，系统自动起卦'),
              const SizedBox(height: 10),
              Center(child: _qiGuaButton()),
            ],
          ),
          _tipCard('电脑自动：请让内心平静，摒除杂念，集中注意力默想自己占卜之事，会更加准确哦！'),
        ];
      case kQiGuaTypeTime:
        return [
          _panel(
            title: '时间起卦',
            children: [
              const _SectionTip('请选择时间'),
              const SizedBox(height: 10),
              CastingTimeField(
                fieldKey: const Key('castingTimeFieldPanel'),
                value: _castingTime,
                onTap: _pickCastingTime,
                centered: true,
                lunarText: lunarDateOf(_castingTime)?.text,
              ),
              const SizedBox(height: 14),
              Center(child: _qiGuaButton()),
            ],
          ),
          _tipCard('起卦原理：\n1、（年+月+日）除以８取余数做上卦；\n'
              '2、（年+月+日+时）除以８取余数做下卦；\n'
              '3、（年+月+日+时）除以６取余数做动爻。'),
        ];
      case kQiGuaTypeSingleNumber:
        return [
          _panel(
            title: '单数起卦',
            children: [
              _numberInput(_numberController, '请输入起卦数字', maxLength: 10),
              const SizedBox(height: 14),
              Center(child: _qiGuaButton()),
            ],
          ),
          _tipCard('单数起卦（输入正整数，负数会被自动转为正整数，有小数则小数点后面的部分会被自动删除）'),
        ];
      case kQiGuaTypeDoubleNumber:
        return [
          _panel(
            title: '双数起卦',
            children: [
              _numberInput(_number1Controller, '请输入第一组数字', maxLength: 12),
              const SizedBox(height: 10),
              _numberInput(_number2Controller, '请输入第二组数字', maxLength: 12),
              const SizedBox(height: 14),
              Center(child: _qiGuaButton()),
            ],
          ),
          _tipCard('双数起卦（输入正整数，负数会被自动转为正整数，有小数则小数点后面的部分会被自动删除）'),
        ];
      case kQiGuaTypeChinese:
        return [
          _panel(
            title: '汉字起卦',
            children: [
              TextField(
                controller: _hanziController,
                maxLength: 20,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
                inputFormatters: [LengthLimitingTextInputFormatter(10)],
                decoration: _inputDecoration('请输入2-10位汉字'),
              ),
              const SizedBox(height: 14),
              Center(child: _qiGuaButton()),
            ],
          ),
          _tipCard('姓名（汉字）起卦（可以输入2到10个简体汉字起卦）'),
        ];
      case kQiGuaTypeGuaName:
        return [
          _panel(
            title: '卦名起卦',
            children: [
              Row(
                children: [
                  Expanded(
                    child: _guaNamePicker(
                      title: '本卦',
                      value: _benGuaCode,
                      onChanged: (code) => setState(() => _benGuaCode = code),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _guaNamePicker(
                      title: '变卦',
                      value: _bianGuaCode,
                      onChanged: (code) => setState(() => _bianGuaCode = code),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Center(child: _qiGuaButton()),
            ],
          ),
          _tipCard('卦名起卦：可直接指定本卦与变卦快速起卦，虽然业界持有赞否两论，善用者用之。'),
        ];
      default:
        return const [];
    }
  }

  List<Widget> _onlinePanels() {
    // 官方 `data` 采用 unshift 存放，最新一爻在最前；此处按爻序分组展示。
    final sorted = List<_YaoRecord>.from(_records)
      ..sort((a, b) => b.index.compareTo(a.index));
    return [
      _panel(
        title: '在线起卦',
        children: [
          if (_num != 6)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  '${_isShaking ? '点击铜钱停止第' : '点击铜钱开始第'}${_num + 1}次摇卦',
                  style: const TextStyle(fontSize: 15, color: Color(0xFF555555)),
                ),
              ),
            ),
          GestureDetector(
            onTap: _onTapCoins,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 官方三枚铜钱：摇动中统一显示 yingBi.gif，停手后显示正/反面图片
                Row(
                  children: [
                    for (var i = 0; i < 3; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: CopperCoinWidget(
                          size: 45,
                          isFront: _coins[i],
                          isShaking: _isShaking,
                        ),
                      ),
                  ],
                ),
                if (_num < 6)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    margin: const EdgeInsets.only(left: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00ABAE),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      '开始第${_num + 1}次摇卦',
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          if (_num == 6) ...[
            const SizedBox(height: 12),
            Center(child: _qiGuaButton()),
          ],
          if (_num != 0) ...[
            const SizedBox(height: 16),
            for (final record in sorted)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '${kYaoNames[record.index]}：',
                      style: const TextStyle(fontSize: 16, color: Color(0xFF128ADC)),
                    ),
                    const SizedBox(width: 6),
                    YaoLine(
                      isYang: yaoTypeOf(record.value).isYang,
                      isMoving: yaoTypeOf(record.value).isMoving,
                      mark: yaoTypeOf(record.value).mark,
                      width: 70,
                      thickness: 8,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${yaoTypeOf(record.value).name} ${yaoTypeOf(record.value).detail}',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF555555)),
                    ),
                  ],
                ),
              ),
            if (_num != 6)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '还剩${6 - _num}次',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF888888)),
                ),
              ),
          ],
        ],
      ),
      _tipCard('在线起卦：请让内心平静，摒除杂念，集中注意力默想自己占卜之事，每次摇卦时在心中默数3秒，会更加准确哦！'),
      _tipCard('已经在线下通过硬币或者铜钱摇卦生成了卦象，可选择【手工指定】排盘功能，'
          '输入已经起好的正反信息，查看和解读已生成的卦象。'),
    ];
  }

  List<Widget> _manualPanels() {
    return [
      _panel(
        titleWidget: const Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Text('手工指定', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                '请指定每一爻的属性',
                style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
              ),
            ),
          ],
        ),
        children: [
          // 官方按 六爻 → 一爻 顺序展示
          for (var i = 5; i >= 0; i--) ...[
            Row(
              children: [
                SizedBox(
                  width: 56,
                  child: Text(
                    '${kYaoNames[i]}：',
                    style: const TextStyle(fontSize: 16, color: Color(0xFFE5170C)),
                  ),
                ),
                Expanded(
                  child: _manualYaoField(i),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 6),
          Center(child: _qiGuaButton()),
        ],
      ),
      _richTipCard(<InlineSpan>[
        const TextSpan(text: '此摇卦方式可指定每一爻的阴阳属性，您可用铜钱或者硬币摇卦后，填入在线排盘系统，系统即可为你生成卦象！\n'),
        const TextSpan(text: '正反约定：', style: TextStyle(fontWeight: FontWeight.bold)),
        const TextSpan(text: '铜钱有汉字（或硬币有数字1）的一面为正；铜钱无字 （或硬币的菊花、国徽）图案一面为 背\n'),
        const TextSpan(text: '摇卦顺序：', style: TextStyle(fontWeight: FontWeight.bold)),
        const TextSpan(text: '从下往上，一爻到六爻，依次为第一次到第六次摇卦的正反信息。'),
      ]),
    ];
  }

  /// 单爻选择框：显示的文案与官方 `Config.yaoMap` 一致（简写为"少阳(2正1背)"）。
  Widget _manualYaoField(int index) {
    final value = _manualYao[index];
    return GestureDetector(
      onTap: () => _showYaoPicker(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: value == null ? const Color(0xFFD6D6D6) : const Color(0xFF00ABAE),
          ),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value == null ? '请选择' : yaoShortLabel(value),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: value == null ? const Color(0xFFA3A0A0) : const Color(0xFF333333),
                ),
              ),
            ),
            if (value != null)
              YaoLine(
                isYang: yaoTypeOf(value).isYang,
                isMoving: yaoTypeOf(value).isMoving,
                mark: yaoTypeOf(value).mark,
                width: 34,
                thickness: 6,
              ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF999999)),
          ],
        ),
      ),
    );
  }

  /// 官方使用 react-native-wheel-picker 滚轮选择，
  /// 此处以底部滚轮（ListWheelScrollView + FixedExtentScrollPhysics）对齐同一交互。
  Future<void> _showYaoPicker(int index) async {
    final options = kManualYaoOptions;
    final current = _manualYao[index];
    var selected = 0;
    if (current != null) {
      final found = options.indexWhere((option) => option.yaoValue == current);
      if (found > 0) selected = found;
    }

    final controller = FixedExtentScrollController(initialItem: selected);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SizedBox(
              height: 300,
              child: Column(
                children: [
                  SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(sheetContext, false),
                          child: const Text('取消', style: TextStyle(color: Color(0xFF999999))),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              '${kYaoNames[index]}属性',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(sheetContext, true),
                          child: const Text('确定', style: TextStyle(color: Color(0xFF00ABAE))),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE9E9E9)),
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      controller: controller,
                      itemExtent: 44,
                      diameterRatio: 1.6,
                      perspective: 0.004,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (value) => setSheetState(() => selected = value),
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: options.length,
                        builder: (context, i) => Center(
                          child: Text(
                            options[i].label,
                            style: TextStyle(
                              fontSize: selected == i ? 15 : 14,
                              fontWeight: selected == i ? FontWeight.bold : FontWeight.normal,
                              color: selected == i
                                  ? const Color(0xFF00ABAE)
                                  : const Color(0xFF999999),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    controller.dispose();

    if (confirmed == true && mounted) {
      setState(() => _manualYao[index] = options[selected].yaoValue);
    }
  }

  // ------------------------------------------------------------ 小组件封装

  Widget _panel({
    String? title,
    Widget? titleWidget,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF999999)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (titleWidget != null)
            titleWidget
          else if (title != null)
            Center(
              child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _tipCard(String text) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF999999)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, height: 24 / 14, color: Color(0xFF7B7B7B)),
      ),
    );
  }

  Widget _richTipCard(List<InlineSpan> spans) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF999999)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, height: 24 / 14, color: Color(0xFF7B7B7B)),
          children: spans,
        ),
      ),
    );
  }

  Widget _qiGuaButton() {
    return GestureDetector(
      onTap: _onQiGua,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF00ABAE),
          borderRadius: BorderRadius.circular(3),
        ),
        alignment: Alignment.center,
        child: const Text(
          '开始起卦',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  Widget _numberInput(TextEditingController controller, String hint, {required int maxLength}) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: maxLength,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(maxLength),
      ],
      style: const TextStyle(fontSize: 16),
      decoration: _inputDecoration(hint),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      counterText: '',
      hintStyle: const TextStyle(fontSize: 15, color: Color(0xFFA3A0A0)),
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Color(0xFF999999)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Color(0xFF00ABAE)),
      ),
    );
  }

  Widget _guaNamePicker({
    required String title,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF28B7A3)),
        ),
        const SizedBox(height: 6),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD3D3D3)),
            borderRadius: BorderRadius.circular(5),
          ),
          alignment: Alignment.centerLeft,
          child: DropdownButton<String?>(
            value: value,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            hint: const Text('请选择', style: TextStyle(fontSize: 14, color: Color(0xFFA3A0A0))),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('请选择')),
              for (final gua in kDivineNameData)
                DropdownMenuItem<String?>(
                  value: gua.code,
                  child: Text(
                    '${gua.palace} ${gua.name}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
                  ),
                ),
            ],
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Future<void> _pickCastingTime() async {
    // 官方 DatePick（模块 2234 + iOS 弹层 2236）：底部滚轮选择年月日时分
    // 六爻起卦时间支持"公历 / 农历"切换，农历选择后换算成公历再排盘。
    final picked = await DateTimePickerSheet.show(
      context,
      initial: _castingTime,
      isShowLunar: true,
    );
    if (picked == null || !mounted) return;
    setState(() => _castingTime = picked);
  }

  Widget _row({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          child,
        ],
      ),
    );
  }

  Widget _card({required Widget child, EdgeInsetsGeometry? margin}) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF999999)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: child,
    );
  }
}

/// 面板中的居中说明文字（官方 `shengYuTextStyle`）。
class _SectionTip extends StatelessWidget {
  final String text;

  const _SectionTip(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, color: Color(0xFF555555)),
      ),
    );
  }
}
