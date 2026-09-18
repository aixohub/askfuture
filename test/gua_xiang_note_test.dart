import 'package:divination/main.dart';
import 'package:divination/models/divination_models.dart';
import 'package:divination/models/hexagram.dart';
import 'package:divination/models/qi_gua_record.dart';
import 'package:divination/pages/gua_xiang_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _guaXiangPage({QiGuaRecord? record}) => MaterialApp(
      home: GuaXiangPage(
        request: const QiGuaRequest(sex: 1, quetitle: '测试问占', quetype: 1),
        result: buildGuaResult(const <int>[1, 1, 1, 1, 1, 1]),
        methodName: '手工指定',
        castingTime: DateTime(2026, 9, 17, 10, 30),
        inputSummary: '',
        record: record,
      ),
    );

/// AppToast 内部有 1.8s 定时器，测试结束前需推进掉。
Future<void> _drainToast(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  setUp(() => QiGuaRecordStore.instance.clear());

  testWidgets('解卦笔记：点"完成"保存并回显', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_guaXiangPage());
    await tester.pumpAndSettle();

    await tester.tap(find.text('解卦笔记'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '世应相生，谋事可成');
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    await _drainToast(tester);

    expect(find.text('世应相生，谋事可成'), findsOneWidget);
  });

  testWidgets('解卦笔记：点空白关闭弹层也不会丢', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_guaXiangPage());
    await tester.pumpAndSettle();

    await tester.tap(find.text('解卦笔记'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '随手记的内容');
    // 点弹层外的遮罩关闭
    await tester.tapAt(const Offset(20, 40));
    await tester.pumpAndSettle();
    await _drainToast(tester);

    expect(find.text('随手记的内容'), findsOneWidget);
  });

  testWidgets('解卦笔记：写回起卦记录并可回看', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final record = QiGuaRecord(
      request: const QiGuaRequest(sex: 1, quetitle: '今年事业如何', quetype: 1),
      result: buildGuaResult(const <int>[1, 1, 1, 1, 1, 1]),
      methodName: '手工指定',
      castingTime: DateTime(2026, 9, 17, 10, 30),
      savedAt: DateTime(2026, 9, 17, 10, 31),
      inputSummary: '',
    );
    QiGuaRecordStore.instance.save(record);

    // 1) 首页"起卦记录"→ 打开该记录 → 编辑笔记
    await tester.pumpWidget(const DivinationApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('起卦记录'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('【乾为天】静卦'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('解卦笔记'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '回看时补充的笔记');
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    await _drainToast(tester);

    // 笔记已写回记录
    expect(QiGuaRecordStore.instance.records.single.note, '回看时补充的笔记');

    // 2) 返回首页后再次打开该记录，笔记仍在
    await tester.tap(find.byKey(const Key('guaXiangBottomCloseButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('起卦记录'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('【乾为天】静卦'));
    await tester.pumpAndSettle();

    expect(find.text('回看时补充的笔记'), findsOneWidget);
    expect(find.text('已保存排盘'), findsOneWidget);
  });

  testWidgets('解卦笔记：保存排盘时一并写入记录', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_guaXiangPage());
    await tester.pumpAndSettle();

    await tester.tap(find.text('解卦笔记'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '先写笔记再保存');
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    await _drainToast(tester);

    await tester.tap(find.text('保存排盘'));
    await tester.pumpAndSettle();
    await _drainToast(tester);

    final saved = QiGuaRecordStore.instance.records.single;
    expect(saved.note, '先写笔记再保存');
    expect(find.text('已保存排盘'), findsOneWidget);
  });
}
