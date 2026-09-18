import 'package:divination/main.dart';
import 'package:divination/models/qi_gua_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 首页 → 排盘页（默认手工指定）→ 六爻全部选"少阳"→ 乾为天静卦 → 卦象页。
Future<void> gotoGuaXiangByManual(WidgetTester tester, {String question = '今年事业能否晋升'}) async {
  await tester.pumpWidget(const DivinationApp());
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextField).first, question);
  await tester.tap(find.text('事业官运'));
  await tester.tap(find.text('男'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('开 始 起 卦'));
  await tester.pumpAndSettle();

  for (var i = 0; i < 6; i++) {
    await tester.tap(find.text('请选择').first);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListWheelScrollView), const Offset(0, -44 * 3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text('开始起卦'));
  await tester.pumpAndSettle();
}

void main() {
  // 起卦记录为进程内存储，逐个用例清空，避免相互影响
  setUp(() => QiGuaRecordStore.instance.clear());

  /// 首页"开始起卦"完整链路：
  /// 首页表单 → 校验 → 排盘方式选择页 → 起卦 → 卦象页。
  testWidgets('首页开始起卦：校验 + 参数换算 + 排盘跳转', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const DivinationApp());
    await tester.pumpAndSettle();

    // 1. 首页标题与"在线起卦"卡片
    expect(find.text('易占师算卦大师'), findsOneWidget);
    expect(find.text('开 始 起 卦'), findsOneWidget);
    expect(find.text('占事分类:'), findsOneWidget);

    // 2. 占事分类共 16 项（已移除测手机号与消息联络）
    expect(find.text('婚姻情感'), findsOneWidget);
    expect(find.text('股票期货'), findsOneWidget);
    expect(find.text('其它杂占'), findsOneWidget);
    expect(find.text('测手机号'), findsNothing);
    expect(find.text('消息联络'), findsNothing);

    // 3. 未选择分类即点击 → 提示"问题分类可提高预测准确性，请仔细选择"
    await tester.tap(find.text('开 始 起 卦'));
    await tester.pump();
    expect(find.text('问题分类可提高预测准确性，请仔细选择'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2000));

    // 4. 选择分类但不填标题 → 提示"请输入求测问题~"
    await tester.tap(find.text('婚姻情感'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('开 始 起 卦'));
    await tester.pump();
    expect(find.text('请输入求测问题~'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2000));

    // 5. 性别默认选中"男"：填写标题后直接进入排盘方式选择页，
    //    分类按官方规则 3 → 2（感情/婚姻(男)）
    await tester.enterText(find.byType(TextField).first, '我和他能结婚吗');
    await tester.pumpAndSettle();
    await tester.tap(find.text('开 始 起 卦'));
    await tester.pumpAndSettle();

    expect(find.text('排盘方式选择'), findsOneWidget);
    expect(find.text('占卜问题：'), findsOneWidget);
    expect(find.text('我和他能结婚吗'), findsOneWidget);
    expect(find.text('占事分类：感情/婚姻(男)'), findsOneWidget);
    expect(find.text('卦主性别：男'), findsOneWidget);
    expect(find.text('起卦方式：'), findsOneWidget);

    // 7. 8 种起卦方式全部呈现
    for (final name in ['在线起卦', '电脑自动', '手工指定', '时间起卦', '单数起卦', '双数起卦', '汉字起卦', '卦名起卦']) {
      expect(find.text(name), findsWidgets, reason: '缺少起卦方式 $name');
    }

    // 8. 电脑自动 → 开始起卦 → 卦象页
    await tester.tap(find.text('电脑自动').first);
    await tester.pumpAndSettle();
    expect(find.text('点击下方按钮，系统自动起卦'), findsOneWidget);
    await tester.tap(find.text('开始起卦'));
    await tester.pumpAndSettle();

    expect(find.text('易占师'), findsWidgets);
    // 卦象图：占事信息 + 干支旬空 + 六神表 + 工具条
    expect(find.textContaining('问占：'), findsOneWidget);
    expect(find.textContaining('干支：', findRichText: true), findsWidgets);
    expect(find.textContaining('旬空', findRichText: true), findsWidgets);
    expect(find.text('六神'), findsOneWidget);
    expect(find.text('梅花盘'), findsOneWidget);
    expect(find.text('收藏'), findsOneWidget);
    expect(find.text('复制'), findsOneWidget);
    expect(find.text('截图'), findsOneWidget);
    expect(find.text('保存排盘'), findsOneWidget);
    expect(find.byKey(const Key('guaXiangBottomCloseButton')), findsOneWidget);
    expect(find.text('关闭'), findsWidgets);

    // 点击底部关闭按钮跳转回到首页
    await tester.tap(find.byKey(const Key('guaXiangBottomCloseButton')));
    await tester.pumpAndSettle();
    expect(find.text('开 始 起 卦'), findsOneWidget);
  });

  /// 在线摇卦：点击铜钱开始/停止，累计六次后可起卦。
  testWidgets('首页开始起卦：在线摇卦六次后进入卦象页', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const DivinationApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '近期求财是否顺利');
    // "财运生意"同时出现在分类网格与热门占问入口，这里取卡片内的分类按钮
    await tester.tap(find.text('财运生意').first);
    await tester.tap(find.text('女'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('开 始 起 卦'));
    await tester.pumpAndSettle();

    expect(find.text('占事分类：财运/生意'), findsOneWidget);

    // 排盘页默认"手工指定"，先切换到"在线起卦"
    await tester.tap(find.text('在线起卦').first);
    await tester.pumpAndSettle();

    // 摇卦六次：每次点击"开始第N次摇卦"再点击"停止"
    for (var i = 1; i <= 6; i++) {
      await tester.tap(find.text('开始第$i次摇卦'));
      await tester.pump();
      // 摇动中提示文案切换为"点击铜钱停止第N次摇卦"
      expect(find.text('点击铜钱停止第$i次摇卦'), findsOneWidget);
      await tester.tap(find.text('开始第$i次摇卦'));
      await tester.pump(const Duration(milliseconds: 600));
    }

    // 六爻全备后出现"开始起卦"按钮
    expect(find.text('开始起卦'), findsOneWidget);
    await tester.tap(find.text('开始起卦'));
    await tester.pumpAndSettle();

    expect(find.text('易占师'), findsWidgets);
    expect(find.text('六神'), findsOneWidget);
    expect(find.text('保存排盘'), findsOneWidget);
  });

  /// 小屏（iPhone SE 尺寸）下首页与排盘页不应出现布局溢出。
  testWidgets('首页开始起卦：小屏布局无溢出', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(750, 1334);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const DivinationApp());
    await tester.pumpAndSettle();
    expect(find.text('易占师算卦大师'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '近期事业运势如何');
    await tester.tap(find.text('事业官运'));
    await tester.tap(find.text('男'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('开 始 起 卦'));
    await tester.pumpAndSettle();

    expect(find.text('占卜问题：'), findsOneWidget);
    // 默认即为"手工指定"
    expect(find.textContaining('手工指定'), findsWidgets);
    expect(find.text('请指定每一爻的属性'), findsOneWidget);
  });

  /// 软键盘弹出（viewInsets 变化）时首页不应出现布局溢出。
  testWidgets('首页开始起卦：软键盘弹出无溢出', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(750, 1334);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(const DivinationApp());
    await tester.pumpAndSettle();

    // 模拟键盘顶起 300 逻辑像素
    tester.view.viewInsets = const FakeViewPadding(bottom: 600);
    await tester.pumpAndSettle();
    expect(find.text('易占师算卦大师'), findsOneWidget);

    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pumpAndSettle();
    expect(find.text('开 始 起 卦'), findsOneWidget);
  });

  /// 手工指定：六爻全部指定为少阳 → 乾为天静卦。
  testWidgets('首页开始起卦：手工指定六爻推卦', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const DivinationApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '今年事业能否晋升');
    await tester.tap(find.text('事业官运'));
    await tester.tap(find.text('男'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('开 始 起 卦'));
    await tester.pumpAndSettle();

    // 默认起卦方式即为"手工指定"
    expect(find.text('请指定每一爻的属性'), findsOneWidget);

    // 未选择任何一爻即起卦 → 官方提示
    await tester.tap(find.text('开始起卦'));
    await tester.pump();
    expect(find.text('摇卦不能为空，每一次摇卦都需要记录~'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2000));

    // 六爻依次指定为"少阳"：点击选择框 → 滚轮下移 3 格（请选择→少阳）→ 确定
    expect(find.text('请选择'), findsNWidgets(6));
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.text('请选择').first);
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListWheelScrollView), const Offset(0, -44 * 3));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
    }

    expect(find.text('少阳(2正1背)'), findsNWidgets(6));

    await tester.tap(find.text('开始起卦'));
    await tester.pumpAndSettle();

    // 静卦时本卦与变卦均为乾为天
    expect(find.text('乾为天 (乾-六冲)'), findsNWidgets(2));
    // 六爻装卦：乾为天 六爻为子孙甲子水…父母壬戌土，世六应三
    // 静卦时本卦、变卦两列同时渲染
    expect(find.text('子孙甲子水'), findsNWidgets(2));
    expect(find.text('父母壬戌土'), findsNWidgets(2));
    expect(find.text('妻财甲寅木'), findsNWidgets(2));
    expect(find.text('世'), findsWidgets);
    expect(find.text('应'), findsWidgets);

    // 保存排盘 → 首页"起卦记录"可查看
    await tester.ensureVisible(find.text('保存排盘'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存排盘'));
    await tester.pump();
    expect(find.text('保存成功'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2000));
    expect(find.text('已保存排盘'), findsOneWidget);

    // 点击底部关闭按钮直接跳到首页
    await tester.tap(find.byKey(const Key('guaXiangBottomCloseButton')));
    await tester.pumpAndSettle();
    expect(find.text('易占师算卦大师'), findsOneWidget);

    await tester.tap(find.text('起卦记录'));
    await tester.pumpAndSettle();
    expect(find.text('【乾为天】静卦'), findsWidgets);
    expect(find.text('占卜问题：今年事业能否晋升'), findsOneWidget);
  });

  /// 起卦时间：点击时间栏弹出官方同款滚轮选择器（年/月/日/时/分 + 取消/确定），
  /// 对齐官方 DatePick（模块 2234）在 iOS 的弹层（模块 2236）。
  testWidgets('起卦时间：滚轮选择器可选并回填', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const DivinationApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '今年运势如何');
    await tester.tap(find.text('事业官运'));
    await tester.tap(find.text('男'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('开 始 起 卦'));
    await tester.pumpAndSettle();

    String fieldText() {
      final text = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const Key('castingTimeField')),
          matching: find.byType(Text),
        ),
      );
      // 字段文案为 `YYYY-MM-DD HH:mm（农历）`，解析时去掉农历括注
      return text.data!.split('（').first;
    }

    final before = DateTime.parse(fieldText().replaceFirst(' ', 'T'));

    // 排盘页占事信息中的起卦时间 → 弹出官方同款滚轮选择器
    await tester.tap(find.byKey(const Key('castingTimeField')));
    await tester.pumpAndSettle();

    // 弹层结构：取消 / 确定、年月日时分标签、五列滚轮
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('确定'), findsOneWidget);
    for (final label in ['年', '月', '日', '时', '分']) {
      expect(find.text(label), findsOneWidget, reason: '缺少滚轮标签 $label');
    }
    expect(find.byType(ListWheelScrollView), findsNWidgets(5));

    // 拖动"日"滚轮向前滚动（itemExtent = 36）
    await tester.drag(
      find.byKey(const Key('pickerDayWheel')),
      const Offset(0, -36 * 3),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    // 回到排盘页，时间已按滚轮选择回填（晚于选择前的时间）
    expect(find.text('占卜问题：'), findsOneWidget);
    final after = DateTime.parse(fieldText().replaceFirst(' ', 'T'));
    expect(after.isAfter(before), isTrue,
        reason: '滚轮选择后应回填更晚的时间：$before -> $after');
  });

  /// 卦象页神煞栏：折叠显示贵人/驿马/桃花，展开补出日禄
  /// （口径对齐 sixyao-main liuyaodata.js）。
  testWidgets('卦象页：神煞栏折叠与展开', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await gotoGuaXiangByManual(tester);

    expect(find.textContaining('贵人 —'), findsWidgets);
    expect(find.textContaining('驿马 —'), findsWidgets);
    expect(find.textContaining('桃花 —'), findsWidgets);
    expect(find.textContaining('日禄 —'), findsNothing);

    await tester.tap(find.text('展开').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('日禄 —'), findsWidgets);
    expect(find.text('收起'), findsOneWidget);
  });

  /// 卦象页"复制"：写入剪贴板，文案对齐官方 copyPaiPanInfo。
  testWidgets('卦象页：复制排盘信息到剪贴板', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final clipboardCalls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'Clipboard.setData') clipboardCalls.add(call);
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await gotoGuaXiangByManual(tester, question: '今年事业能否晋升');

    await tester.ensureVisible(find.text('复制'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('复制'));
    await tester.pump();
    expect(find.text('已复制到剪贴板'), findsOneWidget);

    expect(clipboardCalls, isNotEmpty);
    final copied = (clipboardCalls.last.arguments as Map)['text'] as String;
    expect(copied.startsWith('易占师\n'), isTrue);
    expect(copied.contains('占问：今年事业能否晋升'), isTrue);
    expect(copied.contains('本卦：乾为天/乾宫六冲'), isTrue);
    expect(copied.contains('(旬空：'), isTrue);
    // 六行爻（含六神简写）
    expect(copied.contains('龙 '), isTrue);
    expect(copied.split('\n').length, 12);
    // 让 Toast 计时器落地，避免测试结束时仍有 pending timer
    await tester.pump(const Duration(milliseconds: 2000));
  });

  /// 卦象页"截图"：显示"保存到相册 / 关闭"浮层，可关闭返回。
  testWidgets('卦象页：截图浮层与关闭', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await gotoGuaXiangByManual(tester);

    await tester.ensureVisible(find.text('截图'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('截图'));
    await tester.pumpAndSettle();

    // 官方截图浮层：保存到相册 70% + 关闭 30%，同时隐藏工具条
    expect(find.text('保存到相册'), findsOneWidget);
    expect(find.byKey(const Key('snapShotCloseButton')), findsOneWidget);
    expect(find.text('复制'), findsNothing);

    await tester.tap(find.byKey(const Key('snapShotCloseButton')));
    await tester.pumpAndSettle();
    expect(find.text('保存到相册'), findsNothing);
    expect(find.text('复制'), findsOneWidget);
  });
}
