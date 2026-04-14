import 'package:flutter/material.dart';

/// qBittorrent Tracker 模型
/// 用于 /api/v2/torrents/trackers 接口
class QBTrackerModel {
  /// Tracker URL
  final String url;

  /// Tracker 状态码（0=正常, 1=更新中, 2=更新失败, 3=错误, 4=错误等）
  final int status;

  /// 优先级（0 表示禁用，-1 表示未设置）
  final int tier;

  /// 完整消息（包含状态信息）
  final String msg;

  /// 已下载数量（-1 表示不可用）
  final int numDownloaded;

  /// Leech 数量（-1 表示不可用）
  final int numLeeches;

  /// Peer 数量（-1 表示不可用）
  final int numPeers;

  /// Seed 数量（-1 表示不可用）
  final int numSeeds;

  QBTrackerModel({
    required this.url,
    required this.status,
    required this.tier,
    required this.msg,
    required this.numDownloaded,
    required this.numLeeches,
    required this.numPeers,
    required this.numSeeds,
  });

  factory QBTrackerModel.fromJson(Map<String, dynamic> json) {
    return QBTrackerModel(
      url: json['url'] as String? ?? '',
      status: (json['status'] as num?)?.toInt() ?? 0,
      tier: (json['tier'] as num?)?.toInt() ?? -1,
      msg: json['msg'] as String? ?? '',
      numDownloaded: (json['num_downloaded'] as num?)?.toInt() ?? -1,
      numLeeches: (json['num_leeches'] as num?)?.toInt() ?? -1,
      numPeers: (json['num_peers'] as num?)?.toInt() ?? -1,
      numSeeds: (json['num_seeds'] as num?)?.toInt() ?? -1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'status': status,
      'tier': tier,
      'msg': msg,
      'num_downloaded': numDownloaded,
      'num_leeches': numLeeches,
      'num_peers': numPeers,
      'num_seeds': numSeeds,
    };
  }

  /// 是否启用（tier >= 0）
  bool get isEnabled => tier >= 0;

  /// 是否为特殊 Tracker（DHT、PeX、LSD 等）
  bool get isSpecialTracker => url.startsWith('** [') && url.endsWith('] **');

  /// 获取状态显示文本（中文）
  String get statusText {
    switch (status) {
      case 0:
        return '禁用';
      case 1:
        return '未联系';
      case 2:
        return '工作';
      case 3:
      case 4:
        return '未工作';
      default:
        return '未知';
    }
  }

  /// 获取状态颜色（用于 UI 显示）
  Color get statusColor {
    switch (status) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.orange;
      case 3:
      case 4:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// 获取格式化的人数信息
  String get formattedPeers {
    if (numPeers < 0 && numSeeds < 0) {
      return '未知';
    }
    final seeds = numSeeds >= 0 ? numSeeds : 0;
    final leeches = numLeeches >= 0 ? numLeeches : 0;
    if (seeds == 0 && leeches == 0) {
      return '0/0';
    }
    return '$seeds/$leeches';
  }
}
