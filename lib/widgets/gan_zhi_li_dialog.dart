import 'package:flutter/material.dart';

import '../models/ganzhi.dart';
import '../models/jieqi.dart';
import '../models/lunar_calendar.dart';

/// 干支历弹层（官方万年历）。
///
/// 对齐官方实现：
///   * 弹层容器：模块 3131 —— 半透明黑底 + 居中卡片 + 右上角白色关闭按钮；
///   * 日历主体：模块 2225 —— 顶部年月区 + 四柱 + 星期表头 + 月历 + 节气
///     （模块 2226）；
///   * 四柱行：模块 2228 `[马] 丙午年    丁酉月    甲午日    甲戌时`；
///   * 节气行：模块 2227 `节气:白露 2026年09月07日  22 : 41` /
///     `中气:秋分 2026年09月23日  08 : 05`；
///   * 日期格：模块 2232 —— 公历日 + （当天节气名 或 农历日）；
///   * 配色取官方易占师皮肤（模块 1270 `calendarStyle`）。
class GanZhiLiDialog extends StatefulWidget {
  final DateTime initialDate;

  const GanZhiLiDialog({super.key, required this.initialDate});

  static Future<void> show(BuildContext context, {required DateTime initialDate}) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '干支历',
      barrierColor: const Color(0x80000000),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, _, _) => GanZhiLiDialog(initialDate: initialDate),
      transitionBuilder: (ctx, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }

  @override
  State<GanZhiLiDialog> createState() => _GanZhiLiDialogState();
}

class _GanZhiLiDialogState extends State<GanZhiLiDialog> {
  /// 官方 `calendarStyle`（易占师皮肤，模块 1270）。
  static const Color _todayColor = Color(0xFF01AAEC);
  static const Color _selectedColor = Color(0xFFB0B0B0);
  static const Color _notMonthColor = Color(0xFFBBBBBB);
  static const Color _restTextColor = Color(0xFFE51C23);
  static const Color _jieQiBadgeColor = Color(0xFF28B7A3);
  static const Color _jieQiNameColor = Color(0xFF259B24);
  static const Color _jieQiDateColor = Color(0xFFABABAB);

  late DateTime _selected;
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    _selected = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
      widget.initialDate.hour,
      widget.initialDate.minute,
    );
    _visibleMonth = DateTime(_selected.year, _selected.month);
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// 官方模块 2226 / 2233：仅当选中日不是"今天"时才显示"回到今天"。
  bool get _isTodaySelected =>
      _selected.year == _today.year &&
      _selected.month == _today.month &&
      _selected.day == _today.day;

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  void _backToToday() {
    final now = DateTime.now();
    setState(() {
      _selected = DateTime(now.year, now.month, now.day, _selected.hour, _selected.minute);
      _visibleMonth = DateTime(now.year, now.month);
    });
  }

  void _pickDay(DateTime day) {
    setState(() {
      _selected = DateTime(day.year, day.month, day.day, _selected.hour, _selected.minute);
      if (day.month != _visibleMonth.month || day.year != _visibleMonth.year) {
        _visibleMonth = DateTime(day.year, day.month);
      }
    });
  }

  /// 官方 `_formatDate`：`2026年09月07日  22 : 41`。
  String _formatJieQiTime(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}年${two(dt.month)}月${dt.day}日  ${two(dt.hour)} : ${two(dt.minute)}';
  }

  /// 月历 6×7 的日期序列（含上下月补位，周一起始，周日位于最右侧）。
  List<DateTime> get _gridDays {
    final first = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    // DateTime.weekday: 周一=1 … 周日=7；以周一为第一列，周日为第七列
    final leading = first.weekday - 1;
    final start = first.subtract(Duration(days: leading));
    return <DateTime>[for (var i = 0; i < 42; i++) start.add(Duration(days: i))];
  }

  @override
  Widget build(BuildContext context) {
    final sizhu = computeSiZhu(_selected);
    final animal = animalOfYear(_selected.year);
    final jie = currentJie(_selected);
    final zhongQi = currentZhongQi(_selected);
    final width = MediaQuery.of(context).size.width;
    final cardWidth = width - 60 > 340 ? 340.0 : width - 60;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 官方模块 3131：关闭按钮位于卡片右上外侧
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.only(right: 4, bottom: 6),
              child: Icon(Icons.close, color: Colors.white, size: 26),
            ),
          ),
          Material(
            type: MaterialType.transparency,
            child: Container(
              width: cardWidth,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                _buildSiZhuLine(animal, sizhu),
                _buildWeekHeader(),
                _buildMonthGrid(),
                _buildJieQiRow(jie, zhongQi),
              ],
            ),
          ),
          ),
        ],
      ),
    );
  }

  /// 顶部年月区（官方模块 2246 / 2233）：年月 + 回到今天。
  Widget _buildHeader() {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color(0xFFB0C6D2),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
          Text(
            '${_visibleMonth.year}年${_visibleMonth.month}月',
            style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w600),
          ),
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
          const Spacer(),
          if (_isTodaySelected)
            Text(
              '${DateTime.now().hour.toString().padLeft(2, '0')} : '
              '${DateTime.now().minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 14, color: Colors.white),
            )
          else
            GestureDetector(
              onTap: _backToToday,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF01AAEC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white),
                ),
                child: const Text('回到今天', style: TextStyle(fontSize: 12, color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }

  /// 四柱行（官方模块 2228）。
  Widget _buildSiZhuLine(String animal, SiZhu sizhu) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: Text(
          '[$animal] ${sizhu.year.text}年    ${sizhu.month.text}月    '
          '${sizhu.day.text}日    ${sizhu.hour.text}时',
          style: const TextStyle(fontSize: 15, color: Color(0xFF222222)),
        ),
      ),
    );
  }

  /// 星期表头：一 二 三 四 五 六 日（周日在周六右边）。
  Widget _buildWeekHeader() {
    const weekdays = <String>['一', '二', '三', '四', '五', '六', '日'];
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFD9D9D9))),
      ),
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          for (var i = 0; i < weekdays.length; i++)
            Expanded(
              child: Center(
                child: Text(
                  weekdays[i],
                  style: TextStyle(
                    fontSize: 13,
                    color: (i >= 5) ? _restTextColor : const Color(0xFF333333),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _verticalOffset = 0.0;

  /// 月历网格（官方模块 2226 + 2232），支持上下滑动手势切换月份。
  Widget _buildMonthGrid() {
    final days = _gridDays;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragStart: (_) => _verticalOffset = 0.0,
      onVerticalDragUpdate: (details) => _verticalOffset += details.delta.dy,
      onVerticalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -200 || _verticalOffset < -40) {
          _changeMonth(1); // 向上滑动，查看下个月
        } else if (velocity > 200 || _verticalOffset > 40) {
          _changeMonth(-1); // 向下滑动，查看上个月
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            for (var row = 0; row < 6; row++)
              Row(
                children: [
                  for (var col = 0; col < 7; col++) _buildDayCell(days[row * 7 + col]),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCell(DateTime day) {
    final isCurrentMonth =
        day.month == _visibleMonth.month && day.year == _visibleMonth.year;
    final isSelected = day.year == _selected.year &&
        day.month == _selected.month &&
        day.day == _selected.day;
    final isToday = day.year == _today.year &&
        day.month == _today.month &&
        day.day == _today.day;

    final lunar = solar2Lunar(day.year, day.month, day.day);
    final term = jieQiOnDay(day);
    final bottomText = term?.name ?? (lunar == null
        ? ''
        : (lunar.day == 1 ? lunar.monthCn : lunar.dayCn));
    final dayGz = dayGanZhi(day);

    Color textColor = isCurrentMonth ? const Color(0xFF333333) : _notMonthColor;
    Color? circleColor;
    if (isToday) {
      circleColor = _todayColor;
      textColor = Colors.white;
    } else if (isSelected) {
      circleColor = _selectedColor;
      textColor = Colors.white;
    } else if (isCurrentMonth && (day.weekday == DateTime.sunday || day.weekday == DateTime.saturday)) {
      textColor = _restTextColor;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => _pickDay(day),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            children: [
              Text(
                dayGz.text,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: TextStyle(
                  fontSize: 10,
                  color: isCurrentMonth ? const Color(0xFF666666) : _notMonthColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 1),
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: circleColor,
                ),
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                bottomText,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: TextStyle(
                  fontSize: 10,
                  color: term != null
                      ? (isCurrentMonth ? _jieQiNameColor : _notMonthColor)
                      : (isCurrentMonth ? const Color(0xFF999999) : _notMonthColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 节气 / 中气行（官方模块 2227），切换月份后在最右边提供"今"按钮快速回到当月。
  Widget _buildJieQiRow(JieQiMoment? jie, JieQiMoment? zhongQi) {
    final isCurrentMonth =
        _visibleMonth.year == _today.year && _visibleMonth.month == _today.month;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: _jieQiBadgeColor,
              shape: BoxShape.circle,
            ),
            child: const Text('节', style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _jieQiLine('节气:', jie),
                _jieQiLine('中气:', zhongQi),
              ],
            ),
          ),
          if (!isCurrentMonth) ...[
            const SizedBox(width: 8),
            GestureDetector(
              key: const ValueKey('gan_zhi_li_today_btn'),
              onTap: _backToToday,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFF01AAEC),
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '今',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _jieQiLine(String label, JieQiMoment? moment) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF333333))),
        if (moment != null) ...[
          Text(
            moment.name,
            style: const TextStyle(fontSize: 13, color: _jieQiNameColor),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              _formatJieQiTime(moment.time),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: _jieQiDateColor),
            ),
          ),
        ],
      ],
    );
  }
}
