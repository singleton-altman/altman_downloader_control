/// qBittorrent 种子属性详情模型
/// 用于 /api/v2/torrents/properties 接口
class QBTorrentPropertiesModel {
  /// 添加日期（时间戳，秒）
  final int additionDate;

  /// 注释
  final String comment;

  /// 完成日期（时间戳，秒）
  final int completionDate;

  /// 创建者
  final String createdBy;

  /// 创建日期（时间戳，秒，-1 表示未知）
  final int creationDate;

  /// 下载速度限制（字节/秒，-1 表示无限制）
  final int dlLimit;

  /// 当前下载速度（字节/秒）
  final int dlSpeed;

  /// 平均下载速度（字节/秒）
  final int dlSpeedAvg;

  /// 下载路径
  final String downloadPath;

  /// 预计剩余时间（秒，8640000 表示未知）
  final int eta;

  /// 是否有元数据
  final bool hasMetadata;

  /// 种子哈希值
  final String hash;

  /// Infohash v1
  final String infohashV1;

  /// Infohash v2
  final String infohashV2;

  /// 是否为私有种子
  final bool isPrivate;

  /// 最后见到时间（时间戳，秒）
  final int lastSeen;

  /// 种子名称
  final String name;

  /// 当前连接数
  final int nbConnections;

  /// 最大连接数限制
  final int nbConnectionsLimit;

  /// 当前做种数
  final int peers;

  /// 总做种数
  final int peersTotal;

  /// 分片大小（字节）
  final int pieceSize;

  /// 已获得分片数
  final int piecesHave;

  /// 总分片数
  final int piecesNum;

  /// 流行度
  final double popularity;

  /// 是否为私有（冗余字段）
  final bool private;

  /// 进度（0.0 到 1.0）
  final double progress;

  /// 重新声明间隔（秒）
  final int reannounce;

  /// 保存路径
  final String savePath;

  /// 做种时间（秒）
  final int seedingTime;

  /// 当前做种数（seeds）
  final int seeds;

  /// 总做种数
  final int seedsTotal;

  /// 分享率
  final double shareRatio;

  /// 已用时间（秒）
  final int timeElapsed;

  /// 总下载量（字节）
  final int totalDownloaded;

  /// 本次会话总下载量（字节）
  final int totalDownloadedSession;

  /// 总大小（字节）
  final int totalSize;

  /// 总上传量（字节）
  final int totalUploaded;

  /// 本次会话总上传量（字节）
  final int totalUploadedSession;

  /// 总浪费流量（字节）
  final int totalWasted;

  /// 上传速度限制（字节/秒，-1 表示无限制）
  final int upLimit;

  /// 当前上传速度（字节/秒）
  final int upSpeed;

  /// 平均上传速度（字节/秒）
  final double upSpeedAvg;

  QBTorrentPropertiesModel({
    required this.additionDate,
    required this.comment,
    required this.completionDate,
    required this.createdBy,
    required this.creationDate,
    required this.dlLimit,
    required this.dlSpeed,
    required this.dlSpeedAvg,
    required this.downloadPath,
    required this.eta,
    required this.hasMetadata,
    required this.hash,
    required this.infohashV1,
    required this.infohashV2,
    required this.isPrivate,
    required this.lastSeen,
    required this.name,
    required this.nbConnections,
    required this.nbConnectionsLimit,
    required this.peers,
    required this.peersTotal,
    required this.pieceSize,
    required this.piecesHave,
    required this.piecesNum,
    required this.popularity,
    required this.private,
    required this.progress,
    required this.reannounce,
    required this.savePath,
    required this.seedingTime,
    required this.seeds,
    required this.seedsTotal,
    required this.shareRatio,
    required this.timeElapsed,
    required this.totalDownloaded,
    required this.totalDownloadedSession,
    required this.totalSize,
    required this.totalUploaded,
    required this.totalUploadedSession,
    required this.totalWasted,
    required this.upLimit,
    required this.upSpeed,
    required this.upSpeedAvg,
  });

  factory QBTorrentPropertiesModel.fromJson(Map<String, dynamic> json) {
    return QBTorrentPropertiesModel(
      additionDate: (json['addition_date'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String? ?? '',
      completionDate: (json['completion_date'] as num?)?.toInt() ?? 0,
      createdBy: json['created_by'] as String? ?? '',
      creationDate: (json['creation_date'] as num?)?.toInt() ?? -1,
      dlLimit: (json['dl_limit'] as num?)?.toInt() ?? -1,
      dlSpeed: (json['dl_speed'] as num?)?.toInt() ?? 0,
      dlSpeedAvg: (json['dl_speed_avg'] as num?)?.toInt() ?? 0,
      downloadPath: json['download_path'] as String? ?? '',
      eta: (json['eta'] as num?)?.toInt() ?? 8640000,
      hasMetadata: json['has_metadata'] as bool? ?? false,
      hash: json['hash'] as String? ?? '',
      infohashV1: json['infohash_v1'] as String? ?? '',
      infohashV2: json['infohash_v2'] as String? ?? '',
      isPrivate: json['is_private'] as bool? ?? false,
      lastSeen: (json['last_seen'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      nbConnections: (json['nb_connections'] as num?)?.toInt() ?? 0,
      nbConnectionsLimit:
          (json['nb_connections_limit'] as num?)?.toInt() ?? 100,
      peers: (json['peers'] as num?)?.toInt() ?? 0,
      peersTotal: (json['peers_total'] as num?)?.toInt() ?? 0,
      pieceSize: (json['piece_size'] as num?)?.toInt() ?? 0,
      piecesHave: (json['pieces_have'] as num?)?.toInt() ?? 0,
      piecesNum: (json['pieces_num'] as num?)?.toInt() ?? 0,
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0.0,
      private: json['private'] as bool? ?? false,
      progress: () {
        final value = json['progress'];
        if (value == null) return 0.0;
        if (value is int) return value.toDouble();
        if (value is double) return value;
        if (value is num) return value.toDouble();
        return 0.0;
      }(),
      reannounce: (json['reannounce'] as num?)?.toInt() ?? 0,
      savePath: json['save_path'] as String? ?? '',
      seedingTime: (json['seeding_time'] as num?)?.toInt() ?? 0,
      seeds: (json['seeds'] as num?)?.toInt() ?? 0,
      seedsTotal: (json['seeds_total'] as num?)?.toInt() ?? 0,
      shareRatio: (json['share_ratio'] as num?)?.toDouble() ?? 0.0,
      timeElapsed: (json['time_elapsed'] as num?)?.toInt() ?? 0,
      totalDownloaded: (json['total_downloaded'] as num?)?.toInt() ?? 0,
      totalDownloadedSession:
          (json['total_downloaded_session'] as num?)?.toInt() ?? 0,
      totalSize: (json['total_size'] as num?)?.toInt() ?? 0,
      totalUploaded: (json['total_uploaded'] as num?)?.toInt() ?? 0,
      totalUploadedSession:
          (json['total_uploaded_session'] as num?)?.toInt() ?? 0,
      totalWasted: (json['total_wasted'] as num?)?.toInt() ?? 0,
      upLimit: (json['up_limit'] as num?)?.toInt() ?? -1,
      upSpeed: (json['up_speed'] as num?)?.toInt() ?? 0,
      upSpeedAvg: (json['up_speed_avg'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// 格式化时间戳（秒）为可读日期时间
  static String formatTimestamp(int timestamp) {
    if (timestamp <= 0) return '未知';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  /// 格式化时长（秒）为可读文本
  static String formatDuration(int seconds) {
    if (seconds <= 0) return '0秒';
    if (seconds < 60) return '$seconds秒';
    if (seconds < 3600) return '${seconds ~/ 60}分钟';
    if (seconds < 86400) {
      return '${seconds ~/ 3600}小时${(seconds % 3600) ~/ 60}分钟';
    }
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    if (hours == 0 && mins == 0) return '$days天';
    if (mins == 0) return '$days天$hours小时';
    return '$days天$hours小时$mins分钟';
  }

  /// 进度百分比
  double get progressPercent => progress * 100;
}
