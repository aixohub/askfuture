import 'package:flutter/material.dart';

import '../models/bazi_record.dart';
import '../models/qi_gua_record.dart';
import '../models/ziwei.dart';
import '../models/ziwei_record.dart';
import '../pages/bazi_paipan_page.dart';
import '../pages/gua_xiang_page.dart';
import '../pages/ziwei_chart_page.dart';
import '../theme/app_theme.dart';

class DivinationDialog {
  /// 展示起卦过程与结果弹窗
  static void showResultDialog({
    required BuildContext context,
    required String category,
    required String question,
    required String gender,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        return _DivinationResultDialog(
          category: category,
          question: question.isEmpty ? '今日运势与前程吉凶' : question,
          gender: gender,
        );
      },
    );
  }

  /// 展示服务指引说明
  static void showGuideDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                '如何选择指定的老师给我提供服务？',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '1. 起卦完成后，在卦象解析页面可查看入驻名师列表。\n'
                '2. 点击“选择名师”，根据老师擅长领域（如六爻、梅花、奇门、八字）进行一对一精准解卦。\n'
                '3. 支持查看老师的历史好评率、从业年限与擅长方向。\n'
                '4. 提交咨询后，老师将在 15 分钟内为您发送深度语音或文字复盘。',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    '知道了',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  /// 展示历史记录或咨询
  static void showHistorySheet(BuildContext context, String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textLight),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(color: AppColors.dividerGrey),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.hourglass_empty_rounded,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '暂无更多$title',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 起卦记录：展示本次会话中在卦象页"保存排盘"过的卦。
  ///
  /// 官方的起卦记录来自服务端，这里读取本地记录存储
  /// （见 `QiGuaRecordStore` 与 `BaZiRecordStore`），保存后即可在首页"起卦记录"中查看。
  static void showQiGuaRecords(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        var activeTab = 0; // 0: 六爻起卦, 1: 八字排盘
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final qiGuaRecords = QiGuaRecordStore.instance.records;
            final baziRecords = BaZiRecordStore.instance.records;
            final ziweiRecords = ZiWeiRecordStore.instance.records;
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '起卦记录',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _recordTabChip(
                            key: const Key('recordTabQiGua'),
                            label: '六爻起卦',
                            selected: activeTab == 0,
                            onTap: () => setSheetState(() => activeTab = 0),
                          ),
                          const SizedBox(width: 6),
                          _recordTabChip(
                            key: const Key('recordTabBazi'),
                            label: '八字排盘',
                            selected: activeTab == 1,
                            onTap: () => setSheetState(() => activeTab = 1),
                          ),
                          const SizedBox(width: 6),
                          _recordTabChip(
                            key: const Key('recordTabZiWei'),
                            label: '紫微斗数',
                            selected: activeTab == 2,
                            onTap: () => setSheetState(() => activeTab = 2),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textLight),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.dividerGrey),
                  Expanded(
                    child: activeTab == 0
                        ? (qiGuaRecords.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.hourglass_empty_rounded,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '暂无起卦记录',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '起卦后在卦象页点击"保存排盘"即可保存',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Material(
                                color: Colors.transparent,
                                child: ListView.separated(
                                  itemCount: qiGuaRecords.length,
                                  separatorBuilder: (_, _) => const Divider(
                                    height: 1,
                                    color: AppColors.dividerGrey,
                                  ),
                                  itemBuilder: (subCtx, index) {
                                    final record = qiGuaRecords[index];
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      onTap: () => _openRecord(context, ctx, record),
                                      trailing: const Icon(
                                        Icons.chevron_right,
                                        size: 20,
                                        color: AppColors.textLight,
                                      ),
                                      title: Text(
                                        record.title,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '占卜问题：${record.request.quetitle}',
                                              style: const TextStyle(fontSize: 12.5),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${record.methodName} · ${record.request.quetypeName} · '
                                              '${record.request.sexName}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textLight,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '起卦时间：${_formatDateTime(record.castingTime)}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textLight,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ))
                        : (activeTab == 1
                            ? (baziRecords.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.hourglass_empty_rounded,
                                          size: 48,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          '暂无八字排盘记录',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '排盘后在八字排盘页点击"保存排盘"即可保存',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Material(
                                    color: Colors.transparent,
                                    child: ListView.separated(
                                      itemCount: baziRecords.length,
                                      separatorBuilder: (_, _) => const Divider(
                                        height: 1,
                                        color: AppColors.dividerGrey,
                                      ),
                                      itemBuilder: (subCtx, index) {
                                        final record = baziRecords[index];
                                        return ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          onTap: () => _openBaZiRecord(context, ctx, record),
                                          trailing: const Icon(
                                            Icons.chevron_right,
                                            size: 20,
                                            color: AppColors.textLight,
                                          ),
                                          title: Text(
                                            record.title,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                          subtitle: Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '命主：某人（${record.input.sexName}）· ${record.input.dateTypeName}'
                                                  '${record.input.cityText.isNotEmpty ? ' · ${record.input.cityText}' : ''}',
                                                  style: const TextStyle(fontSize: 12.5),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '出生：${_formatDateTime(record.input.birthTime)}'
                                                  '${record.input.useTrueSolarTime ? '（真太阳时）' : ''}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.textLight,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '排盘时间：${_formatDateTime(record.savedAt)}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.textLight,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ))
                            : (ziweiRecords.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.hourglass_empty_rounded,
                                          size: 48,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          '暂无紫微斗数排盘记录',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '排盘后在紫微斗数排盘页点击"保存排盘"即可保存',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Material(
                                    color: Colors.transparent,
                                    child: ListView.separated(
                                      itemCount: ziweiRecords.length,
                                      separatorBuilder: (_, _) => const Divider(
                                        height: 1,
                                        color: AppColors.dividerGrey,
                                      ),
                                      itemBuilder: (subCtx, index) {
                                        final record = ziweiRecords[index];
                                        return ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          onTap: () => _openZiWeiRecord(context, ctx, record),
                                          trailing: const Icon(
                                            Icons.chevron_right,
                                            size: 20,
                                            color: AppColors.textLight,
                                          ),
                                          title: Text(
                                            record.title,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                          subtitle: Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '命主：某人（${record.input.gender == 1 ? '男' : '女'}）· ${record.input.isLunar ? '阴历' : '阳历'}',
                                                  style: const TextStyle(fontSize: 12.5),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '出生：${_formatDateTime(record.input.dateTime)}'
                                                  '${record.input.trueSolarMinutes != 0 ? '（真太阳时）' : ''}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.textLight,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '排盘时间：${_formatDateTime(record.savedAt)}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.textLight,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ))),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _recordTabChip({
    Key? key,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF00ABAE) : const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? Colors.white : const Color(0xFF666666),
          ),
        ),
      ),
    );
  }

  static String _formatDateTime(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  /// 打开历史记录对应的卦象页：先关闭底部弹层，再压入卦象页。
  static void _openRecord(
    BuildContext pageContext,
    BuildContext sheetContext,
    QiGuaRecord record,
  ) {
    final navigator = Navigator.of(pageContext);
    Navigator.of(sheetContext).pop();
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => GuaXiangPage(
          request: record.request,
          result: record.result,
          methodName: record.methodName,
          castingTime: record.castingTime,
          inputSummary: record.inputSummary,
          record: record,
        ),
      ),
    );
  }

  /// 打开历史记录对应的八字排盘页：先关闭底部弹层，再压入八字排盘页。
  static void _openBaZiRecord(
    BuildContext pageContext,
    BuildContext sheetContext,
    BaZiRecord record,
  ) {
    final navigator = Navigator.of(pageContext);
    Navigator.of(sheetContext).pop();
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => BaZiPaiPanPage(
          input: record.input,
          savedRecord: record,
        ),
      ),
    );
  }

  /// 打开历史记录对应的紫微斗数排盘页：先关闭底部弹层，再压入排盘页。
  static void _openZiWeiRecord(
    BuildContext pageContext,
    BuildContext sheetContext,
    ZiWeiRecord record,
  ) {
    final chart = buildZiWeiChart(record.input);
    if (chart == null) return;
    final navigator = Navigator.of(pageContext);
    Navigator.of(sheetContext).pop();
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => ZiWeiChartPage(
          chart: chart,
          question: record.question,
          input: record.input,
          savedRecord: record,
        ),
      ),
    );
  }
}

class _DivinationResultDialog extends StatefulWidget {
  final String category;
  final String question;
  final String gender;

  const _DivinationResultDialog({
    required this.category,
    required this.question,
    required this.gender,
  });

  @override
  State<_DivinationResultDialog> createState() =>
      _DivinationResultDialogState();
}

class _DivinationResultDialogState extends State<_DivinationResultDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _castingDone = false;

  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 1600),
          )
          ..forward().then((_) {
            if (mounted) {
              setState(() {
                _castingDone = true;
              });
            }
          });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: _castingDone ? _buildResultView() : _buildCastingView(),
      ),
    );
  }

  Widget _buildCastingView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        RotationTransition(
          turns: _animController,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: const Center(
              child: Icon(
                Icons.toll_rounded,
                color: AppColors.primary,
                size: 38,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          '灵感凝聚，神卦起运中...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '诚心默念：“${widget.question}”',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.textLight),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildResultView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.category,
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.close,
                size: 20,
                color: AppColors.textLight,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            '【乾为天】卦 (上乾下乾)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            '求测问题：${widget.question}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textMedium),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.dividerGrey),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '【卦象浅释】',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 6),
              Text(
                '天行健，君子以自强不息。此卦象征纯阳刚正、亨通顺遂，虽眼前略有起伏，但坚守正道，蓄力而行，终将顺达大吉。',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text(
            '查看详细解卦',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
