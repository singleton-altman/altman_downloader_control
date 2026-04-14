import 'package:altman_downloader_control/model/qb_torrent_model.dart';
import 'package:altman_downloader_control/model/server_state_model.dart';

/// qBittorrent MainData 响应模型
/// 用于 /api/v2/sync/maindata 接口
class QBMainDataModel {
  /// Response ID，用于下次增量同步
  final int rid;

  /// 是否为完整更新
  final bool fullUpdate;

  /// 变更的种子列表（以 hash 为 key）
  final Map<String, QBTorrentModel> torrents;

  /// 被移除的种子 hash 列表
  final List<String> torrentsRemoved;

  /// 服务器状态
  final QBServerState? serverState;

  QBMainDataModel({
    required this.rid,
    required this.fullUpdate,
    required this.torrents,
    required this.torrentsRemoved,
    this.serverState,
  });

  factory QBMainDataModel.fromJson(Map<String, dynamic> json) {
    // 解析 torrents 对象
    final Map<String, QBTorrentModel> torrentsMap = {};
    if (json['torrents'] is Map) {
      final torrentsData = json['torrents'] as Map<String, dynamic>;
      torrentsData.forEach((hash, data) {
        if (data is Map<String, dynamic>) {
          // 添加 hash 字段到数据中
          final torrentData = Map<String, dynamic>.from(data);
          torrentData['hash'] = hash;
          try {
            torrentsMap[hash] = QBTorrentModel.fromJson(torrentData);
          } catch (e) {
            // 忽略解析错误的种子
          }
        }
      });
    }

    // 解析被移除的种子列表
    final List<String> removed = [];
    if (json['torrents_removed'] is List) {
      removed.addAll(
        (json['torrents_removed'] as List)
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty),
      );
    }

    // 解析服务器状态
    QBServerState? serverState;
    if (json['server_state'] is Map) {
      try {
        serverState = QBServerState.fromJson(
          json['server_state'] as Map<String, dynamic>,
        );
      } catch (e) {}
    }

    return QBMainDataModel(
      rid: (json['rid'] as num?)?.toInt() ?? 0,
      fullUpdate: json['full_update'] as bool? ?? false,
      torrents: torrentsMap,
      torrentsRemoved: removed,
      serverState: serverState,
    );
  }

  /// 获取所有种子的列表
  List<QBTorrentModel> get torrentsList => torrents.values.toList();
}

/// qBittorrent 服务器状态
class QBServerState {
  /// 总下载量（字节）
  final int alltimeDl;

  /// 总上传量（字节）
  final int alltimeUl;

  /// 平均队列时间（秒）
  final int averageTimeQueue;

  /// 连接状态（字符串，如 "firewalled"）
  final String connectionStatus;

  /// DHT 节点数
  final int dhtNodes;

  /// 全局下载数据量（字节）
  final int dlInfoData;

  /// 全局下载速度（字节/秒）
  final int dlInfoSpeed;

  /// 下载速度限制（字节/秒）
  final int dlRateLimit;

  /// 磁盘剩余空间（字节）
  final int freeSpaceOnDisk;

  /// 全局分享率
  final String globalRatio;

  /// 最后外部 IPv4 地址
  final String lastExternalAddressV4;

  /// 最后外部 IPv6 地址
  final String lastExternalAddressV6;

  /// 队列中的 IO 任务数
  final int queuedIoJobs;

  /// 是否启用队列
  final bool queueing;

  /// 读缓存命中率（字符串）
  final String readCacheHits;

  /// 读缓存过载率（字符串）
  final String readCacheOverload;

  /// 刷新间隔（毫秒）
  final int refreshInterval;

  /// 总缓冲区大小（字节）
  final int totalBuffersSize;

  /// 总对等连接数
  final int totalPeerConnections;

  /// 总队列大小（字节）
  final int totalQueuedSize;

  /// 会话总浪费数据（字节）
  final int totalWastedSession;

  /// 全局上传数据量（字节）
  final int upInfoData;

  /// 全局上传速度（字节/秒）
  final int upInfoSpeed;

  /// 上传速度限制（字节/秒）
  final int upRateLimit;

  /// 是否使用替代速度限制
  final bool useAltSpeedLimits;

  /// 是否使用子分类
  final bool useSubcategories;

  /// 写缓存过载率（字符串）
  final String writeCacheOverload;

  /// 转换为通用 ServerStateModel
  ServerStateModel toServerStateModel() {
    return ServerStateModel.fromQBServerState(this);
  }

  QBServerState({
    required this.alltimeDl,
    required this.alltimeUl,
    required this.averageTimeQueue,
    required this.connectionStatus,
    required this.dhtNodes,
    required this.dlInfoData,
    required this.dlInfoSpeed,
    required this.dlRateLimit,
    required this.freeSpaceOnDisk,
    required this.globalRatio,
    required this.lastExternalAddressV4,
    required this.lastExternalAddressV6,
    required this.queuedIoJobs,
    required this.queueing,
    required this.readCacheHits,
    required this.readCacheOverload,
    required this.refreshInterval,
    required this.totalBuffersSize,
    required this.totalPeerConnections,
    required this.totalQueuedSize,
    required this.totalWastedSession,
    required this.upInfoData,
    required this.upInfoSpeed,
    required this.upRateLimit,
    required this.useAltSpeedLimits,
    required this.useSubcategories,
    required this.writeCacheOverload,
  });

  factory QBServerState.fromJson(Map<String, dynamic> json) {
    return QBServerState(
      alltimeDl: (json['alltime_dl'] as num?)?.toInt() ?? 0,
      alltimeUl: (json['alltime_ul'] as num?)?.toInt() ?? 0,
      averageTimeQueue: (json['average_time_queue'] as num?)?.toInt() ?? 0,
      connectionStatus: json['connection_status'] as String? ?? '',
      dhtNodes: (json['dht_nodes'] as num?)?.toInt() ?? 0,
      dlInfoData: (json['dl_info_data'] as num?)?.toInt() ?? 0,
      dlInfoSpeed: (json['dl_info_speed'] as num?)?.toInt() ?? 0,
      dlRateLimit: (json['dl_rate_limit'] as num?)?.toInt() ?? 0,
      freeSpaceOnDisk: (json['free_space_on_disk'] as num?)?.toInt() ?? 0,
      globalRatio: json['global_ratio'] as String? ?? '0',
      lastExternalAddressV4: json['last_external_address_v4'] as String? ?? '',
      lastExternalAddressV6: json['last_external_address_v6'] as String? ?? '',
      queuedIoJobs: (json['queued_io_jobs'] as num?)?.toInt() ?? 0,
      queueing: json['queueing'] as bool? ?? false,
      readCacheHits: json['read_cache_hits'] as String? ?? '0',
      readCacheOverload: json['read_cache_overload'] as String? ?? '0',
      refreshInterval: (json['refresh_interval'] as num?)?.toInt() ?? 0,
      totalBuffersSize: (json['total_buffers_size'] as num?)?.toInt() ?? 0,
      totalPeerConnections:
          (json['total_peer_connections'] as num?)?.toInt() ?? 0,
      totalQueuedSize: (json['total_queued_size'] as num?)?.toInt() ?? 0,
      totalWastedSession: (json['total_wasted_session'] as num?)?.toInt() ?? 0,
      upInfoData: (json['up_info_data'] as num?)?.toInt() ?? 0,
      upInfoSpeed: (json['up_info_speed'] as num?)?.toInt() ?? 0,
      upRateLimit: (json['up_rate_limit'] as num?)?.toInt() ?? 0,
      useAltSpeedLimits: json['use_alt_speed_limits'] as bool? ?? false,
      useSubcategories: json['use_subcategories'] as bool? ?? false,
      writeCacheOverload: json['write_cache_overload'] as String? ?? '0',
    );
  }
}
