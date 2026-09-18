import 'package:divination/main.dart';
import 'package:divination/models/ziwei.dart';
import 'package:divination/models/ziwei_record.dart';
import 'package:divination/pages/ziwei_chart_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => ZiWeiRecordStore.instance.clear());

  testWidgets('紫微斗数排盘页：包含保存排盘与关闭按钮，且功能正确', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final input = ZiWeiInput(
      dateTime: DateTime(2026, 9, 18, 12, 0),
      isLunar: false,
      gender: 1,
    );
    final chart = buildZiWeiChart(input)!;

    await tester.pumpWidget(
      MaterialApp(
        home: ZiWeiChartPage(
          chart: chart,
          question: '测试紫微运势',
          input: input,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. 验证底部存在"保存排盘"和"关闭"按钮
    final saveButton = find.byKey(const Key('ziweiSaveButton'));
    final closeButton = find.byKey(const Key('ziweiCloseButton'));

    expect(saveButton, findsOneWidget);
    expect(closeButton, findsOneWidget);
    expect(find.text('保存排盘'), findsOneWidget);
    expect(find.text('关闭'), findsOneWidget);

    // 2. 点击"保存排盘"
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // 按钮文案变为"已保存排盘"，且 Store 中有记录
    expect(find.text('已保存排盘'), findsOneWidget);
    expect(ZiWeiRecordStore.instance.records.length, 1);
    expect(ZiWeiRecordStore.instance.records.first.question, '测试紫微运势');

    // 再次点击提示已保存
    await tester.tap(saveButton);
    await tester.pump();
    expect(find.text('本次排盘已保存成功，可随时至 起卦记录 查看。'), findsOneWidget);

    // 等待 toast 倒计时结束以避免 pending timer
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('紫微斗数排盘页：点击关闭按钮返回首页', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const DivinationApp());
    await tester.pumpAndSettle();

    // 首页切换到紫微斗数 Tab
    await tester.tap(find.text('紫微斗数'));
    await tester.pumpAndSettle();

    // 输入问题
    await tester.enterText(find.byType(TextField).first, '事业前程');
    await tester.pumpAndSettle();

    // 提交紫微表单排盘（按钮文案为紫薇排盘）
    await tester.tap(find.text('紫薇排盘'));
    await tester.pumpAndSettle();

    // 验证进入紫微排盘页
    expect(find.text('紫微斗数排盘'), findsOneWidget);
    expect(find.text('保存排盘'), findsOneWidget);
    expect(find.text('关闭'), findsOneWidget);

    // 点击关闭按钮
    await tester.tap(find.byKey(const Key('ziweiCloseButton')));
    await tester.pumpAndSettle();

    // 验证返回到首页
    expect(find.text('易占师算卦大师'), findsOneWidget);
  });

  testWidgets('起卦记录弹窗：紫微斗数标签展示记录并可回看', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final input = ZiWeiInput(
      dateTime: DateTime(2026, 9, 18, 12, 0),
      isLunar: false,
      gender: 1,
    );
    ZiWeiRecordStore.instance.save(
      ZiWeiRecord(
        input: input,
        question: '婚恋情感运势',
        savedAt: DateTime(2026, 9, 18, 12, 1),
      ),
    );

    await tester.pumpWidget(const DivinationApp());
    await tester.pumpAndSettle();

    // 打开起卦记录弹层
    await tester.tap(find.text('起卦记录'));
    await tester.pumpAndSettle();

    // 切换到紫微斗数标签
    await tester.tap(find.byKey(const Key('recordTabZiWei')));
    await tester.pumpAndSettle();

    expect(find.text('紫微斗数 · 婚恋情感运势'), findsOneWidget);

    // 点击记录回看
    await tester.tap(find.text('紫微斗数 · 婚恋情感运势'));
    await tester.pumpAndSettle();

    // 验证进入紫微排盘页且底栏显示"已保存排盘"
    expect(find.text('紫微斗数排盘'), findsOneWidget);
    expect(find.text('已保存排盘'), findsOneWidget);
    expect(find.text('关闭'), findsOneWidget);
  });
}
