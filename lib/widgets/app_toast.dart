import 'package:flutter/material.dart';

/// 轻提示，用于承载官方实现中 `Toast.warn(...)` 的校验文案。
///
/// 官方文案（首页 `_checkInput`）：
///   * 未选占事分类 → "问题分类可提高预测准确性，请仔细选择"
///   * 未填/过短标题 → "请输入求测问题~"
///   * 未选性别       → "请选择性别!"
class AppToast {
  static OverlayEntry? _entry;

  static void show(BuildContext context, String message) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    _entry?.remove();
    _entry = null;

    final entry = OverlayEntry(
      builder: (ctx) => Positioned(
        left: 40,
        right: 40,
        bottom: MediaQuery.of(ctx).size.height * 0.22,
        child: IgnorePointer(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    _entry = entry;
    overlay.insert(entry);
    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (_entry == entry) {
        entry.remove();
        _entry = null;
      }
    });
  }
}
