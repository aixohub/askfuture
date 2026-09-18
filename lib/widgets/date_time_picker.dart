import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/lunar_calendar.dart';
import 'app_toast.dart';

/// 官方日历图标：模块 2245 注册的 `/assets/public/img/date_icon.png`（100×117），
/// 官方以 20×20 显示在时间输入框左侧。
const String kDateIconAsset = 'assets/images/public/date_icon.png';

/// 起卦时间选择器。
///
/// 对齐官方 `DatePick` 组件（模块 2234）在 iOS 上的弹层实现（模块 2236）：
///   * 底部弹出，点浮层外或"取消"关闭，右侧"确定"回填
///   * 弹层内一行"年 月 日 时 分"标签 + 五列滚轮
///   * 可选范围取官方 `Config.DatePick.minDate / maxDate`
///     （1876-05-01 ~ 2089-05-01）
///   * 输出格式与官方 `Config.DatePick.format` 一致：`YYYY-MM-DD HH:mm`
///   * 按钮文案取官方 `confirmBtnText / cancelBtnText`：确定 / 取消
///
/// 官方该弹层还带"公历/农历"切换，仅在传入 `isShowLunar` 时显示（模块 2238
/// `isShowLunar` / `isLunar` / `LeapMonth_check`）；六爻起卦时间默认开启，
/// 便于按农历时间起卦：选择农历后由 [lunar2Solar] 换算成公历再排盘。
class DateTimePickerSheet {
  const DateTimePickerSheet._();

  /// 官方 `Config.DatePick.minDate`。
  static final DateTime minDate = DateTime(1876, 5, 1);

  /// 官方 `Config.DatePick.maxDate`。
  static final DateTime maxDate = DateTime(2089, 5, 1);

  /// 官方按钮/选中色（模块 2236 `pickerBtn` / `typeText`）。
  static const Color actionColor = Color(0xFF2AA9B9);

  /// 打开选择器，返回选中的时间；取消返回 null。
  ///
  /// [isShowLunar] 为 true 时显示"公历/农历"切换按钮；
  /// [isLunar] 为 true 时初始处于农历模式（对齐官方默认值）。
  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initial,
    bool isShowLunar = false,
    bool isLunar = false,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DateTimePickerSheetBody(
        initial: initial,
        isShowLunar: isShowLunar,
        isLunar: isLunar,
      ),
    );
  }
}

class _DateTimePickerSheetBody extends StatefulWidget {
  final DateTime initial;
  final bool isShowLunar;
  final bool isLunar;

  const _DateTimePickerSheetBody({
    required this.initial,
    this.isShowLunar = false,
    this.isLunar = false,
  });

  @override
  State<_DateTimePickerSheetBody> createState() =>
      _DateTimePickerSheetBodyState();
}

class _DateTimePickerSheetBodyState extends State<_DateTimePickerSheetBody> {
  /// 官方 `setOptions()`：年取 [minYear, maxYear]，月 / 日随边界收敛。
  late final List<int> _years = <int>[
    for (
      var y = DateTimePickerSheet.minDate.year;
      y <= DateTimePickerSheet.maxDate.year;
      y++
    )
      y,
  ];

  late final List<int> _months = <int>[for (var m = 1; m <= 12; m++) m];
  late final List<int> _solarHours = <int>[for (var h = 0; h < 24; h++) h];
  late final List<int> _lunarHours = <int>[for (var i = 0; i < 12; i++) i];
  late final List<int> _minutes = <int>[for (var m = 0; m < 60; m++) m];
  late List<int> _days;

  /// 农历模式（官方 `state.isLunar`）。
  late bool _isLunar;

  /// 农历模式下的"闰月"勾选（官方 `LeapMonth_check`）。
  bool _isLeap = false;

  /// 切换公历/农历重建滚轮时，忽略滚轮上报的过时选中项。
  bool _suppressWheelUpdates = false;

  late int _yearIndex;
  late int _monthIndex;
  late int _dayIndex;
  late int _hourIndex;
  late int _minuteIndex;

  late final FixedExtentScrollController _yearController;
  late final FixedExtentScrollController _monthController;
  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;

  static const double _wheelHeight = 200;
  static const double _itemExtent = 36;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _isLunar = widget.isLunar;
    // 入参始终是公历时间；农历模式下先换算成农历再定位滚轮
    final lunar = _isLunar
        ? solar2Lunar(initial.year, initial.month, initial.day)
        : null;
    if (lunar != null) {
      _isLeap = lunar.isLeap;
      _yearIndex = math.max(0, _years.indexOf(lunar.year));
      _monthIndex = math.max(0, _months.indexOf(lunar.month));
      _days = _daysForSelection(lunar.year, lunar.month);
      _dayIndex = math.max(0, _days.indexOf(lunar.day));
      _hourIndex = lunarHourIndex(initial.hour);
    } else {
      _isLunar = false;
      _yearIndex = math.max(0, _years.indexOf(initial.year));
      _monthIndex = math.max(0, _months.indexOf(initial.month));
      _days = _daysOfYearMonth(initial.year, initial.month);
      _dayIndex = math.max(0, _days.indexOf(initial.day));
      _hourIndex = initial.hour.clamp(0, 23);
    }
    _minuteIndex = initial.minute.clamp(0, 59);

    _yearController = FixedExtentScrollController(initialItem: _yearIndex);
    _monthController = FixedExtentScrollController(initialItem: _monthIndex);
    _dayController = FixedExtentScrollController(initialItem: _dayIndex);
    _hourController = FixedExtentScrollController(initialItem: _hourIndex);
    _minuteController = FixedExtentScrollController(initialItem: _minuteIndex);
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  List<int> _daysOfYearMonth(int year, int month) {
    final maxDay = DateTime(year, month + 1, 0).day;
    var first = 1;
    var last = maxDay;
    final min = DateTimePickerSheet.minDate;
    final max = DateTimePickerSheet.maxDate;
    if (year == min.year && month == min.month) first = min.day;
    if (year == max.year && month == max.month) last = max.day;
    if (first > last) first = last;
    return <int>[for (var d = first; d <= last; d++) d];
  }

  /// 当前模式下的可选日列表：公历按大小月，农历按农历月大小（含闰月）。
  List<int> _daysForSelection(int year, int month) {
    if (!_isLunar) return _daysOfYearMonth(year, month);
    final leap = lunarLeapMonth(year);
    final isLeap = _isLeap && leap == month;
    final count = lunarDaysInMonth(year, month, isLeap: isLeap);
    return <int>[for (var d = 1; d <= (count <= 0 ? 30 : count); d++) d];
  }

  /// 当前选中的小时（农历模式下由时辰换算，官方 `updateLunarTime`）。
  int get _selectedHour => _isLunar
      ? hourOfLunarHourIndex(_hourIndex)
      : _solarHours[_hourIndex.clamp(0, _solarHours.length - 1)];

  /// 切换公历 / 农历（官方 `changeType`）。
  void _setLunar(bool value) {
    if (_isLunar == value) return;
    setState(() {
      if (value) {
        // 由当前公历选择换算出农历月/日，使滚轮显示农历值
        final solar = _selected;
        final lunar = solar2Lunar(solar.year, solar.month, solar.day);
        _isLunar = true;
        _isLeap = false;
        if (lunar != null && _years.contains(lunar.year)) {
          _yearIndex = _years.indexOf(lunar.year);
          _monthIndex = _months.indexOf(lunar.month);
          _isLeap = lunar.isLeap;
          _days = _daysForSelection(lunar.year, lunar.month);
          _dayIndex = _days.indexOf(lunar.day).clamp(0, _days.length - 1);
        } else {
          _syncDays(resetDay: false);
        }
        _hourIndex = lunarHourIndex(solar.hour);
      } else {
        // 保留当前选中的小时/分钟，只用农历选择换算出年月日
        final hour = _selectedHour;
        final solar = _currentSolarDate() ?? _selected;
        _isLunar = false;
        _isLeap = false;
        _yearIndex = _years.indexOf(solar.year).clamp(0, _years.length - 1);
        _monthIndex = _months.indexOf(solar.month).clamp(0, _months.length - 1);
        _days = _daysOfYearMonth(solar.year, solar.month);
        _dayIndex = _days.indexOf(solar.day).clamp(0, _days.length - 1);
        _hourIndex = hour.clamp(0, _solarHours.length - 1);
      }
      _replaceControllers();
      _suppressWheelUpdates = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _suppressWheelUpdates = false;
      });
    });
  }

  /// 当前农历选择对应的公历日期（失败返回 null）。
  DateTime? _currentSolarDate() {
    if (!_isLunar) return null;
    final year = _years[_yearIndex];
    final month = _months[_monthIndex];
    final leap = lunarLeapMonth(year);
    final isLeap = _isLeap && leap == month;
    final day = _days[_dayIndex.clamp(0, _days.length - 1)];
    return solarDateOfLunar(year, month, day, isLeap: isLeap);
  }

  /// 切换模式后把滚轮位置同步到最新状态。
  void _syncControllers() {
    void jump(FixedExtentScrollController controller, int index) {
      if (controller.hasClients) controller.jumpToItem(index);
    }

    jump(_yearController, _yearIndex);
    jump(_monthController, _monthIndex);
    jump(_dayController, _dayIndex);
    jump(_hourController, _hourIndex);
    jump(_minuteController, _minuteIndex);
  }

  /// 日 / 时滚轮的条目数量在两种模式下不同，重建控制器以避免索引被夹断。
  void _replaceControllers() {
    final oldDay = _dayController;
    final oldHour = _hourController;
    _dayController = FixedExtentScrollController(initialItem: _dayIndex);
    _hourController = FixedExtentScrollController(initialItem: _hourIndex);
    _syncControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      oldDay.dispose();
      oldHour.dispose();
    });
  }

  /// 年 / 月变化后按官方规则收敛日列表，并把选中项收敛到合法范围。
  void _syncDays({required bool resetDay}) {
    final year = _years[_yearIndex];
    final month = _months[_monthIndex];
    final days = _daysForSelection(year, month);
    final keepIndex = _dayIndex.clamp(0, days.length - 1);
    final currentDay = _days[keepIndex];
    _days = days;
    final nextIndex = resetDay
        ? days.indexOf(days.first)
        : (days.contains(currentDay) ? days.indexOf(currentDay) : 0);
    _dayIndex = nextIndex.clamp(0, days.length - 1);
    if (_dayController.hasClients) {
      _dayController.jumpToItem(_dayIndex);
    }
  }

  DateTime get _selected => DateTime(
    _years[_yearIndex],
    _months[_monthIndex],
    _days[_dayIndex.clamp(0, _days.length - 1)],
    _selectedHour,
    _minutes[_minuteIndex],
  );

  void _onConfirm() {
    if (_isLunar) {
      // 农历 → 公历（官方 `lunar2solar`），再按选中的时辰组成本地时间。
      final solar = _currentSolarDate();
      if (solar == null) {
        AppToast.show(context, '该日期超出农历换算范围（1900-2099）');
        return;
      }
      Navigator.of(context).pop(
        DateTime(
          solar.year,
          solar.month,
          solar.day,
          _selectedHour,
          _minutes[_minuteIndex],
        ),
      );
      return;
    }
    var value = _selected;
    if (value.isBefore(DateTimePickerSheet.minDate)) {
      value = DateTimePickerSheet.minDate;
    }
    if (value.isAfter(DateTimePickerSheet.maxDate)) {
      value = DateTimePickerSheet.maxDate;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // 官方 datePickerItem 宽度 = 75 × (屏宽 / 375)，并按弹层可用宽度收敛。
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = math.min(
          75 * screenWidth / 375,
          constraints.maxWidth / 5,
        );
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFCCCCCC))),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // pickerCtrl：取消 / 确定
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _actionButton('取消', () => Navigator.of(context).pop()),
                    _actionButton('确定', _onConfirm),
                  ],
                ),
                // 官方面板顶部的"公历 / 农历"切换（`isShowLunar` 时显示）。
                if (widget.isShowLunar) _buildTypeToggle(),
                if (_isLunar && lunarLeapMonth(_years[_yearIndex]) > 0)
                  _buildLeapRow(),
                // 年月日时分标签行
                Container(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFAAAAAA))),
                  ),
                  padding: const EdgeInsets.only(top: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final label in const <String>[
                        '年',
                        '月',
                        '日',
                        '时',
                        '分',
                      ])
                        SizedBox(
                          width: itemWidth,
                          child: Center(
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF222222),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // 五列滚轮
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _wheel(
                      key: const Key('pickerYearWheel'),
                      controller: _yearController,
                      itemWidth: itemWidth,
                      values: _years,
                      selectedIndex: _yearIndex,
                      labelOf: (v) => v.toString(),
                      onChanged: (index) {
                        setState(() {
                          _yearIndex = index;
                          _isLeap = false;
                          _syncDays(resetDay: false);
                        });
                      },
                    ),
                    _wheel(
                      key: const Key('pickerMonthWheel'),
                      controller: _monthController,
                      itemWidth: itemWidth,
                      values: _months,
                      selectedIndex: _monthIndex,
                      labelOf: _monthLabel,
                      onChanged: (index) {
                        setState(() {
                          _monthIndex = index;
                          if (lunarLeapMonth(_years[_yearIndex]) !=
                              _months[index]) {
                            _isLeap = false;
                          }
                          _syncDays(resetDay: false);
                        });
                      },
                    ),
                    _wheel(
                      key: const Key('pickerDayWheel'),
                      controller: _dayController,
                      itemWidth: itemWidth,
                      values: _days,
                      selectedIndex: _dayIndex,
                      labelOf: _dayLabel,
                      onChanged: (index) => setState(() => _dayIndex = index),
                    ),
                    _wheel(
                      key: const Key('pickerHourWheel'),
                      controller: _hourController,
                      itemWidth: itemWidth,
                      values: _isLunar ? _lunarHours : _solarHours,
                      selectedIndex: _hourIndex,
                      labelOf: _hourLabel,
                      onChanged: (index) {
                        if (_suppressWheelUpdates) return;
                        setState(() => _hourIndex = index);
                      },
                    ),
                    _wheel(
                      key: const Key('pickerMinuteWheel'),
                      controller: _minuteController,
                      itemWidth: itemWidth,
                      values: _minutes,
                      selectedIndex: _minuteIndex,
                      labelOf: (v) => v.toString().padLeft(2, '0'),
                      onChanged: (index) =>
                          setState(() => _minuteIndex = index),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _actionButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: DateTimePickerSheet.actionColor,
          ),
        ),
      ),
    );
  }

  /// 官方顶部"公历 / 农历"切换按钮组（模块 2236 `typeBtn` / `typeBtnBc`）。
  Widget _buildTypeToggle() {
    Widget button(String text, bool selected, bool isLeft) {
      return GestureDetector(
        onTap: () => _setLunar(!isLeft),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? DateTimePickerSheet.actionColor : Colors.white,
            border: Border.all(color: const Color(0xFFBBBBBB), width: 0.5),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: selected ? Colors.white : const Color(0xFF666666),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          button('公历', !_isLunar, true),
          button('农历', _isLunar, false),
        ],
      ),
    );
  }

  /// 官方"闰月"勾选（模块 2238 `LeapMonth_check`）。
  Widget _buildLeapRow() {
    final leap = lunarLeapMonth(_years[_yearIndex]);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 32,
          width: 32,
          child: Checkbox(
            key: const Key('lunarLeapCheck'),
            value: _isLeap,
            activeColor: DateTimePickerSheet.actionColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (value) {
              setState(() {
                _isLeap = value ?? false;
                if (_isLeap && _months[_monthIndex] != leap) {
                  _monthIndex = _months.indexOf(leap);
                  if (_monthController.hasClients) {
                    _monthController.jumpToItem(_monthIndex);
                  }
                }
                _syncDays(resetDay: false);
              });
            },
          ),
        ),
        Text(
          '闰${kLunarMonthNames[leap - 1]}',
          style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
        ),
      ],
    );
  }

  String _monthLabel(int month) {
    if (!_isLunar) return month.toString().padLeft(2, '0');
    final leap = lunarLeapMonth(_years[_yearIndex]);
    final prefix = _isLeap && leap == month ? '闰' : '';
    return '$prefix${kLunarMonthNames[month - 1]}';
  }

  String _dayLabel(int day) =>
      _isLunar ? toChinaDay(day) : day.toString().padLeft(2, '0');

  String _hourLabel(int index) => _isLunar
      ? kLunarHourNames[index.clamp(0, kLunarHourNames.length - 1)]
      : index.toString().padLeft(2, '0');

  Widget _wheel({
    required Key key,
    required FixedExtentScrollController controller,
    required double itemWidth,
    required List<int> values,
    required int selectedIndex,
    required ValueChanged<int> onChanged,
    required String Function(int) labelOf,
  }) {
    return SizedBox(
      key: key,
      width: itemWidth,
      height: _wheelHeight,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: _itemExtent,
        diameterRatio: 1.6,
        perspective: 0.004,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: values.length,
          builder: (context, index) {
            final label = labelOf(values[index]);
            final isSelected = index == selectedIndex;
            return Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: label.length > 2 ? 13 : 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? DateTimePickerSheet.actionColor
                      : const Color(0xFF666666),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 起卦时间字段样式（官方 `DatePick` 的输入框外观）。
class CastingTimeField extends StatelessWidget {
  final DateTime value;
  final VoidCallback onTap;
  final Key? fieldKey;

  /// 时间起卦面板中文案居中（官方 `inputTimeText.textAlign = "center"`）。
  final bool centered;

  /// 附加的农历文案（如 `八月初六`），为空时不显示。
  final String? lunarText;

  const CastingTimeField({
    super.key,
    required this.value,
    required this.onTap,
    this.fieldKey,
    this.centered = false,
    this.lunarText,
  });

  static String format(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: fieldKey,
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 35,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD6D6D6)),
          borderRadius: BorderRadius.circular(5),
          color: Colors.white,
        ),
        child: Row(
          children: [
            // 官方 isShowIcon：左侧日历图标（模块 2245 date_icon.png，20×20）
            Padding(
              padding: const EdgeInsets.only(left: 9),
              child: Image.asset(
                kDateIconAsset,
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 10, right: 12),
                child: Text(
                  lunarText == null || lunarText!.isEmpty
                      ? format(value)
                      : '${format(value)}（$lunarText）',
                  textAlign: centered ? TextAlign.center : TextAlign.left,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF747474),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
