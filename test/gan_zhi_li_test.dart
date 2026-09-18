import 'package:divination/models/ganzhi.dart';
import 'package:divination/models/lunar_calendar.dart';
import 'package:divination/widgets/gan_zhi_li_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

String _siZhuText(DateTime date) {
  final sizhu = computeSiZhu(date);
  return '[${animalOfYear(date.year)}] ${sizhu.year.text}年    ${sizhu.month.text}月    '
      '${sizhu.day.text}日    ${sizhu.hour.text}时';
}

void main() {
  group('干支历弹层（官方模块 3131 + 2225/2226/2227/2228）', () {
    testWidgets('四柱 / 星期表头 / 月历 / 节气中气', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GanZhiLiDialog(initialDate: DateTime(2026, 9, 17, 19, 16)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 四柱行：`[马] 丙午年    丁酉月    甲午日    甲戌时`
      expect(find.text(_siZhuText(DateTime(2026, 9, 17, 19, 16))), findsOneWidget);

      // 星期表头：一 二 三 四 五 六 日（周日在周六右边）
      final weekdays = ['一', '二', '三', '四', '五', '六', '日'];
      for (final w in weekdays) {
        expect(find.text(w), findsWidgets, reason: '缺少星期 $w');
      }

      // 节气 / 中气行（官方模块 2227）
      expect(find.text('节气:'), findsOneWidget);
      expect(find.text('中气:'), findsOneWidget);
      // 节气名同时出现在"节气行"和对应的日期格中
      expect(find.text('白露'), findsWidgets);
      expect(find.text('秋分'), findsWidgets);
      // 官方 `_formatDate`：月补零、日不补零
      expect(find.textContaining('2026年09月7日'), findsOneWidget);
      expect(find.textContaining('2026年09月23日'), findsOneWidget);

      // 月历底部显示农历日（初一显示月份）
      expect(find.text('初七'), findsWidgets);

      // 日期上方显示当天的日干支（例如 2026-09-17 为甲午日）
      expect(find.text('甲午'), findsWidgets);
    });

    testWidgets('切换日期后四柱与"回到今天"联动', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GanZhiLiDialog(initialDate: DateTime(2026, 9, 17, 19, 16)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 点击 9 月 7 日（白露当天）→ 四柱随之变化
      await tester.tap(find.text('7').first);
      await tester.pumpAndSettle();
      expect(find.text(_siZhuText(DateTime(2026, 9, 7, 19, 16))), findsOneWidget);

      // 选中日不是今天 → 出现"回到今天"
      expect(find.text('回到今天'), findsOneWidget);
      await tester.tap(find.text('回到今天'));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      expect(
        find.text(_siZhuText(DateTime(now.year, now.month, now.day, 19, 16))),
        findsOneWidget,
      );
    });

    testWidgets('月份切换：上月/下月按钮', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GanZhiLiDialog(initialDate: DateTime(2026, 9, 17, 19, 16)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2026年9月'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      expect(find.text('2026年8月'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(find.text('2026年9月'), findsOneWidget);
      // 8 月 23 日处暑
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      expect(find.text('处暑'), findsWidgets);
    });

    testWidgets('上下滑动切换月份及节气行"今"按钮', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final now = DateTime.now();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GanZhiLiDialog(initialDate: now),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 当前处于当月，节气行右侧不显示"今"按钮
      expect(find.byKey(const ValueKey('gan_zhi_li_today_btn')), findsNothing);

      // 向上滑动月历，切换至下个月
      await tester.drag(find.text('15').first, const Offset(0, -250));
      await tester.pumpAndSettle();

      // 切换月份后，节气行最右边出现"今"按钮
      expect(find.byKey(const ValueKey('gan_zhi_li_today_btn')), findsOneWidget);

      // 点击"今"按钮，切换回当前月份
      await tester.tap(find.byKey(const ValueKey('gan_zhi_li_today_btn')));
      await tester.pumpAndSettle();

      expect(find.text('${now.year}年${now.month}月'), findsOneWidget);
      expect(find.byKey(const ValueKey('gan_zhi_li_today_btn')), findsNothing);

      // 向下滑动月历，切换至上个月
      await tester.drag(find.text('15').first, const Offset(0, 250));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('gan_zhi_li_today_btn')), findsOneWidget);
    });
  });
}
