import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'divination_models.dart';
import 'hexagram.dart';

/// 一次起卦记录。
///
/// 官方"起卦记录"数据来自服务端（`yjhapp/getOrdersByPids` 等），
/// 本地以本地 JSON 文件承载"保存排盘 → 起卦记录 → 回看卦象 / 解卦笔记"闭环。
class QiGuaRecord {
  /// 占事信息（问题、分类、性别）。
  final QiGuaRequest request;

  /// 起卦结果（本卦 / 变卦 / 动爻）。
  final GuaResult result;

  /// 起卦方式名，如"手工指定"。
  final String methodName;

  /// 起卦时间。
  final DateTime castingTime;

  /// 保存时间。
  final DateTime savedAt;

  /// 起卦输入摘要（手工指定为各爻属性）。
  final String inputSummary;

  /// 解卦笔记；卦象页保存笔记后写入此字段并落盘。
  String note;

  QiGuaRecord({
    required this.request,
    required this.result,
    required this.methodName,
    required this.castingTime,
    required this.savedAt,
    required this.inputSummary,
    this.note = '',
  });

  /// 卦象标题，如 "【乾为天】变【泽天夬】卦"。
  String get title => result.isStatic
      ? '【${result.benGua.name}】静卦'
      : '【${result.benGua.name}】变【${result.bianGua.name}】卦';

  Map<String, dynamic> toJson() => <String, dynamic>{
        'sex': request.sex,
        'quetitle': request.quetitle,
        'quetype': request.quetype,
        'remark': request.remark,
        'productId': request.productId,
        'yaoValues': result.yaoValues,
        'methodName': methodName,
        'castingTime': castingTime.toIso8601String(),
        'savedAt': savedAt.toIso8601String(),
        'inputSummary': inputSummary,
        'note': note,
      };

  static QiGuaRecord? fromJson(Map<String, dynamic> json) {
    final yaoValues = (json['yaoValues'] as List<dynamic>?)
        ?.map((value) => (value as num).toInt())
        .toList();
    if (yaoValues == null || yaoValues.length != 6) return null;

    final castingTime = DateTime.tryParse(json['castingTime'] as String? ?? '');
    final savedAt = DateTime.tryParse(json['savedAt'] as String? ?? '');
    if (castingTime == null || savedAt == null) return null;

    return QiGuaRecord(
      request: QiGuaRequest(
        sex: (json['sex'] as num?)?.toInt() ?? 1,
        quetitle: json['quetitle'] as String? ?? '',
        quetype: (json['quetype'] as num?)?.toInt() ?? 0,
        remark: json['remark'] as String? ?? '',
        productId: json['productId'] as String? ?? kYaoGuaProIdSet,
      ),
      result: buildGuaResult(yaoValues),
      methodName: json['methodName'] as String? ?? '',
      castingTime: castingTime,
      savedAt: savedAt,
      inputSummary: json['inputSummary'] as String? ?? '',
      note: json['note'] as String? ?? '',
    );
  }
}

/// 起卦记录存储：内存列表 + 本地 JSON 文件持久化。
///
/// * 读取为同步（[records]），写入异步落盘，落盘失败只影响持久化、不影响界面；
/// * 测试环境没有 `path_provider` 实现时自动降级为纯内存存储。
class QiGuaRecordStore {
  QiGuaRecordStore._();

  static final QiGuaRecordStore instance = QiGuaRecordStore._();

  static const String _fileName = 'qigua_records.json';

  final List<QiGuaRecord> _records = <QiGuaRecord>[];

  File? _file;
  bool _loaded = false;
  Future<void>? _loading;

  /// 记录列表，最新保存的在前。
  List<QiGuaRecord> get records => List<QiGuaRecord>.unmodifiable(_records.reversed);

  bool get isEmpty => _records.isEmpty;

  /// 从本地文件载入记录（幂等；App 启动时调用一次）。
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
                .map(QiGuaRecord.fromJson)
                .whereType<QiGuaRecord>(),
          );
      }
    } catch (error) {
      // 测试环境或平台不支持时降级为内存存储
      debugPrint('读取起卦记录失败，改用内存存储：$error');
    } finally {
      _loaded = true;
    }
  }

  void save(QiGuaRecord record) {
    _records.add(record);
    _persist();
  }

  /// 更新某条记录的解卦笔记（内容相同则不重复落盘）。
  void updateNote(QiGuaRecord record, String note) {
    if (record.note == note) return;
    record.note = note;
    _persist();
  }

  void clear() {
    _records.clear();
    _persist();
  }

  void _persist() {
    final file = _file;
    if (file == null) return;
    try {
      final payload = jsonEncode(
        _records.map((record) => record.toJson()).toList(growable: false),
      );
      file.writeAsString(payload);
    } catch (error) {
      debugPrint('保存起卦记录失败：$error');
    }
  }
}
