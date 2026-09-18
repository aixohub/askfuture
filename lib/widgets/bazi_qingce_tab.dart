import 'package:flutter/material.dart';

import '../pages/bazi_paipan_page.dart';
import '../theme/app_theme.dart';
import 'app_toast.dart';
import 'area_picker_sheet.dart';
import 'date_time_picker.dart';

/// 首页"八字轻测"面板。
///
/// 对齐官方首页模块 2423 的 `render()`：
///   命主性别（男 / 女）+ 日期类型（阴历 / 阳历）+ 出生日期（DatePick）+
///   出生城市（省市选择器 + 使用真太阳时 + 什么是真太阳时说明）+
///   问题描述（maxLength 100）+ 三条提示 + 「立即查询」。
///
/// 校验文案沿用官方 `_baZiPaiPan()`：
///   问题描述不足 2 字 → "请输入求测问题~"；未选性别 → "请选择性别"；
///   未选阴/阳历 → "请选择阴/阳历"；勾选真太阳时但未选出生地 → "请先选择出生地点"。
class BaziQingCeTab extends StatefulWidget {
  /// 出生日期：与「紫微斗数」页签共用同一份，保证两个页签保持一致。
  final DateTime birthTime;

  /// 出生日期变更回调。
  final ValueChanged<DateTime> onBirthTimeChanged;

  const BaziQingCeTab({
    super.key,
    required this.birthTime,
    required this.onBirthTimeChanged,
  });

  @override
  State<BaziQingCeTab> createState() => _BaziQingCeTabState();
}

class _BaziQingCeTabState extends State<BaziQingCeTab> {
  /// 官方 `N`：男 1 / 女 0；本工程按需求默认选中「男」。
  int _sex = 1;

  /// 官方 `L`：阴历 0 / 阳历 1；本工程按需求默认选中「阴历」。
  int _dateType = 0;

  /// 出生省 / 市，空串表示未选择（官方占位项「忽略」按未选择处理）。
  String _province = '';
  String _city = '';

  bool _useTrueSolarTime = false;

  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _hasAreaSelected => _province.isNotEmpty && _city.isNotEmpty;

  String get _areaText => _hasAreaSelected ? '$_province  $_city' : '请选择';

  DateTime get _birthTime => widget.birthTime;

  Future<void> _pickBirthTime() async {
    final picked = await DateTimePickerSheet.show(context, initial: _birthTime);
    if (picked == null || !mounted) return;
    if (picked.isAfter(DateTime.now())) {
      AppToast.show(context, '您选择的时间大于当前时间');
      return;
    }
    // 与「紫微斗数」页签共用同一份出生日期
    widget.onBirthTimeChanged(picked);
  }

  /// 弹出省 / 市并列联动的出生地选择弹框（页面展示框保持单框不变）。
  Future<void> _pickArea() async {
    final selection = await AreaPickerSheet.show(
      context,
      province: _province,
      city: _city,
    );
    if (selection == null || !mounted) return;
    setState(() {
      _province = selection.province;
      _city = selection.city;
      if (!_hasAreaSelected) _useTrueSolarTime = false;
    });
  }

  void _onToggleTrueSolarTime(bool value) {
    if (value && !_hasAreaSelected) {
      AppToast.show(context, '请先选择出生地点');
      return;
    }
    setState(() => _useTrueSolarTime = value);
  }

  /// 官方 `showSunTimeDetail()`：真太阳时说明弹窗。
  void _showTrueSolarTimeDetail() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('什么是真太阳时'),
        content: const Text(
          '真太阳时，是指以太阳高度所决定的当地的真实时间，与普通情况下所使用的北京时间不同，'
          '是有误差的，这种误差被称为真太阳时。\n\n'
          '由于我国地域广阔，东西部时差大，都用北京时间是不精确的，'
          '尤其在命理算八字方面，使用真太阳时排盘对排盘结果会更精确。',
          style: TextStyle(fontSize: 14, height: 1.7),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('我知道了', style: TextStyle(color: Color(0xFF00ABAE))),
          ),
        ],
      ),
    );
  }

  void _onSubmit() {
    final description = _descriptionController.text.trim();
    if (description.length < 2) {
      AppToast.show(context, '请输入求测问题~');
      return;
    }
    if (_sex == -1) {
      AppToast.show(context, '请选择性别');
      return;
    }
    if (_dateType == -1) {
      AppToast.show(context, '请选择阴/阳历');
      return;
    }
    if (_useTrueSolarTime && !_hasAreaSelected) {
      AppToast.show(context, '请先选择出生地点');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BaZiPaiPanPage(
          input: BaZiInput(
            sex: _sex,
            dateType: _dateType,
            birthTime: _birthTime,
            province: _hasAreaSelected ? _province : '',
            city: _hasAreaSelected ? _city : '',
            cityText: _areaText,
            useTrueSolarTime: _useTrueSolarTime,
            description: description,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSexRow(),
          _buildDateTypeRow(),
          _buildBirthTimeRow(),
          _buildCityRow(),
          const SizedBox(height: 6),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            maxLength: 100,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: '问题描述',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFA3A0A0)),
              counterText: '',
              isDense: true,
              contentPadding: const EdgeInsets.all(8),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(2),
                borderSide: const BorderSide(color: Color(0xFFD7D7D7), width: 0.6),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(2),
                borderSide: const BorderSide(color: Color(0xFF00ABAE)),
              ),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            '1、请描述具体求测问题，便于老师针对性解答。',
            style: TextStyle(fontSize: 12, color: Color(0xFFA3A0A0)),
          ),
          const Text(
            '2、输入多个问题时，老师仅分析第一个问题。',
            style: TextStyle(fontSize: 12, color: Color(0xFFA3A0A0)),
          ),
          const Text(
            '3、时辰不清楚，可备注大概时间(如3-5点)。',
            style: TextStyle(fontSize: 12, color: Color(0xFFA3A0A0)),
          ),
          const SizedBox(height: 10),
          Center(
            child: GestureDetector(
              onTap: _onSubmit,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFF00ABAE),
                  borderRadius: BorderRadius.circular(3),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '八字排盘',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(fontSize: 14.5, color: AppColors.textDark),
      );

  Widget _radioOption({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? const Color(0xFF00ABAE) : const Color(0xFFBBBBBB),
                width: 1.2,
              ),
            ),
            alignment: Alignment.center,
            child: selected
                ? Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF00ABAE),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              color: selected ? const Color(0xFF00ABAE) : const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSexRow() {
    return Row(
      children: [
        _label('命主性别:'),
        const SizedBox(width: 8),
        _radioOption(
          label: '男',
          selected: _sex == 1,
          onTap: () => setState(() => _sex = 1),
        ),
        const SizedBox(width: 18),
        _radioOption(
          label: '女',
          selected: _sex == 0,
          onTap: () => setState(() => _sex = 0),
        ),
      ],
    );
  }

  Widget _buildDateTypeRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          _label('日期类型:'),
          const SizedBox(width: 8),
          _radioOption(
            label: '阴历',
            selected: _dateType == 0,
            onTap: () => setState(() => _dateType = 0),
          ),
          const SizedBox(width: 18),
          _radioOption(
            label: '阳历',
            selected: _dateType == 1,
            onTap: () => setState(() => _dateType = 1),
          ),
        ],
      ),
    );
  }

  Widget _buildBirthTimeRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          _label('出生日期:'),
          const SizedBox(width: 8),
          Expanded(
            child: CastingTimeField(
              fieldKey: const Key('baziBirthTimeField'),
              value: _birthTime,
              onTap: _pickBirthTime,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          _label('出生城市:'),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              key: const Key('baziAreaPicker'),
              onTap: _pickArea,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      _areaText,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: _hasAreaSelected ? const Color(0xFF333333) : const Color(0xFF9A9A9A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF999999)),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _onToggleTrueSolarTime(!_useTrueSolarTime),
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _useTrueSolarTime
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  size: 16,
                  color: _useTrueSolarTime ? const Color(0xFF00ABAE) : const Color(0xFF999999),
                ),
                const SizedBox(width: 3),
                Text(
                  '使用真太阳时',
                  style: TextStyle(
                    fontSize: 13,
                    color: _useTrueSolarTime ? const Color(0xFF00ABAE) : const Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _showTrueSolarTimeDetail,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.help_outline, size: 18, color: Color(0xFF999999)),
            ),
          ),
        ],
      ),
    );
  }
}
