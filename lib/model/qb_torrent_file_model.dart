import 'package:flutter/material.dart';

/// qBittorrent 种子文件模型
/// 用于 /api/v2/torrents/files 接口
class QBTorrentFileModel {
  /// 可用性（-1 表示不可用）
  final double availability;

  /// 文件索引
  final int index;

  /// 是否为种子文件
  final bool? isSeed;

  /// 文件名（包含路径）
  final String name;

  /// 分片范围 [起始, 结束]
  final List<int> pieceRange;

  /// 优先级（0=不下载, 1=正常, 2-7=更高优先级）
  final int priority;

  /// 进度（0.0 到 1.0）
  final double progress;

  /// 文件大小（字节）
  final int size;

  QBTorrentFileModel({
    required this.availability,
    required this.index,
    this.isSeed,
    required this.name,
    required this.pieceRange,
    required this.priority,
    required this.progress,
    required this.size,
  });

  factory QBTorrentFileModel.fromJson(Map<String, dynamic> json) {
    return QBTorrentFileModel(
      availability: (json['availability'] as num?)?.toDouble() ?? -1.0,
      index: (json['index'] as num?)?.toInt() ?? 0,
      isSeed: json['is_seed'] as bool?,
      name: json['name'] as String? ?? '',
      pieceRange: (json['piece_range'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [0, 0],
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      progress: () {
        final value = json['progress'];
        if (value == null) return 0.0;
        if (value is int) return value.toDouble();
        if (value is double) return value;
        if (value is num) return value.toDouble();
        return 0.0;
      }(),
      size: (json['size'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'availability': availability,
      'index': index,
      if (isSeed != null) 'is_seed': isSeed,
      'name': name,
      'piece_range': pieceRange,
      'priority': priority,
      'progress': progress,
      'size': size,
    };
  }

  /// 进度百分比
  double get progressPercent => progress * 100;

  /// 获取文件名（不含路径）
  String get fileName {
    final parts = name.split('/');
    return parts.isNotEmpty ? parts.last : name;
  }

  /// 获取文件路径（不含文件名）
  String get filePath {
    final parts = name.split('/');
    if (parts.length > 1) {
      return parts.sublist(0, parts.length - 1).join('/');
    }
    return '';
  }

  /// 获取优先级显示文本
  String get priorityText {
    switch (priority) {
      case 0:
        return '不下载';
      case 1:
        return '正常';
      case 2:
      case 3:
      case 4:
      case 5:
      case 6:
      case 7:
        return '高优先级';
      default:
        return '未知';
    }
  }

  /// 获取优先级颜色
  Color get priorityColor {
    switch (priority) {
      case 0:
        return Colors.grey;
      case 1:
        return Colors.blue;
      case 2:
      case 3:
      case 4:
      case 5:
      case 6:
      case 7:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// 获取分片范围显示文本
  String get pieceRangeText {
    if (pieceRange.length >= 2) {
      return '${pieceRange[0]}-${pieceRange[1]}';
    }
    return '未知';
  }
}
