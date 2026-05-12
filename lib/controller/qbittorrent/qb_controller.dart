import 'dart:async';
import 'dart:convert';
import 'package:altman_downloader_control/controller/downloader_config.dart';
import 'package:altman_downloader_control/controller/protocol.dart';
import 'package:altman_downloader_control/controller/qbittorrent/qb_service.dart';
import 'package:altman_downloader_control/model/qb_filter_model.dart';
import 'package:altman_downloader_control/model/qb_log_model.dart';
import 'package:altman_downloader_control/model/qb_main_data_model.dart';
import 'package:altman_downloader_control/model/qb_preferences_model.dart';
import 'package:altman_downloader_control/model/qb_rss_item_model.dart';
import 'package:altman_downloader_control/model/qb_sort_type.dart';
import 'package:altman_downloader_control/model/qb_torrent_file_model.dart';
import 'package:altman_downloader_control/model/qb_torrent_model.dart';
import 'package:altman_downloader_control/model/qb_torrent_properties_model.dart';
import 'package:altman_downloader_control/model/qb_tracker_model.dart';
import 'package:altman_downloader_control/model/server_state_model.dart';
import 'package:altman_downloader_control/model/torrent_item_model.dart';
import 'package:altman_downloader_control/utils/log.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// qBittorrent 控制器
/// 管理 qBittorrent 下载器的状态和操作
/// 实现了 DownloaderControllerProtocol 协议
class QBController extends GetxController
    implements DownloaderControllerProtocol {
  final _log = DownloaderLog();
  final _service = QBService();

  final torrents = <QBTorrentModel>[].obs;
  final filteredTorrents = <QBTorrentModel>[].obs; // 筛选后的种子列表
  @override
  final isLoading = false.obs;
  @override
  final isConnected = false.obs;
  @override
  final errorMessage = ''.obs;
  final serverState = Rxn<QBServerState>();
  @override
  final preferences = Rxn<QBPreferencesModel>();
  final version = Rxn<String>(); // qBittorrent 客户端版本

  // 筛选相关
  final filter = QBFilterModel().obs;

  // RSS 相关
  final rssItems = <QBRssItemModel>[].obs;
  final rssFeeds = <String, QBRssFeedModel>{}.obs;
  final isLoadingRss = false.obs;
  final rssErrorMessage = ''.obs;

  // 日志相关
  final logs = <QBLogEntry>[].obs;
  final isLoadingLogs = false.obs;
  final logErrorMessage = ''.obs;
  int? _lastKnownLogId; // 最后已知的日志 ID，用于增量获取

  // 排序相关
  final torrentSortType = QBTorrentSortType.dateAdded.obs; // 默认按添加时间排序
  final rssSortType = QBRssSortType.date.obs;
  final isLocalStateReady = false.obs;

  // 自动刷新相关
  @override
  final autoRefresh = true.obs;
  Timer? _autoRefreshTimer;
  bool _isRefreshing = false; // 防止并发刷新

  // MainData 同步相关
  int? _rid; // Response ID，用于增量同步
  final Map<String, TorrentModel> _torrentUniversalByHash = {};

  @override
  DownloaderConfig? config;

  QBController({required this.config});

  @override
  void onReady() async {
    super.onReady();
    await _restoreLocalUiState();
    initialize();
  }

  Future<void> _restoreLocalUiState() async {
    if (isLocalStateReady.value) return;
    await _loadSavedFilter();
    await _loadSavedSort();
    isLocalStateReady.value = true;
  }

  /// 初始化下载器
  Future<bool> initialize() async {
    final url = config?.url ?? '';
    final username = config?.username ?? '';
    final password = config?.password ?? '';

    if (url.isEmpty) {
      errorMessage.value = 'URL 不能为空';
      return false;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final success = await _service.initialize(
        baseUrl: url,
        username: username,
        password: password,
      );

      if (success) {
        isConnected.value = await _service.checkConnection();
        if (isConnected.value) {
          // 初始化时重置 rid
          _rid = null;
          // 获取版本信息
          await refreshVersion();
          // 获取 preferences
          await refreshPreferences();
          await refreshTorrentsWithMainData();
          // 首次加载 RSS 列表时显示加载状态
          if (rssItems.isEmpty) {
            isLoadingRss.value = true;
          }
          try {
            await refreshRssItems();
          } finally {
            isLoadingRss.value = false;
          }
        } else {
          errorMessage.value = '无法连接到 qBittorrent';
        }
      } else {
        errorMessage.value = '初始化失败';
      }

      return isConnected.value;
    } catch (e) {
      errorMessage.value = '连接错误: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 获取版本信息
  @override
  Future<String?> getVersion() async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return null;
    }

    try {
      final v = await _service.getVersion();
      return v;
    } catch (e) {
      _log.w('获取版本信息失败: $e');
      return null;
    }
  }

  /// 刷新版本信息
  @override
  Future<void> refreshVersion() async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return;
    }

    try {
      final v = await getVersion();
      if (v != null && v.isNotEmpty) {
        version.value = v;
      }
    } catch (e) {
      // 静默失败，不影响其他功能
      _log.w('刷新版本信息失败: $e');
    }
  }

  /// 刷新偏好设置
  @override
  Future<void> refreshPreferences() async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return;
    }

    try {
      final prefsData = await _service.getPreferences();
      _log.d('获取偏好设置 prefsData: $prefsData');
      preferences.value = QBPreferencesModel.fromJson(prefsData);
    } catch (e) {
      _log.e('获取偏好设置失败: $e');
    }
  }

  /// 获取原始偏好设置数据（不解析为模型）
  Future<Map<String, dynamic>> getRawPreferences() async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) {
        throw Exception('未连接到服务器');
      }
    }

    return await _service.getPreferences();
  }

  /// 更新偏好设置
  @override
  Future<bool> updatePreferences(Map<String, dynamic> prefsData) async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) {
        errorMessage.value = '未连接到服务器';
        return false;
      }
    }

    try {
      await _service.setPreferences(prefsData);
      // 更新成功后刷新本地数据
      await refreshPreferences();
      return true;
    } catch (e) {
      errorMessage.value = '更新偏好设置失败: ${e.toString()}';
      return false;
    }
  }

  /// 刷新种子列表（使用增量更新）
  @override
  Future<void> refreshTorrents() async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return;
    }

    // 不设置 isLoading，避免显示刷新动画
    errorMessage.value = '';

    try {
      final newList = await _service.getTorrents();
      _updateTorrentsList(newList);
      // _updateTorrentsList 内部已经调用了 _applySorting 和 _applyFilter
    } catch (e) {
      errorMessage.value = '获取种子列表失败: ${e.toString()}';
      torrents.clear();
      _torrentUniversalByHash.clear();
    }
  }

  /// 使用 maindata 接口刷新种子列表（增量同步，更高效）
  /// 使用 diff 算法只更新变化的数据
  Future<void> refreshTorrentsWithMainData() async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return;
    }

    // 防止并发刷新
    if (_isRefreshing) return;
    _isRefreshing = true;

    // 不设置 isLoading，避免显示刷新动画
    errorMessage.value = '';

    try {
      final mainData = await _service.getMainData(rid: _rid);

      // 更新 rid
      _rid = mainData.rid;

      // 更新服务器状态（合并更新，保留历史数据）
      _updateServerState(mainData.serverState);

      // 如果是完整更新，直接替换列表
      if (mainData.fullUpdate || torrents.isEmpty) {
        torrents.assignAll(mainData.torrentsList);
        // 应用排序和筛选
        _applySorting();
        _applyFilter();
      } else {
        // 使用 diff 算法进行增量更新（内部会调用 _applySorting 和 _applyFilter）
        _applyTorrentsDiff(
          mainData.torrents,
          mainData.torrentsRemoved,
          mainData.torrentDeltas,
        );
      }

      // 请求成功后，根据资源数量安排下一次刷新
      if (autoRefresh.value) {
        _scheduleNextRefresh();
      }
    } catch (e) {
      errorMessage.value = '获取种子列表失败: ${e.toString()}';
      // 如果 maindata 失败，回退到普通方法
      if (torrents.isEmpty) {
        await refreshTorrents();
      }
      // 即使失败也安排下一次刷新
      if (autoRefresh.value) {
        _scheduleNextRefresh();
      }
    } finally {
      _isRefreshing = false;
    }
  }

  /// 根据资源数量计算刷新间隔（秒）
  /// - 1000 以下：1 秒
  /// - 1000-5000：3 秒
  /// - 5000 及以上：5 秒
  int _calculateRefreshInterval() {
    // ⭐ Debug 模式下统一 10 秒
    if (kDebugMode) {
      return 10;
    }

    final count = torrents.length;
    if (count < 1000) {
      return 1;
    } else if (count < 5000) {
      return 3;
    } else {
      return 5;
    }
  }

  /// 安排下一次刷新
  void _scheduleNextRefresh() {
    // 取消之前的定时器
    _autoRefreshTimer?.cancel();

    final interval = _calculateRefreshInterval();
    _autoRefreshTimer = Timer(Duration(seconds: interval), () {
      if (autoRefresh.value && isConnected.value) {
        refreshTorrentsWithMainData();
        refreshRssItems();
      }
    });
  }

  /// 应用增量更新 diff
  /// 高效的 diff 算法：使用 Map 快速查找，只更新变化的项
  /// 注意：maindata 接口返回的是增量数据，需要合并而不是替换
  void _applyTorrentsDiff(
    Map<String, QBTorrentModel> newTorrents,
    List<String> removedHashes,
    Map<String, Map<String, dynamic>> torrentDeltas,
  ) {
    // 如果列表为空，直接赋值并排序
    if (torrents.isEmpty) {
      torrents.assignAll(newTorrents.values.toList());
      _applySorting(); // 确保排序
      _applyFilter(); // 更新筛选后的列表
      torrents.refresh(); // 触发响应式更新
      return;
    }

    // 创建当前列表的 hash 索引，用于快速查找
    final currentMap = <String, QBTorrentModel>{
      for (var torrent in torrents) torrent.hash: torrent,
    };

    // 1. 处理移除的种子
    if (removedHashes.isNotEmpty) {
      // 移除指定的种子
      torrents.removeWhere((t) => removedHashes.contains(t.hash));

      // 从 currentMap 中移除已删除的项
      for (var hash in removedHashes) {
        currentMap.remove(hash);
      }
    }

    // 2. 处理新增和更新的种子
    bool hasChanges = false;

    for (var entry in newTorrents.entries) {
      final hash = entry.key;
      final partialUpdate = entry.value; // 注意：这是增量数据，可能缺少某些字段
      final existingTorrent = currentMap[hash];

      if (existingTorrent == null) {
        // 新增：添加新种子（首次获取的数据应该是完整的）
        torrents.add(partialUpdate);
        currentMap[hash] = partialUpdate;
        hasChanges = true;
      } else {
        // 更新：合并增量数据，保留旧数据中未更新的字段
        final mergedTorrent = _mergeTorrentData(
          existingTorrent,
          partialUpdate,
          torrentDeltas[hash] ?? const {},
        );
        if (_hasTorrentChanged(existingTorrent, mergedTorrent)) {
          final index = torrents.indexWhere((t) => t.hash == hash);
          if (index != -1) {
            torrents[index] = mergedTorrent;
            currentMap[hash] = mergedTorrent;
            hasChanges = true;
          }
        }
      }
    }

    // 3. 只有在有变化时才触发刷新
    if (hasChanges || removedHashes.isNotEmpty) {
      // 应用当前排序
      _applySorting();
      // 更新筛选后的列表（如果正在使用筛选）
      _applyFilter();
      torrents.refresh();
    }
  }

  /// 合并种子数据：将增量更新数据合并到现有数据上
  /// maindata 接口返回的数据通常是完整的，但某些情况下可能只返回变化的字段
  /// 我们采用保守策略：总是使用新数据，但对于可能被清空的字段进行保护
  T _mergeIfDeltaHasKey<T>(
    Map<String, dynamic> delta,
    String jsonKey,
    T partialVal,
    T existingVal,
  ) {
    return delta.containsKey(jsonKey) ? partialVal : existingVal;
  }

  QBTorrentModel _mergeTorrentData(
    QBTorrentModel existing,
    QBTorrentModel partial,
    Map<String, dynamic> rawDelta,
  ) {
    // qBittorrent 的 maindata 增量更新只下发变更字段。
    // 因此合并时必须以 rawDelta 是否带 key 为准，避免 fromJson 的默认值
    // （0、''、[]、-1）把未变化的历史数据覆盖掉。

    return QBTorrentModel(
      hash: partial.hash.isNotEmpty ? partial.hash : existing.hash,
      name: _mergeIfDeltaHasKey(rawDelta, 'name', partial.name, existing.name),
      size: _mergeIfDeltaHasKey(rawDelta, 'size', partial.size, existing.size),
      totalSize: rawDelta.containsKey('total_size') || rawDelta.containsKey('size')
          ? partial.totalSize
          : existing.totalSize,
      progress: _mergeIfDeltaHasKey(
        rawDelta,
        'progress',
        partial.progress,
        existing.progress,
      ),
      dlspeed: _mergeIfDeltaHasKey(
        rawDelta,
        'dlspeed',
        partial.dlspeed,
        existing.dlspeed,
      ),
      upspeed: _mergeIfDeltaHasKey(
        rawDelta,
        'upspeed',
        partial.upspeed,
        existing.upspeed,
      ),
      priority: _mergeIfDeltaHasKey(
        rawDelta,
        'priority',
        partial.priority,
        existing.priority,
      ),
      numSeeds: _mergeIfDeltaHasKey(
        rawDelta,
        'num_seeds',
        partial.numSeeds,
        existing.numSeeds,
      ),
      numLeechers: _mergeIfDeltaHasKey(
        rawDelta,
        'num_leechs',
        partial.numLeechers,
        existing.numLeechers,
      ),
      numComplete: _mergeIfDeltaHasKey(
        rawDelta,
        'num_complete',
        partial.numComplete,
        existing.numComplete,
      ),
      numIncomplete: _mergeIfDeltaHasKey(
        rawDelta,
        'num_incomplete',
        partial.numIncomplete,
        existing.numIncomplete,
      ),
      ratio: _mergeIfDeltaHasKey(rawDelta, 'ratio', partial.ratio, existing.ratio),
      popularity: _mergeIfDeltaHasKey(
        rawDelta,
        'popularity',
        partial.popularity,
        existing.popularity,
      ),
      hasPopularityField:
          rawDelta.containsKey('popularity') || existing.hasPopularityField,
      eta: _mergeIfDeltaHasKey(rawDelta, 'eta', partial.eta, existing.eta),
      state: _mergeIfDeltaHasKey(rawDelta, 'state', partial.state, existing.state),
      category: _mergeIfDeltaHasKey(
        rawDelta,
        'category',
        partial.category,
        existing.category,
      ),
      tags: _mergeIfDeltaHasKey(rawDelta, 'tags', partial.tags, existing.tags),
      addedOn: _mergeIfDeltaHasKey(
        rawDelta,
        'added_on',
        partial.addedOn,
        existing.addedOn,
      ),
      completionOn: _mergeIfDeltaHasKey(
        rawDelta,
        'completion_on',
        partial.completionOn,
        existing.completionOn,
      ),
      lastActivity: _mergeIfDeltaHasKey(
        rawDelta,
        'last_activity',
        partial.lastActivity,
        existing.lastActivity,
      ),
      seenComplete: _mergeIfDeltaHasKey(
        rawDelta,
        'seen_complete',
        partial.seenComplete,
        existing.seenComplete,
      ),
      savePath: _mergeIfDeltaHasKey(
        rawDelta,
        'save_path',
        partial.savePath,
        existing.savePath,
      ),
      contentPath: _mergeIfDeltaHasKey(
        rawDelta,
        'content_path',
        partial.contentPath,
        existing.contentPath,
      ),
      downloadPath: _mergeIfDeltaHasKey(
        rawDelta,
        'download_path',
        partial.downloadPath,
        existing.downloadPath,
      ),
      rootPath: _mergeIfDeltaHasKey(
        rawDelta,
        'root_path',
        partial.rootPath,
        existing.rootPath,
      ),
      downloaded: _mergeIfDeltaHasKey(
        rawDelta,
        'downloaded',
        partial.downloaded,
        existing.downloaded,
      ),
      completed: _mergeIfDeltaHasKey(
        rawDelta,
        'completed',
        partial.completed,
        existing.completed,
      ),
      uploaded: _mergeIfDeltaHasKey(
        rawDelta,
        'uploaded',
        partial.uploaded,
        existing.uploaded,
      ),
      downloadedSession: _mergeIfDeltaHasKey(
        rawDelta,
        'downloaded_session',
        partial.downloadedSession,
        existing.downloadedSession,
      ),
      uploadedSession: _mergeIfDeltaHasKey(
        rawDelta,
        'uploaded_session',
        partial.uploadedSession,
        existing.uploadedSession,
      ),
      amountLeft: _mergeIfDeltaHasKey(
        rawDelta,
        'amount_left',
        partial.amountLeft,
        existing.amountLeft,
      ),
      tracker: _mergeIfDeltaHasKey(
        rawDelta,
        'tracker',
        partial.tracker,
        existing.tracker,
      ),
      comment: _mergeIfDeltaHasKey(
        rawDelta,
        'comment',
        partial.comment,
        existing.comment,
      ),
      magnetUri: _mergeIfDeltaHasKey(
        rawDelta,
        'magnet_uri',
        partial.magnetUri,
        existing.magnetUri,
      ),
      availability: _mergeIfDeltaHasKey(
        rawDelta,
        'availability',
        partial.availability,
        existing.availability,
      ),
      hasAvailabilityField:
          rawDelta.containsKey('availability') || existing.hasAvailabilityField,
      dlLimit: _mergeIfDeltaHasKey(
        rawDelta,
        'dl_limit',
        partial.dlLimit,
        existing.dlLimit,
      ),
      upLimit: _mergeIfDeltaHasKey(
        rawDelta,
        'up_limit',
        partial.upLimit,
        existing.upLimit,
      ),
      timeActive: _mergeIfDeltaHasKey(
        rawDelta,
        'time_active',
        partial.timeActive,
        existing.timeActive,
      ),
      seedingTime: _mergeIfDeltaHasKey(
        rawDelta,
        'seeding_time',
        partial.seedingTime,
        existing.seedingTime,
      ),
    );
  }

  /// 更新服务器状态（合并更新，保留历史数据）
  /// 如果新数据中某些字段缺失或为空，使用历史数据
  void _updateServerState(QBServerState? newState) {
    if (newState == null) {
      // 如果没有新数据，保持现有状态不变
      return;
    }

    final currentState = serverState.value;

    if (currentState == null) {
      // 如果当前没有状态，直接使用新状态
      serverState.value = newState;
      return;
    }

    // 合并状态：使用新值覆盖，如果新值缺失则使用历史值
    serverState.value = _mergeServerState(currentState, newState);
  }

  /// 合并服务器状态：使用新值覆盖，如果新值缺失则使用历史值
  QBServerState _mergeServerState(
    QBServerState existing,
    QBServerState newState,
  ) {
    return QBServerState(
      // 累计数据：总下载/上传量应该只增不减，使用较大的值
      alltimeDl: newState.alltimeDl > existing.alltimeDl
          ? newState.alltimeDl
          : existing.alltimeDl,
      alltimeUl: newState.alltimeUl > existing.alltimeUl
          ? newState.alltimeUl
          : existing.alltimeUl,

      // 动态数据：直接使用新值
      averageTimeQueue: newState.averageTimeQueue,
      connectionStatus: newState.connectionStatus.isNotEmpty
          ? newState.connectionStatus
          : existing.connectionStatus,
      dhtNodes: newState.dhtNodes >= 0 ? newState.dhtNodes : existing.dhtNodes,

      // 下载/上传信息：使用新值（可能为0，这是正常的）
      dlInfoData: newState.dlInfoData,
      dlInfoSpeed: newState.dlInfoSpeed,
      upInfoData: newState.upInfoData,
      upInfoSpeed: newState.upInfoSpeed,

      // 限制设置：使用新值
      dlRateLimit: newState.dlRateLimit,
      upRateLimit: newState.upRateLimit,

      // 磁盘空间：如果新值为0且旧值不为0，可能是数据丢失，保留旧值
      freeSpaceOnDisk:
          (newState.freeSpaceOnDisk > 0 || existing.freeSpaceOnDisk == 0)
          ? newState.freeSpaceOnDisk
          : existing.freeSpaceOnDisk,

      // 全局分享率：使用新值
      globalRatio: newState.globalRatio.isNotEmpty
          ? newState.globalRatio
          : existing.globalRatio,

      // IP 地址：如果新值为空，保留旧值
      lastExternalAddressV4: newState.lastExternalAddressV4.isNotEmpty
          ? newState.lastExternalAddressV4
          : existing.lastExternalAddressV4,
      lastExternalAddressV6: newState.lastExternalAddressV6.isNotEmpty
          ? newState.lastExternalAddressV6
          : existing.lastExternalAddressV6,

      // 队列相关：使用新值
      queuedIoJobs: newState.queuedIoJobs,
      queueing: newState.queueing,

      // 缓存相关：使用新值
      readCacheHits: newState.readCacheHits.isNotEmpty
          ? newState.readCacheHits
          : existing.readCacheHits,
      readCacheOverload: newState.readCacheOverload.isNotEmpty
          ? newState.readCacheOverload
          : existing.readCacheOverload,
      writeCacheOverload: newState.writeCacheOverload.isNotEmpty
          ? newState.writeCacheOverload
          : existing.writeCacheOverload,

      // 其他设置：使用新值
      refreshInterval: newState.refreshInterval > 0
          ? newState.refreshInterval
          : existing.refreshInterval,
      totalBuffersSize: newState.totalBuffersSize,
      totalPeerConnections: newState.totalPeerConnections,
      totalQueuedSize: newState.totalQueuedSize,
      totalWastedSession: newState.totalWastedSession,

      // 功能开关：使用新值
      useAltSpeedLimits: newState.useAltSpeedLimits,
      useSubcategories: newState.useSubcategories,
    );
  }

  /// 检查种子是否有变化（用于优化，只更新真正变化的数据）
  bool _hasTorrentChanged(QBTorrentModel old, QBTorrentModel new_) {
    // 比较关键字段，如果任何一个发生变化就返回 true
    return old.name != new_.name ||
        old.progress != new_.progress ||
        old.state != new_.state ||
        old.dlspeed != new_.dlspeed ||
        old.upspeed != new_.upspeed ||
        old.numSeeds != new_.numSeeds ||
        old.numLeechers != new_.numLeechers ||
        old.numComplete != new_.numComplete ||
        old.numIncomplete != new_.numIncomplete ||
        old.ratio != new_.ratio ||
        old.popularity != new_.popularity ||
        old.eta != new_.eta ||
        old.size != new_.size ||
        old.downloaded != new_.downloaded ||
        old.uploaded != new_.uploaded ||
        old.amountLeft != new_.amountLeft ||
        old.priority != new_.priority ||
        old.category != new_.category ||
        old.availability != new_.availability ||
        old.addedOn != new_.addedOn ||
        old.tags.join(', ') != new_.tags.join(', ');
  }

  /// 增量更新种子列表（只更新变化的数据）
  void _updateTorrentsList(List<QBTorrentModel> newList) {
    if (torrents.isEmpty) {
      // 首次加载，直接赋值后应用排序
      torrents.assignAll(newList);
      _applySorting();
      _applyFilter(); // 更新筛选后的列表
      torrents.refresh(); // 触发响应式更新
      return;
    }

    // 创建旧数据的 hash 映射
    final oldMap = <String, QBTorrentModel>{
      for (var torrent in torrents) torrent.hash: torrent,
    };

    // 创建新数据的 hash 映射
    final newMap = <String, QBTorrentModel>{
      for (var torrent in newList) torrent.hash: torrent,
    };

    // 找出需要添加的（新数据中有，旧数据中没有）
    final toAdd = <QBTorrentModel>[];
    for (var torrent in newList) {
      if (!oldMap.containsKey(torrent.hash)) {
        toAdd.add(torrent);
      }
    }

    // 找出需要删除的（旧数据中有，新数据中没有）
    final toRemove = <String>[];
    for (var hash in oldMap.keys) {
      if (!newMap.containsKey(hash)) {
        toRemove.add(hash);
      }
    }

    // 找出需要更新的（hash 相同但内容不同）
    final toUpdate = <QBTorrentModel>[];
    for (var newTorrent in newList) {
      final oldTorrent = oldMap[newTorrent.hash];
      if (oldTorrent != null && !_isTorrentEqual(oldTorrent, newTorrent)) {
        toUpdate.add(newTorrent);
      }
    }

    // 执行更新
    if (toAdd.isNotEmpty || toRemove.isNotEmpty || toUpdate.isNotEmpty) {
      // 先删除
      torrents.removeWhere((t) => toRemove.contains(t.hash));

      // 更新现有项
      for (var updated in toUpdate) {
        final index = torrents.indexWhere((t) => t.hash == updated.hash);
        if (index != -1) {
          torrents[index] = updated;
        }
      }

      // 添加新项
      torrents.addAll(toAdd);

      // 应用排序
      _applySorting();
      // 更新筛选后的列表
      _applyFilter();

      // 触发更新
      torrents.refresh();
    }
  }

  /// 比较两个种子是否相等
  bool _isTorrentEqual(QBTorrentModel a, QBTorrentModel b) {
    return a.hash == b.hash &&
        a.name == b.name &&
        a.progress == b.progress &&
        a.state == b.state &&
        a.dlspeed == b.dlspeed &&
        a.upspeed == b.upspeed &&
        a.numSeeds == b.numSeeds &&
        a.numLeechers == b.numLeechers &&
        a.numComplete == b.numComplete &&
        a.numIncomplete == b.numIncomplete;
  }

  /// 检查连接
  @override
  Future<bool> checkConnection() async {
    isLoading.value = true;
    try {
      isConnected.value = await _service.checkConnection();
      if (!isConnected.value && config != null) {
        // 重新初始化
        await initialize();
      }
      return isConnected.value;
    } catch (e) {
      isConnected.value = false;
      errorMessage.value = '连接检查失败: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 暂停种子
  @override
  Future<void> pauseTorrent(String hash) async {
    try {
      await _service.pauseTorrents([hash]);
      await refreshTorrentsWithMainData();
    } catch (e) {
      errorMessage.value = '暂停失败: ${e.toString()}';
    }
  }

  /// 恢复种子
  @override
  Future<void> resumeTorrent(String hash) async {
    try {
      await _service.resumeTorrents([hash]);
      await refreshTorrentsWithMainData();
    } catch (e) {
      errorMessage.value = '恢复失败: ${e.toString()}';
    }
  }

  /// 删除种子
  @override
  Future<void> deleteTorrent(String hash, {bool deleteFiles = false}) async {
    try {
      await _service.deleteTorrents([hash], deleteFiles: deleteFiles);
      await refreshTorrentsWithMainData();
    } catch (e) {
      errorMessage.value = '删除失败: ${e.toString()}';
    }
  }

  /// 暂停多个种子
  @override
  Future<void> pauseTorrents(List<String> hashes) async {
    try {
      await _service.pauseTorrents(hashes);
      await refreshTorrentsWithMainData();
    } catch (e) {
      errorMessage.value = '暂停失败: ${e.toString()}';
    }
  }

  /// 恢复多个种子
  @override
  Future<void> resumeTorrents(List<String> hashes) async {
    try {
      await _service.resumeTorrents(hashes);
      await refreshTorrentsWithMainData();
    } catch (e) {
      errorMessage.value = '恢复失败: ${e.toString()}';
    }
  }

  /// 强制启动种子
  @override
  Future<bool> forceStartTorrents(List<String> hashes, bool value) async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return false;
    }

    try {
      await _service.setForceStart(hashes, value);
      await refreshTorrentsWithMainData();
      return true;
    } catch (e) {
      errorMessage.value = '设置强制启动失败: ${e.toString()}';
      return false;
    }
  }

  /// 设置保存位置
  @override
  Future<bool> setTorrentLocation(List<String> hashes, String location) async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return false;
    }

    try {
      await _service.setLocation(hashes, location);
      await refreshTorrentsWithMainData();
      return true;
    } catch (e) {
      errorMessage.value = '设置保存位置失败: ${e.toString()}';
      return false;
    }
  }

  /// 重命名种子
  @override
  Future<bool> renameTorrent(String hash, String newName) async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return false;
    }

    try {
      await _service.renameTorrent(hash, newName);
      await refreshTorrentsWithMainData();
      return true;
    } catch (e) {
      errorMessage.value = '重命名失败: ${e.toString()}';
      return false;
    }
  }

  /// 强制重新校验种子
  @override
  Future<bool> recheckTorrents(List<String> hashes) async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return false;
    }

    try {
      await _service.recheckTorrents(hashes);
      await refreshTorrentsWithMainData();
      return true;
    } catch (e) {
      errorMessage.value = '重新校验失败: ${e.toString()}';
      return false;
    }
  }

  /// 获取分类列表
  Future<Map<String, dynamic>> getCategories() async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return {};
    }

    try {
      return await _service.getCategories();
    } catch (e) {
      errorMessage.value = '获取分类列表失败: ${e.toString()}';
      return {};
    }
  }

  /// 创建分类
  Future<bool> createCategory({
    required String category,
    String? savePath,
  }) async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return false;
    }

    try {
      await _service.createCategory(category: category, savePath: savePath);
      return true;
    } catch (e) {
      errorMessage.value = '创建分类失败: ${e.toString()}';
      return false;
    }
  }

  /// 设置分类
  @override
  Future<bool> setTorrentCategory(List<String> hashes, String category) async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return false;
    }

    try {
      await _service.setCategory(hashes, category);
      await refreshTorrentsWithMainData();
      return true;
    } catch (e) {
      errorMessage.value = '设置分类失败: ${e.toString()}';
      return false;
    }
  }

  /// 获取所有标签列表
  Future<List<String>> getAllTags() async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return [];
    }

    try {
      return await _service.getAllTags();
    } catch (e) {
      errorMessage.value = '获取标签列表失败: ${e.toString()}';
      return [];
    }
  }

  /// 添加标签（增量添加）
  Future<bool> addTorrentTags(List<String> hashes, List<String> tags) async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return false;
    }

    try {
      await _service.addTags(hashes, tags);
      await refreshTorrentsWithMainData();
      return true;
    } catch (e) {
      errorMessage.value = '添加标签失败: ${e.toString()}';
      return false;
    }
  }

  /// 移除标签（增量移除）
  Future<bool> removeTorrentTags(List<String> hashes, List<String> tags) async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return false;
    }

    try {
      await _service.removeTags(hashes, tags);
      await refreshTorrentsWithMainData();
      return true;
    } catch (e) {
      errorMessage.value = '移除标签失败: ${e.toString()}';
      return false;
    }
  }

  /// 设置标签（先移除所有，再添加新标签）
  @override
  Future<bool> setTorrentTags(List<String> hashes, List<String> tags) async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return false;
    }

    try {
      await _service.setTags(hashes, tags);
      await refreshTorrentsWithMainData();
      return true;
    } catch (e) {
      errorMessage.value = '设置标签失败: ${e.toString()}';
      return false;
    }
  }

  /// 设置下载速度限制
  /// limit 为 -1 表示无限制，单位为字节/秒
  @override
  Future<bool> setTorrentDownloadLimit(List<String> hashes, int limit) async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return false;
    }

    try {
      await _service.setDownloadLimit(hashes, limit);
      await refreshTorrentsWithMainData();
      return true;
    } catch (e) {
      errorMessage.value = '设置下载速度限制失败: ${e.toString()}';
      return false;
    }
  }

  /// 设置上传速度限制
  /// limit 为 -1 表示无限制，单位为字节/秒
  @override
  Future<bool> setTorrentUploadLimit(List<String> hashes, int limit) async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return false;
    }

    try {
      await _service.setUploadLimit(hashes, limit);
      await refreshTorrentsWithMainData();
      return true;
    } catch (e) {
      errorMessage.value = '设置上传速度限制失败: ${e.toString()}';
      return false;
    }
  }

  /// 获取下载中的种子
  List<QBTorrentModel> get downloadingTorrents {
    return torrents.where((t) => t.isDownloading).toList();
  }

  /// 获取做种中的种子
  List<QBTorrentModel> get seedingTorrents {
    return torrents.where((t) => t.isSeeding).toList();
  }

  /// 获取已暂停的种子
  List<QBTorrentModel> get pausedTorrents {
    return torrents.where((t) => t.isPaused).toList();
  }

  /// 刷新 RSS 列表（使用增量更新，不显示刷新动画）
  Future<void> refreshRssItems({bool withData = true}) async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return;
    }

    // 不设置 isLoadingRss，避免显示刷新动画
    rssErrorMessage.value = '';

    try {
      final response = await _service.getRssItems(withData: withData);

      // 更新 Feeds
      rssFeeds.assignAll(response.feeds);

      // 更新扁平化的 Items 列表
      final allItems = response.getAllItems();
      _updateRssItemsList(allItems);
    } catch (e) {
      rssErrorMessage.value = '获取 RSS 列表失败: ${e.toString()}';
      rssItems.clear();
      rssFeeds.clear();
    }
  }

  /// 增量更新 RSS Items 列表
  void _updateRssItemsList(List<QBRssItemModel> newList) {
    if (rssItems.isEmpty) {
      rssItems.assignAll(newList);
      return;
    }

    // 创建旧数据的映射（使用 id 或 articleId 或 link 作为唯一标识）
    final oldMap = <String, QBRssItemModel>{};
    for (var item in rssItems) {
      final key = item.id ?? item.articleId ?? item.link ?? '';
      if (key.isNotEmpty) {
        oldMap[key] = item;
      }
    }

    // 创建新数据的映射
    final newMap = <String, QBRssItemModel>{};
    for (var item in newList) {
      final key = item.id ?? item.articleId ?? item.link ?? '';
      if (key.isNotEmpty) {
        newMap[key] = item;
      }
    }

    // 找出需要添加的
    final toAdd = <QBRssItemModel>[];
    for (var item in newList) {
      final key = item.id ?? item.articleId ?? item.link ?? '';
      if (key.isNotEmpty && !oldMap.containsKey(key)) {
        toAdd.add(item);
      }
    }

    // 找出需要删除的
    final toRemove = <String>[];
    for (var key in oldMap.keys) {
      if (!newMap.containsKey(key)) {
        toRemove.add(key);
      }
    }

    // 找出需要更新的
    final toUpdate = <QBRssItemModel>[];
    for (var newItem in newList) {
      final key = newItem.id ?? newItem.articleId ?? newItem.link ?? '';
      if (key.isNotEmpty) {
        final oldItem = oldMap[key];
        if (oldItem != null && !_isRssItemEqual(oldItem, newItem)) {
          toUpdate.add(newItem);
        }
      }
    }

    // 执行更新
    if (toAdd.isNotEmpty || toRemove.isNotEmpty || toUpdate.isNotEmpty) {
      // 先删除
      rssItems.removeWhere((item) {
        final key = item.id ?? item.articleId ?? item.link ?? '';
        return key.isNotEmpty && toRemove.contains(key);
      });

      // 更新现有项
      for (var updated in toUpdate) {
        final key = updated.id ?? updated.articleId ?? updated.link ?? '';
        if (key.isNotEmpty) {
          final index = rssItems.indexWhere((item) {
            final itemKey = item.id ?? item.articleId ?? item.link ?? '';
            return itemKey == key;
          });
          if (index != -1) {
            rssItems[index] = updated;
          }
        }
      }

      // 添加新项
      rssItems.addAll(toAdd);

      // 按日期排序（最新的在前）
      rssItems.sort((a, b) {
        if (a.date == null && b.date == null) return 0;
        if (a.date == null) return 1;
        if (b.date == null) return -1;
        return b.date!.compareTo(a.date!);
      });

      // 触发更新
      rssItems.refresh();
    }
  }

  /// 比较两个 RSS Item 是否相等
  bool _isRssItemEqual(QBRssItemModel a, QBRssItemModel b) {
    final aId = a.id ?? a.articleId;
    final bId = b.id ?? b.articleId;
    return aId == bId &&
        a.title == b.title &&
        a.isRead == b.isRead &&
        a.date == b.date;
  }

  /// 添加 RSS Feed
  Future<void> addRssFeed({required String url, String? path}) async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return;
    }

    try {
      await _service.addRssFeed(url: url, path: path);
      await refreshRssItems();
    } catch (e) {
      rssErrorMessage.value = '添加 RSS Feed 失败: ${e.toString()}';
    }
  }

  /// 删除 RSS Feed
  Future<void> removeRssFeed(String path) async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return;
    }

    try {
      await _service.removeRssFeed(path);
      await refreshRssItems();
    } catch (e) {
      rssErrorMessage.value = '删除 RSS Feed 失败: ${e.toString()}';
    }
  }

  /// 标记 RSS Item 为已读
  /// [itemPath] RSS Feed 路径（如 "大青虫 Torrents"）
  Future<void> markRssAsRead({required String itemPath}) async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return;
    }

    try {
      await _service.markRssAsRead(itemPath: itemPath);
      // 标记该 Feed 下的所有 items 为已读（更新本地状态）
      rssFeeds.refresh();
      // 刷新 RSS 列表以获取最新的已读状态
      await refreshRssItems();
    } catch (e) {
      rssErrorMessage.value = '标记已读失败: ${e.toString()}';
    }
  }

  /// 刷新 RSS Feed
  Future<void> refreshRssFeed(String itemPath) async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return;
    }

    try {
      await _service.refreshRssFeed(itemPath);
      await refreshRssItems();
    } catch (e) {
      rssErrorMessage.value = '刷新 RSS Feed 失败: ${e.toString()}';
    }
  }

  /// 重命名 RSS Feed
  /// [itemPath] 原始路径
  /// [destPath] 新路径（新名称）
  Future<bool> renameRssFeed({
    required String itemPath,
    required String destPath,
  }) async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return false;
    }

    try {
      await _service.moveRssItem(itemPath: itemPath, destPath: destPath);
      await refreshRssItems();
      return true;
    } catch (e) {
      rssErrorMessage.value = '重命名 RSS Feed 失败: ${e.toString()}';
      return false;
    }
  }

  /// 对种子列表进行排序
  void sortTorrents(QBTorrentSortType sortType) {
    torrentSortType.value = sortType;
    _applySorting();
    _applyFilter();
    unawaited(saveSortPreference(sortType.name));
  }

  Future<void> _loadSavedSort() async {
    try {
      final saved = await loadSortPreference();
      if (saved == null || saved.isEmpty) return;
      final matched = QBTorrentSortType.sortTypes.firstWhereOrNull(
        (e) => e.name == saved,
      );
      if (matched != null) {
        torrentSortType.value = matched;
      }
    } catch (e) {
      _log.w('加载排序条件失败: $e');
    }
  }

  /// 应用筛选条件
  void _applyFilter() {
    if (torrents.isEmpty) {
      filteredTorrents.clear();
      filteredTorrents.refresh();
      return;
    }

    final currentFilter = filter.value;

    // 预处理：如果有关键字，先转换为小写（避免在循环中重复转换）
    final keyword = currentFilter.searchKeyword.isNotEmpty
        ? currentFilter.searchKeyword.toLowerCase()
        : null;

    final results = torrents.where((torrent) {
      // 搜索关键词筛选（优化：提前返回，避免不必要的处理）
      if (keyword != null) {
        // 使用小写比较，避免每次调用 toLowerCase()
        final torrentNameLower = torrent.name.toLowerCase();
        if (!torrentNameLower.contains(keyword)) {
          return false;
        }
      }

      // 状态筛选（参考 Swift TorrentStateUtil 逻辑）
      if (currentFilter.selectedStatuses.isNotEmpty) {
        bool matchesStatus = false;

        for (var status in currentFilter.selectedStatuses) {
          switch (status.toLowerCase()) {
            case 'all':
              matchesStatus = true;
              break;
            case 'downloading':
              // 下载状态：downloading, checkingDL, stalledDL, forcedDL, queuedDL, metaDL, forcedMetaDL, pausedDL
              matchesStatus = torrent.isDownloading;
              break;
            case 'seeding':
              // 做种状态：uploading, checkingUP, stalledUP, forcedUP, queuedUP
              matchesStatus = torrent.isSeeding;
              break;
            case 'completed':
              // 已完成状态：seedingStates + pausedUP
              matchesStatus = torrent.isCompleted;
              break;
            case 'resumed':
              // 恢复状态：各种运行中的状态（不包括 paused）
              matchesStatus = torrent.isResumed;
              break;
            case 'running':
              // 运行中：下载或做种状态
              matchesStatus = torrent.isDownloading || torrent.isSeeding;
              break;
            case 'stopped':
              matchesStatus = torrent.isStopped;
              break;
            case 'active':
              // 活跃：有下载或上传速度
              matchesStatus = torrent.isActive;
              break;
            case 'inactive':
              // 非活跃：没有下载和上传速度
              matchesStatus = torrent.isInactive;
              break;
            case 'stalled':
              // 停滞状态：stalledDL, stalledUP
              matchesStatus = torrent.isStalled;
              break;
            case 'stalled_uploading':
            case 'stalled uploading':
              matchesStatus = torrent.isStalled && torrent.isSeeding;
              break;
            case 'stalled_download':
            case 'stalled download':
              matchesStatus = torrent.isStalled && torrent.isDownloading;
              break;
            case 'checking':
              // 检查状态：checkingDL, checkingUP, checkingResumeData
              matchesStatus = torrent.isChecking;
              break;
            case 'moving':
              matchesStatus = torrent.isMoving;
              break;
            case 'errored':
            case 'error':
            case 'missingfiles':
            case 'missing_files':
              // 错误状态：error, missingFiles
              matchesStatus = torrent.hasError;
              break;
            case 'paused':
              // 暂停状态：pausedDL, pausedUP
              matchesStatus = torrent.isPaused;
              break;
          }

          if (matchesStatus) break;
        }

        if (!matchesStatus) return false;
      }

      // 分类筛选
      if (currentFilter.selectedCategories.isNotEmpty) {
        if (!currentFilter.selectedCategories.contains(torrent.category)) {
          return false;
        }
      }

      // 标签筛选（种子必须包含所有选中的标签）
      if (currentFilter.selectedTags.isNotEmpty) {
        final torrentTags = torrent.tags.toSet();
        final selectedTagsSet = currentFilter.selectedTags.toSet();
        if (!selectedTagsSet.every((tag) => torrentTags.contains(tag))) {
          return false;
        }
      }

      // 跟踪器筛选（基于主域名）
      if (currentFilter.selectedTrackers.isNotEmpty) {
        if (torrent.tracker.isEmpty) return false;
        // 提取 tracker 的主域名
        String extractMainDomain(String tracker) {
          try {
            String url = tracker.trim();
            if (url.startsWith('http://') || url.startsWith('https://')) {
              url = url.substring(url.indexOf('://') + 3);
            }
            final pathIndex = url.indexOf('/');
            if (pathIndex != -1) {
              url = url.substring(0, pathIndex);
            }
            final portIndex = url.indexOf(':');
            if (portIndex != -1) {
              url = url.substring(0, portIndex);
            }
            final parts = url.split('.');
            if (parts.length >= 2) {
              return '${parts[parts.length - 2]}.${parts[parts.length - 1]}';
            } else if (parts.length == 1) {
              return parts[0];
            }
            return url;
          } catch (e) {
            return tracker;
          }
        }

        final torrentMainDomain = extractMainDomain(
          torrent.tracker,
        ).toLowerCase();
        bool matchesTracker = false;
        for (var tracker in currentFilter.selectedTrackers) {
          if (torrentMainDomain == tracker.toLowerCase()) {
            matchesTracker = true;
            break;
          }
        }
        if (!matchesTracker) return false;
      }

      return true;
    }).toList();

    filteredTorrents.assignAll(results);
    filteredTorrents.refresh();
  }

  /// 获取筛选条件的存储 key
  String get _filterStorageKey => 'qb_filter_${config?.id ?? 'default'}';

  /// 加载保存的筛选条件
  Future<void> _loadSavedFilter() async {
    try {
      final savedFilterJson = await loadFilterPreference();
      if (savedFilterJson != null) {
        final filterData = jsonDecode(savedFilterJson) as Map<String, dynamic>;
        final savedFilter = QBFilterModel.fromJson(filterData);
        filter.value = savedFilter;
        _applyFilter();
      }
    } catch (e) {
      _log.w('加载保存的筛选条件失败: $e');
    }
  }

  /// 保存筛选条件到本地
  Future<void> _saveFilter() async {
    try {
      final filterJson = jsonEncode(filter.value.toJson());
      await saveFilterPreference(filterJson);
      _log.d('筛选条件已保存: $_filterStorageKey');
    } catch (e) {
      _log.w('保存筛选条件失败: $e');
    }
  }

  /// 设置筛选条件
  void setFilter(QBFilterModel newFilter) {
    filter.value = newFilter;
    filter.refresh(); // 确保触发响应式更新
    _applyFilter();
    unawaited(_saveFilter());
  }

  /// 清除筛选
  void clearFilter() {
    filter.value = QBFilterModel();
    _applyFilter();
    unawaited(_saveFilter());
  }

  /// 应用当前排序类型到种子列表
  void _applySorting() {
    if (torrents.isEmpty) {
      filteredTorrents.clear();
      filteredTorrents.refresh();
      return;
    }
    torrents.sort((a, b) {
      switch (torrentSortType.value) {
        case QBTorrentSortType.name:
          return a.name.compareTo(b.name);
        case QBTorrentSortType.size:
          return b.size.compareTo(a.size);
        case QBTorrentSortType.progress:
          return b.progress.compareTo(a.progress);
        case QBTorrentSortType.status:
          return a.state.compareTo(b.state);
        case QBTorrentSortType.dateAdded:
          // 处理 addedOn 为 null、0 或无效值的情况，将它们排在最后
          // 使用安全的方式获取值，防止运行时 null 错误
          int aAddedOn = 0;
          int bAddedOn = 0;

          try {
            final aVal = a.addedOn as dynamic;
            final bVal = b.addedOn as dynamic;

            if (aVal is int) {
              aAddedOn = aVal;
            } else if (aVal != null) {
              aAddedOn = (aVal as num?)?.toInt() ?? 0;
            }

            if (bVal is int) {
              bAddedOn = bVal;
            } else if (bVal != null) {
              bAddedOn = (bVal as num?)?.toInt() ?? 0;
            }
          } catch (e) {
            // 如果出现异常，使用默认值 0
            aAddedOn = 0;
            bAddedOn = 0;
          }

          if (aAddedOn <= 0 && bAddedOn <= 0) {
            // 两个都无效，保持原序
            return 0;
          }
          if (aAddedOn <= 0) {
            return 1; // a 无效，排在后面
          }
          if (bAddedOn <= 0) {
            return -1; // b 无效，排在后面
          }
          // 降序：最新的在前
          final dateCompare = bAddedOn.compareTo(aAddedOn);
          return dateCompare;
        case QBTorrentSortType.speed:
          final aSpeed = a.dlspeed + a.upspeed;
          final bSpeed = b.dlspeed + b.upspeed;
          return bSpeed.compareTo(aSpeed);
        case QBTorrentSortType.seeds:
          return b.numSeeds.compareTo(a.numSeeds);
        case QBTorrentSortType.ratio:
          return b.ratio.compareTo(a.ratio);
      }
    });
  }

  /// 对 RSS 列表进行排序
  void sortRss(QBRssSortType sortType) {
    rssSortType.value = sortType;
    rssItems.sort((a, b) {
      switch (sortType) {
        case QBRssSortType.date:
          if (a.date == null && b.date == null) return 0;
          if (a.date == null) return 1;
          if (b.date == null) return -1;
          return b.date!.compareTo(a.date!);
        case QBRssSortType.title:
          final aTitle = a.title ?? '';
          final bTitle = b.title ?? '';
          return aTitle.compareTo(bTitle);
        case QBRssSortType.feed:
          // 可以根据 feed 来源排序，这里简化处理
          return 0;
      }
    });
    rssItems.refresh();
  }

  /// 启动自动刷新
  /// 现在使用动态刷新间隔，基于资源数量
  @override
  void startAutoRefresh() {
    stopAutoRefresh();
    if (autoRefresh.value) {
      // 立即执行一次刷新，然后由 refreshTorrentsWithMainData 安排下一次
      if (isConnected.value) {
        refreshTorrentsWithMainData();
        refreshRssItems();
      }
    }
  }

  /// 停止自动刷新
  @override
  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  /// 获取种子属性详情
  Future<QBTorrentPropertiesModel?> getTorrentProperties(String hash) async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return null;
    }

    try {
      return await _service.getTorrentProperties(hash);
    } catch (e) {
      errorMessage.value = '获取种子详情失败: ${e.toString()}';
      return null;
    }
  }

  /// 获取种子 Tracker 列表
  Future<List<QBTrackerModel>> getTorrentTrackers(String hash) async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return [];
    }

    try {
      return await _service.getTorrentTrackers(hash);
    } catch (e) {
      errorMessage.value = '获取 Tracker 列表失败: ${e.toString()}';
      return [];
    }
  }

  /// 添加 Tracker
  Future<bool> addTrackers(String hash, List<String> urls) async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return false;
    }

    try {
      await _service.addTrackers(hash, urls);
      return true;
    } catch (e) {
      errorMessage.value = '添加 Tracker 失败: ${e.toString()}';
      return false;
    }
  }

  /// 编辑 Tracker
  Future<bool> editTracker(String hash, String oldUrl, String newUrl) async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return false;
    }

    try {
      await _service.editTracker(hash, oldUrl, newUrl);
      return true;
    } catch (e) {
      errorMessage.value = '编辑 Tracker 失败: ${e.toString()}';
      return false;
    }
  }

  /// 移除 Tracker
  Future<bool> removeTrackers(String hash, List<String> urls) async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return false;
    }

    try {
      await _service.removeTrackers(hash, urls);
      return true;
    } catch (e) {
      errorMessage.value = '移除 Tracker 失败: ${e.toString()}';
      return false;
    }
  }

  /// 获取种子文件列表
  Future<List<QBTorrentFileModel>> getTorrentFiles(String hash) async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return [];
    }

    try {
      return await _service.getTorrentFiles(hash);
    } catch (e) {
      errorMessage.value = '获取文件列表失败: ${e.toString()}';
      return [];
    }
  }

  /// 添加种子（协议方法）
  @override
  Future<bool> addTorrent({
    required String torrent,
    String? savePath,
    String? category,
    List<String>? tags,
    bool paused = false,
    bool skipChecking = false,
  }) async {
    // 调用详细版本的 addTorrent 方法
    return await addTorrentDetailed(
      urls: torrent,
      savePath: savePath ?? '',
      category: category,
      paused: paused,
      skipChecking: skipChecking,
      tags: tags,
    );
  }

  /// 添加种子（详细版本，保留原有方法）
  Future<bool> addTorrentDetailed({
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
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return false;
    }

    try {
      await _service.addTorrent(
        urls: urls,
        torrentFilePaths: torrentFilePaths,
        savePath: savePath,
        autoTMM: autoTMM,
        cookie: cookie,
        rename: rename,
        category: category,
        tags: tags,
        paused: paused,
        stopCondition: stopCondition,
        skipChecking: skipChecking,
        contentLayout: contentLayout,
        dlLimit: dlLimit,
        upLimit: upLimit,
      );

      // 等待一小段时间，让服务器处理完添加请求
      await Future.delayed(const Duration(milliseconds: 500));

      // 如果提供了 tags，设置标签
      if (tags != null && tags.isNotEmpty && urls != null) {
        // 需要先刷新种子列表以获取新添加种子的 hash
        _rid = null;
        await refreshTorrentsWithMainData();

        // 尝试从 URL 中提取 hash（如果可能），或者从最新添加的种子中获取
        // 这里简化处理：如果只有一个 URL，可以尝试设置标签
        // 注意：qBittorrent 的 addTorrent 不会返回 hash，所以这里需要特殊处理
        // 实际使用时可能需要根据具体情况调整
      }

      // 重置 rid 以强制完整更新，确保新添加的种子能被获取到
      _rid = null;

      // 刷新种子列表（会进行完整更新）
      await refreshTorrentsWithMainData();
      return true;
    } catch (e) {
      errorMessage.value = '添加种子失败: ${e.toString()}';
      return false;
    }
  }

  @override
  void onClose() {
    stopAutoRefresh();
    _service.dispose();
    super.onClose();
  }

  @override
  ServerStateModel? get serverStateUniversal =>
      serverState.value?.toServerStateModel();

  @override
  List<TorrentModel> get torrentsUniversal {
    final out = <TorrentModel>[];
    final next = <String, TorrentModel>{};
    for (final t in torrents) {
      final prev = _torrentUniversalByHash[t.hash];
      final m = t.toTorrentModel(previous: prev);
      out.add(m);
      next[t.hash] = m;
    }
    _torrentUniversalByHash
      ..clear()
      ..addAll(next);
    return out;
  }

  /// 获取日志
  /// [normal] 是否包含普通日志
  /// [info] 是否包含信息日志
  /// [warning] 是否包含警告日志
  /// [critical] 是否包含严重日志
  /// [incremental] 是否使用增量获取（基于 lastKnownId）
  Future<void> refreshLogs({
    bool normal = true,
    bool info = true,
    bool warning = true,
    bool critical = true,
    bool incremental = false,
  }) async {
    if (!isConnected.value) {
      logErrorMessage.value = '未连接到服务器';
      return;
    }

    isLoadingLogs.value = true;
    logErrorMessage.value = '';

    try {
      final response = await _service.getLogs(
        normal: normal,
        info: info,
        warning: warning,
        critical: critical,
        lastKnownId: incremental ? _lastKnownLogId : null,
      );

      if (incremental && _lastKnownLogId != null) {
        // 增量获取：只添加新的日志
        final newLogs = response.logs
            .where((log) => log.id > _lastKnownLogId!)
            .toList();
        logs.addAll(newLogs);
      } else {
        // 完整获取：替换所有日志
        logs.assignAll(response.logs);
      }

      // 更新最后已知的日志 ID
      if (response.id > 0) {
        _lastKnownLogId = response.id;
      }

      // 按 ID 降序排序（最新的在前）
      logs.sort((a, b) => b.id.compareTo(a.id));
    } catch (e) {
      logErrorMessage.value = '获取日志失败: ${e.toString()}';
      _log.e('Refresh logs error: $e');
    } finally {
      isLoadingLogs.value = false;
    }
  }

  /// 清空日志列表
  void clearLogs() {
    logs.clear();
    _lastKnownLogId = null;
  }
}
