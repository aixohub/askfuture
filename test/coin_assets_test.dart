import 'dart:async';
import 'dart:ui' as ui;

import 'package:divination/widgets/copper_coin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('在线起卦铜钱素材', () {
    const cases = <String, String>{
      CopperCoinAssets.front: '正面（模块 2401 frontImg.png）',
      CopperCoinAssets.back: '背面（模块 2402 backImg.png）',
      CopperCoinAssets.shaking: '摇卦动画（模块 2403 yingBi.gif）',
    };

    for (final entry in cases.entries) {
      test('${entry.value} 已打包且尺寸 148×148', () async {
        final ByteData data = await rootBundle.load(entry.key);
        expect(data.lengthInBytes, greaterThan(0));

        final completer = Completer<ui.Image>();
        ui.decodeImageFromList(data.buffer.asUint8List(), completer.complete);
        final ui.Image image = await completer.future;
        expect(image.width, 148, reason: entry.key);
        expect(image.height, 148, reason: entry.key);
        image.dispose();
      });
    }

    testWidgets('铜钱组件使用官方图片（含摇动动画分支）', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: <Widget>[
                CopperCoinWidget(size: 45, isFront: true),
                CopperCoinWidget(size: 45, isFront: false),
                CopperCoinWidget(size: 45, isFront: true, isShaking: true),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      expect(images.length, 3);
      expect((images[0].image as AssetImage).assetName, CopperCoinAssets.front);
      expect((images[1].image as AssetImage).assetName, CopperCoinAssets.back);
      expect((images[2].image as AssetImage).assetName, CopperCoinAssets.shaking);
    });
  });
}
