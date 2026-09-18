import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';

import '../models/divination_models.dart';
import '../models/hexagram.dart';
import '../models/hexagram_text.dart';
import '../models/liuyao.dart';
import '../models/lunar_and_shensha.dart';
import '../models/qi_gua_record.dart';
import '../widgets/app_toast.dart';
import '../widgets/gan_zhi_li_dialog.dart';
import '../widgets/yao_line.dart';

/// 卦象结果页面（对齐易占师官方视觉原型）。
///
/// 视觉与交互结构：
/// 1. 顶部 AppBar：墨绿色背景（#23B59B），左侧"关闭"文本按钮，居中"易占师"标题。
/// 2. 占事信息区：问占 / 占类 / 卦主 / 时间（含农历），右侧浮动褐色"干支历"卡片按钮。
/// 3. 四柱干支与神煞：干支（月柱日柱标红）、卦身/世身（红字）、神煞（展开/收起）。
/// 4. 六爻排盘表：六神、本卦（六亲干支五行+爻线+世应动标+伏神）、变卦（六亲干支五行+爻线+世应）。
/// 5. 卦辞爻辞栏与解卦笔记栏。
/// 6. 四胶囊工具栏：梅花盘 / 收藏 / 复制 / 截图。
/// 7. 居中卦辞诗区：青绿色卦名 + 经典两句诗。
/// 8. 底部吸底双操作按钮：保存排盘（蓝色 #32A5F8） + 关闭（点击返回首页）。
class GuaXiangPage extends StatefulWidget {
  final QiGuaRequest request;
  final GuaResult result;
  final String methodName;
  final DateTime castingTime;
  final String inputSummary;

  /// 从"起卦记录"回看时传入对应记录：
  /// 底部按钮直接显示「已保存排盘」，解卦笔记也会写回这条记录。
  final QiGuaRecord? record;

  const GuaXiangPage({
    super.key,
    required this.request,
    required this.result,
    required this.methodName,
    required this.castingTime,
    required this.inputSummary,
    this.record,
  });

  @override
  State<GuaXiangPage> createState() => _GuaXiangPageState();
}

class _GuaXiangPageState extends State<GuaXiangPage> {
  final GlobalKey _shotKey = GlobalKey();

  late final LiuYaoPan _pan = buildLiuYaoPan(
    result: widget.result,
    castTime: widget.castingTime,
  );

  late final ShenShaInfo _shenSha = calculateShenSha(
    dayGan: _pan.siZhu.day.gan,
    dayZhi: _pan.siZhu.day.zhi,
  );

  late final GuaShenInfo _guaShen = calculateGuaShen(
    benGuaName: _pan.ben.gua.name,
    shiYaoIndex: _pan.ben.shiPosition - 1,
    benYaoZhis: _pan.ben.yaos.map((y) => y.zhi).toList(),
  );

  late bool _saved = widget.record != null;

  /// 本条卦象对应的记录：来自"起卦记录"回看，或本次点击"保存排盘"后生成。
  late QiGuaRecord? _savedRecord = widget.record;

  bool _isFavorite = false;
  bool _shenShaExpanded = false;
  bool _showSnapShot = false;
  late String _note = widget.record?.note ?? '';

  String _formatDateTime(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${dt.month}-${dt.day} ${two(dt.hour)}:${two(dt.minute)}';
  }

  // -------------------------------------------------------------- 截图/复制/工具

  Future<Uint8List?> _capturePng() async {
    final object = _shotKey.currentContext?.findRenderObject();
    if (object is! RenderRepaintBoundary) return null;
    final image = await object.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
  }

  Future<void> _onCopy() async {
    final text = buildCopyText(
      pan: _pan,
      titleText: '易占师',
      question: widget.request.quetitle,
    );
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    AppToast.show(context, '已复制到剪贴板');
  }

  void _onScreenshot() {
    setState(() => _showSnapShot = !_showSnapShot);
  }

  Future<void> _onSaveToAlbum() async {
    try {
      final bytes = await _capturePng();
      if (bytes == null) {
        if (mounted) AppToast.show(context, '生成图片失败，请重试');
        return;
      }
      await Gal.putImageBytes(
        bytes,
        name: 'guaxiang_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!mounted) return;
      AppToast.show(context, '已保存到相册');
    } catch (error) {
      if (!mounted) return;
      AppToast.show(context, '保存失败：$error');
    }
  }

  void _onSave() {
    if (_saved) {
      AppToast.show(context, '本次占卦已保存成功，可随时至 个人中心 - 起卦记录 查看。');
      return;
    }
    final record = QiGuaRecord(
      request: widget.request,
      result: widget.result,
      methodName: widget.methodName,
      castingTime: widget.castingTime,
      savedAt: DateTime.now(),
      inputSummary: widget.inputSummary,
      note: _note,
    );
    QiGuaRecordStore.instance.save(record);
    setState(() {
      _saved = true;
      _savedRecord = record;
    });
    AppToast.show(context, '保存成功');
  }

  /// 保存解卦笔记：更新页面状态，并写回对应的起卦记录。
  void _commitNote(String text) {
    if (text == _note && _savedRecord?.note == text) return;
    setState(() => _note = text);
    final record = _savedRecord;
    if (record != null) {
      QiGuaRecordStore.instance.updateNote(record, text);
    }
    AppToast.show(context, '笔记已保存');
  }

  void _onToggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    AppToast.show(context, _isFavorite ? '已加入收藏' : '已取消收藏');
  }

  void _onOpenNoteDialog() {
    final controller = TextEditingController(text: _note);
    final initial = _note;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        // 键盘弹起时把弹层顶上去，内容可滚动，避免小屏溢出
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '解卦笔记',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        '完成',
                        style: TextStyle(color: Color(0xFF23B59B)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  maxLines: 5,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: '可记录解卦的思路、过程等...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      // 无论是点"完成"、点空白处还是返回键关闭弹层，都提交当前文本，
      // 避免用户输入的解卦笔记被静默丢弃。
      final text = controller.text.trim();
      if (text != initial && mounted) {
        _commitNote(text);
      }
    });
  }

  void _onShowGuaCiDetail() {
    final guaName = _pan.ben.gua.name;
    final guaCi = getGuaCi(guaName);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '卦辞爻辞 · $guaName',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              guaCi,
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  '关 闭',
                  style: TextStyle(fontSize: 15, color: Color(0xFF23B59B)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onShowGanZhiInfo() {
    // 官方模块 2442 的时间栏按钮 → 打开干支历（万年历）
    GanZhiLiDialog.show(context, initialDate: widget.castingTime);
  }

  void _onClose() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // ------------------------------------------------------------------ 页面构建

  @override
  Widget build(BuildContext context) {
    final poem = getGuaCiPoem(_pan.ben.gua.name);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF23B59B),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leadingWidth: 70,
        leading: Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.only(left: 16),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              '关闭',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ),
        title: const Text(
          '易占师',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RepaintBoundary(
                    key: _shotKey,
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeaderSection(),
                          const Divider(
                            height: 1,
                            thickness: 0.8,
                            color: Color(0xFFE5E5E5),
                          ),
                          _buildGuaTable(),
                          const Divider(
                            height: 1,
                            thickness: 0.8,
                            color: Color(0xFFE5E5E5),
                          ),
                          _buildGuaCiRow(),
                          const Divider(
                            height: 1,
                            thickness: 0.8,
                            color: Color(0xFFE5E5E5),
                          ),
                          _buildNoteRow(),
                        ],
                      ),
                    ),
                  ),
                  if (!_showSnapShot) ...[
                    const SizedBox(height: 16),
                    _buildToolsRow(),
                    const SizedBox(height: 24),
                    _buildPoemSection(poem),
                    const SizedBox(height: 90),
                  ],
                ],
              ),
            ),
          ),
          if (!_showSnapShot)
            Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomBar()),
          if (_showSnapShot)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildSnapShotBar(),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- 信息区

  Widget _buildHeaderSection() {
    final lunarText = getLunarDateText(widget.castingTime);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Row(
                        children: [
                          const Text(
                            '问占： ',
                            style: TextStyle(
                              fontSize: 14.5,
                              height: 1.6,
                              color: Colors.black,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              widget.request.quetitle,
                              style: const TextStyle(
                                fontSize: 14.5,
                                height: 1.6,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _plainText('占类： ${widget.request.quetypeName}'),
                    _plainText('卦主： ${widget.request.sexName}'),
                    // 与官方截图一致：`时间：2026-9-17 19:16（八月初七）`
                    _plainText(
                      '时间：${_formatDateTime(widget.castingTime)}（$lunarText）',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildGanZhiButton(),
            ],
          ),
          const SizedBox(height: 2),
          _buildGanZhiLine(),
          const SizedBox(height: 3),
          _buildGuaShenLine(),
          const SizedBox(height: 3),
          _buildShenShaLine(),
        ],
      ),
    );
  }

  Widget _plainText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14.5,
          height: 1.6,
          color: Colors.black,
        ),
      ),
    );
  }

  /// 右侧褐色"干支历"卡片按钮
  Widget _buildGanZhiButton() {
    return GestureDetector(
      onTap: _onShowGanZhiInfo,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF9A5832),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month_outlined, size: 20, color: Colors.white),
            SizedBox(height: 2),
            Text(
              '干支历',
              style: TextStyle(
                fontSize: 10.5,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 干支：月柱日柱标红
  Widget _buildGanZhiLine() {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 14.5,
          height: 1.6,
          color: Colors.black,
        ),
        children: [
          const TextSpan(text: '干支：'),
          TextSpan(text: '${_pan.siZhu.year.text} '),
          TextSpan(
            text: '${_pan.siZhu.month.text} ${_pan.siZhu.day.text} ',
            style: const TextStyle(color: Color(0xFFE5170C)),
          ),
          TextSpan(text: '${_pan.siZhu.hour.text}（旬空 ${_pan.xunKong}）'),
        ],
      ),
    );
  }

  /// 卦身、世身：红字标识
  Widget _buildGuaShenLine() {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 14.5,
          height: 1.6,
          color: Colors.black,
        ),
        children: [
          const TextSpan(text: '卦身： '),
          TextSpan(
            text: _guaShen.guaShen,
            style: const TextStyle(
              color: Color(0xFFE5170C),
              fontWeight: FontWeight.w500,
            ),
          ),
          const TextSpan(text: '  世身： '),
          TextSpan(
            text: _guaShen.shiShen,
            style: const TextStyle(
              color: Color(0xFFE5170C),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 神煞行：展开/收起
  Widget _buildShenShaLine() {
    // 与官方一致：折叠时只显示前 3 项，展开显示全部（见 sixyao-main 的神煞口径：
    // 贵人、驿马、桃花、日禄）
    final textContent =
        _shenShaExpanded ? _shenSha.detailText : _shenSha.summary;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          '神煞： ',
          style: TextStyle(fontSize: 14.5, height: 1.6, color: Colors.black),
        ),
        Text(
          '$textContent  ',
          style: const TextStyle(
            fontSize: 14.5,
            height: 1.6,
            color: Colors.black,
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => _shenShaExpanded = !_shenShaExpanded),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            child: Text(
              _shenShaExpanded ? '收起' : '展开',
              style: const TextStyle(
                fontSize: 14.5,
                color: Color(0xFF23B59B),
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------- 六爻排盘表

  Widget _buildGuaTable() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTableHeader(),
          const SizedBox(height: 6),
          for (var i = 5; i >= 0; i--) _buildTableYaoRow(i),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    // 卦名行 + 宫内八名/世应关系行（对齐六爻参考实现 YaoUtil.Array64Gua 的字段）
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 38,
              child: Text(
                '六神',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            Expanded(
              flex: 55,
              child: Text(
                _pan.ben.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            Expanded(
              flex: 45,
              child: Text(
                _pan.bian.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            const SizedBox(width: 38),
            Expanded(
              flex: 55,
              child: Text(
                _pan.ben.desc,
                key: const Key('benGuaDesc'),
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF8A8A8A),
                ),
              ),
            ),
            Expanded(
              flex: 45,
              child: Text(
                _pan.bian.desc,
                key: const Key('bianGuaDesc'),
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF8A8A8A),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTableYaoRow(int index) {
    final benYao = _pan.ben.yaos[index];
    final bianYao = _pan.bian.yaos[index];

    String benSuffix = '';
    if (benYao.shiYingText.isNotEmpty) {
      benSuffix += benYao.shiYingText;
    }
    if (benYao.isMoving) {
      if (benSuffix.isNotEmpty) benSuffix += ' ';
      benSuffix += benYao.moveMark;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧：六神 + 本卦（含伏神）
          Expanded(
            flex: 59,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 38,
                      child: Text(
                        benYao.liuShen,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Text(
                      benYao.detail,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 4),
                    YaoLine(isYang: benYao.isYang, width: 40, thickness: 7),
                    const SizedBox(width: 4),
                    Text(
                      benSuffix,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                if (benYao.fuShen != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 38, top: 1),
                    child: Text(
                      '↑ 伏神：${benYao.fuShen!.detail}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFFE5170C),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // 右侧：变卦
          Expanded(
            flex: 41,
            child: Row(
              children: [
                Text(
                  bianYao.detail,
                  style: const TextStyle(fontSize: 12.5, color: Colors.black),
                ),
                const SizedBox(width: 4),
                YaoLine(isYang: bianYao.isYang, width: 40, thickness: 7),
                const SizedBox(width: 4),
                Text(
                  bianYao.shiYingText,
                  style: const TextStyle(fontSize: 12.5, color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- 卦辞与笔记

  Widget _buildGuaCiRow() {
    final guaName = _pan.ben.gua.name;
    final guaCi = getGuaCi(guaName);

    return InkWell(
      onTap: _onShowGuaCiDetail,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const Text(
              '卦辞爻辞',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                '$guaName:$guaCi',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteRow() {
    return InkWell(
      onTap: _onOpenNoteDialog,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const Text(
              '解卦笔记',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                _note.isEmpty ? '可记录解卦的思路、过程等' : _note,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  color: _note.isEmpty
                      ? const Color(0xFF999999)
                      : const Color(0xFF333333),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: Color(0xFF999999)),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------- 工具胶囊行

  Widget _buildToolsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPillButton(
            icon: Icons.swap_horiz,
            label: '梅花盘',
            onTap: () => AppToast.show(context, '切换为梅花易数排盘'),
          ),
          _buildPillButton(
            icon: _isFavorite ? Icons.star : Icons.star_border,
            label: '收藏',
            onTap: _onToggleFavorite,
            iconColor: _isFavorite
                ? const Color(0xFFE5B532)
                : const Color(0xFF4A4A4A),
          ),
          _buildPillButton(
            icon: Icons.copy_outlined,
            label: '复制',
            onTap: _onCopy,
          ),
          _buildPillButton(
            icon: Icons.crop_outlined,
            label: '截图',
            onTap: _onScreenshot,
          ),
        ],
      ),
    );
  }

  Widget _buildPillButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFF4A4A4A),
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------- 卦辞诗

  Widget _buildPoemSection(List<String> poem) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            _pan.ben.gua.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF23B59B),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            poem[0],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.8,
              color: Color(0xFF333333),
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            poem[1],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.8,
              color: Color(0xFF333333),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- 底部吸底栏

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
                key: const Key('guaXiangBottomCloseButton'),
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

  /// 截图浮层：保存到相册（70%）+ 关闭（30%）
  Widget _buildSnapShotBar() {
    final width = MediaQuery.of(context).size.width;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SizedBox(
        height: 50,
        child: Row(
          children: [
            GestureDetector(
              onTap: _onSaveToAlbum,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: width * 0.7,
                color: const Color(0xFF23B59B),
                alignment: Alignment.center,
                child: const Text(
                  '保存到相册',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            GestureDetector(
              key: const Key('snapShotCloseButton'),
              onTap: () => setState(() => _showSnapShot = false),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: width * 0.3,
                color: const Color(0xFF46A9F0),
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
          ],
        ),
      ),
    );
  }
}
