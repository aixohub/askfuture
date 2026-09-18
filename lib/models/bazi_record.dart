import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../pages/bazi_paipan_page.dart';

/// 一次八字排盘记录。
class BaZiRecord {
  final BaZiInput input;
  final DateTime savedAt;
  String note;

  BaZiRecord({
    required this.input,
    required this.savedAt,
    this.note = '',
  });

  String get title => input.description.isNotEmpty
      ? '八字排盘 · ${input.description}'
      : '八字排盘（${input.sexName}命）';

  Map<String, dynamic> toJson() => <String, dynamic>{
        'input': input.toJson(),
        'savedAt': savedAt.toIso8601String(),
        'note': note,
      };

  static BaZiRecord? fromJson(Map<String, dynamic> json) {
    final inputMap = json['input'] as Map<String, dynamic>?;
    if (inputMap == null) return null;
    final savedAt = DateTime.tryParse(json['savedAt'] as String? ?? '');
    if (savedAt == null) return null;
    return BaZiRecord(
      input: BaZiInput.fromJson(inputMap),
      savedAt: savedAt,
      note: json['note'] as String? ?? '',
    );
  }
}

/// 八字排盘记录存储：内存列表 + 本地 JSON 文件持久化。
class BaZiRecordStore {
  BaZiRecordStore._();

  static final BaZiRecordStore instance = BaZiRecordStore._();

  static const String _fileName = 'bazi_records.json';

  final List<BaZiRecord> _records = <BaZiRecord>[];

  File? _file;
  bool _loaded = false;
  Future<void>? _loading;

  /// 记录列表，最新保存的在前。
  List<BaZiRecord> get records => List<BaZiRecord>.unmodifiable(_records.reversed);

  bool get isEmpty => _records.isEmpty;

  Future<void> ensureLoaded() {
    if (_loaded) return Future<void>.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      _file = file;
      if (file.existsSync()) {
        final raw = await file.readAsString();
        final list = jsonDecode(raw) as List<dynamic>;
        _records
          ..clear()
          ..addAll(
            list
                .whereType<Map<String, dynamic>>()
                .map(BaZiRecord.fromJson)
                .whereType<BaZiRecord>(),
          );
      }
    } catch (error) {
      debugPrint('读取八字排盘记录失败，改用内存存储：$error');
    } finally {
      _loaded = true;
    }
  }

  void save(BaZiRecord record) {
    _records.add(record);
    _persist();
  }

  void updateNote(BaZiRecord record, String note) {
    if (record.note == note) return;
    record.note = note;
    _persist();
  }

  void clear() {
    _records.clear();
    _persist();
  }

  Future<void> _persist() async {
    final file = _file;
    if (file == null) return;
    try {
      final data = jsonEncode(_records.map((r) => r.toJson()).toList());
      await file.writeAsString(data);
    } catch (error) {
      debugPrint('保存八字排盘记录失败：$error');
    }
  }
}
