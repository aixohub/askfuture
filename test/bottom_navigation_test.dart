import 'package:divination/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('底部导航栏：已去掉大厅，且点击命理、消息、我的打开对应页面', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const DivinationApp());
    await tester.pumpAndSettle();

    // 1. 验证底部导航项包含首页、命理、消息、我的，但没有大厅
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('命理'), findsOneWidget);
    expect(find.text('消息'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
    expect(find.text('大厅'), findsNothing);

    // 2. 点击"命理"导航项
    await tester.tap(find.text('命理'));
    await tester.pumpAndSettle();

    // 验证打开命理页面（AppBar 标题为命理）
    expect(find.widgetWithText(AppBar, '命理'), findsOneWidget);

    // 3. 点击"消息"导航项
    await tester.tap(find.text('消息'));
    await tester.pumpAndSettle();

    // 验证打开消息页面（AppBar 标题为消息）
    expect(find.widgetWithText(AppBar, '消息'), findsOneWidget);

    // 4. 点击"我的"导航项
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();

    // 验证打开我的页面（AppBar 标题为我的）
    expect(find.widgetWithText(AppBar, '我的'), findsOneWidget);

    // 5. 点击"首页"导航项，切回首页
    await tester.tap(find.text('首页'));
    await tester.pumpAndSettle();

    expect(find.text('易占师算卦大师'), findsOneWidget);
  });
}
