import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'ziwei.dart';

/// 一次紫微斗数排盘记录。
class ZiWeiRecord {
  final ZiWeiInput input;
  final String question;
  final DateTime savedAt;
  String note;

  ZiWeiRecord({
    required this.input,
    required this.question,
    required this.savedAt,
    this.note = '',
  });

  String get title => question.isNotEmpty
      ? '紫微斗数 · $question'
      : '紫微斗数（${input.gender == 1 ? '男' : '女'}命）';

  Map<String, dynamic> toJson() => <String, dynamic>{
        'input': input.toJson(),
        'question': question,
        'savedAt': savedAt.toIso8601String(),
        'note': note,
      };

  static ZiWeiRecord? fromJson(Map<String, dynamic> json) {
    final inputMap = json['input'] as Map<String, dynamic>?;
    if (inputMap == null) return null;
    final savedAt = DateTime.tryParse(json['savedAt'] as String? ?? '');
    if (savedAt == null) return null;
    return ZiWeiRecord(
      input: ZiWeiInput.fromJson(inputMap),
      question: json['question'] as String? ?? '',
      savedAt: savedAt,
      note: json['note'] as String? ?? '',
    );
  }
}

/// 紫微斗数排盘记录存储：内存列表 + 本地 JSON 文件持久化。
class ZiWeiRecordStore {
  ZiWeiRecordStore._();

  static final ZiWeiRecordStore instance = ZiWeiRecordStore._();

  static const String _fileName = 'ziwei_records.json';

  final List<ZiWeiRecord> _records = <ZiWeiRecord>[];

  File? _file;
  bool _loaded = false;
  Future<void>? _loading;

  /// 记录列表，最新保存的在前。
  List<ZiWeiRecord> get records =>
      List<ZiWeiRecord>.unmodifiable(_records.reversed);

  int get length => _records.length;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final loading = _loading;
    if (loading != null) return loading;
    final future = _load();
    _loading = future;
    try {
      await future;
    } finally {
      _loading = null;
    }
  }

  Future<void> _load() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      _file = file;
      if (!await file.exists()) {
        _loaded = true;
        return;
      }
      final text = await file.readAsString();
      final list = jsonDecode(text);
      if (list is List) {
        _records.clear();
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final record = ZiWeiRecord.fromJson(item);
            if (record != null) _records.add(record);
          }
        }
      }
    } catch (error) {
      debugPrint('读取紫微斗数记录失败：$error');
    } finally {
      _loaded = true;
    }
  }

  Future<void> save(ZiWeiRecord record) async {
    _records.removeWhere((r) =>
        r.savedAt.millisecondsSinceEpoch ==
        record.savedAt.millisecondsSinceEpoch);
    _records.add(record);
    await _persist();
  }

  Future<void> delete(ZiWeiRecord record) async {
    _records.removeWhere((r) =>
        r.savedAt.millisecondsSinceEpoch ==
        record.savedAt.millisecondsSinceEpoch);
    await _persist();
  }

  Future<void> clear() async {
    _records.clear();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      var file = _file;
      if (file == null) {
        final dir = await getApplicationDocumentsDirectory();
        file = File('${dir.path}/$_fileName');
        _file = file;
      }
      final jsonList = _records.map((r) => r.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (error) {
      debugPrint('保存紫微斗数记录失败：$error');
    }
  }
}
