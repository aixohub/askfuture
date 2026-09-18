import 'package:flutter/material.dart';

import '../models/ziwei.dart';
import '../models/ziwei_record.dart';
import '../widgets/app_toast.dart';

/// 紫微斗数命盘（官方路由 `ZiWeiResult`，模块 2569）。
///
/// 版式与官方一致：4×4 宫格，十二宫按地支就位，中宫显示阴阳/命局/阳历/
/// 农历/命主身主/四柱；每宫自下而上显示大限、宫名与干支，宫格内为星曜
/// （含庙旺与生年四化）与四组十二神。
class ZiWeiChartPage extends StatefulWidget {
  final ZiWeiChart chart;
  final String question;
  final ZiWeiInput? input;
  final ZiWeiRecord? savedRecord;

  const ZiWeiChartPage({
    super.key,
    required this.chart,
    required this.question,
    this.input,
    this.savedRecord,
  });

  @override
  State<ZiWeiChartPage> createState() => _ZiWeiChartPageState();
}

class _ZiWeiChartPageState extends State<ZiWeiChartPage> {
  late bool _saved = widget.savedRecord != null;

  ZiWeiChart get chart => widget.chart;
  String get question => widget.question;

  void _onSave() {
    if (_saved) {
      AppToast.show(context, '本次排盘已保存成功，可随时至 起卦记录 查看。');
      return;
    }
    final input = widget.input ??
        ZiWeiInput(
          dateTime: DateTime.now(),
          isLunar: chart.lunarText.isNotEmpty,
          gender: chart.gender,
        );
    final record = ZiWeiRecord(
      input: input,
      question: question,
      savedAt: DateTime.now(),
    );
    ZiWeiRecordStore.instance.save(record);
    setState(() {
      _saved = true;
    });
    AppToast.show(context, '保存成功');
  }

  void _onClose() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width - 16;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF23B59B),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '紫微斗数排盘',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildChart(width),
            const SizedBox(height: 8),
            _buildLegend(),
            const SizedBox(height: 8),
            _buildQuestionCard(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ---------------------------------------------------------------- 命盘布局

  /// 官方版式：上排 巳午未申，左右两列 辰卯 / 酉戌，下排 寅丑子亥，中间 2×2 中宫。
  Widget _buildChart(double width) {
    final cellWidth = width / 4;
    final cellHeight = cellWidth * 1.5;
    return Container(
      color: const Color(0xFFF1EEE3),
      width: width,
      child: Column(
        children: [
          SizedBox(
            height: cellHeight,
            child: Row(
              children: [
                _cell(3, width: cellWidth, height: cellHeight, rightBorder: true, bottomBorder: true),
                _cell(4, width: cellWidth, height: cellHeight, rightBorder: true, bottomBorder: true),
                _cell(5, width: cellWidth, height: cellHeight, rightBorder: true, bottomBorder: true),
                _cell(6, width: cellWidth, height: cellHeight, bottomBorder: true),
              ],
            ),
          ),
          SizedBox(
            height: cellHeight * 2,
            child: Row(
              children: [
                SizedBox(
                  width: cellWidth,
                  child: Column(
                    children: [
                      _cell(2, width: cellWidth, height: cellHeight, rightBorder: true, bottomBorder: true),
                      _cell(1, width: cellWidth, height: cellHeight, rightBorder: true),
                    ],
                  ),
                ),
                SizedBox(
                  width: cellWidth * 2,
                  height: cellHeight * 2,
                  child: _buildCenterPanel(),
                ),
                SizedBox(
                  width: cellWidth,
                  child: Column(
                    children: [
                      _cell(7, width: cellWidth, height: cellHeight, leftBorder: true),
                      _cell(8, width: cellWidth, height: cellHeight, leftBorder: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: cellHeight,
            child: Row(
              children: [
                _cell(0, width: cellWidth, height: cellHeight, rightBorder: true, topBorder: true, leftBottomCorner: true),
                _cell(11, width: cellWidth, height: cellHeight, rightBorder: true, topBorder: true),
                _cell(10, width: cellWidth, height: cellHeight, rightBorder: true, topBorder: true),
                _cell(9, width: cellWidth, height: cellHeight, topBorder: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(
    int palaceIndex, {
    required double width,
    required double height,
    bool topBorder = false,
    bool bottomBorder = false,
    bool leftBorder = false,
    bool rightBorder = false,
    bool leftBottomCorner = false,
  }) {
    final palace = chart.palaces[palaceIndex];
    const borderColor = Color(0xFF666666);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF1EEE3),
        border: Border(
          top: topBorder ? const BorderSide(color: borderColor) : BorderSide.none,
          bottom: bottomBorder ? const BorderSide(color: borderColor) : BorderSide.none,
          left: leftBorder ? const BorderSide(color: borderColor) : BorderSide.none,
          right: rightBorder ? const BorderSide(color: borderColor) : BorderSide.none,
        ),
      ),
      padding: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 星曜：主星在上，辅星在下，含庙旺与四化
          Expanded(
            child: Align(
              alignment: Alignment.topRight,
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 4,
                children: [
                  for (final star in palace.allStars) _starText(star),
                ],
              ),
            ),
          ),
          // 四组十二神
          Text(
            '${palace.changsheng12} ${palace.boshi12}',
            style: const TextStyle(fontSize: 6, color: Color(0xFF7A6A4F), height: 1.2),
            maxLines: 1,
            overflow: TextOverflow.clip,
          ),
          Text(
            '${palace.jiangqian12} ${palace.suiqian12}',
            style: const TextStyle(fontSize: 6, color: Color(0xFF7A6A4F), height: 1.2),
            maxLines: 1,
            overflow: TextOverflow.clip,
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                palace.decadalText,
                style: const TextStyle(fontSize: 7, color: Color(0xFFC0392B)),
              ),
              if (palace.isBodyPalace)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  color: const Color(0xFF28B7A3),
                  child: const Text('身宫', style: TextStyle(fontSize: 6, color: Colors.white)),
                ),
              Text(
                '${palace.heavenlyStem}${palace.earthlyBranch}',
                style: const TextStyle(fontSize: 7, color: Color(0xFF333333)),
              ),
            ],
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              color: const Color(0xFF28B7A3),
              child: Text(
                palace.name,
                style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _starText(ZiWeiStar star) {
    final isMajor = star.isMajor;
    return RichText(
      text: TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: star.name,
            style: TextStyle(
              fontSize: isMajor ? 8 : 7,
              color: isMajor ? const Color(0xFFB03A2E) : const Color(0xFF1F618D),
              fontWeight: isMajor ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (star.brightness.isNotEmpty)
            TextSpan(
              text: star.brightness,
              style: const TextStyle(fontSize: 6, color: Color(0xFF7A6A4F)),
            ),
          if (star.mutagen.isNotEmpty)
            TextSpan(
              text: star.mutagen,
              style: const TextStyle(fontSize: 6, color: Color(0xFFC0392B)),
            ),
        ],
      ),
    );
  }

  /// 中宫：阴阳 / 命局 / 阳历 / 农历 / 命主身主 / 四柱。
  Widget _buildCenterPanel() {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFF666666))),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${chart.yinYangText}  命局:${chart.fiveElementsClass}',
            style: const TextStyle(fontSize: 9, color: Colors.black),
          ),
          const SizedBox(height: 4),
          Text('阳历:${chart.solarText}', style: const TextStyle(fontSize: 8, color: Colors.black)),
          Text(
            '农历:${chart.lunarText}  ${chart.siZhuZhi[3]}时',
            style: const TextStyle(fontSize: 8, color: Colors.black),
          ),
          const SizedBox(height: 4),
          Text(
            '命主:${chart.soul}  身主:${chart.body}',
            style: const TextStyle(fontSize: 8, color: Colors.black),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final gan in chart.siZhuGan)
                Text(gan, style: const TextStyle(fontSize: 9, color: Colors.black)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final zhi in chart.siZhuZhi)
                Text(zhi, style: const TextStyle(fontSize: 9, color: Colors.black)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    Widget item(String label, Color color) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, color: color),
            const SizedBox(width: 3),
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF666666))),
          ],
        );

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          item('身宫', const Color(0xFF28B7A3)),
          item('先天（大限）', const Color(0xFFC0392B)),
          item('主星', const Color(0xFFB03A2E)),
          item('辅星', const Color(0xFF1F618D)),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    final palace = chart.palaces[chart.soulIndex];
    final major = palace.majorStars.map((s) => '${s.name}${s.mutagen}').join('、');
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.isEmpty ? '命盘解析' : '求测问题：$question',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF222222)),
          ),
          const SizedBox(height: 8),
          Text(
            '命宫在${palace.earthlyBranch}（${palace.heavenlyStem}${palace.earthlyBranch}），'
            '${major.isEmpty ? '命宫无主星（空宫）' : '命宫主星：$major'}；'
            '五行局为${chart.fiveElementsClass}，命主${chart.soul}，身主${chart.body}。',
            style: const TextStyle(fontSize: 13, height: 1.7, color: Color(0xFF555555)),
          ),
          const Text(
            '以上为按传统安星诀排出的先天命盘，仅供参考。',
            style: TextStyle(fontSize: 12, height: 1.8, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
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
                key: const Key('ziweiSaveButton'),
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
                key: const Key('ziweiCloseButton'),
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

