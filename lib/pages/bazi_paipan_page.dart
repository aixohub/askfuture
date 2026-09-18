import 'package:flutter/material.dart';

import '../models/bazi.dart';
import '../models/bazi_record.dart';
import '../models/ganzhi.dart';
import '../models/jieqi.dart';
import '../models/lunar_calendar.dart';
import '../widgets/app_toast.dart';

/// 八字排盘输入（对应官方首页模块 2423 `_baZiPaiPan()` 组装的参数）。
class BaZiInput {
  /// 1 男 / 0 女（官方 `sex: 0 == o ? 2 : 1` 的服务端取值另存于提交体）。
  final int sex;

  /// 0 阴历 / 1 阳历。
  final int dateType;

  /// 出生时间（官方 `inputTime` / `bornTime`）。
  final DateTime birthTime;

  final String province;
  final String city;

  /// 出生地展示文本（官方 `city = 省 + "  " + 市`）。
  final String cityText;

  /// 是否使用真太阳时（官方 `isUseSunTime`）。
  final bool useTrueSolarTime;

  /// 求测问题（官方 `description`）。
  final String description;

  const BaZiInput({
    required this.sex,
    required this.dateType,
    required this.birthTime,
    required this.province,
    required this.city,
    required this.cityText,
    required this.useTrueSolarTime,
    required this.description,
  });

  String get sexName => sex == 1 ? '男' : '女';

  String get dateTypeName => dateType == 1 ? '阳历' : '阴历';

  Map<String, dynamic> toJson() => <String, dynamic>{
        'sex': sex,
        'dateType': dateType,
        'birthTime': birthTime.toIso8601String(),
        'province': province,
        'city': city,
        'cityText': cityText,
        'useTrueSolarTime': useTrueSolarTime,
        'description': description,
      };

  static BaZiInput fromJson(Map<String, dynamic> json) {
    return BaZiInput(
      sex: (json['sex'] as num?)?.toInt() ?? 1,
      dateType: (json['dateType'] as num?)?.toInt() ?? 0,
      birthTime: DateTime.tryParse(json['birthTime'] as String? ?? '') ?? DateTime.now(),
      province: json['province'] as String? ?? '',
      city: json['city'] as String? ?? '',
      cityText: json['cityText'] as String? ?? '',
      useTrueSolarTime: json['useTrueSolarTime'] as bool? ?? false,
      description: json['description'] as String? ?? '',
    );
  }
}

/// 八字排盘页（官方路由 `ResultPage2`，页面为官方模块 2508）。
///
/// 该页包含两个页签：基本信息与专业命盘；底部为「保存排盘」操作按钮。
class BaZiPaiPanPage extends StatefulWidget {
  final BaZiInput input;
  final BaZiRecord? savedRecord;

  const BaZiPaiPanPage({
    super.key,
    required this.input,
    this.savedRecord,
  });

  @override
  State<BaZiPaiPanPage> createState() => _BaZiPaiPanPageState();
}

class _BaZiPaiPanPageState extends State<BaZiPaiPanPage> {
  /// 官方配色（模块 2470 ResultStyle）。
  static const Color _rowAlt = Color(0xFFF5F6F7);
  static const Color _ganColor = Color(0xFFCD2626);
  static const Color _valueColor = Color(0xFF333333);

  late final BaZiPan _pan = buildBaZiPan(_solarBirthTime, male: widget.input.sex == 1);
  late final DateTime _solarBirthTime = _resolveSolarBirthTime();
  int _selectedDaYun = 0;
  int _selectedLiuNian = 0;

  /// 大运 / 流年横排选择器的滚动控制器：首次进入时把当前年份滚到可视区。
  final ScrollController _daYunScrollController = ScrollController();
  final ScrollController _liuNianScrollController = ScrollController();

  late bool _saved = widget.savedRecord != null;

  @override
  void initState() {
    super.initState();
    _selectedDaYun = _initialDaYunIndex();
    _selectedLiuNian = _initialLiuNianIndex();
    // 官方进入专业命盘即定位到"当前所处大运 / 当前流年"，这里同时把选择项滚入可视区
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollSelectedIntoView(_daYunScrollController, _selectedDaYun);
      _scrollSelectedIntoView(_liuNianScrollController, _selectedLiuNian);
    });
    if (!_saved) {
      final exists = BaZiRecordStore.instance.records.any((r) =>
          r.input.birthTime == widget.input.birthTime &&
          r.input.sex == widget.input.sex &&
          r.input.description == widget.input.description);
      if (exists) {
        _saved = true;
      }
    }
  }

  void _onSave() {
    if (_saved) {
      AppToast.show(context, '本次排盘已保存成功，可随时至 起卦记录 查看。');
      return;
    }
    final record = BaZiRecord(
      input: widget.input,
      savedAt: DateTime.now(),
    );
    BaZiRecordStore.instance.save(record);
    setState(() {
      _saved = true;
    });
    AppToast.show(context, '保存成功');
  }

  void _onClose() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _daYunScrollController.dispose();
    _liuNianScrollController.dispose();
    super.dispose();
  }

  /// 勾选「阴历」时先把输入的农历日期换算成公历再排盘（官方由服务端按
  /// `dateType` 处理，本地用农历库换算）。
  DateTime _resolveSolarBirthTime() {
    final input = widget.input;
    if (input.dateType != 0) return input.birthTime;
    final solar = lunar2Solar(
      input.birthTime.year,
      input.birthTime.month,
      input.birthTime.day,
    );
    if (solar == null) return input.birthTime;
    return DateTime(
      solar.year,
      solar.month,
      solar.day,
      input.birthTime.hour,
      input.birthTime.minute,
    );
  }

  /// 官方 `getInitDaYunIndex()`：以起运年份定位当前所处大运。
  int _initialDaYunIndex() {
    return initialDaYunIndex(
      firstDaYunYear: _pan.qiYunDetail.jiaoYunDate.year,
      currentYear: DateTime.now().year,
    ).clamp(0, _pan.daYun.length - 1);
  }

  /// 官方 `getInitLiuNianIndex()`：在当前大运的十年内定位当前流年。
  int _initialLiuNianIndex() {
    return initialLiuNianIndex(
      firstDaYunYear: _pan.qiYunDetail.jiaoYunDate.year,
      currentYear: DateTime.now().year,
      daYunIndex: _selectedDaYun,
    );
  }

  /// 把横排选择器中的选中项滚到可视区（尽量居中）。
  void _scrollSelectedIntoView(ScrollController controller, int index) {
    if (!controller.hasClients) return;
    const itemWidth = 44.0;
    final position = controller.position;
    final target =
        index * itemWidth - (position.viewportDimension - itemWidth) / 2;
    controller.jumpTo(target.clamp(0.0, position.maxScrollExtent));
  }

  String _formatDateTime(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  /// 官方 `formatTime`：`2026-09-18 06:49:00`。
  String _formatFullTime(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${_formatDateTime(dt)}:${two(dt.second)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF23B59B),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '八字排盘',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: _buildContent(),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  // ------------------------------------------------------------ 命主信息（2509）

  /// 官方模块 2509：求测标题 / 姓名(性别) 地点 / 时间（公历 + 农历）/ 节气，行高 28、底色交替。
  Widget _buildMinZhuInfo() {
    final input = widget.input;
    final lunar = solar2Lunar(_solarBirthTime.year, _solarBirthTime.month, _solarBirthTime.day);

    String two(int v) => v.toString().padLeft(2, '0');
    final solarYear = _solarBirthTime.year;
    final solarMonthStr = two(_solarBirthTime.month);
    final solarDayStr = two(_solarBirthTime.day);
    final solarHourStr = two(_solarBirthTime.hour);
    final solarMinuteStr = two(_solarBirthTime.minute);

    final lunarYear = lunar?.year ?? _solarBirthTime.year;
    final lunarMonthStr = lunar?.monthCn ?? '';
    final lunarDayStr = lunar?.dayCn ?? '';
    final lunarHourStr = '${_pan.siZhu.hour.zhi}时';

    final prevJie = currentJie(_solarBirthTime);
    final nJie = nextJie(_solarBirthTime);
    String jieQiStr = '';
    if (prevJie != null && nJie != null) {
      jieQiStr =
          '${prevJie.name} ${prevJie.time.year} 年 ${two(prevJie.time.month)} 月 ${two(prevJie.time.day)} 日,'
          '${nJie.name} ${nJie.time.year} 年 ${two(nJie.time.month)} 月 ${two(nJie.time.day)} 日';
    }

    return Column(
      children: [
        _row(
          label: '求测标题：',
          value: input.description,
          background: Colors.white,
        ),
        _row(
          label: '姓名：',
          value: '(${input.sexName})',
          background: _rowAlt,
          secondLabel: '地点：',
          secondValue: input.cityText.isEmpty || input.cityText == '请选择'
              ? '未填写'
              : input.cityText,
        ),
        _buildTimeRow(
          isFirst: true,
          calendarType: '公历',
          year: '$solarYear 年',
          month: '$solarMonthStr 月',
          day: '$solarDayStr 日',
          hour: '$solarHourStr 时',
          minute: '$solarMinuteStr 分${input.useTrueSolarTime ? '（真太阳时）' : ''}',
          background: Colors.white,
        ),
        _buildTimeRow(
          isFirst: false,
          calendarType: '农历',
          year: '$lunarYear 年',
          month: lunarMonthStr,
          day: lunarDayStr,
          hour: lunarHourStr,
          minute: '',
          background: _rowAlt,
        ),
        _row(
          label: '节气：',
          value: jieQiStr,
          background: Colors.white,
        ),
      ],
    );
  }

  /// 公历与农历时间行：通过等宽列实现「公历/农历」对齐以及「年/月/日/时」上下垂直精准对齐。
  Widget _buildTimeRow({
    required bool isFirst,
    required String calendarType,
    required String year,
    required String month,
    required String day,
    required String hour,
    required String minute,
    required Color background,
  }) {
    const labelStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: _valueColor,
    );
    const valueStyle = TextStyle(
      fontSize: 13,
      color: _valueColor,
    );

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      color: background,
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          // 左侧标签：首行显示"时间："，次行使用相同组件占位确保完全同宽
          Opacity(
            opacity: isFirst ? 1.0 : 0.0,
            child: const Text('时间：', style: labelStyle),
          ),
          // 历法标识（公历 / 农历）对齐
          SizedBox(
            width: 36,
            child: Text(calendarType, style: valueStyle),
          ),
          // 年对齐
          SizedBox(
            width: 56,
            child: Text(year, style: valueStyle),
          ),
          // 月对齐
          SizedBox(
            width: 44,
            child: Text(month, style: valueStyle),
          ),
          // 日对齐
          SizedBox(
            width: 42,
            child: Text(day, style: valueStyle),
          ),
          // 时对齐
          SizedBox(
            width: 42,
            child: Text(hour, style: valueStyle),
          ),
          // 分与真太阳时说明（公历行跟随展示）
          if (minute.isNotEmpty)
            Flexible(
              child: Text(
                minute,
                overflow: TextOverflow.ellipsis,
                style: valueStyle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _row({
    required String label,
    required String value,
    required Color background,
    String? secondLabel,
    String? secondValue,
  }) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      color: background,
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          if (label.isNotEmpty)
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _valueColor),
            ),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: _valueColor),
            ),
          ),
          if (secondLabel != null) ...[
            const SizedBox(width: 20),
            Text(
              secondLabel,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _valueColor),
            ),
            Flexible(
              child: Text(
                secondValue ?? '',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: _valueColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------ 专业命盘（2514）

  Color _ganZhiColor(String char) {
    final wx = kBaziTianGan[char]?.wuXing ?? kBaziDiZhi[char]?.wuXing;
    switch (wx) {
      case '金':
        return const Color(0xFFEA873A);
      case '木':
        return const Color(0xFF439B31);
      case '水':
        return const Color(0xFF3A80EA);
      case '火':
        return const Color(0xFFE12F26);
      case '土':
        return const Color(0xFF905322);
      default:
        return _valueColor;
    }
  }

  GanZhi _xiaoYunOf(int daYunIndex, int yearOffset) {
    final offset = daYunIndex * 10 + yearOffset + 1;
    final hourGanIndex = kTianGan.indexOf(_pan.siZhu.hour.gan);
    final hourZhiIndex = kDiZhi.indexOf(_pan.siZhu.hour.zhi);
    final signedOffset = _pan.forward ? offset : -offset;
    final gan = kTianGan[((hourGanIndex + signedOffset) % 10 + 10) % 10];
    final zhi = kDiZhi[((hourZhiIndex + signedOffset) % 12 + 12) % 12];
    return GanZhi(gan, zhi);
  }

  Widget _buildContent() {
    final pan = _pan;
    final firstDaYunYear = pan.qiYunDetail.jiaoYunDate.year;
    final selectedDaYunIndex = _selectedDaYun.clamp(0, pan.daYun.length - 1);
    final step = pan.daYun[selectedDaYunIndex];
    final startYear = firstDaYunYear + selectedDaYunIndex * 10;
    final curDaYun = step.ganZhi;
    final curLiuNianYear = startYear + _selectedLiuNian.clamp(0, 9);
    final curLiuNian = yearGanZhi(curLiuNianYear);

    return ListView(
      children: [
        _buildMinZhuInfo(),
        _buildMainChartGrid(curLiuNian, curDaYun),
        _row(
          label: '起运：',
          value: pan.qiYunDetail.text,
          background: Colors.white,
        ),
        _row(
          label: '交运：',
          value: pan.qiYunDetail.jiaoYunText,
          background: _rowAlt,
        ),
        const SizedBox(height: 8),
        _buildDaYunSelector(firstDaYunYear),
        const SizedBox(height: 6),
        _buildLiuNianSelector(startYear),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMainChartGrid(GanZhi curLiuNian, GanZhi curDaYun) {
    final pan = _pan;
    final dayMaster = pan.dayMaster;
    final isMale = widget.input.sex == 1;

    return Column(
      children: [
        // 表头
        _gridRow(
          label: '',
          background: Colors.white,
          height: 30,
          items: [
            const Text('大运', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _valueColor)),
            const Text('流年', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _valueColor)),
            const Text('年柱', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _valueColor)),
            const Text('月柱', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _valueColor)),
            const Text('日柱', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _valueColor)),
            const Text('时柱', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _valueColor)),
          ],
        ),
        // 十神
        _gridRow(
          label: '十神：',
          background: _rowAlt,
          height: 28,
          items: [
            Text(shiShenOf(curDaYun.gan, dayMaster), style: const TextStyle(fontSize: 13, color: _valueColor)),
            Text(shiShenOf(curLiuNian.gan, dayMaster), style: const TextStyle(fontSize: 13, color: _valueColor)),
            Text(pan.pillarOf('年柱').shiShen, style: const TextStyle(fontSize: 13, color: _valueColor)),
            Text(pan.pillarOf('月柱').shiShen, style: const TextStyle(fontSize: 13, color: _valueColor)),
            Text(isMale ? '元男' : '元女', style: const TextStyle(fontSize: 13, color: _valueColor)),
            Text(pan.pillarOf('时柱').shiShen, style: const TextStyle(fontSize: 13, color: _valueColor)),
          ],
        ),
        // 天干
        _gridRow(
          label: '天干：',
          background: Colors.white,
          height: 34,
          items: [
            _ganZhiText(curDaYun.gan),
            _ganZhiText(curLiuNian.gan),
            _ganZhiText(pan.siZhu.year.gan),
            _ganZhiText(pan.siZhu.month.gan),
            _ganZhiText(pan.siZhu.day.gan),
            _ganZhiText(pan.siZhu.hour.gan),
          ],
        ),
        // 地支
        _gridRow(
          label: '地支：',
          background: _rowAlt,
          height: 34,
          items: [
            _ganZhiText(curDaYun.zhi),
            _ganZhiText(curLiuNian.zhi),
            _ganZhiText(pan.siZhu.year.zhi),
            _ganZhiText(pan.siZhu.month.zhi),
            _ganZhiText(pan.siZhu.day.zhi),
            _ganZhiText(pan.siZhu.hour.zhi),
          ],
        ),
        // 遁藏
        _gridRow(
          label: '遁藏：',
          background: Colors.white,
          height: 56,
          items: [
            _cangGanCell(curDaYun.zhi, dayMaster),
            _cangGanCell(curLiuNian.zhi, dayMaster),
            _cangGanCell(pan.siZhu.year.zhi, dayMaster),
            _cangGanCell(pan.siZhu.month.zhi, dayMaster),
            _cangGanCell(pan.siZhu.day.zhi, dayMaster),
            _cangGanCell(pan.siZhu.hour.zhi, dayMaster),
          ],
        ),
        // 旬空
        _gridRow(
          label: '旬空：',
          background: _rowAlt,
          height: 28,
          items: [
            Text(xunKongOf(curDaYun), style: const TextStyle(fontSize: 13, color: _valueColor)),
            Text(xunKongOf(curLiuNian), style: const TextStyle(fontSize: 13, color: _valueColor)),
            Text(xunKongOf(pan.siZhu.year), style: const TextStyle(fontSize: 13, color: _valueColor)),
            Text(xunKongOf(pan.siZhu.month), style: const TextStyle(fontSize: 13, color: _valueColor)),
            Text(xunKongOf(pan.siZhu.day), style: const TextStyle(fontSize: 13, color: _valueColor)),
            Text(xunKongOf(pan.siZhu.hour), style: const TextStyle(fontSize: 13, color: _valueColor)),
          ],
        ),
        // 地势
        _gridRow(
          label: '地势：',
          background: Colors.white,
          height: 28,
          items: [
            Text(changSheng12Of(curDaYun.gan, curDaYun.zhi), style: const TextStyle(fontSize: 13, color: _valueColor)),
            Text(changSheng12Of(curLiuNian.gan, curLiuNian.zhi), style: const TextStyle(fontSize: 13, color: _valueColor)),
            Text(changSheng12Of(dayMaster, pan.siZhu.year.zhi), style: const TextStyle(fontSize: 13, color: _valueColor)),
            Text(changSheng12Of(dayMaster, pan.siZhu.month.zhi), style: const TextStyle(fontSize: 13, color: _valueColor)),
            Text(changSheng12Of(dayMaster, pan.siZhu.day.zhi), style: const TextStyle(fontSize: 13, color: _valueColor)),
            Text(changSheng12Of(dayMaster, pan.siZhu.hour.zhi), style: const TextStyle(fontSize: 13, color: _valueColor)),
          ],
        ),
        // 纳音
        _gridRow(
          label: '纳音：',
          background: _rowAlt,
          height: 28,
          items: [
            Text(nayinOf(curDaYun.gan, curDaYun.zhi), style: const TextStyle(fontSize: 12, color: _valueColor)),
            Text(nayinOf(curLiuNian.gan, curLiuNian.zhi), style: const TextStyle(fontSize: 12, color: _valueColor)),
            Text(nayinOf(pan.siZhu.year.gan, pan.siZhu.year.zhi), style: const TextStyle(fontSize: 12, color: _valueColor)),
            Text(nayinOf(pan.siZhu.month.gan, pan.siZhu.month.zhi), style: const TextStyle(fontSize: 12, color: _valueColor)),
            Text(nayinOf(pan.siZhu.day.gan, pan.siZhu.day.zhi), style: const TextStyle(fontSize: 12, color: _valueColor)),
            Text(nayinOf(pan.siZhu.hour.gan, pan.siZhu.hour.zhi), style: const TextStyle(fontSize: 12, color: _valueColor)),
          ],
        ),
      ],
    );
  }

  Widget _gridRow({
    required String label,
    required List<Widget> items,
    required Color background,
    double height = 28,
  }) {
    return Container(
      height: height,
      color: background,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: label.isNotEmpty
                ? Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _valueColor,
                    ),
                  )
                : null,
          ),
          Expanded(child: Center(child: items[0])),
          Expanded(child: Center(child: items[1])),
          Container(
            width: 1,
            height: height,
            color: const Color(0xFFD4D4D4),
          ),
          Expanded(child: Center(child: items[2])),
          Expanded(child: Center(child: items[3])),
          Expanded(child: Center(child: items[4])),
          Expanded(child: Center(child: items[5])),
        ],
      ),
    );
  }

  Widget _ganZhiText(String char) {
    return Text(
      char,
      style: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.bold,
        color: _ganZhiColor(char),
      ),
    );
  }

  Widget _cangGanCell(String zhi, String dayMaster) {
    final cangs = kDiZhiCangGan[zhi] ?? const <CangGan>[];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final cang in cangs)
          Text(
            '${cang.gan}${shiShenOf(cang.gan, dayMaster)}',
            style: const TextStyle(fontSize: 11, color: _valueColor, height: 1.25),
          ),
      ],
    );
  }

  Widget _buildDaYunSelector(int firstDaYunYear) {
    final pan = _pan;
    final firstDaYunAge = firstDaYunYear - _solarBirthTime.year;
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            alignment: Alignment.center,
            child: const Text(
              '大\n运',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _valueColor,
                height: 1.3,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _daYunScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: pan.daYun.length,
              itemBuilder: (context, index) {
                final step = pan.daYun[index];
                final startYear = firstDaYunYear + index * 10;
                final startAge = firstDaYunAge + index * 10;
                final isSelected = index == _selectedDaYun;
                final ssShort = ganZhiShiShenShort(step.ganZhi, pan.dayMaster);
                final s0 = ssShort.isNotEmpty ? ssShort[0] : '';
                final s1 = ssShort.length > 1 ? ssShort[1] : '';

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDaYun = index;
                    });
                  },
                  child: Container(
                    width: 44,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFE2E4E6) : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$startYear', style: const TextStyle(fontSize: 11, color: _valueColor, height: 1.15)),
                        Text('$startAge岁', style: const TextStyle(fontSize: 11, color: _valueColor, height: 1.15)),
                        Text(step.ganZhi.text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _valueColor, height: 1.15)),
                        Text(
                          '$s0 $s1'.trim(),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE12F26), height: 1.15),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiuNianSelector(int startYear) {
    final pan = _pan;
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            alignment: Alignment.center,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '流年',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _valueColor),
                ),
                Text(
                  '小运',
                  style: TextStyle(fontSize: 10, color: Color(0xFF666666)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _liuNianScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: 10,
              itemBuilder: (context, index) {
                final year = startYear + index;
                final gz = yearGanZhi(year);
                final xiaoGz = _xiaoYunOf(_selectedDaYun, index);
                final isSelected = index == _selectedLiuNian;
                final ssShort = ganZhiShiShenShort(gz, pan.dayMaster);
                final s0 = ssShort.isNotEmpty ? ssShort[0] : '';
                final s1 = ssShort.length > 1 ? ssShort[1] : '';

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedLiuNian = index;
                    });
                  },
                  child: Container(
                    width: 44,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFE2E4E6) : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$year', style: const TextStyle(fontSize: 11, color: _valueColor, height: 1.15)),
                        Text(gz.text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _valueColor, height: 1.15)),
                        Text(xiaoGz.text, style: const TextStyle(fontSize: 11, color: Color(0xFF4C4C4C), height: 1.15)),
                        Text(
                          '$s0 $s1'.trim(),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE12F26), height: 1.15),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SizedBox(
        height: 50,
        child: Row(
          children: [
            Expanded(
              flex: 65,
              child: GestureDetector(
                key: const Key('baziSaveButton'),
                onTap: _onSave,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  color: const Color(0xFF32A5F8),
                  alignment: Alignment.center,
                  child: Text(
                    _saved ? '已保存排盘' : '保存排盘',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 35,
              child: GestureDetector(
                key: const Key('baziCloseButton'),
                onTap: _onClose,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  color: const Color(0xFFE52828),
                  alignment: Alignment.center,
                  child: const Text(
                    '关闭',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
