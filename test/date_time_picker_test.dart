import 'package:divination/models/lunar_calendar.dart';
import 'package:divination/widgets/date_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('起卦时间选择器（官方 DatePick / 模块 2234 + 2236）', () {
    test('可选范围对齐 Config.DatePick：1876-05-01 ~ 2089-05-01', () {
      expect(DateTimePickerSheet.minDate, DateTime(1876, 5, 1));
      expect(DateTimePickerSheet.maxDate, DateTime(2089, 5, 1));
      expect(DateTimePickerSheet.actionColor, const Color(0xFF2AA9B9));
    });

    test('时间格式对齐 Config.DatePick.format：YYYY-MM-DD HH:mm', () {
      expect(
        CastingTimeField.format(DateTime(2026, 9, 7, 8, 5)),
        '2026-09-07 08:05',
      );
    });

    testWidgets('官方同款字段：日历图标 + 时间文本', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CastingTimeField(
              fieldKey: const Key('castingTimeField'),
              value: DateTime(2026, 9, 17, 10, 30),
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2026-09-17 10:30'), findsOneWidget);
      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as AssetImage).assetName, kDateIconAsset);
    });

    testWidgets('弹层：取消关闭且不改动时间', (WidgetTester tester) async {
      DateTime? picked;
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CastingTimeField(
              fieldKey: const Key('castingTimeField'),
              value: DateTime(2026, 9, 17, 10, 30),
              onTap: () async {
                tapped = true;
                picked = await DateTimePickerSheet.show(
                  tester.element(find.byType(CastingTimeField)),
                  initial: DateTime(2026, 9, 17, 10, 30),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('castingTimeField')));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
      expect(find.byType(ListWheelScrollView), findsNWidgets(5));

      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(picked, isNull);
    });

    testWidgets('农历切换：确定后按官方 lunar2solar 换算成公历', (WidgetTester tester) async {
      DateTime? picked;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CastingTimeField(
              fieldKey: const Key('castingTimeField'),
              value: DateTime(2026, 9, 18, 10, 30),
              onTap: () async {
                picked = await DateTimePickerSheet.show(
                  tester.element(find.byType(CastingTimeField)),
                  initial: DateTime(2026, 9, 18, 10, 30),
                  isShowLunar: true,
                  isLunar: true,
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('castingTimeField')));
      await tester.pumpAndSettle();

      // 默认农历模式：公历/农历切换按钮 + 农历月/日文案
      expect(find.text('公历'), findsOneWidget);
      expect(find.text('农历'), findsOneWidget);
      expect(find.text('八月'), findsOneWidget);
      expect(find.text('初八'), findsOneWidget); // 选中日：农历八月初八
      // 2026 年无闰月，故不出现"闰月"勾选
      expect(find.byKey(const Key('lunarLeapCheck')), findsNothing);

      // 切回公历再切回农历，界面保持一致
      await tester.tap(find.text('公历'));
      await tester.pumpAndSettle();
      expect(find.text('八月'), findsNothing);
      await tester.tap(find.text('农历'));
      await tester.pumpAndSettle();
      expect(find.text('八月'), findsOneWidget);

      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();

      // 初始值 2026-09-18 10:30 → 农历 八月初八（与官方换算一致）
      final lunar = lunarDateOf(DateTime(2026, 9, 18));
      expect(lunar, isNotNull);
      expect(picked, isNotNull);
      expect(picked!.year, 2026);
      expect(picked!.month, 9);
      expect(picked!.day, 18);
      expect(picked!.hour, hourOfLunarHourIndex(lunarHourIndex(10)));
    });

    testWidgets('闰月年份显示"闰月"勾选（2023 闰二月）', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CastingTimeField(
              fieldKey: const Key('castingTimeField'),
              value: DateTime(2023, 3, 22, 10, 0),
              onTap: () async {
                await DateTimePickerSheet.show(
                  tester.element(find.byType(CastingTimeField)),
                  initial: DateTime(2023, 3, 22, 10, 0),
                  isShowLunar: true,
                  isLunar: true,
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('castingTimeField')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('lunarLeapCheck')), findsOneWidget);
      // 勾选说明 + 月滚轮上的"闰二月"标签
      expect(find.text('闰二月'), findsWidgets);
    });
  });
}
