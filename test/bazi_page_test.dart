import 'package:divination/main.dart';
import 'package:divination/models/bazi.dart';
import 'package:divination/models/bazi_record.dart';
import 'package:divination/models/ganzhi.dart';
import 'package:divination/pages/bazi_paipan_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

BaZiInput _input({bool useTrueSolarTime = false}) => BaZiInput(
      sex: 1,
      dateType: 1,
      birthTime: DateTime(2026, 9, 17, 19, 16),
      province: '广东',
      city: '广州',
      cityText: '广东  广州',
      useTrueSolarTime: useTrueSolarTime,
      description: '今年事业如何',
    );

Future<void> _openPage(WidgetTester tester, BaZiInput input) async {
  await tester.pumpWidget(MaterialApp(home: BaZiPaiPanPage(input: input)));
  await tester.pumpAndSettle();
}

/// 单选标签的选中色（官方 `typeTextAct`）。
const Color _baziSelectedColor = Color(0xFF00ABAE);

Color? _labelColor(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style?.color;

String _fieldText(WidgetTester tester, String key) {
  final text = tester.widget<Text>(
    find.descendant(of: find.byKey(Key(key)), matching: find.byType(Text)),
  );
  return text.data!;
}

void main() {
  setUp(() {
    BaZiRecordStore.instance.clear();
  });
  group('首页八字轻测面板（官方模块 2423）', () {
    testWidgets('切到八字轻测 Tab 显示表单', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const DivinationApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('八字轻测'));
      await tester.pumpAndSettle();

      expect(find.text('命主性别:'), findsOneWidget);
      expect(find.text('日期类型:'), findsOneWidget);
      expect(find.text('出生日期:'), findsOneWidget);
      expect(find.text('出生城市:'), findsOneWidget);
      expect(find.text('使用真太阳时'), findsOneWidget);
      expect(find.text('问题描述'), findsOneWidget);
      expect(find.text('八字排盘'), findsOneWidget);
      expect(find.text('1、请描述具体求测问题，便于老师针对性解答。'), findsOneWidget);
      expect(find.text('3、时辰不清楚，可备注大概时间(如3-5点)。'), findsOneWidget);
    });

    testWidgets('默认命主性别为男、日期类型为阴历', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const DivinationApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('八字轻测'));
      await tester.pumpAndSettle();

      expect(_labelColor(tester, '男'), _baziSelectedColor);
      expect(_labelColor(tester, '女'), isNot(_baziSelectedColor));
      expect(_labelColor(tester, '阴历'), _baziSelectedColor);
      expect(_labelColor(tester, '阳历'), isNot(_baziSelectedColor));
    });

    testWidgets('校验：问题 / 真太阳时出生地，默认性别日期类型可直接提交', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const DivinationApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('八字轻测'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('八字排盘'));
      await tester.pump();
      expect(find.text('请输入求测问题~'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));

      // 勾选真太阳时但未选出生地 → 官方提示
      await tester.tap(find.text('使用真太阳时'));
      await tester.pumpAndSettle();
      expect(find.text('请先选择出生地点'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));

      // 性别与日期类型已默认选中，填问题即可进入排盘页
      await tester.enterText(find.byType(TextField).first, '今年事业如何');
      await tester.pumpAndSettle();
      await tester.tap(find.text('八字排盘'));
      await tester.pumpAndSettle();

      // 进入排盘页后直出专业命盘，不再有页签
      expect(find.text('基本信息'), findsNothing);
      expect(find.text('基本命盘'), findsNothing);
      expect(find.text('专业命盘'), findsNothing);
      expect(find.text('求测标题：'), findsOneWidget);
    });

    testWidgets('出生城市：页面单框展示，弹框内省市并列联动', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const DivinationApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('八字轻测'));
      await tester.pumpAndSettle();

      // 页面展示框保持单个（占位「请选择」）
      expect(find.byKey(const Key('baziAreaPicker')), findsOneWidget);
      expect(_fieldText(tester, 'baziAreaPicker'), '请选择');

      // 弹框：省 / 市两列滚轮并列
      await tester.tap(find.byKey(const Key('baziAreaPicker')));
      await tester.pumpAndSettle();
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('确定'), findsOneWidget);
      expect(find.text('省'), findsOneWidget);
      expect(find.text('市'), findsOneWidget);
      expect(find.byType(ListWheelScrollView), findsNWidgets(2));

      // 省份滚轮往前选一项（忽略 → 北京），城市滚轮联动
      await tester.drag(
        find.byKey(const Key('areaProvinceWheel')),
        const Offset(0, -40),
      );
      await tester.pumpAndSettle();
      expect(find.text('东城区'), findsWidgets, reason: '城市滚轮应联动到北京各区');

      // 城市滚轮选一项（忽略 → 东城区）
      await tester.drag(
        find.byKey(const Key('areaCityWheel')),
        const Offset(0, -40),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();

      // 页面单框回填「省  市」
      expect(_fieldText(tester, 'baziAreaPicker'), '北京  东城区');
    });

    testWidgets('出生日期：八字轻测与紫微斗数保持一致', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const DivinationApp());
      await tester.pumpAndSettle();

      Future<void> shiftYear(String fieldKey) async {
        await tester.tap(find.byKey(Key(fieldKey)));
        await tester.pumpAndSettle();
        // 向下拖动 = 年份回退 2 年（官方八字轻测禁止选择晚于当前时间的出生时间）
        await tester.drag(
          find.byKey(const Key('pickerYearWheel')),
          const Offset(0, 36 * 2),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('确定'));
        await tester.pumpAndSettle();
      }

      // 八字轻测：改日期
      await tester.tap(find.text('八字轻测'));
      await tester.pumpAndSettle();
      final baziBefore = _fieldText(tester, 'baziBirthTimeField');
      await shiftYear('baziBirthTimeField');
      final baziAfter = _fieldText(tester, 'baziBirthTimeField');
      expect(baziAfter, isNot(baziBefore));

      // 紫微斗数：沿用八字轻测的出生日期
      await tester.tap(find.text('紫微斗数'));
      await tester.pumpAndSettle();
      expect(_fieldText(tester, 'ziweiBirthTimeField'), baziAfter);

      // 紫微斗数改日期后切回，八字轻测同步更新
      await shiftYear('ziweiBirthTimeField');
      final ziweiAfter = _fieldText(tester, 'ziweiBirthTimeField');
      expect(ziweiAfter, isNot(baziAfter));

      await tester.tap(find.text('八字轻测'));
      await tester.pumpAndSettle();
      expect(_fieldText(tester, 'baziBirthTimeField'), ziweiAfter);
    });

    testWidgets('小屏：出生城市展示框与两个页签均无溢出', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(750, 1334);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const DivinationApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('八字轻测'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('baziAreaPicker')), findsOneWidget);
      expect(find.text('使用真太阳时'), findsOneWidget);

      await tester.tap(find.text('紫微斗数'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ziweiAreaPicker')), findsOneWidget);
      expect(find.text('使用真太阳时'), findsOneWidget);
    });
  });

  group('八字排盘页（专业命盘直出）', () {
    testWidgets('命主信息与排盘内容直接展示，无页签头', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await _openPage(tester, _input());

      // 不再展示基本信息与专业命盘页签
      expect(find.text('基本信息'), findsNothing);
      expect(find.text('基本命盘'), findsNothing);
      expect(find.text('专业命盘'), findsNothing);

      // 命主信息直接展示
      expect(find.text('求测标题：'), findsOneWidget);
      expect(find.text('今年事业如何'), findsOneWidget);
      expect(find.text('姓名：'), findsOneWidget);
      expect(find.text('地点：'), findsOneWidget);
      expect(find.text('广东  广州'), findsOneWidget);
      // 公历与农历对齐展示，年月日时字段精准对齐
      expect(find.text('时间：'), findsWidgets);
      expect(find.text('公历'), findsOneWidget);
      expect(find.text('农历'), findsOneWidget);
      expect(find.text('2026 年'), findsNWidgets(2));
      expect(find.text('09 月'), findsOneWidget);
      expect(find.text('17 日'), findsOneWidget);
      expect(find.text('19 时'), findsOneWidget);
      expect(find.textContaining('16 分'), findsOneWidget);
      expect(find.text('八月'), findsOneWidget);
      expect(find.text('初七'), findsOneWidget);
      expect(find.text('戌时'), findsOneWidget);
    });

    testWidgets('专业命盘：默认定位到当前大运与当前流年', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final birth = DateTime(1990, 6, 15, 6, 20);
      await _openPage(
        tester,
        BaZiInput(
          sex: 1,
          dateType: 1,
          birthTime: birth,
          province: '广东',
          city: '广州',
          cityText: '广东  广州',
          useTrueSolarTime: false,
          description: '今年事业如何',
        ),
      );

      final pan = buildBaZiPan(birth, male: true);
      final firstYear = pan.qiYunDetail.jiaoYunDate.year;
      final nowYear = DateTime.now().year;
      final daYunIndex = initialDaYunIndex(
        firstDaYunYear: firstYear,
        currentYear: nowYear,
      );
      final liuNian = yearGanZhi(nowYear);

      List<String?> rowTexts(String label) {
        final row = find
            .ancestor(of: find.text(label), matching: find.byType(Row))
            .first;
        return tester
            .widgetList<Text>(find.descendant(of: row, matching: find.byType(Text)))
            .map((t) => t.data)
            .toList();
      }

      // 主对照表：大运列 = 当前所处大运，流年列 = 当前流年
      final ganRow = rowTexts('天干：');
      expect(ganRow[1], pan.daYun[daYunIndex].ganZhi.gan,
          reason: '大运列应定位到当前所处大运');
      expect(ganRow[2], liuNian.gan, reason: '流年列应定位到当前年份');
      final zhiRow = rowTexts('地支：');
      expect(zhiRow[1], pan.daYun[daYunIndex].ganZhi.zhi);
      expect(zhiRow[2], liuNian.zhi);

      // 流年选择器：当前年份单元格高亮（选中色 0xFFE2E4E6）
      final highlighted = find.byWidgetPredicate((widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).color == const Color(0xFFE2E4E6));
      expect(
        find.descendant(of: highlighted, matching: find.text('$nowYear')),
        findsWidgets,
        reason: '当前年份应处于选中状态',
      );
    });

    testWidgets('专业命盘：主对照表（流年/大运/四柱）、起运交运与保存排盘功能',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await _openPage(tester, _input());

      // 主表各列标题
      for (final col in ['流年', '大运', '年柱', '月柱', '日柱', '时柱']) {
        expect(find.text(col), findsWidgets, reason: '缺少 $col');
      }

      // 主表属性行标签
      for (final label in ['十神：', '天干：', '地支：', '遁藏：', '旬空：', '地势：', '纳音：']) {
        expect(find.text(label), findsOneWidget, reason: '缺少 $label');
      }

      // 起运与交运提示
      expect(find.text('起运：'), findsOneWidget);
      expect(find.text('交运：'), findsOneWidget);

      // 底部操作按钮：保存排盘
      expect(find.text('保存排盘'), findsOneWidget);
      await tester.tap(find.text('保存排盘'));
      await tester.pump();
      expect(find.text('保存成功'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('已保存排盘'), findsOneWidget);
      expect(BaZiRecordStore.instance.records.length, 1);

      // 重复点击：提示已保存成功
      await tester.tap(find.text('已保存排盘'));
      await tester.pump();
      expect(find.text('本次排盘已保存成功，可随时至 起卦记录 查看。'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('起卦记录弹层：可切换至八字排盘并回看已保存记录', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      BaZiRecordStore.instance.save(
        BaZiRecord(
          input: _input(),
          savedAt: DateTime(2026, 9, 18, 11, 20),
        ),
      );

      await tester.pumpWidget(const DivinationApp());
      await tester.pumpAndSettle();

      // 点击首页"起卦记录"
      await tester.tap(find.text('起卦记录'));
      await tester.pumpAndSettle();

      // 切换到"八字排盘"页签
      await tester.tap(find.byKey(const Key('recordTabBazi')));
      await tester.pumpAndSettle();

      expect(find.text('八字排盘 · 今年事业如何'), findsOneWidget);

      // 点击该条记录，跳转到八字排盘页，底部显示"已保存排盘"与"关闭"
      await tester.tap(find.text('八字排盘 · 今年事业如何'));
      await tester.pumpAndSettle();

      expect(find.text('求测标题：'), findsOneWidget);
      expect(find.text('今年事业如何'), findsWidgets);
      expect(find.text('已保存排盘'), findsOneWidget);
      expect(find.byKey(const Key('baziCloseButton')), findsOneWidget);

      // 点击关闭按钮跳转回到首页
      await tester.tap(find.byKey(const Key('baziCloseButton')));
      await tester.pumpAndSettle();
      expect(find.text('八字轻测'), findsOneWidget);
    });

    testWidgets('专业命盘与用户截图数据精确对齐（2026-10-27 06:38 男命）',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final screenshotInput = BaZiInput(
        sex: 1,
        dateType: 1,
        birthTime: DateTime(2026, 10, 27, 6, 38),
        province: '国外',
        city: '忽略',
        cityText: '国外  忽略',
        useTrueSolarTime: false,
        description: '看看',
      );

      await _openPage(tester, screenshotInput);

      // 命主信息与起运交运
      expect(find.text('看看'), findsOneWidget);
      expect(find.text('(男)'), findsOneWidget);
      expect(find.textContaining('寒露 2026 年 10 月 08 日,立冬 2026 年 11 月 07 日'), findsOneWidget);
      expect(find.textContaining('3 年 9 个月 26 天 11 小时'), findsOneWidget);
      expect(find.textContaining('2030 年 08 月 22 日交运'), findsOneWidget);

      // 主表十神：七杀 正财 食神 偏财 元男 伤官
      expect(find.text('七杀'), findsWidgets);
      expect(find.text('正财'), findsWidgets);
      expect(find.text('食神'), findsWidgets);
      expect(find.text('偏财'), findsWidgets);
      expect(find.text('元男'), findsOneWidget);
      expect(find.text('伤官'), findsWidgets);

      // 主表天干：庚 己 丙 戊 甲 丁
      for (final gan in ['庚', '己', '丙', '戊', '甲', '丁']) {
        expect(find.text(gan), findsWidgets, reason: '天干缺少 $gan');
      }

      // 主表地支：戌 亥 午 卯
      for (final zhi in ['戌', '亥', '午', '卯']) {
        expect(find.text(zhi), findsWidgets, reason: '地支缺少 $zhi');
      }

      // 纳音
      expect(find.text('钗钏金'), findsOneWidget);
      expect(find.text('平地木'), findsWidgets);
      expect(find.text('天河水'), findsOneWidget);
      expect(find.text('山头火'), findsOneWidget);
      expect(find.text('炉中火'), findsOneWidget);
    });

    testWidgets('真太阳时：时间行标注', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await _openPage(tester, _input(useTrueSolarTime: true));
      expect(find.textContaining('真太阳时'), findsWidgets);
    });
  });
}
