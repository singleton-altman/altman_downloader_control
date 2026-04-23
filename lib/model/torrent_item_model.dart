/// 通用的种子数据模型
/// 统一 qBittorrent 和 Transmission 的种子数据格式
class TorrentModel {
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
  final double dlLimit;
  final double upLimit;
  final double timeActive;
  final int seedingTime;

  TorrentModel({
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
    required this.dlLimit,
    required this.upLimit,
    required this.timeActive,
    required this.seedingTime,
  });

  /// 从 QBTorrentModel 转换；[previous] 存在时对空字段与未携带的可选指标沿用历史值
  factory TorrentModel.fromQBTorrentModel(
    dynamic qbTorrent, {
    TorrentModel? previous,
  }) {
    final p = previous;
    if (p == null) {
      return TorrentModel(
        hash: qbTorrent.hash,
        name: qbTorrent.name,
        size: qbTorrent.size,
        totalSize: qbTorrent.totalSize,
        progress: qbTorrent.progress,
        dlspeed: qbTorrent.dlspeed,
        upspeed: qbTorrent.upspeed,
        priority: qbTorrent.priority,
        numSeeds: qbTorrent.numSeeds,
        numLeechers: qbTorrent.numLeechers,
        numComplete: qbTorrent.numComplete,
        numIncomplete: qbTorrent.numIncomplete,
        ratio: qbTorrent.ratio,
        popularity: qbTorrent.popularity,
        eta: qbTorrent.eta,
        state: qbTorrent.state,
        category: qbTorrent.category,
        tags: qbTorrent.tags,
        addedOn: qbTorrent.addedOn,
        completionOn: qbTorrent.completionOn,
        lastActivity: qbTorrent.lastActivity,
        seenComplete: qbTorrent.seenComplete,
        savePath: qbTorrent.savePath,
        contentPath: qbTorrent.contentPath,
        downloadPath: qbTorrent.downloadPath,
        rootPath: qbTorrent.rootPath,
        downloaded: qbTorrent.downloaded,
        completed: qbTorrent.completed,
        uploaded: qbTorrent.uploaded,
        downloadedSession: qbTorrent.downloadedSession,
        uploadedSession: qbTorrent.uploadedSession,
        amountLeft: qbTorrent.amountLeft,
        tracker: qbTorrent.tracker,
        comment: qbTorrent.comment,
        magnetUri: qbTorrent.magnetUri,
        availability: qbTorrent.availability,
        dlLimit: qbTorrent.dlLimit,
        upLimit: qbTorrent.upLimit,
        timeActive: qbTorrent.timeActive,
        seedingTime: qbTorrent.seedingTime,
      );
    }

    final qHash = qbTorrent.hash as String? ?? '';
    final qName = qbTorrent.name as String? ?? '';
    final qSize = (qbTorrent.size as num?)?.toInt() ?? 0;
    final qTotal = (qbTorrent.totalSize as num?)?.toInt() ?? 0;
    final qProgress = (qbTorrent.progress as num?)?.toDouble() ?? 0.0;
    final qNumComplete = (qbTorrent.numComplete as num?)?.toInt() ?? 0;
    final qNumIncomplete = (qbTorrent.numIncomplete as num?)?.toInt() ?? 0;
    final qState = qbTorrent.state as String? ?? '';
    final qCategory = qbTorrent.category as String? ?? '';
    final qTags = qbTorrent.tags is List
        ? (qbTorrent.tags as List).map((e) => e.toString()).toList()
        : <String>[];
    final qAddedOn = (qbTorrent.addedOn as num?)?.toInt() ?? 0;
    final qSavePath = qbTorrent.savePath as String? ?? '';
    final qContentPath = qbTorrent.contentPath as String? ?? '';
    final qDownloadPath = qbTorrent.downloadPath as String? ?? '';
    final qRootPath = qbTorrent.rootPath as String? ?? '';
    final qTracker = qbTorrent.tracker as String? ?? '';
    final qComment = qbTorrent.comment as String? ?? '';
    final qMagnetUri = qbTorrent.magnetUri as String? ?? '';
    final hasPopularityField = qbTorrent.hasPopularityField == true;
    final hasAvailabilityField = qbTorrent.hasAvailabilityField == true;

    return TorrentModel(
      hash: qHash.isNotEmpty ? qHash : p.hash,
      name: (qName.isNotEmpty || p.name.isEmpty) ? qName : p.name,
      size: (qSize > 0 || p.size == 0) ? qSize : p.size,
      totalSize: (qTotal > 0 || p.totalSize == 0)
          ? qTotal
          : (p.totalSize > 0 ? p.totalSize : qSize),
      progress: (qProgress > 0 || p.progress == 0) ? qProgress : p.progress,
      dlspeed: (qbTorrent.dlspeed as num?)?.toInt() ?? 0,
      upspeed: (qbTorrent.upspeed as num?)?.toInt() ?? 0,
      priority: (qbTorrent.priority as num?)?.toInt() ?? 0,
      numSeeds: (qbTorrent.numSeeds as num?)?.toInt() ?? 0,
      numLeechers: (qbTorrent.numLeechers as num?)?.toInt() ?? 0,
      numComplete: (qNumComplete >= 0) ? qNumComplete : p.numComplete,
      numIncomplete: (qNumIncomplete >= 0) ? qNumIncomplete : p.numIncomplete,
      ratio: (qbTorrent.ratio as num?)?.toDouble() ?? 0.0,
      popularity: hasPopularityField
          ? ((qbTorrent.popularity as num?)?.toDouble() ?? 0.0)
          : p.popularity,
      eta: (qbTorrent.eta as num?)?.toInt() ?? 0,
      state: qState.isNotEmpty ? qState : p.state,
      category: (qCategory.isNotEmpty || p.category.isEmpty)
          ? qCategory
          : p.category,
      tags: qTags.isNotEmpty || p.tags.isEmpty ? qTags : p.tags,
      addedOn: (qAddedOn > 0 || p.addedOn == 0) ? qAddedOn : p.addedOn,
      completionOn: (qbTorrent.completionOn as num?)?.toInt() ?? 0,
      lastActivity: (qbTorrent.lastActivity as num?)?.toInt() ?? 0,
      seenComplete: (qbTorrent.seenComplete as num?)?.toInt() ?? 0,
      savePath: (qSavePath.isNotEmpty || p.savePath.isEmpty)
          ? qSavePath
          : p.savePath,
      contentPath: (qContentPath.isNotEmpty || p.contentPath.isEmpty)
          ? qContentPath
          : p.contentPath,
      downloadPath: (qDownloadPath.isNotEmpty || p.downloadPath.isEmpty)
          ? qDownloadPath
          : p.downloadPath,
      rootPath: (qRootPath.isNotEmpty || p.rootPath.isEmpty)
          ? qRootPath
          : p.rootPath,
      downloaded: (qbTorrent.downloaded as num?)?.toInt() ?? 0,
      completed: (qbTorrent.completed as num?)?.toInt() ?? 0,
      uploaded: (qbTorrent.uploaded as num?)?.toInt() ?? 0,
      downloadedSession: (qbTorrent.downloadedSession as num?)?.toInt() ?? 0,
      uploadedSession: (qbTorrent.uploadedSession as num?)?.toInt() ?? 0,
      amountLeft: (qbTorrent.amountLeft as num?)?.toInt() ?? 0,
      tracker: (qTracker.isNotEmpty || p.tracker.isEmpty)
          ? qTracker
          : p.tracker,
      comment: (qComment.isNotEmpty || p.comment.isEmpty)
          ? qComment
          : p.comment,
      magnetUri: (qMagnetUri.isNotEmpty || p.magnetUri.isEmpty)
          ? qMagnetUri
          : p.magnetUri,
      availability: hasAvailabilityField
          ? ((qbTorrent.availability as num?)?.toDouble() ?? 0.0)
          : p.availability,
      dlLimit: (qbTorrent.dlLimit as num?)?.toDouble() ?? 0.0,
      upLimit: (qbTorrent.upLimit as num?)?.toDouble() ?? 0.0,
      timeActive: (qbTorrent.timeActive as num?)?.toDouble() ?? 0.0,
      seedingTime: (qbTorrent.seedingTime as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hash': hash,
      'name': name,
      'size': size,
      'totalSize': totalSize,
      'progress': progress,
      'dlspeed': dlspeed,
      'upspeed': upspeed,
      'priority': priority,
      'numSeeds': numSeeds,
      'numLeechers': numLeechers,
      'numComplete': numComplete,
      'numIncomplete': numIncomplete,
      'ratio': ratio,
      'popularity': popularity,
      'eta': eta,
      'state': state,
      'category': category,
      'tags': tags,
      'addedOn': addedOn,
      'completionOn': completionOn,
      'lastActivity': lastActivity,
      'seenComplete': seenComplete,
      'savePath': savePath,
      'contentPath': contentPath,
      'downloadPath': downloadPath,
      'rootPath': rootPath,
      'downloaded': downloaded,
      'completed': completed,
      'uploaded': uploaded,
      'downloadedSession': downloadedSession,
      'uploadedSession': uploadedSession,
      'amountLeft': amountLeft,
      'tracker': tracker,
      'comment': comment,
      'magnetUri': magnetUri,
      'availability': availability,
      'dlLimit': dlLimit,
      'upLimit': upLimit,
      'timeActive': timeActive,
      'seedingTime': seedingTime,
    };
  }

  factory TorrentModel.fromJson(Map<String, dynamic> json) {
    return TorrentModel(
      hash: json['hash']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
      totalSize: (json['totalSize'] as num?)?.toInt() ?? 0,
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      dlspeed: (json['dlspeed'] as num?)?.toInt() ?? 0,
      upspeed: (json['upspeed'] as num?)?.toInt() ?? 0,
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      numSeeds: (json['numSeeds'] as num?)?.toInt() ?? 0,
      numLeechers: (json['numLeechers'] as num?)?.toInt() ?? 0,
      numComplete: (json['numComplete'] as num?)?.toInt() ?? 0,
      numIncomplete: (json['numIncomplete'] as num?)?.toInt() ?? 0,
      ratio: (json['ratio'] as num?)?.toDouble() ?? 0,
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0,
      eta: (json['eta'] as num?)?.toInt() ?? 0,
      state: json['state']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      addedOn: (json['addedOn'] as num?)?.toInt() ?? 0,
      completionOn: (json['completionOn'] as num?)?.toInt() ?? 0,
      lastActivity: (json['lastActivity'] as num?)?.toInt() ?? 0,
      seenComplete: (json['seenComplete'] as num?)?.toInt() ?? 0,
      savePath: json['savePath']?.toString() ?? '',
      contentPath: json['contentPath']?.toString() ?? '',
      downloadPath: json['downloadPath']?.toString() ?? '',
      rootPath: json['rootPath']?.toString() ?? '',
      downloaded: (json['downloaded'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      uploaded: (json['uploaded'] as num?)?.toInt() ?? 0,
      downloadedSession: (json['downloadedSession'] as num?)?.toInt() ?? 0,
      uploadedSession: (json['uploadedSession'] as num?)?.toInt() ?? 0,
      amountLeft: (json['amountLeft'] as num?)?.toInt() ?? 0,
      tracker: json['tracker']?.toString() ?? '',
      comment: json['comment']?.toString() ?? '',
      magnetUri: json['magnetUri']?.toString() ?? '',
      availability: (json['availability'] as num?)?.toDouble() ?? 0,
      dlLimit: (json['dlLimit'] as num?)?.toDouble() ?? 0,
      upLimit: (json['upLimit'] as num?)?.toDouble() ?? 0,
      timeActive: (json['timeActive'] as num?)?.toDouble() ?? 0,
      seedingTime: (json['seedingTime'] as num?)?.toInt() ?? 0,
    );
  }

  /// 转换为 QBTorrentModel（兼容性方法）
  dynamic toQBTorrentModel() {
    // 导入 QBTorrentModel 并创建实例
    // 这里需要导入 QBTorrentModel，但为了解耦，我们返回一个 Map
    // 或者让 QBTorrentModel 提供一个 fromTorrentModel 方法
    throw UnimplementedError('Use QBTorrentModel.fromTorrentModel instead');
  }

  // 便捷方法
  bool get isDownloading => state == 'downloading';
  bool get isSeeding => state == 'seeding';
  bool get isPaused => state == 'paused' || state == 'stopped';
  bool get hasError => state.contains('error') || state == 'missingFiles';
}
