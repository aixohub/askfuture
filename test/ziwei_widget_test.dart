import 'package:divination/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 单选标签的选中色（官方 `typeTextAct`）。
const Color _selectedColor = Color(0xFF00ABAE);

Color? _labelColor(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style?.color;

/// 首页「紫微斗数」页签与命盘页的交互回归。
void main() {
  Future<void> openZiWeiTab(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const DivinationApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('紫微斗数'));
    await tester.pumpAndSettle();
  }

  testWidgets('紫微斗数页签：字段与校验提示对齐官方', (WidgetTester tester) async {
    await openZiWeiTab(tester);

    // 官方字段
    for (final label in <String>['命主性别:', '日期类型:', '出生日期:', '出生城市:']) {
      expect(find.text(label), findsOneWidget, reason: '缺少字段 $label');
    }
    // 求测问题与八字轻测同款：多行输入框 + 三条提示
    expect(find.text('问题描述'), findsOneWidget);
    expect(find.text('1、请描述具体求测问题，便于老师针对性解答。'), findsOneWidget);
    expect(find.text('2、输入多个问题时，老师仅分析第一个问题。'), findsOneWidget);
    expect(find.text('3、时辰不清楚，可备注大概时间(如3-5点)。'), findsOneWidget);
    expect(find.text('紫薇排盘'), findsOneWidget);
    expect(find.text('使用真太阳时'), findsOneWidget);

    // 命主性别默认男、日期类型默认阴历
    expect(_labelColor(tester, '男'), _selectedColor);
    expect(_labelColor(tester, '女'), isNot(_selectedColor));
    expect(_labelColor(tester, '阴历'), _selectedColor);
    expect(_labelColor(tester, '阳历'), isNot(_selectedColor));

    // 出生城市：页面单框展示，点开后弹框内省市并列联动
    expect(find.byKey(const Key('ziweiAreaPicker')), findsOneWidget);
    expect(find.text('请选择'), findsOneWidget);
    await tester.tap(find.byKey(const Key('ziweiAreaPicker')));
    await tester.pumpAndSettle();
    expect(find.text('省'), findsOneWidget);
    expect(find.text('市'), findsOneWidget);
    expect(find.byType(ListWheelScrollView), findsNWidgets(2));
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    // 求测问题排在"出生城市"之后
    final questionTop = tester.getTopLeft(find.byType(TextField)).dy;
    final cityTop = tester.getTopLeft(find.text('出生城市:')).dy;
    expect(questionTop, greaterThan(cityTop));

    // 未填问题 → 请输入求测问题~
    await tester.tap(find.text('紫薇排盘'));
    await tester.pump();
    expect(find.text('请输入求测问题~'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2000));

    // 默认性别/日期类型已选中，填问题即可继续
    await tester.enterText(find.byType(TextField).last, '今年事业运势如何');
    await tester.pumpAndSettle();

    // 勾选真太阳时但未选出生地 → 请先选择出生地点
    await tester.tap(find.text('使用真太阳时'));
    await tester.pump();
    expect(find.text('请先选择出生地点'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2000));
  });

  testWidgets('紫微斗数页签：填写完整后进入命盘页', (WidgetTester tester) async {
    await openZiWeiTab(tester);

    await tester.enterText(find.byType(TextField).last, '今年事业运势如何');
    await tester.tap(find.text('男'));
    await tester.tap(find.text('阳历'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('紫薇排盘'));
    await tester.pumpAndSettle();

    // 命盘页：标题 + 十二宫 + 中宫信息
    expect(find.text('紫微斗数排盘'), findsOneWidget);
    expect(find.text('命宫'), findsOneWidget);
    expect(find.text('兄弟'), findsOneWidget);
    expect(find.text('夫妻'), findsOneWidget);
    expect(find.textContaining('命局:'), findsOneWidget);
    expect(find.textContaining('命主:'), findsOneWidget);
    expect(find.textContaining('今年事业运势如何'), findsOneWidget);
  });

  testWidgets('紫微斗数页签：阴历入口可正常出盘', (WidgetTester tester) async {
    await openZiWeiTab(tester);

    await tester.enterText(find.byType(TextField).last, '求测姻缘');
    await tester.tap(find.text('女'));
    await tester.tap(find.text('阴历'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('紫薇排盘'));
    await tester.pumpAndSettle();
    expect(find.text('紫微斗数排盘'), findsOneWidget);
  });

  /// 小屏（iPhone SE 尺寸）下命盘 4×4 宫格不应溢出。
  testWidgets('命盘页：小屏布局无溢出', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(750, 1334);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const DivinationApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('紫微斗数'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '小屏排盘校验');
    await tester.tap(find.text('女'));
    await tester.tap(find.text('阳历'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('紫薇排盘'));
    await tester.pumpAndSettle();

    expect(find.text('紫微斗数排盘'), findsOneWidget);
    expect(find.text('命宫'), findsOneWidget);
    expect(find.textContaining('命局:'), findsOneWidget);
  });
}
