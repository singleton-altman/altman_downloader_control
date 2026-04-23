import 'package:altman_downloader_control/model/torrent_item_model.dart';
import 'package:altman_downloader_control/utils/torrent_state_localizable.dart';

/// qBittorrent 种子数据模型
/// 兼容通用 TorrentModel
class QBTorrentModel {
  final String hash;
  final String name;
  final int size;
  final int totalSize;
  final double progress;
  final int dlspeed;
  final int upspeed;
  final int priority;
  final int numSeeds;
  final int numLeechers;
  final int numComplete;
  final int numIncomplete;
  final double ratio;
  final double popularity;
  final bool hasPopularityField;
  final int eta;
  final String state;
  final String category;
  final List<String> tags;
  final int addedOn;
  final int completionOn;
  final int lastActivity;
  final int seenComplete;
  final String savePath;
  final String contentPath;
  final String downloadPath;
  final String rootPath;
  final int downloaded;
  final int completed;
  final int uploaded;
  final int downloadedSession;
  final int uploadedSession;
  final int amountLeft;
  final String tracker;
  final String comment;
  final String magnetUri;
  final double availability;
  final bool hasAvailabilityField;
  final double dlLimit;
  final double upLimit;
  final double timeActive;
  final int seedingTime;

  QBTorrentModel({
    required this.hash,
    required this.name,
    required this.size,
    required this.totalSize,
    required this.progress,
    required this.dlspeed,
    required this.upspeed,
    required this.priority,
    required this.numSeeds,
    required this.numLeechers,
    required this.numComplete,
    required this.numIncomplete,
    required this.ratio,
    required this.popularity,
    required this.hasPopularityField,
    required this.eta,
    required this.state,
    required this.category,
    required this.tags,
    required this.addedOn,
    required this.completionOn,
    required this.lastActivity,
    required this.seenComplete,
    required this.savePath,
    required this.contentPath,
    required this.downloadPath,
    required this.rootPath,
    required this.downloaded,
    required this.completed,
    required this.uploaded,
    required this.downloadedSession,
    required this.uploadedSession,
    required this.amountLeft,
    required this.tracker,
    required this.comment,
    required this.magnetUri,
    required this.availability,
    required this.hasAvailabilityField,
    required this.dlLimit,
    required this.upLimit,
    required this.timeActive,
    required this.seedingTime,
  });

  factory QBTorrentModel.fromJson(Map<String, dynamic> json) {
    return QBTorrentModel(
      hash: json['hash'] as String? ?? '',
      name: json['name'] as String? ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
      totalSize:
          (json['total_size'] as num?)?.toInt() ??
          (json['size'] as num?)?.toInt() ??
          0,
      progress: () {
        final value = json['progress'];
        if (value == null) return 0.0;
        // 处理整数 1 转换为 1.0 的情况
        if (value is int) return value.toDouble();
        if (value is double) return value;
        if (value is num) return value.toDouble();
        return 0.0;
      }(),
      dlspeed: (json['dlspeed'] as num?)?.toInt() ?? 0,
      upspeed: (json['upspeed'] as num?)?.toInt() ?? 0,
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      numSeeds: (json['num_seeds'] as num?)?.toInt() ?? 0,
      numLeechers: (json['num_leechs'] as num?)?.toInt() ?? 0,
      numComplete: () {
        final value = (json['num_complete'] as num?)?.toInt();
        return value != null && value >= 0 ? value : 0;
      }(),
      numIncomplete: () {
        final value = (json['num_incomplete'] as num?)?.toInt();
        return value != null && value >= 0 ? value : 0;
      }(),
      ratio: (json['ratio'] as num?)?.toDouble() ?? 0.0,
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0.0,
      hasPopularityField: json.containsKey('popularity'),
      eta: (json['eta'] as num?)?.toInt() ?? 0,
      state: json['state'] as String? ?? '',
      category: json['category'] as String? ?? '',
      tags:
          (json['tags'] as String?)
              ?.split(', ')
              .where((t) => t.isNotEmpty)
              .toList() ??
          [],
      addedOn: (json['added_on'] as num?)?.toInt() ?? 0,
      completionOn: (json['completion_on'] as num?)?.toInt() ?? 0,
      lastActivity: (json['last_activity'] as num?)?.toInt() ?? 0,
      seenComplete: (json['seen_complete'] as num?)?.toInt() ?? 0,
      savePath: json['save_path'] as String? ?? '',
      contentPath: json['content_path'] as String? ?? '',
      downloadPath: json['download_path'] as String? ?? '',
      rootPath: json['root_path'] as String? ?? '',
      downloaded: (json['downloaded'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      uploaded: (json['uploaded'] as num?)?.toInt() ?? 0,
      downloadedSession: (json['downloaded_session'] as num?)?.toInt() ?? 0,
      uploadedSession: (json['uploaded_session'] as num?)?.toInt() ?? 0,
      amountLeft: (json['amount_left'] as num?)?.toInt() ?? 0,
      tracker: json['tracker'] as String? ?? '',
      comment: json['comment'] as String? ?? '',
      magnetUri: json['magnet_uri'] as String? ?? '',
      availability: (json['availability'] as num?)?.toDouble() ?? -1.0,
      hasAvailabilityField: json.containsKey('availability'),
      dlLimit: (json['dl_limit'] as num?)?.toDouble() ?? -1,
      upLimit: (json['up_limit'] as num?)?.toDouble() ?? -1,
      timeActive: (json['time_active'] as num?)?.toDouble() ?? 0,
      seedingTime: (json['seeding_time'] as num?)?.toInt() ?? 0,
    );
  }

  /// 获取状态显示文本（支持本地化）
  String get stateText {
    return _getLocalizedStateText(state);
  }

  /// 根据状态获取本地化文本
  static String _getLocalizedStateText(String state) {
    return QBLocalizable.getStateText(state);
  }

  /// 进度百分比
  double get progressPercent => progress * 100;

  /// 下载状态集合
  static final Set<String> _downloadingStates = {
    'downloading',
    'checkingdl',
    'checking_download',
    'stalleddl',
    'stalled_download',
    'forceddl',
    'forced_download',
    'queueddl',
    'queued_download',
    'metadl',
    'meta_download',
    'forcedmetadata',
    'forced_meta_download',
    'pauseddl',
    'paused_download',
  };

  /// 做种状态集合
  static final Set<String> _seedingStates = {
    'uploading',
    'seeding',
    'checkingup',
    'checking_upload',
    'stalledup',
    'stalled_upload',
    'forcedup',
    'forced_upload',
    'queuedup',
    'queued_upload',
    'queued_to_seed',
  };

  /// 已完成状态集合（做种状态 + pausedUP）
  static Set<String> get _completedStates =>
      _seedingStates.union({'pausedup', 'paused_upload'});

  /// 恢复状态集合（运行中的状态，不包括 paused）
  static final Set<String> _resumedStates = {
    'downloading',
    'checkingdl',
    'checking_download',
    'stalleddl',
    'stalled_download',
    'queueddl',
    'queued_download',
    'metadl',
    'meta_download',
    'forcedmetadata',
    'forced_meta_download',
    'uploading',
    'seeding',
    'checkingup',
    'checking_upload',
    'stalledup',
    'stalled_upload',
    'queuedup',
    'queued_upload',
    'queued_to_seed',
    'forcedup',
    'forced_upload',
  };

  /// 暂停状态集合
  static final Set<String> _pausedStates = {
    'pauseddl',
    'paused_download',
    'pausedup',
    'paused_upload',
    'paused',
  };

  /// 停滞状态集合
  static final Set<String> _stalledStates = {
    'stalleddl',
    'stalled_download',
    'stalledup',
    'stalled_upload',
  };

  /// 检查状态集合
  static final Set<String> _checkingStates = {
    'checkingdl',
    'checking_download',
    'checkingup',
    'checking_upload',
    'checkingresumedata',
    'checking_resume_data',
    'checking',
  };

  /// 错误状态集合
  static final Set<String> _errorStates = {
    'error',
    'missingfiles',
    'missing_files',
  };

  /// 获取状态的小写形式
  String get _stateLower => state.toLowerCase();

  /// 是否正在下载（包括所有下载相关的状态）
  bool get isDownloading => _downloadingStates.contains(_stateLower);

  /// 是否正在做种（包括所有上传/做种相关的状态）
  bool get isSeeding => _seedingStates.contains(_stateLower);

  /// 是否已完成（做种状态 + pausedUP）
  bool get isCompleted => _completedStates.contains(_stateLower);

  /// 是否已恢复（运行中的状态）
  bool get isResumed => _resumedStates.contains(_stateLower);

  /// 是否已暂停
  bool get isPaused => _pausedStates.contains(_stateLower);

  /// 是否停滞
  bool get isStalled => _stalledStates.contains(_stateLower);

  /// 是否正在检查
  bool get isChecking => _checkingStates.contains(_stateLower);

  /// 是否有错误
  bool get hasError => _errorStates.contains(_stateLower);

  /// 是否在移动
  bool get isMoving => _stateLower == 'moving';

  /// 是否已停止（显式停止状态）
  bool get isStopped => _stateLower == 'stopped';

  /// 是否活跃（有下载或上传速度）
  bool get isActive => dlspeed > 0 || upspeed > 0;

  /// 是否非活跃（没有下载和上传速度）
  bool get isInactive => dlspeed == 0 && upspeed == 0;

  /// 从通用 TorrentModel 转换
  factory QBTorrentModel.fromTorrentModel(TorrentModel torrent) {
    return QBTorrentModel(
      hash: torrent.hash,
      name: torrent.name,
      size: torrent.size,
      totalSize: torrent.totalSize,
      progress: torrent.progress,
      dlspeed: torrent.dlspeed,
      upspeed: torrent.upspeed,
      priority: torrent.priority,
      numSeeds: torrent.numSeeds,
      numLeechers: torrent.numLeechers,
      numComplete: torrent.numComplete,
      numIncomplete: torrent.numIncomplete,
      ratio: torrent.ratio,
      popularity: torrent.popularity,
      hasPopularityField: true,
      eta: torrent.eta,
      state: torrent.state,
      category: torrent.category,
      tags: torrent.tags,
      addedOn: torrent.addedOn,
      completionOn: torrent.completionOn,
      lastActivity: torrent.lastActivity,
      seenComplete: torrent.seenComplete,
      savePath: torrent.savePath,
      contentPath: torrent.contentPath,
      downloadPath: torrent.downloadPath,
      rootPath: torrent.rootPath,
      downloaded: torrent.downloaded,
      completed: torrent.completed,
      uploaded: torrent.uploaded,
      downloadedSession: torrent.downloadedSession,
      uploadedSession: torrent.uploadedSession,
      amountLeft: torrent.amountLeft,
      tracker: torrent.tracker,
      comment: torrent.comment,
      magnetUri: torrent.magnetUri,
      availability: torrent.availability,
      hasAvailabilityField: true,
      dlLimit: torrent.dlLimit,
      upLimit: torrent.upLimit,
      timeActive: torrent.timeActive,
      seedingTime: torrent.seedingTime,
    );
  }

  /// 转换为通用 TorrentModel
  TorrentModel toTorrentModel({TorrentModel? previous}) {
    return TorrentModel.fromQBTorrentModel(this, previous: previous);
  }
}
