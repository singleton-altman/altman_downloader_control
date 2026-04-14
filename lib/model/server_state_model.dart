/// 通用的服务器状态模型
/// 统一 qBittorrent 和 Transmission 的服务器状态数据格式
class ServerStateModel {
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

  ServerStateModel({
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

  /// 从 QBServerState 转换
  factory ServerStateModel.fromQBServerState(dynamic qbServerState) {
    return ServerStateModel(
      alltimeDl: qbServerState.alltimeDl,
      alltimeUl: qbServerState.alltimeUl,
      averageTimeQueue: qbServerState.averageTimeQueue,
      connectionStatus: qbServerState.connectionStatus,
      dhtNodes: qbServerState.dhtNodes,
      dlInfoData: qbServerState.dlInfoData,
      dlInfoSpeed: qbServerState.dlInfoSpeed,
      dlRateLimit: qbServerState.dlRateLimit,
      freeSpaceOnDisk: qbServerState.freeSpaceOnDisk,
      globalRatio: qbServerState.globalRatio,
      lastExternalAddressV4: qbServerState.lastExternalAddressV4,
      lastExternalAddressV6: qbServerState.lastExternalAddressV6,
      queuedIoJobs: qbServerState.queuedIoJobs,
      queueing: qbServerState.queueing,
      readCacheHits: qbServerState.readCacheHits,
      readCacheOverload: qbServerState.readCacheOverload,
      refreshInterval: qbServerState.refreshInterval,
      totalBuffersSize: qbServerState.totalBuffersSize,
      totalPeerConnections: qbServerState.totalPeerConnections,
      totalQueuedSize: qbServerState.totalQueuedSize,
      totalWastedSession: qbServerState.totalWastedSession,
      upInfoData: qbServerState.upInfoData,
      upInfoSpeed: qbServerState.upInfoSpeed,
      upRateLimit: qbServerState.upRateLimit,
      useAltSpeedLimits: qbServerState.useAltSpeedLimits,
      useSubcategories: qbServerState.useSubcategories,
      writeCacheOverload: qbServerState.writeCacheOverload,
    );
  }

  /// 从 Transmission Session 数据创建（适配器）
  /// 将 Transmission 的会话数据转换为统一的 ServerStateModel
  factory ServerStateModel.fromTransmissionSession({
    required int? downloadDirFreeSpace,
    required int? speedLimitDown,
    required bool? speedLimitDownEnabled,
    required int? speedLimitUp,
    required bool? speedLimitUpEnabled,
    required int? totalDownloadSpeed,
    required int? totalUploadSpeed,
    required int? totalDownloaded,
    required int? totalUploaded,
  }) {
    return ServerStateModel(
      alltimeDl: totalDownloaded ?? 0,
      alltimeUl: totalUploaded ?? 0,
      averageTimeQueue: 0, // Transmission 不提供
      connectionStatus: 'connected', // Transmission 不提供详细状态
      dhtNodes: 0, // Transmission 不提供
      dlInfoData: totalDownloaded ?? 0,
      dlInfoSpeed: totalDownloadSpeed ?? 0,
      dlRateLimit: (speedLimitDownEnabled == true && speedLimitDown != null)
          ? speedLimitDown
          : -1,
      freeSpaceOnDisk: downloadDirFreeSpace ?? 0,
      globalRatio: '0.0', // Transmission 不提供全局分享率
      lastExternalAddressV4: '', // Transmission 不提供
      lastExternalAddressV6: '', // Transmission 不提供
      queuedIoJobs: 0, // Transmission 不提供
      queueing: false, // Transmission 不提供
      readCacheHits: '0%', // Transmission 不提供
      readCacheOverload: '0%', // Transmission 不提供
      refreshInterval: 3000, // 默认 3 秒
      totalBuffersSize: 0, // Transmission 不提供
      totalPeerConnections: 0, // Transmission 不提供
      totalQueuedSize: 0, // Transmission 不提供
      totalWastedSession: 0, // Transmission 不提供
      upInfoData: totalUploaded ?? 0,
      upInfoSpeed: totalUploadSpeed ?? 0,
      upRateLimit: (speedLimitUpEnabled == true && speedLimitUp != null)
          ? speedLimitUp
          : -1,
      useAltSpeedLimits: false, // Transmission 不提供
      useSubcategories: false, // Transmission 不支持
      writeCacheOverload: '0%', // Transmission 不提供
    );
  }
}
