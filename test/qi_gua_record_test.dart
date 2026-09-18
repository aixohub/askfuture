import 'package:divination/main.dart';
import 'package:divination/models/divination_models.dart';
import 'package:divination/models/hexagram.dart';
import 'package:divination/models/qi_gua_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => QiGuaRecordStore.instance.clear());

  /// 首页"起卦记录"中的条目应能回看到该卦的卦象页。
  testWidgets('起卦记录：点击记录跳转卦象页', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    QiGuaRecordStore.instance.save(
      QiGuaRecord(
        request: const QiGuaRequest(sex: 1, quetitle: '今年事业如何', quetype: 1),
        result: buildGuaResult(const <int>[1, 1, 1, 1, 1, 1]),
        methodName: '手工指定',
        castingTime: DateTime(2026, 9, 17, 10, 30),
        savedAt: DateTime(2026, 9, 17, 10, 31),
        inputSummary: '一爻 少阳，二爻 少阳，三爻 少阳，四爻 少阳，五爻 少阳，六爻 少阳',
      ),
    );

    await tester.pumpWidget(const DivinationApp());
    await tester.pumpAndSettle();

    // 打开首页"起卦记录"弹层
    await tester.tap(find.text('起卦记录'));
    await tester.pumpAndSettle();
    expect(find.text('【乾为天】静卦'), findsOneWidget);
    expect(find.text('占卜问题：今年事业如何'), findsOneWidget);

    // 点击记录 → 关闭弹层并进入卦象页
    await tester.tap(find.text('【乾为天】静卦'));
    await tester.pumpAndSettle();

    expect(find.text('易占师'), findsWidgets); // 卦象页 AppBar 标题
    expect(find.textContaining('问占：'), findsOneWidget);
    expect(find.textContaining('今年事业如何'), findsWidgets);
    expect(find.textContaining('乾为天'), findsWidgets);
    // 回看历史记录时按钮直接是「已保存排盘」，避免重复保存
    expect(find.text('已保存排盘'), findsOneWidget);
  });

  /// 没有记录时保持空态，不应出现可点击条目。
  testWidgets('起卦记录：空态提示', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const DivinationApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('起卦记录'));
    await tester.pumpAndSettle();

    expect(find.text('暂无起卦记录'), findsOneWidget);
    expect(find.text('起卦后在卦象页点击"保存排盘"即可保存'), findsOneWidget);
  });
}
