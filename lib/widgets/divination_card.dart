import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/divination_models.dart';
import '../pages/pai_pan_type_page.dart';
import '../theme/app_theme.dart';
import 'app_toast.dart';
import 'bazi_qingce_tab.dart';
import 'ziwei_form.dart';

/// 首页主卡片：顶部三等分 Tab + "在线起卦"表单。
///
/// 对齐官方 RN bundle 模块 2416（首页）的渲染结构：
///   * `renderTabBar` → `["在线起卦", "八字轻测", "紫微斗数"]`
///   * `_geZhanBuBox()` → 占事分类网格 / 问题输入 / 性别选择 / 开始起卦
/// 以及模块 2416 `_checkInput()` 的校验与参数换算规则。
class DivinationCard extends StatefulWidget {
  const DivinationCard({super.key});

  @override
  State<DivinationCard> createState() => _DivinationCardState();
}

class _DivinationCardState extends State<DivinationCard> {
  /// 顶部 Tab：0 在线起卦 / 1 八字轻测 / 2 紫微斗数。
  int _selectedTabIndex = 0;

  /// 官方 `state.quetype` 初值为 `""`，即默认不选中任何分类。
  int? _quetype;

  /// 官方 `state.sex` 初值为 -1（不选中）；本工程按需求默认选中"男"(1)。
  int? _sex = 1;

  final TextEditingController _questionController = TextEditingController();

  /// 出生日期：八字轻测与紫微斗数两个页签共用，切换页签时保持一致。
  DateTime _birthTime = DateTime.now();

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  /// 对齐首页 `_checkInput()`：
  /// 1. 未选分类 → "问题分类可提高预测准确性，请仔细选择"
  /// 2. 标题为空或少于 2 字 → "请输入求测问题~"
  /// 3. 未选性别 → "请选择性别!"
  /// 4. 换算分类：30 → 3；婚姻情感 + 男 → 2
  /// 5. 跳转"排盘方式选择页"，携带 {sex, question, quetitle, quetype, type}
  void _onStartQiGua() {
    final quetype = _quetype;
    if (quetype == null || quetype == 0) {
      AppToast.show(context, '问题分类可提高预测准确性，请仔细选择');
      return;
    }

    final title = _questionController.text.trim();
    if (title.isEmpty || title.length < 2) {
      AppToast.show(context, '请输入求测问题~');
      return;
    }

    final sex = _sex;
    if (sex == null) {
      AppToast.show(context, '请选择性别!');
      return;
    }

    var finalQueType = quetype;
    if (finalQueType == 30) finalQueType = 3;
    if (finalQueType == 3 && sex == 1) finalQueType = 2;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PaiPanTypePage(
          request: QiGuaRequest(
            sex: sex,
            quetitle: title,
            quetype: finalQueType,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 4,
            offset: Offset(3, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabBar(),
          if (_selectedTabIndex == 0)
            _buildZhanBuBox()
          else if (_selectedTabIndex == 1)
            BaziQingCeTab(
              birthTime: _birthTime,
              onBirthTimeChanged: (value) => setState(() => _birthTime = value),
            )
          else if (_selectedTabIndex == 2)
            ZiWeiForm(
              birthTime: _birthTime,
              onBirthTimeChanged: (value) => setState(() => _birthTime = value),
            )
          else
            _buildPlaceholderTab(),
        ],
      ),
    );
  }

  /// 顶部三等分 Tab 栏。
  Widget _buildTabBar() {
    const tabs = <String>['在线起卦', '八字轻测', '紫微斗数'];
    return Container(
      height: 46,
      color: AppColors.tabInactiveBg,
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = index),
              behavior: HitTestBehavior.opaque,
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : AppColors.tabInactiveBg,
                  borderRadius: isSelected
                      ? const BorderRadius.vertical(top: Radius.circular(16))
                      : BorderRadius.zero,
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.textDark : AppColors.textMedium,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// `_geZhanBuBox()`：占事分类 + 问题 + 性别 + 开始起卦。
  Widget _buildZhanBuBox() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Padding(
                padding: EdgeInsets.only(left: 5),
                child: Text('占事分类:', style: TextStyle(fontSize: 18)),
              ),
              Text('正确的分类可提高预测准确性', style: TextStyle(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          _buildCategoryGrid(),
          const SizedBox(height: 10),
          _buildQuestionRow(),
          _buildGenderRow(),
          const SizedBox(height: 10),
          Center(child: _buildStartButton()),
        ],
      ),
    );
  }

  /// 18 个分类药丸按钮，3 列。
  Widget _buildCategoryGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 3;
        final itemWidth = constraints.maxWidth * 0.30;
        final gap = (constraints.maxWidth - itemWidth * columns) / (columns - 1);
        return Wrap(
          spacing: gap,
          runSpacing: 10,
          children: [
            for (final category in kDivinationCategories)
              SizedBox(
                width: itemWidth,
                height: 30,
                child: GestureDetector(
                  onTap: () => setState(() => _quetype = category.value),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _quetype == category.value
                          ? const Color(0xFF00ABAE)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: _quetype == category.value
                          ? null
                          : Border.all(color: const Color(0xFF999999)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 13,
                        color: _quetype == category.value
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

  Widget _buildQuestionRow() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFE9E9E9)),
          bottom: BorderSide(color: Color(0xFF999999)),
        ),
      ),
      constraints: const BoxConstraints(minHeight: 40),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 5),
            child: Text('问题:', style: TextStyle(fontSize: 16)),
          ),
          Expanded(
            child: TextField(
              controller: _questionController,
              maxLines: null,
              inputFormatters: [LengthLimitingTextInputFormatter(100)],
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(
                hintText: '请输入求测问题，一事一测',
                hintStyle: TextStyle(fontSize: 16, color: Color(0xFFA3A0A0)),
                border: InputBorder.none,
                counterText: '',
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderRow() {
    return Container(
      height: 40,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF999999))),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 5),
            child: Text('性别:', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 10),
          _buildGenderOption(1, '男'),
          const SizedBox(width: 30),
          _buildGenderOption(0, '女'),
        ],
      ),
    );
  }

  Widget _buildGenderOption(int value, String label) {
    final isSelected = _sex == value;
    return GestureDetector(
      onTap: () => setState(() => _sex = value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? const Color(0xFF1296DB) : const Color(0xFFE6E6E6),
            ),
            child: Text(
              value == 1 ? '♂' : '♀',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF9A9A9A),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    // 官方为 0.9 × 屏宽；此处取卡片可用宽度与 0.9 屏宽的较小值，避免小屏溢出。
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = MediaQuery.of(context).size.width * 0.9;
        return GestureDetector(
          onTap: _onStartQiGua,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: width > constraints.maxWidth ? constraints.maxWidth : width,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFF00ABAE),
              borderRadius: BorderRadius.circular(3),
            ),
            alignment: Alignment.center,
            child: const Text(
              '开 始 起 卦',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  /// 两个业务页签（八字轻测 / 紫微斗数）均已由独立组件渲染，此处为兜底占位。
  Widget _buildPlaceholderTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 60),
      child: Column(
        children: [
          const Text('敬请期待', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            '该功能即将上线',
            style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }
}
