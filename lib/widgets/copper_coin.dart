import 'package:flutter/material.dart';

/// 在线起卦铜钱素材路径。
///
/// 资源直接取自官方 iOS 包：
/// `RN0615.app/assets/bus/zyPaipan/public/img/quice/yingBiQiGua/`
///
/// 对应官方模块：
///   * `frontImg.png` → 模块 2401，铜钱正面（字面）
///   * `backImg.png`  → 模块 2402，铜钱背面
///   * `yingBi.gif`   → 模块 2403，摇卦动画
///
/// 官方"在线起卦页面"（模块 2400）以
/// `frontImgSource / backImgSource / yingBiGif` 三个属性传入铜钱组件（模块 2391）。
class CopperCoinAssets {
  const CopperCoinAssets._();

  static const String front = 'assets/images/qigua/yingBiQiGua/frontImg.png';
  static const String back = 'assets/images/qigua/yingBiQiGua/backImg.png';
  static const String shaking = 'assets/images/qigua/yingBiQiGua/yingBi.gif';
}

/// 铜钱组件：正面/背面使用官方图片，摇卦过程中显示官方 GIF 动画。
///
/// 图片缺失时回退到 [_CopperCoinPainter] 手绘铜钱，保证界面可用。
class CopperCoinWidget extends StatelessWidget {
  final double size;

  /// true 为正面（字面），false 为背面。
  final bool isFront;

  /// 摇卦中：三枚铜钱统一显示官方 `yingBi.gif`。
  final bool isShaking;

  const CopperCoinWidget({
    super.key,
    this.size = 56,
    this.isFront = true,
    this.isShaking = false,
  });

  @override
  Widget build(BuildContext context) {
    final String asset = isShaking
        ? CopperCoinAssets.shaking
        : (isFront ? CopperCoinAssets.front : CopperCoinAssets.back);

    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => _FallbackCoin(
        size: size,
        isFront: isFront,
      ),
    );
  }
}

/// 素材缺失时的兜底手绘铜钱。
class _FallbackCoin extends StatelessWidget {
  final double size;
  final bool isFront;

  const _FallbackCoin({required this.size, required this.isFront});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(size, size),
        painter: _CopperCoinPainter(isFront: isFront),
      ),
    );
  }
}

class _CopperCoinPainter extends CustomPainter {
  final bool isFront;

  _CopperCoinPainter({required this.isFront});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. 铜钱外圆主体底色渐变（古铜青铜色质感）
    final outerGradient = RadialGradient(
      center: const Alignment(-0.2, -0.3),
      colors: const [
        Color(0xFFC7B286),
        Color(0xFFA59066),
        Color(0xFF86724A),
        Color(0xFF5F4E2D),
      ],
      stops: const [0.0, 0.45, 0.85, 1.0],
    );

    final outerPaint = Paint()
      ..shader = outerGradient.createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, outerPaint);

    // 2. 铜钱外凸边缘轮廓线（外廓）
    final rimPaint = Paint()
      ..color = const Color(0xFF675635)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06;
    canvas.drawCircle(center, radius * 0.94, rimPaint);

    final highlightRim = Paint()
      ..color = const Color(0xFFE4D6AE).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius * 0.90, highlightRim);

    // 3. 中间方孔（外圆内方）
    final holeSize = size.width * 0.30;
    final holeRect = Rect.fromCenter(center: center, width: holeSize, height: holeSize);

    final holeBgPaint = Paint()..color = const Color(0xFF3F341F);
    canvas.drawRect(holeRect, holeBgPaint);

    // 方孔边框凸起线（内廓）
    final holeRimPaint = Paint()
      ..color = const Color(0xFF7A6844)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.035;
    canvas.drawRect(holeRect, holeRimPaint);

    // 4. 文字绘制（正面为“乾隆通宝”，背面为“满文”纹路）
    if (isFront) {
      _drawFrontCharacters(canvas, size, center, radius, holeSize);
    } else {
      _drawBackSymbols(canvas, size, center, radius, holeSize);
    }
  }

  void _drawFrontCharacters(
    Canvas canvas,
    Size size,
    Offset center,
    double radius,
    double holeSize,
  ) {
    final textStyle = TextStyle(
      color: const Color(0xFF3E311A),
      fontSize: size.width * 0.16,
      fontWeight: FontWeight.w900,
      fontFamily: 'serif',
      shadows: const [
        Shadow(color: Color(0xFFDACBA3), offset: Offset(0.6, 0.6), blurRadius: 0.5),
      ],
    );

    // 乾 (上)
    _drawText(canvas, '乾', Offset(center.dx, center.dy - holeSize / 2 - size.width * 0.12), textStyle);
    // 隆 (下)
    _drawText(canvas, '隆', Offset(center.dx, center.dy + holeSize / 2 + size.width * 0.12), textStyle);
    // 通 (右)
    _drawText(canvas, '通', Offset(center.dx + holeSize / 2 + size.width * 0.12, center.dy), textStyle);
    // 宝 (左)
    _drawText(canvas, '宝', Offset(center.dx - holeSize / 2 - size.width * 0.12, center.dy), textStyle);
  }

  void _drawBackSymbols(
    Canvas canvas,
    Size size,
    Offset center,
    double radius,
    double holeSize,
  ) {
    final textStyle = TextStyle(
      color: const Color(0xFF3E311A),
      fontSize: size.width * 0.15,
      fontWeight: FontWeight.bold,
      shadows: const [
        Shadow(color: Color(0xFFDACBA3), offset: Offset(0.5, 0.5), blurRadius: 0.5),
      ],
    );

    // 背面满文或纹样表示
    _drawText(canvas, 'ᠪᠣᠣ', Offset(center.dx - holeSize / 2 - size.width * 0.13, center.dy), textStyle);
    _drawText(canvas, 'ᠴᡳᠣᠠᠨ', Offset(center.dx + holeSize / 2 + size.width * 0.13, center.dy), textStyle);
  }

  void _drawText(Canvas canvas, String text, Offset position, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(position.dx - tp.width / 2, position.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _CopperCoinPainter oldDelegate) {
    return oldDelegate.isFront != isFront;
  }
}
