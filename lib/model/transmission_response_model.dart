/// Transmission RPC 响应基础模型
class TransmissionResponse<T> {
  final String? result;
  final T arguments;

  TransmissionResponse({this.result, required this.arguments});

  factory TransmissionResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return TransmissionResponse<T>(
      result: json['result'] as String?,
      arguments: fromJsonT(json['arguments']),
    );
  }
}

/// Transmission 会话响应
class TransmissionSessionResponse {
  final String? version;
  final int? rpcVersion;
  final int? rpcVersionMinimum;
  final String? rpcVersionSemver;
  final String? sessionId;
  final String? downloadDir;
  final int? downloadDirFreeSpace;
  final bool? downloadQueueEnabled;
  final int? downloadQueueSize;
  final String? incompleteDir;
  final bool? incompleteDirEnabled;
  final bool? seedQueueEnabled;
  final int? seedQueueSize;
  final double? seedRatioLimit;
  final bool? seedRatioLimited;
  final int? speedLimitDown;
  final bool? speedLimitDownEnabled;
  final int? speedLimitUp;
  final bool? speedLimitUpEnabled;
  final int? altSpeedDown;
  final int? altSpeedUp;
  final bool? altSpeedEnabled;
  final bool? altSpeedTimeEnabled;
  final int? altSpeedTimeBegin;
  final int? altSpeedTimeEnd;
  final int? altSpeedTimeDay;
  final int? peerLimitGlobal;
  final int? peerLimitPerTorrent;
  final int? peerPort;
  final bool? peerPortRandomOnStart;
  final bool? portForwardingEnabled;
  final bool? dhtEnabled;
  final bool? lpdEnabled;
  final bool? pexEnabled;
  final bool? tcpEnabled;
  final bool? utpEnabled;
  final String? encryption;
  final bool? queueStalledEnabled;
  final int? queueStalledMinutes;
  final bool? startAddedTorrents;

  TransmissionSessionResponse({
    this.version,
    this.rpcVersion,
    this.rpcVersionMinimum,
    this.rpcVersionSemver,
    this.sessionId,
    this.downloadDir,
    this.downloadDirFreeSpace,
    this.downloadQueueEnabled,
    this.downloadQueueSize,
    this.incompleteDir,
    this.incompleteDirEnabled,
    this.seedQueueEnabled,
    this.seedQueueSize,
    this.seedRatioLimit,
    this.seedRatioLimited,
    this.speedLimitDown,
    this.speedLimitDownEnabled,
    this.speedLimitUp,
    this.speedLimitUpEnabled,
    this.altSpeedDown,
    this.altSpeedUp,
    this.altSpeedEnabled,
    this.altSpeedTimeEnabled,
    this.altSpeedTimeBegin,
    this.altSpeedTimeEnd,
    this.altSpeedTimeDay,
    this.peerLimitGlobal,
    this.peerLimitPerTorrent,
    this.peerPort,
    this.peerPortRandomOnStart,
    this.portForwardingEnabled,
    this.dhtEnabled,
    this.lpdEnabled,
    this.pexEnabled,
    this.tcpEnabled,
    this.utpEnabled,
    this.encryption,
    this.queueStalledEnabled,
    this.queueStalledMinutes,
    this.startAddedTorrents,
  });

  factory TransmissionSessionResponse.fromJson(Map<String, dynamic> json) {
    return TransmissionSessionResponse(
      version: json['version'] as String?,
      rpcVersion: _parseInt(json['rpc-version']),
      rpcVersionMinimum: _parseInt(json['rpc-version-minimum']),
      rpcVersionSemver: json['rpc-version-semver'] as String?,
      sessionId: json['session-id'] as String?,
      downloadDir: json['download-dir'] as String?,
      downloadDirFreeSpace: _parseInt64(json['download-dir-free-space']),
      downloadQueueEnabled: json['download-queue-enabled'] as bool?,
      downloadQueueSize: _parseInt(json['download-queue-size']),
      incompleteDir: json['incomplete-dir'] as String?,
      incompleteDirEnabled: json['incomplete-dir-enabled'] as bool?,
      seedQueueEnabled: json['seed-queue-enabled'] as bool?,
      seedQueueSize: _parseInt(json['seed-queue-size']),
      seedRatioLimit: _parseDouble(json['seedRatioLimit']),
      seedRatioLimited: json['seedRatioLimited'] as bool?,
      speedLimitDown: _parseInt(json['speed-limit-down']),
      speedLimitDownEnabled: json['speed-limit-down-enabled'] as bool?,
      speedLimitUp: _parseInt(json['speed-limit-up']),
      speedLimitUpEnabled: json['speed-limit-up-enabled'] as bool?,
      altSpeedDown: _parseInt(json['alt-speed-down']),
      altSpeedUp: _parseInt(json['alt-speed-up']),
      altSpeedEnabled: json['alt-speed-enabled'] as bool?,
      altSpeedTimeEnabled: json['alt-speed-time-enabled'] as bool?,
      altSpeedTimeBegin: _parseInt(json['alt-speed-time-begin']),
      altSpeedTimeEnd: _parseInt(json['alt-speed-time-end']),
      altSpeedTimeDay: _parseInt(json['alt-speed-time-day']),
      peerLimitGlobal: _parseInt(json['peer-limit-global']),
      peerLimitPerTorrent: _parseInt(json['peer-limit-per-torrent']),
      peerPort: _parseInt(json['peer-port']),
      peerPortRandomOnStart: json['peer-port-random-on-start'] as bool?,
      portForwardingEnabled: json['port-forwarding-enabled'] as bool?,
      dhtEnabled: json['dht-enabled'] as bool?,
      lpdEnabled: json['lpd-enabled'] as bool?,
      pexEnabled: json['pex-enabled'] as bool?,
      tcpEnabled: json['tcp-enabled'] as bool?,
      utpEnabled: json['utp-enabled'] as bool?,
      encryption: json['encryption'] as String?,
      queueStalledEnabled: json['queue-stalled-enabled'] as bool?,
      queueStalledMinutes: _parseInt(json['queue-stalled-minutes']),
      startAddedTorrents: json['start-added-torrents'] as bool?,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static int? _parseInt64(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

/// Transmission 种子列表响应
class TransmissionTorrentResponse {
  final List<TransmissionTorrent>? torrents;

  TransmissionTorrentResponse({this.torrents});

  factory TransmissionTorrentResponse.fromJson(Map<String, dynamic> json) {
    final torrentsJson = json['torrents'] as List?;
    return TransmissionTorrentResponse(
      torrents: torrentsJson
          ?.map((t) => TransmissionTorrent.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Transmission 种子模型
class TransmissionTorrent {
  final String? hashString;
  final String? name;
  final int? sizeWhenDone;
  final int? downloaded;
  final int? uploaded;
  final double? uploadRatio;
  final int? rateDownload;
  final int? rateUpload;
  final int? eta;
  final int? status;
  final double? percentDone;
  final int? peersConnected;
  final int? peersGettingFromUs;
  final int? peersSendingToUs;
  final String? comment;
  final int? dateDone;
  final String? creator;
  final int? dateCreated;
  final int? downloadLimit;
  final int? uploadLimit;
  final String? downloadDir;
  final bool? isPrivate;
  final int? dateActive;
  final int? peerLimit;
  final int? pieceSize;
  final String? pieces;
  final int? pieceCount;
  final int? announceResponse;
  final int? secondsSeeding;
  final int? secondsActive;
  final int? corruptEver;
  final List<TransmissionTracker>? trackers;
  final List<TransmissionFile>? files;
  final List<String>? labels;
  final int? downloadedEver;
  final int? downloadedWhenStarted;
  final int? uploadedEver;
  final int? uploadedWhenStarted;
  final bool? downloadLimited;
  final bool? uploadLimited;
  final bool? isFinished;
  final bool? isStalled;
  final int? dateStarted;
  final int? bytesCompleted;
  final List<TransmissionPeer>? peers;
  final List<TransmissionFileStats>? fileStats;
  final List<bool>? piecesArray;
  final int? error;
  final String? errorString;
  final int? id;
  final int? leftUntilDone;
  final double? metadataPercentComplete;
  final int? peerCount;
  final Map<String, int>? peersFrom;
  final int? queuePosition;
  final double? recheckProgress;
  final int? seedIdleLimit;
  final int? seedIdleMode;
  final double? seedRatioLimit;
  final int? seedRatioMode;
  final int? startDate;
  final List<TransmissionTrackerStats>? trackerStats;
  final int? webseedsSendingToUs;

  TransmissionTorrent({
    this.hashString,
    this.name,
    this.sizeWhenDone,
    this.downloaded,
    this.uploaded,
    this.uploadRatio,
    this.rateDownload,
    this.rateUpload,
    this.eta,
    this.status,
    this.percentDone,
    this.peersConnected,
    this.peersGettingFromUs,
    this.peersSendingToUs,
    this.comment,
    this.dateDone,
    this.creator,
    this.dateCreated,
    this.downloadLimit,
    this.uploadLimit,
    this.downloadDir,
    this.isPrivate,
    this.dateActive,
    this.peerLimit,
    this.pieceSize,
    this.pieces,
    this.pieceCount,
    this.announceResponse,
    this.secondsSeeding,
    this.secondsActive,
    this.corruptEver,
    this.trackers,
    this.files,
    this.labels,
    this.downloadedEver,
    this.downloadedWhenStarted,
    this.uploadedEver,
    this.uploadedWhenStarted,
    this.downloadLimited,
    this.uploadLimited,
    this.isFinished,
    this.isStalled,
    this.dateStarted,
    this.bytesCompleted,
    this.peers,
    this.fileStats,
    this.piecesArray,
    this.error,
    this.errorString,
    this.id,
    this.leftUntilDone,
    this.metadataPercentComplete,
    this.peerCount,
    this.peersFrom,
    this.queuePosition,
    this.recheckProgress,
    this.seedIdleLimit,
    this.seedIdleMode,
    this.seedRatioLimit,
    this.seedRatioMode,
    this.startDate,
    this.trackerStats,
    this.webseedsSendingToUs,
  });

  factory TransmissionTorrent.fromJson(Map<String, dynamic> json) {
    return TransmissionTorrent(
      hashString: json['hashString'] as String?,
      name: json['name'] as String?,
      sizeWhenDone: _parseInt64(json['sizeWhenDone']),
      downloaded: _parseInt64(json['downloaded']),
      uploaded: _parseInt64(json['uploaded']),
      uploadRatio: _parseDouble(json['uploadRatio']),
      rateDownload: _parseInt64(json['rateDownload']),
      rateUpload: _parseInt64(json['rateUpload']),
      eta: _parseInt(json['eta']),
      status: _parseInt(json['status']),
      percentDone: _parseDouble(json['percentDone']),
      peersConnected: _parseInt(json['peersConnected']),
      peersGettingFromUs: _parseInt(json['peersGettingFromUs']),
      peersSendingToUs: _parseInt(json['peersSendingToUs']),
      comment: json['comment'] as String?,
      dateDone: _parseInt(json['dateDone']),
      creator: json['creator'] as String?,
      dateCreated: _parseInt(json['dateCreated']),
      downloadLimit: _parseInt(json['downloadLimit']),
      uploadLimit: _parseInt(json['uploadLimit']),
      downloadDir: json['downloadDir'] as String?,
      isPrivate: json['isPrivate'] as bool?,
      dateActive: _parseInt(json['dateActive']),
      peerLimit: _parseInt(json['peerLimit']),
      pieceSize: _parseInt(json['pieceSize']),
      pieces: json['pieces'] as String?,
      pieceCount: _parseInt(json['pieceCount']),
      announceResponse: _parseInt(json['announceResponse']),
      secondsSeeding: _parseInt(json['secondsSeeding']),
      secondsActive: _parseInt(json['secondsActive']),
      corruptEver: _parseInt64(json['corruptEver']),
      trackers: (json['trackers'] as List?)
          ?.map((t) => TransmissionTracker.fromJson(t as Map<String, dynamic>))
          .toList(),
      files: (json['files'] as List?)
          ?.map((f) => TransmissionFile.fromJson(f as Map<String, dynamic>))
          .toList(),
      labels: (json['labels'] as List?)?.map((l) => l.toString()).toList(),
      downloadedEver: _parseInt64(json['downloadedEver']),
      downloadedWhenStarted: _parseInt64(json['downloadedWhenStarted']),
      uploadedEver: _parseInt64(json['uploadedEver']),
      uploadedWhenStarted: _parseInt64(json['uploadedWhenStarted']),
      downloadLimited: json['downloadLimited'] as bool?,
      uploadLimited: json['uploadLimited'] as bool?,
      isFinished: json['isFinished'] as bool?,
      isStalled: json['isStalled'] as bool?,
      dateStarted: _parseInt(json['dateStarted']),
      bytesCompleted: _parseInt64(json['bytesCompleted']),
      peers: (json['peers'] as List?)
          ?.map((p) => TransmissionPeer.fromJson(p as Map<String, dynamic>))
          .toList(),
      fileStats: (json['fileStats'] as List?)
          ?.map(
            (fs) => TransmissionFileStats.fromJson(fs as Map<String, dynamic>),
          )
          .toList(),
      piecesArray: (json['piecesArray'] as List?)
          ?.map((p) => p as bool)
          .toList(),
      error: _parseInt(json['error']),
      errorString: json['errorString'] as String?,
      id: _parseInt(json['id']),
      leftUntilDone: _parseInt64(json['leftUntilDone']),
      metadataPercentComplete: _parseDouble(json['metadataPercentComplete']),
      peerCount: _parseInt(json['peerCount']),
      peersFrom: _parseMapStringInt(json['peersFrom']),
      queuePosition: _parseInt(json['queuePosition']),
      recheckProgress: _parseDouble(json['recheckProgress']),
      seedIdleLimit: _parseInt(json['seedIdleLimit']),
      seedIdleMode: _parseInt(json['seedIdleMode']),
      seedRatioLimit: _parseDouble(json['seedRatioLimit']),
      seedRatioMode: _parseInt(json['seedRatioMode']),
      startDate: _parseInt(json['startDate']),
      trackerStats: (json['trackerStats'] as List?)
          ?.map(
            (ts) =>
                TransmissionTrackerStats.fromJson(ts as Map<String, dynamic>),
          )
          .toList(),
      webseedsSendingToUs: _parseInt(json['webseedsSendingToUs']),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static int? _parseInt64(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static Map<String, int>? _parseMapStringInt(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, int>) return value;
    if (value is Map) {
      final result = <String, int>{};
      value.forEach((key, val) {
        if (key is String) {
          final intVal = _parseInt(val);
          if (intVal != null) {
            result[key] = intVal;
          }
        }
      });
      return result.isEmpty ? null : result;
    }
    return null;
  }
}

/// Transmission Tracker 模型
class TransmissionTracker {
  final String? announce;
  final String? lastAnnounceResult;
  final int? lastAnnouncePeerCount;
  final int? lastAnnounceStatus;

  TransmissionTracker({
    this.announce,
    this.lastAnnounceResult,
    this.lastAnnouncePeerCount,
    this.lastAnnounceStatus,
  });

  factory TransmissionTracker.fromJson(Map<String, dynamic> json) {
    return TransmissionTracker(
      announce: json['announce'] as String?,
      lastAnnounceResult: json['lastAnnounceResult'] as String?,
      lastAnnouncePeerCount: _parseInt(json['lastAnnouncePeerCount']),
      lastAnnounceStatus: _parseInt(json['lastAnnounceStatus']),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

/// Transmission File 模型
class TransmissionFile {
  final String? name;
  final int? length;
  final int? bytesCompleted;
  final int? priority;
  final bool? isSeed;
  final bool? wanted;
  final double? availability;

  TransmissionFile({
    this.name,
    this.length,
    this.bytesCompleted,
    this.priority,
    this.isSeed,
    this.wanted,
    this.availability,
  });

  factory TransmissionFile.fromJson(Map<String, dynamic> json) {
    return TransmissionFile(
      name: json['name'] as String?,
      length: _parseInt64(json['length']),
      bytesCompleted: _parseInt64(json['bytesCompleted']),
      priority: _parseInt(json['priority']),
      isSeed: json['isSeed'] as bool?,
      wanted: json['wanted'] as bool?,
      availability: _parseDouble(json['availability']),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static int? _parseInt64(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

/// Transmission Peer 模型
class TransmissionPeer {
  final String? address;
  final int? port;
  final String? clientName;
  final String? flagStr;
  final double? progress;
  final int? rateToClient;
  final int? rateToPeer;
  final bool? isDownloadingFrom;
  final bool? isUploadingTo;
  final bool? isEncrypted;
  final bool? isUTP;
  final bool? isIncoming;
  final bool? clientIsChoked;
  final bool? clientIsInterested;
  final bool? peerIsChoked;
  final bool? peerIsInterested;

  TransmissionPeer({
    this.address,
    this.port,
    this.clientName,
    this.flagStr,
    this.progress,
    this.rateToClient,
    this.rateToPeer,
    this.isDownloadingFrom,
    this.isUploadingTo,
    this.isEncrypted,
    this.isUTP,
    this.isIncoming,
    this.clientIsChoked,
    this.clientIsInterested,
    this.peerIsChoked,
    this.peerIsInterested,
  });

  factory TransmissionPeer.fromJson(Map<String, dynamic> json) {
    return TransmissionPeer(
      address: json['address'] as String?,
      port: _parseInt(json['port']),
      clientName: json['clientName'] as String?,
      flagStr: json['flagStr'] as String?,
      progress: _parseDouble(json['progress']),
      rateToClient: _parseInt64(json['rateToClient']),
      rateToPeer: _parseInt64(json['rateToPeer']),
      isDownloadingFrom: json['isDownloadingFrom'] as bool?,
      isUploadingTo: json['isUploadingTo'] as bool?,
      isEncrypted: json['isEncrypted'] as bool?,
      isUTP: json['isUTP'] as bool?,
      isIncoming: json['isIncoming'] as bool?,
      clientIsChoked: json['clientIsChoked'] as bool?,
      clientIsInterested: json['clientIsInterested'] as bool?,
      peerIsChoked: json['peerIsChoked'] as bool?,
      peerIsInterested: json['peerIsInterested'] as bool?,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static int? _parseInt64(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

/// Transmission File Stats 模型
class TransmissionFileStats {
  final int? bytesCompleted;
  final bool? wanted;
  final int? priority;

  TransmissionFileStats({this.bytesCompleted, this.wanted, this.priority});

  factory TransmissionFileStats.fromJson(Map<String, dynamic> json) {
    return TransmissionFileStats(
      bytesCompleted: _parseInt64(json['bytesCompleted']),
      wanted: json['wanted'] as bool?,
      priority: _parseInt(json['priority']),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static int? _parseInt64(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

/// Transmission Tracker Stats 模型
class TransmissionTrackerStats {
  final String? announce;
  final int? announceState;
  final int? downloadCount;
  final bool? hasAnnounced;
  final bool? hasScraped;
  final String? host;
  final int? id;
  final bool? isBackup;
  final int? lastAnnouncePeerCount;
  final String? lastAnnounceResult;
  final int? lastAnnounceStartTime;
  final bool? lastAnnounceSucceeded;
  final int? lastAnnounceTime;
  final bool? lastAnnounceTimedOut;
  final String? lastScrapeResult;
  final int? lastScrapeStartTime;
  final bool? lastScrapeSucceeded;
  final int? lastScrapeTime;
  final bool? lastScrapeTimedOut;
  final int? leecherCount;
  final int? nextAnnounceTime;
  final int? nextScrapeTime;
  final String? scrape;
  final int? scrapeState;
  final int? seederCount;
  final int? tier;

  TransmissionTrackerStats({
    this.announce,
    this.announceState,
    this.downloadCount,
    this.hasAnnounced,
    this.hasScraped,
    this.host,
    this.id,
    this.isBackup,
    this.lastAnnouncePeerCount,
    this.lastAnnounceResult,
    this.lastAnnounceStartTime,
    this.lastAnnounceSucceeded,
    this.lastAnnounceTime,
    this.lastAnnounceTimedOut,
    this.lastScrapeResult,
    this.lastScrapeStartTime,
    this.lastScrapeSucceeded,
    this.lastScrapeTime,
    this.lastScrapeTimedOut,
    this.leecherCount,
    this.nextAnnounceTime,
    this.nextScrapeTime,
    this.scrape,
    this.scrapeState,
    this.seederCount,
    this.tier,
  });

  factory TransmissionTrackerStats.fromJson(Map<String, dynamic> json) {
    return TransmissionTrackerStats(
      announce: json['announce'] as String?,
      announceState: _parseInt(json['announceState']),
      downloadCount: _parseInt(json['downloadCount']),
      hasAnnounced: json['hasAnnounced'] as bool?,
      hasScraped: json['hasScraped'] as bool?,
      host: json['host'] as String?,
      id: _parseInt(json['id']),
      isBackup: json['isBackup'] as bool?,
      lastAnnouncePeerCount: _parseInt(json['lastAnnouncePeerCount']),
      lastAnnounceResult: json['lastAnnounceResult'] as String?,
      lastAnnounceStartTime: _parseInt(json['lastAnnounceStartTime']),
      lastAnnounceSucceeded: json['lastAnnounceSucceeded'] as bool?,
      lastAnnounceTime: _parseInt(json['lastAnnounceTime']),
      lastAnnounceTimedOut: json['lastAnnounceTimedOut'] as bool?,
      lastScrapeResult: json['lastScrapeResult'] as String?,
      lastScrapeStartTime: _parseInt(json['lastScrapeStartTime']),
      lastScrapeSucceeded: json['lastScrapeSucceeded'] as bool?,
      lastScrapeTime: _parseInt(json['lastScrapeTime']),
      lastScrapeTimedOut: json['lastScrapeTimedOut'] as bool?,
      leecherCount: _parseInt(json['leecherCount']),
      nextAnnounceTime: _parseInt(json['nextAnnounceTime']),
      nextScrapeTime: _parseInt(json['nextScrapeTime']),
      scrape: json['scrape'] as String?,
      scrapeState: _parseInt(json['scrapeState']),
      seederCount: _parseInt(json['seederCount']),
      tier: _parseInt(json['tier']),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
