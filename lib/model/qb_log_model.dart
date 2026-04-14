/// qBittorrent 日志条目模型
class QBLogEntry {
  /// 日志 ID
  final int id;

  /// 日志消息
  final String message;

  /// 时间戳（秒）
  final int timestamp;

  /// 日志类型：1=normal, 2=info, 4=warning, 8=critical
  final int type;

  QBLogEntry({
    required this.id,
    required this.message,
    required this.timestamp,
    required this.type,
  });

  factory QBLogEntry.fromJson(Map<String, dynamic> json) {
    return QBLogEntry(
      id: (json['id'] as num?)?.toInt() ?? 0,
      message: json['message'] as String? ?? '',
      timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
      type: (json['type'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'timestamp': timestamp,
      'type': type,
    };
  }

  /// 获取日志类型名称
  String get typeName {
    switch (type) {
      case 1:
        return 'normal';
      case 2:
        return 'info';
      case 4:
        return 'warning';
      case 8:
        return 'critical';
      default:
        return 'unknown';
    }
  }

  /// 是否为普通日志
  bool get isNormal => type == 1;

  /// 是否为信息日志
  bool get isInfo => type == 2;

  /// 是否为警告日志
  bool get isWarning => type == 4;

  /// 是否为严重日志
  bool get isCritical => type == 8;
}

/// qBittorrent 日志响应模型
/// 支持两种格式：
/// 1. Map 格式：{"id": 123, "logs": [...]}
/// 2. 数组格式：[{...}, {...}]（直接返回日志数组）
class QBLogResponse {
  /// 最后已知的日志 ID（用于增量获取）
  final int id;

  /// 日志条目列表
  final List<QBLogEntry> logs;

  QBLogResponse({
    required this.id,
    required this.logs,
  });

  /// 从 Map 格式解析
  factory QBLogResponse.fromJson(Map<String, dynamic> json) {
    return QBLogResponse(
      id: (json['id'] as num?)?.toInt() ?? 0,
      logs: (json['logs'] as List<dynamic>?)
              ?.map((item) => QBLogEntry.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// 从数组格式解析（API 直接返回日志数组）
  factory QBLogResponse.fromList(List<dynamic> jsonList, {int? lastKnownId}) {
    final logs = jsonList
        .map((item) => QBLogEntry.fromJson(item as Map<String, dynamic>))
        .toList();

    // 从日志列表中获取最大的 ID 作为 lastKnownId
    final maxId = logs.isNotEmpty
        ? logs.map((log) => log.id).reduce((a, b) => a > b ? a : b)
        : (lastKnownId ?? 0);

    return QBLogResponse(
      id: maxId,
      logs: logs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'logs': logs.map((log) => log.toJson()).toList(),
    };
  }
}
