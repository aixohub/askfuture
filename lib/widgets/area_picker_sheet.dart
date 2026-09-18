import 'package:flutter/material.dart';

import '../models/china_area.dart';

/// 出生地选择结果：占位项「忽略」统一转成空串（表示未选择）。
class AreaSelection {
  final String province;
  final String city;

  const AreaSelection(this.province, this.city);
}

/// 出生城市弹框：省 / 市两级滚轮并列联动。
///
/// 对齐官方 `UnionPicker`（模块 2424）+ `CommonPicker`（模块 1864）的级联形态：
///   * 弹层自底部弹出，顶部为「取消 / 确定」（`#2AA9B9`，14）
///   * 标题行取 `areaTitle`（模块 2427）= `["省", "市"]`
///   * 两级滚轮并列（官方 `pickerWrap: {flexDirection: "row", flex: 1}`、
///     `pickerWheel: {flex: 1}`），切换省份后城市列表联动刷新
///
/// 页面上的展示框保持不变（单框文本 + 下拉箭头），由调用方负责渲染。
class AreaPickerSheet {
  const AreaPickerSheet._();

  /// 官方 `UnionPicker` 弹层按钮色（模块 2425 `pickerBtn`）。
  static const Color actionColor = Color(0xFF2AA9B9);

  static Future<AreaSelection?> show(
    BuildContext context, {
    required String province,
    required String city,
  }) {
    return showModalBottomSheet<AreaSelection>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => _AreaPickerSheetBody(province: province, city: city),
    );
  }
}

class _AreaPickerSheetBody extends StatefulWidget {
  final String province;
  final String city;

  const _AreaPickerSheetBody({required this.province, required this.city});

  @override
  State<_AreaPickerSheetBody> createState() => _AreaPickerSheetBodyState();
}

class _AreaPickerSheetBodyState extends State<_AreaPickerSheetBody> {
  static const double _itemExtent = 40;
  static const double _wheelHeight = 200;

  /// 官方数据首项为占位「忽略」，这里原样保留，选中后按未选择处理。
  final List<String> _provinces = kProvinces;

  late List<String> _cities;
  late int _provinceIndex;
  late int _cityIndex;

  late final FixedExtentScrollController _provinceController;
  late final FixedExtentScrollController _cityController;

  @override
  void initState() {
    super.initState();
    _provinceIndex = _provinces.indexOf(_normalize(widget.province));
    if (_provinceIndex < 0) _provinceIndex = 0;
    _cities = _citiesOf(_provinces[_provinceIndex]);
    _cityIndex = _cities.indexOf(_normalize(widget.city));
    if (_cityIndex < 0) _cityIndex = 0;

    _provinceController = FixedExtentScrollController(initialItem: _provinceIndex);
    _cityController = FixedExtentScrollController(initialItem: _cityIndex);
  }

  @override
  void dispose() {
    _provinceController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  static String _normalize(String value) => value.isEmpty ? '忽略' : value;

  static List<String> _citiesOf(String province) =>
      kUnionAreaData[province] ?? const <String>['忽略'];

  /// 切换省份：城市列表联动刷新并回到首项。
  void _onProvinceChanged(int index) {
    if (index == _provinceIndex) return;
    setState(() {
      _provinceIndex = index;
      _cities = _citiesOf(_provinces[index]);
      _cityIndex = 0;
    });
    if (_cityController.hasClients) {
      _cityController.jumpToItem(0);
    }
  }

  void _onConfirm() {
    final province = _provinces[_provinceIndex];
    final city = _cities[_cityIndex.clamp(0, _cities.length - 1)];
    Navigator.of(context).pop(
      AreaSelection(
        province == '忽略' ? '' : province,
        city == '忽略' ? '' : city,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // pickerCtrl：取消 / 确定
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _actionButton('取消', () => Navigator.of(context).pop()),
                _actionButton('确定', _onConfirm),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE1E1E1)),
          // pickerTitle：省 / 市
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                for (final title in kAreaTitle)
                  Expanded(
                    child: Center(
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // pickerWrap：两级滚轮并列
          SizedBox(
            height: _wheelHeight,
            child: Row(
              children: [
                Expanded(
                  child: _wheel(
                    wheelKey: const Key('areaProvinceWheel'),
                    controller: _provinceController,
                    values: _provinces,
                    selectedIndex: _provinceIndex,
                    onChanged: _onProvinceChanged,
                  ),
                ),
                Expanded(
                  child: _wheel(
                    wheelKey: const Key('areaCityWheel'),
                    controller: _cityController,
                    values: _cities,
                    selectedIndex: _cityIndex,
                    onChanged: (index) => setState(() => _cityIndex = index),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
          style: const TextStyle(fontSize: 14, color: AreaPickerSheet.actionColor),
        ),
      ),
    );
  }

  Widget _wheel({
    required Key wheelKey,
    required FixedExtentScrollController controller,
    required List<String> values,
    required int selectedIndex,
    required ValueChanged<int> onChanged,
  }) {
    return ListWheelScrollView.useDelegate(
      key: wheelKey,
      controller: controller,
      itemExtent: _itemExtent,
      diameterRatio: 1.6,
      perspective: 0.004,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: values.length,
        builder: (context, index) => Center(
          child: Text(
            values[index],
            style: TextStyle(
              fontSize: 16,
              fontWeight: index == selectedIndex ? FontWeight.bold : FontWeight.normal,
              color: index == selectedIndex ? const Color(0xFF222222) : const Color(0xFF666666),
            ),
          ),
        ),
      ),
    );
  }
}
