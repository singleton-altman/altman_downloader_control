import 'package:altman_downloader_control/controller/transmission/transmission_dio_client.dart';
import 'package:altman_downloader_control/model/qb_torrent_file_model.dart';
import 'package:altman_downloader_control/model/qb_torrent_properties_model.dart';
import 'package:altman_downloader_control/model/qb_tracker_model.dart';
import 'package:altman_downloader_control/model/server_state_model.dart';
import 'package:altman_downloader_control/model/torrent_item_model.dart';
import 'package:altman_downloader_control/model/transmission_response_model.dart';
import 'package:altman_downloader_control/utils/log.dart';

/// Transmission 服务类
/// 使用原生 Dio 请求处理 Transmission RPC API
class TransmissionService {
  final _client = TransmissionDioClient();
  bool _initialized = false;

  final DownloaderLog _log = DownloaderLog();

  // 基础字段列表（用于列表显示，减少内存占用）
  // 移除了大字段：files, fileStats, peers, pieces, piecesArray
  static const List<String> _basicFields = [
    'hashString',
    'name',
    'status',
    'sizeWhenDone',
    'downloaded',
    'rateDownload',
    'rateUpload',
    'eta',
    'uploadRatio',
    'downloadDir',
    'error',
    'errorString',
    'peersConnected',
    'peersGettingFromUs',
    'peersSendingToUs',
    'peerCount',
    'queuePosition',
    'percentDone',
    'uploadedEver',
    'uploadedWhenStarted',
    'uploadLimit',
    'uploadLimited',
    'downloadedEver',
    'downloadedWhenStarted',
    'downloadLimit',
    'downloadLimited',
    'dateCreated',
    'comment',
    'dateDone',
    'dateActive',
    'secondsActive',
    'secondsSeeding',
    'trackerStats', // 只获取统计信息，不获取完整tracker列表
    'labels',
    'addedDate',
  ];

  // 完整字段列表（用于详情页面）
  static const List<String> _fullFields = [
    'hashString',
    'name',
    'status',
    'sizeWhenDone',
    'downloaded',
    'uploaded',
    'rateDownload',
    'rateUpload',
    'eta',
    'uploadRatio',
    'downloadDir',
    'error',
    'errorString',
    'isPrivate',
    'pieceCount',
    'pieceSize',
    'files',
    'fileStats',
    'peers',
    'peersConnected',
    'peersFrom',
    'peersGettingFromUs',
    'peersSendingToUs',
    'peerCount',
    'queuePosition',
    'seedIdleLimit',
    'seedIdleMode',
    'seedRatioLimit',
    'seedRatioMode',
    'startDate',
    'trackerStats',
    'uploadedEver',
    'uploadedWhenStarted',
    'uploadLimit',
    'uploadLimited',
    'percentDone',
    'downloadedEver',
    'downloadedWhenStarted',
    'downloadLimit',
    'downloadLimited',
    'dateCreated',
    'creator',
    'comment',
    'dateDone',
    'dateActive',
    'secondsActive',
    'secondsSeeding',
    'corruptEver',
    'trackers',
    'labels',
    'addedDate',
    // 注意：不包含 pieces 和 piecesArray，这些字段对于大量数据会占用大量内存
  ];

  /// 初始化 API 连接
  Future<bool> initialize({
    required String baseUrl,
    String? username,
    String? password,
  }) async {
    try {
      _client.initialize(
        baseUrl: baseUrl,
        username: username,
        password: password,
      );

      // 尝试登录（获取 Session ID）
      final success = await _client.login();
      _initialized = success;
      return success;
    } catch (e) {
      _initialized = false;
      _log.e('Transmission initialize error: $e');
      return false;
    }
  }

  /// 检查连接状态
  Future<bool> checkConnection() async {
    if (!_initialized) return false;
    return await _client.checkConnection();
  }

  /// 获取 Transmission 客户端版本
  Future<String?> getVersion() async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      final response = await _client.rpcRequest(method: 'session-get');
      final data = response.data;
      if (data is Map && data['result'] == 'success') {
        final arguments = data['arguments'] as Map<String, dynamic>?;
        final sessionResponse = TransmissionSessionResponse.fromJson(
          arguments ?? {},
        );
        return sessionResponse.version;
      }
      return null;
    } catch (e) {
      _log.e('Get version error: $e');
      return null;
    }
  }

  /// 获取所有种子列表（返回通用模型）
  /// 使用基础字段列表以减少内存占用
  Future<List<TorrentModel>> getTorrents({bool useFullFields = false}) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      // 默认使用基础字段列表，减少内存占用
      final fieldsToUse = useFullFields ? _fullFields : _basicFields;

      final arguments = {'fields': fieldsToUse};

      final response = await _client.rpcRequest(
        method: 'torrent-get',
        arguments: arguments,
      );

      final data = response.data;
      if (data is Map && data['result'] == 'success') {
        final arguments = data['arguments'] as Map<String, dynamic>?;
        if (arguments != null) {
          final torrentResponse = TransmissionTorrentResponse.fromJson(
            arguments,
          );
          final transmissionTorrents = torrentResponse.torrents ?? [];

          // 使用更高效的方式转换，减少中间对象
          final result = <TorrentModel>[];
          for (final t in transmissionTorrents) {
            if (t.hashString != null && t.hashString!.isNotEmpty) {
              result.add(_convertToTorrentModel(t));
            }
          }
          return result;
        }
      }

      return [];
    } catch (e) {
      _log.e('Get torrents error: $e');
      rethrow;
    }
  }

  /// 将 TransmissionTorrent 转换为通用 TorrentModel（适配器模式）
  /// 优化内存使用，减少不必要的对象创建
  TorrentModel _convertToTorrentModel(TransmissionTorrent torrent) {
    // 转换状态
    final state = _convertStatus(torrent.status ?? 0);

    // 计算剩余下载量
    final sizeWhenDone = torrent.sizeWhenDone ?? 0;
    final downloaded = torrent.downloaded ?? 0;
    final amountLeft = sizeWhenDone > downloaded
        ? (sizeWhenDone - downloaded)
        : 0;

    // 从 trackerStats 中获取 seeder 和 leecher 数量以及 tracker URL（优化：避免多次访问）
    int seederCount = 0;
    int leecherCount = 0;
    String trackerUrl = '';
    final trackerStats = torrent.trackerStats;
    if (trackerStats != null && trackerStats.isNotEmpty) {
      final firstStat = trackerStats.first;
      seederCount = firstStat.seederCount ?? 0;
      leecherCount = firstStat.leecherCount ?? 0;
      trackerUrl = firstStat.announce ?? '';
    }

    // 优化：减少重复计算和对象创建
    final percentDone = torrent.percentDone ?? 0.0;
    final isComplete = percentDone >= 1.0;
    final sizeInt = sizeWhenDone.toInt();
    final name = torrent.name ?? '';
    final downloadDir = torrent.downloadDir ?? '';

    return TorrentModel(
      hash: torrent.hashString ?? '',
      name: name,
      size: sizeInt,
      totalSize: sizeInt,
      progress: percentDone,
      dlspeed: torrent.rateDownload?.toInt() ?? 0,
      upspeed: torrent.rateUpload?.toInt() ?? 0,
      priority: 0, // Transmission 没有直接的优先级字段
      numSeeds: torrent.peersSendingToUs ?? 0,
      numLeechers: torrent.peersGettingFromUs ?? 0,
      numComplete: seederCount,
      numIncomplete: leecherCount,
      ratio: torrent.uploadRatio ?? 0.0,
      popularity: 0.0, // Transmission 不提供
      eta: torrent.eta ?? -1,
      state: state,
      category: torrent.labels?.isNotEmpty == true ? torrent.labels!.first : '',
      tags: torrent.labels ?? const [], // 使用const空列表减少内存
      addedOn: torrent.addedDate ?? 0,
      completionOn: torrent.dateDone ?? 0,
      lastActivity: torrent.dateActive ?? 0,
      seenComplete: isComplete ? sizeInt : 0,
      savePath: downloadDir,
      contentPath: name,
      downloadPath: downloadDir,
      rootPath: downloadDir,
      downloaded: torrent.downloadedEver?.toInt() ?? 0,
      completed: isComplete ? sizeInt : 0,
      uploaded: torrent.uploadedEver?.toInt() ?? 0,
      downloadedSession: torrent.downloadedWhenStarted?.toInt() ?? 0,
      uploadedSession: torrent.uploadedWhenStarted?.toInt() ?? 0,
      amountLeft: amountLeft,
      tracker: trackerUrl, // 从 trackerStats 获取，无需请求完整的 trackers 列表
      comment: torrent.comment ?? '',
      magnetUri: '',
      availability: 1.0, // Transmission 不提供
      dlLimit: torrent.downloadLimit != null
          ? torrent.downloadLimit!.toDouble()
          : -1.0,
      upLimit: torrent.uploadLimit != null
          ? torrent.uploadLimit!.toDouble()
          : -1.0,
      timeActive: (torrent.secondsActive ?? 0).toDouble(),
      seedingTime: torrent.secondsSeeding ?? 0,
    );
  }

  /// 转换 Transmission 状态为 qBittorrent 状态字符串
  String _convertStatus(int status) {
    switch (status) {
      case 0:
        return 'stopped';
      case 1:
      case 2:
        return 'checking';
      case 3:
      case 4:
        return 'downloading';
      case 5:
      case 6:
        return 'paused';
      default:
        return 'unknown';
    }
  }

  /// 暂停种子
  Future<void> pauseTorrents(List<String> hashes) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      await _client.rpcRequest(
        method: 'torrent-stop',
        arguments: {'ids': hashes},
      );
    } catch (e) {
      _log.e('Pause torrents error: $e');
      rethrow;
    }
  }

  /// 恢复种子
  Future<void> resumeTorrents(List<String> hashes) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      await _client.rpcRequest(
        method: 'torrent-start',
        arguments: {'ids': hashes},
      );
    } catch (e) {
      _log.e('Resume torrents error: $e');
      rethrow;
    }
  }

  /// 删除种子
  Future<void> deleteTorrents(
    List<String> hashes, {
    bool deleteFiles = false,
  }) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      await _client.rpcRequest(
        method: 'torrent-remove',
        arguments: {'ids': hashes, 'delete-local-data': deleteFiles},
      );
    } catch (e) {
      _log.e('Delete torrents error: $e');
      rethrow;
    }
  }

  /// 添加种子
  Future<void> addTorrent({
    String? urls,
    List<String>? torrentFilePaths,
    required String savePath,
    bool autoTMM = false,
    String? cookie,
    String? rename,
    String? category,
    bool paused = false,
    String? stopCondition,
    bool? skipChecking,
    String? contentLayout,
    int? dlLimit,
    int? upLimit,
    List<String>? tags,
  }) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      // Transmission 的 torrent-add 参数格式：
      // {
      //   "arguments": {
      //     "download-dir": "/downloads/complete",
      //     "filename": "magnet:?xt=..." 或文件路径,
      //     "paused": false
      //   },
      //   "method": "torrent-add"
      // }

      final arguments = <String, dynamic>{
        'download-dir': savePath,
        'paused': paused,
      };

      // 优先处理文件路径（如果提供）
      if (torrentFilePaths != null && torrentFilePaths.isNotEmpty) {
        // Transmission 一次只能添加一个文件，处理第一个文件
        // filename 可以是文件路径或 URL
        arguments['filename'] = torrentFilePaths.first;
      } else if (urls != null && urls.isNotEmpty) {
        // 如果没有文件，使用 URL（可以是磁力链接或 HTTP 链接）
        arguments['filename'] = urls;
      } else {
        throw Exception('必须提供 torrent URL 或文件路径');
      }

      // Transmission 使用 labels 代替 category 和 tags
      final labels = <String>[];
      if (category != null && category.isNotEmpty) {
        labels.add(category);
      }
      if (tags != null && tags.isNotEmpty) {
        labels.addAll(tags);
      }
      if (labels.isNotEmpty) {
        arguments['labels'] = labels;
      }

      // 速度限制（在添加后通过 torrent-set 设置，但也可以在添加时设置）
      // 注意：Transmission 的 torrent-add 不支持直接设置限速
      // 需要在添加后通过 torrent-set 方法设置

      await _client.rpcRequest(method: 'torrent-add', arguments: arguments);
    } catch (e) {
      _log.e('Add torrent error: $e');
      rethrow;
    }
  }

  /// 设置种子下载限速
  Future<void> setTorrentDownloadLimit(List<String> hashes, int limit) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      await _client.rpcRequest(
        method: 'torrent-set',
        arguments: {
          'ids': hashes,
          'downloadLimit': limit,
          'downloadLimited': limit > 0,
        },
      );
    } catch (e) {
      _log.e('Set download limit error: $e');
      rethrow;
    }
  }

  /// 设置种子上传限速
  Future<void> setTorrentUploadLimit(List<String> hashes, int limit) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      await _client.rpcRequest(
        method: 'torrent-set',
        arguments: {
          'ids': hashes,
          'uploadLimit': limit,
          'uploadLimited': limit > 0,
        },
      );
    } catch (e) {
      _log.e('Set upload limit error: $e');
      rethrow;
    }
  }

  /// 设置种子分类（使用 labels）
  Future<void> setTorrentCategory(List<String> hashes, String category) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      await _client.rpcRequest(
        method: 'torrent-set',
        arguments: {
          'ids': hashes,
          'labels': [category],
        },
      );
    } catch (e) {
      _log.e('Set category error: $e');
      rethrow;
    }
  }

  /// 设置种子标签（使用 labels）
  Future<void> setTorrentTags(List<String> hashes, List<String> tags) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      await _client.rpcRequest(
        method: 'torrent-set',
        arguments: {'ids': hashes, 'labels': tags},
      );
    } catch (e) {
      _log.e('Set tags error: $e');
      rethrow;
    }
  }

  /// 强制启动种子
  Future<void> setForceStart(List<String> hashes, bool value) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      // Transmission 没有直接的 force start，使用 start 代替
      if (value) {
        await resumeTorrents(hashes);
      }
    } catch (e) {
      _log.e('Set force start error: $e');
      rethrow;
    }
  }

  /// 重新检查种子
  Future<void> recheckTorrents(List<String> hashes) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      await _client.rpcRequest(
        method: 'torrent-verify',
        arguments: {'ids': hashes},
      );
    } catch (e) {
      _log.e('Recheck torrents error: $e');
      rethrow;
    }
  }

  /// 重命名种子
  Future<void> renameTorrent(String hash, String newName) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      await _client.rpcRequest(
        method: 'torrent-rename-path',
        arguments: {
          'ids': [hash],
          'path': newName,
        },
      );
    } catch (e) {
      _log.e('Rename torrent error: $e');
      rethrow;
    }
  }

  /// 设置种子保存位置
  Future<void> setTorrentLocation(List<String> hashes, String location) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      await _client.rpcRequest(
        method: 'torrent-set-location',
        arguments: {'ids': hashes, 'location': location, 'move': true},
      );
    } catch (e) {
      _log.e('Set location error: $e');
      rethrow;
    }
  }

  /// 获取种子属性详情
  /// 使用完整字段列表以获取详细信息
  Future<QBTorrentPropertiesModel?> getTorrentProperties(String hash) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      final arguments = {
        'ids': [hash],
        'fields': _fullFields,
      };

      final response = await _client.rpcRequest(
        method: 'torrent-get',
        arguments: arguments,
      );

      final data = response.data;
      if (data is Map && data['result'] == 'success') {
        final arguments = data['arguments'] as Map<String, dynamic>?;
        if (arguments != null) {
          final torrentResponse = TransmissionTorrentResponse.fromJson(
            arguments,
          );
          final torrents = torrentResponse.torrents;
          final torrent = torrents != null && torrents.isNotEmpty
              ? torrents.first
              : null;

          if (torrent != null) {
            return _convertToQBTorrentProperties(torrent);
          }
        }
      }

      return null;
    } catch (e) {
      _log.e('Get torrent properties error: $e');
      return null;
    }
  }

  /// 将 TransmissionTorrent 转换为 QBTorrentPropertiesModel
  QBTorrentPropertiesModel _convertToQBTorrentProperties(
    TransmissionTorrent torrent,
  ) {
    // 转换 trackers
    final trackers = <QBTrackerModel>[];
    if (torrent.trackers != null) {
      for (int i = 0; i < torrent.trackers!.length; i++) {
        final t = torrent.trackers![i];
        if (t.announce != null) {
          trackers.add(
            QBTrackerModel(
              url: t.announce!,
              status: t.lastAnnounceStatus ?? 0,
              tier: i, // 使用索引作为 tier
              msg: t.lastAnnounceResult ?? 'Tracker 正常工作',
              numDownloaded: -1, // Transmission 不提供
              numLeeches: -1, // Transmission 不提供
              numPeers: t.lastAnnouncePeerCount ?? -1,
              numSeeds: -1, // Transmission 不提供
            ),
          );
        }
      }
    }

    // 转换 files
    final files = <QBTorrentFileModel>[];
    if (torrent.files != null && torrent.fileStats != null) {
      for (int i = 0; i < torrent.files!.length; i++) {
        final file = torrent.files![i];
        final fileStat = i < torrent.fileStats!.length
            ? torrent.fileStats![i]
            : null;

        if (file.name != null && file.length != null) {
          final progress = file.bytesCompleted != null && file.length! > 0
              ? (file.bytesCompleted! / file.length!)
              : 0.0;

          files.add(
            QBTorrentFileModel(
              index: i,
              name: file.name!,
              size: file.length!.toInt(),
              progress: progress,
              priority: fileStat?.priority ?? 1,
              isSeed: torrent.status == 5 || torrent.status == 6,
              pieceRange: [],
              availability: 1.0,
            ),
          );
        }
      }
    }

    return QBTorrentPropertiesModel(
      additionDate: torrent.addedDate ?? 0,
      comment: torrent.comment ?? '',
      completionDate: torrent.dateDone ?? 0,
      createdBy: torrent.creator ?? '',
      creationDate: torrent.dateCreated ?? 0,
      dlLimit: torrent.downloadLimit ?? -1,
      dlSpeed: torrent.rateDownload?.toInt() ?? 0,
      dlSpeedAvg: torrent.rateDownload?.toInt() ?? 0,
      downloadPath: torrent.downloadDir ?? '',
      eta: torrent.eta ?? -1,
      hash: torrent.hashString ?? '',
      infohashV1: torrent.hashString ?? '',
      infohashV2: '',
      isPrivate: torrent.isPrivate ?? false,
      lastSeen: torrent.dateActive ?? 0,
      name: torrent.name ?? '',
      nbConnections: torrent.peersConnected ?? 0,
      nbConnectionsLimit: torrent.peerLimit ?? 0,
      peers: torrent.peersGettingFromUs ?? 0,
      peersTotal: torrent.peerCount ?? 0,
      pieceSize: torrent.pieceSize ?? 0,
      piecesHave: torrent.pieces?.length ?? 0,
      piecesNum: torrent.pieceCount ?? 0,
      reannounce: 0,
      savePath: torrent.downloadDir ?? '',
      seedingTime: torrent.secondsSeeding ?? 0,
      seeds: torrent.peersSendingToUs ?? 0,
      seedsTotal:
          (torrent.trackerStats != null && torrent.trackerStats!.isNotEmpty)
          ? (torrent.trackerStats!.first.seederCount ?? 0)
          : 0,
      shareRatio: torrent.uploadRatio ?? 0.0,
      timeElapsed: torrent.secondsActive ?? 0,
      totalDownloaded: torrent.downloadedEver?.toInt() ?? 0,
      totalDownloadedSession: torrent.downloadedWhenStarted?.toInt() ?? 0,
      totalSize: torrent.sizeWhenDone?.toInt() ?? 0,
      totalUploaded: torrent.uploadedEver?.toInt() ?? 0,
      totalUploadedSession: torrent.uploadedWhenStarted?.toInt() ?? 0,
      totalWasted: torrent.corruptEver?.toInt() ?? 0,
      upLimit: torrent.uploadLimit ?? -1,
      upSpeed: torrent.rateUpload?.toInt() ?? 0,
      upSpeedAvg: (torrent.rateUpload?.toDouble() ?? 0.0),
      hasMetadata: true, // Transmission 总是有元数据
      popularity: 0.0, // Transmission 不提供
      private: torrent.isPrivate ?? false,
      progress: torrent.percentDone ?? 0.0,
    );
  }

  // 仅用于服务器状态计算的字段列表（最小化内存占用）
  static const List<String> _statsFields = [
    'rateDownload',
    'rateUpload',
    'downloadedEver',
    'uploadedEver',
  ];

  /// 获取服务器状态（返回通用模型）
  /// 优化：只请求统计字段，避免加载完整种子列表
  Future<ServerStateModel?> getServerState() async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      // 获取会话信息
      final sessionResponse = await _client.rpcRequest(method: 'session-get');
      final data = sessionResponse.data;
      if (data is Map && data['result'] == 'success') {
        final arguments = data['arguments'] as Map<String, dynamic>?;
        if (arguments != null) {
          final session = TransmissionSessionResponse.fromJson(arguments);

          // 只请求统计字段来计算总速度，不创建完整对象
          final statsArguments = {'fields': _statsFields};

          final statsResponse = await _client.rpcRequest(
            method: 'torrent-get',
            arguments: statsArguments,
          );

          final statsData = statsResponse.data;
          int totalDownloadSpeed = 0;
          int totalUploadSpeed = 0;
          int totalDownloaded = 0;
          int totalUploaded = 0;

          if (statsData is Map && statsData['result'] == 'success') {
            final statsArgs = statsData['arguments'] as Map<String, dynamic>?;
            if (statsArgs != null) {
              final torrentResponse = TransmissionTorrentResponse.fromJson(
                statsArgs,
              );
              final torrents = torrentResponse.torrents ?? [];

              // 直接在原始数据上累加，不创建 TorrentModel 对象
              for (final torrent in torrents) {
                totalDownloadSpeed += torrent.rateDownload?.toInt() ?? 0;
                totalUploadSpeed += torrent.rateUpload?.toInt() ?? 0;
                totalDownloaded += torrent.downloadedEver?.toInt() ?? 0;
                totalUploaded += torrent.uploadedEver?.toInt() ?? 0;
              }
            }
          }

          // 转换为通用 ServerStateModel
          return ServerStateModel.fromTransmissionSession(
            downloadDirFreeSpace: session.downloadDirFreeSpace,
            speedLimitDown: session.speedLimitDown,
            speedLimitDownEnabled: session.speedLimitDownEnabled,
            speedLimitUp: session.speedLimitUp,
            speedLimitUpEnabled: session.speedLimitUpEnabled,
            totalDownloadSpeed: totalDownloadSpeed,
            totalUploadSpeed: totalUploadSpeed,
            totalDownloaded: totalDownloaded,
            totalUploaded: totalUploaded,
          );
        }
      }
      return null;
    } catch (e) {
      _log.e('Get server state error: $e');
      return null;
    }
  }

  /// 关闭服务并清理资源
  void dispose() {
    _client.dispose();
    _initialized = false;
  }
}
