import 'package:flutter/material.dart';

import '../models/divination_models.dart';
import '../theme/app_theme.dart';
import '../widgets/divination_card.dart';
import '../widgets/divination_dialog.dart';
import 'message_page.dart';
import 'mine_page.dart';
import 'ming_li_page.dart';
import 'pai_pan_type_page.dart';

/// 首页（官方路由名 `首页`，模块 2416，埋点 `Page_SuanGuaHome`）。
///
/// 页面结构对齐官方渲染：
///   1. 顶部 `#28B7A3 → #fff` 渐变 + "易占师算卦大师"
///   2. 白色圆角卡片：`["在线起卦", "八字轻测", "紫微斗数"]` Tab
///   3. "我的咨询" / "起卦记录" 双按钮
///   4. 热门六爻占问：情感婚恋 / 事业工作 / 财运生意 / 兔年运程
///
/// 热门老师、话题榜、评价列表、八字轻测推荐等区块在官方实现中
/// 依赖服务端接口（`getYSHIndexData` / `getForumTopics` 等），本工程未接入。
class DivinationPage extends StatefulWidget {
  const DivinationPage({super.key});

  @override
  State<DivinationPage> createState() => _DivinationPageState();
}

/// 热门六爻占问入口。
class _HotEntry {
  final String label;
  final int quetype;
  final String quetitle;
  final Color color;

  const _HotEntry(this.label, this.quetype, this.quetitle, this.color);
}

class _DivinationPageState extends State<DivinationPage> {
  int _currentBottomNavIndex = 0;

  /// 官方 `Q` 表（模块 2416）中的求测标题，用于首页快捷起卦。
  static const List<_HotEntry> _hotEntries = <_HotEntry>[
    _HotEntry('情感婚恋', 3, '我今天的婚姻感情运势如何？', Color(0xFFFF6262)),
    _HotEntry('事业工作', 1, '我今天的事业工作运势如何？', Color(0xFF46C7BF)),
    _HotEntry('财运生意', 4, '我今天的财富生意运势如何？', Color(0xFFFF6600)),
    _HotEntry('兔年运程', 9, '我今年的年运如何？', Color(0xFF7B68EE)),
  ];

  /// 官方规则：19 点之后"今天"改为"明天"。
  String _resolveTitle(String title) {
    if (DateTime.now().hour >= 19 && title.contains('今天')) {
      return title.replaceAll('今天', '明天');
    }
    return title;
  }

  void _openHotEntry(_HotEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PaiPanTypePage(
          request: QiGuaRequest(
            sex: 1,
            quetitle: _resolveTitle(entry.quetitle),
            quetype: entry.quetype,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: IndexedStack(
        index: _currentBottomNavIndex,
        children: [
          _buildHomeBody(),
          const MingLiPage(),
          const MessagePage(),
          const MinePage(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHomeBody() {
    return Stack(
      children: [
        _buildTopBackground(),
        SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 20),
            child: Column(
              children: [
                const SizedBox(
                  height: 44,
                  child: Center(
                    child: Text(
                      '易占师算卦大师',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const DivinationCard(),
                const SizedBox(height: 10),
                _buildSubButtons(),
                const SizedBox(height: 10),
                _buildHotSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 顶部翡翠绿渐变背景。
  Widget _buildTopBackground() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 260,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF28B7A3), Color(0xFFFFFFFF)],
          ),
        ),
      ),
    );
  }

  /// "我的咨询" / "起卦记录"。
  Widget _buildSubButtons() {
    return Row(
      children: [
        Expanded(
          child: _subButton(
            '我的咨询',
            () => DivinationDialog.showHistorySheet(context, '我的咨询'),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _subButton(
            '起卦记录',
            () => DivinationDialog.showQiGuaRecords(context),
          ),
        ),
      ],
    );
  }

  Widget _subButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5B772),
          borderRadius: BorderRadius.circular(5),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(fontSize: 14, color: Colors.white),
        ),
      ),
    );
  }

  /// 热门六爻占问。
  Widget _buildHotSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(left: 8),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: Color(0xFF28B7A3), width: 3)),
            ),
            child: const Text(
              '热门六爻占问',
              style: TextStyle(fontSize: 18, color: Color(0xFF222222)),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.maxWidth * 0.44;
              final gap = constraints.maxWidth - size * 2;
              return Wrap(
                spacing: gap,
                runSpacing: 10,
                children: [
                  for (final entry in _hotEntries)
                    SizedBox(
                      width: size,
                      height: size * 0.5,
                      child: GestureDetector(
                        onTap: () => _openHotEntry(entry),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          decoration: BoxDecoration(
                            color: entry.color,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            entry.label,
                            style: const TextStyle(fontSize: 20, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    const navItems = <List<Object>>[
      ['首页', Icons.home_outlined, Icons.home_rounded],
      ['命理', Icons.auto_awesome_mosaic_outlined, Icons.auto_awesome_mosaic_rounded],
      ['消息', Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded],
      ['我的', Icons.person_outline_rounded, Icons.person_rounded],
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: List.generate(navItems.length, (index) {
              final isSelected = _currentBottomNavIndex == index;
              final item = navItems[index];
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentBottomNavIndex = index),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        (isSelected ? item[2] : item[1]) as IconData,
                        size: 24,
                        color: isSelected ? AppColors.primary : const Color(0xFF909AA8),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item[0] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.primary : const Color(0xFF909AA8),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
