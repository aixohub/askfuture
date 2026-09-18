import 'package:flutter/material.dart';

/// 爻线：阳爻为实线，阴爻为断线，动爻额外标记 x / o。
///
/// 视觉对应官方 `yinyao.png` / `yangyao.png`
/// （`/assets/bus/zyPaipan/public/img/quice/yingBiQiGua/`）。
class YaoLine extends StatelessWidget {
  final bool isYang;
  final bool isMoving;
  final String mark;
  final double width;
  final Color color;
  final double thickness;

  const YaoLine({
    super.key,
    required this.isYang,
    this.isMoving = false,
    this.mark = '',
    this.width = 44,
    this.color = Colors.black,
    this.thickness = 7.5,
  });

  @override
  Widget build(BuildContext context) {
    const gap = 7.0;
    final segment = (width - gap) / 2;
    return SizedBox(
      width: width,
      height: thickness,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isYang)
            _bar(width)
          else ...[
            _bar(segment),
            const SizedBox(width: gap),
            _bar(segment),
          ],
        ],
      ),
    );
  }

  Widget _bar(double length) => Container(
        width: length,
        height: thickness,
        color: color,
      );
}
