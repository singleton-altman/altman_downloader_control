import 'dart:async';
import 'package:altman_downloader_control/controller/downloader_config.dart';
import 'package:altman_downloader_control/controller/protocol.dart';
import 'package:altman_downloader_control/controller/transmission/transmission_service.dart';
import 'package:altman_downloader_control/model/qb_preferences_model.dart';
import 'package:altman_downloader_control/model/server_state_model.dart';
import 'package:altman_downloader_control/model/torrent_item_model.dart';
import 'package:altman_downloader_control/model/transmission_list_sort_type.dart';
import 'package:altman_downloader_control/utils/log.dart';
import 'package:get/get.dart';

/// Transmission 控制器
/// 管理 Transmission 下载器的状态和操作
/// 实现了 DownloaderControllerProtocol 协议
class TransmissionController extends GetxController
    implements DownloaderControllerProtocol {
  final _service = TransmissionService();
  final DownloaderLog _log = DownloaderLog();

  @override
  DownloaderConfig? config;

  @override
  final isLoading = false.obs;

  @override
  final isConnected = false.obs;

  @override
  final errorMessage = ''.obs;

  @override
  final autoRefresh = false.obs;

  final listSearchKeyword = ''.obs;
  final listSortType = TransmissionTorrentSortType.dateAdded.obs;

  // 种子列表（使用通用模型）
  final torrents = <TorrentModel>[].obs;
  final version = Rxn<String>(); // Transmission 客户端版本
  final serverState = Rxn<ServerStateModel>(); // 服务器状态（使用通用模型）

  // 用于增量更新的内部 Map（以 hash 为 key，减少查找时间）
  final _torrentsMap = <String, TorrentModel>{};

  // 通用模型 getter（实现协议）
  @override
  List<TorrentModel> get torrentsUniversal => torrents.toList();

  @override
  ServerStateModel? get serverStateUniversal => serverState.value;

  Timer? _autoRefreshTimer;
  Worker? _connectionWorker;

  // 防抖机制：避免并发刷新导致内存问题
  bool _isRefreshing = false;
  Future<void>? _pendingRefresh;

  // Buffer 机制：分批处理数据，减少内存峰值
  static const int _bufferBatchSize = 1000; // 每批处理 1000 条数据
  static const int _bufferMaxSize = 5000; // Buffer 最大容量，超过后强制处理

  TransmissionController({required this.config});

  @override
  void onInit() {
    super.onInit();
    // 监听连接状态变化，当连接成功时自动启动刷新
    _connectionWorker = ever(isConnected, (bool connected) {
      if (connected && autoRefresh.value) {
        // 连接成功且自动刷新已启用，启动刷新
        startAutoRefresh();
      } else if (!connected) {
        // 连接断开，停止刷新
        stopAutoRefresh();
      }
    });
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
          await refreshVersion();
          await refreshTorrents();

          // 连接成功后，如果自动刷新已启用，启动刷新
          if (autoRefresh.value) {
            startAutoRefresh();
          }
        } else {
          errorMessage.value = '无法连接到 Transmission';
        }
      } else {
        errorMessage.value = '初始化失败';
      }

      return isConnected.value;
    } catch (e) {
      errorMessage.value = '连接错误: ${e.toString()}';
      _log.e('Transmission 初始化错误: $e');
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
      return await _service.getVersion();
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
      _log.w('刷新版本信息失败: $e');
    }
  }

  /// 检查连接状态
  @override
  Future<bool> checkConnection() async {
    isLoading.value = true;
    try {
      isConnected.value = await _service.checkConnection();
      if (!isConnected.value && config != null) {
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

  /// 刷新种子列表
  /// 使用增量更新机制，减少内存分配和释放
  @override
  Future<void> refreshTorrents() async {
    // 防抖：如果正在刷新，等待当前刷新完成
    if (_isRefreshing) {
      if (_pendingRefresh != null) {
        await _pendingRefresh;
      }
      return;
    }

    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return;
    }

    _isRefreshing = true;
    errorMessage.value = '';

    _pendingRefresh = _performRefresh();
    try {
      await _pendingRefresh;
    } finally {
      _isRefreshing = false;
      _pendingRefresh = null;
    }
  }

  /// 执行实际的刷新操作
  /// 使用 buffer 机制分批处理数据，减少内存峰值
  Future<void> _performRefresh() async {
    try {
      final newList = await _service.getTorrents();
      _log.d('Transmission: 接收到 ${newList.length} 条种子数据');

      // 使用 buffer 机制分批处理，避免一次性处理大量数据
      if (newList.length > _bufferBatchSize) {
        await _updateTorrentsWithBuffer(newList);
      } else {
        // 数据量小，直接处理
        _updateTorrentsIncremental(newList);
      }

      // 同时刷新服务器状态
      final state = await _service.getServerState();
      if (state != null) {
        serverState.value = state;
      }
    } catch (e) {
      errorMessage.value = '获取种子列表失败: ${e.toString()}';
      _log.e('获取种子列表失败: $e');
      // 发生错误时，清空列表和 Map
      torrents.clear();
      _torrentsMap.clear();
    }
  }

  /// 使用 buffer 机制分批处理大量数据
  /// 每次处理一批数据，然后让出控制权，避免阻塞和内存峰值
  Future<void> _updateTorrentsWithBuffer(List<TorrentModel> newList) async {
    _log.d('Transmission: 使用 buffer 机制分批处理 ${newList.length} 条数据');

    // 如果列表为空，直接赋值（首次加载）
    if (torrents.isEmpty && _torrentsMap.isEmpty) {
      _torrentsMap.clear();

      // 分批添加到 Map 和列表
      for (int i = 0; i < newList.length; i += _bufferBatchSize) {
        final end = (i + _bufferBatchSize < newList.length)
            ? i + _bufferBatchSize
            : newList.length;
        final batch = newList.sublist(i, end);

        // 添加到 Map
        for (var torrent in batch) {
          _torrentsMap[torrent.hash] = torrent;
        }

        // 添加到列表
        torrents.addAll(batch);

        // 每处理一批后让出控制权，避免阻塞
        if (end < newList.length) {
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }

      torrents.refresh();
      _log.d('Transmission: 分批处理完成，共 ${torrents.length} 条数据');
      return;
    }

    // 增量更新模式：分批处理
    final newHashes = <String>{};
    final newListMap = <String, TorrentModel>{};

    // 先构建新数据的 Map 和 hash 集合（分批处理，避免一次性创建大集合）
    for (int i = 0; i < newList.length; i += _bufferBatchSize) {
      final end = (i + _bufferBatchSize < newList.length)
          ? i + _bufferBatchSize
          : newList.length;
      final batch = newList.sublist(i, end);

      for (var torrent in batch) {
        newHashes.add(torrent.hash);
        newListMap[torrent.hash] = torrent;
      }

      // 让出控制权
      if (end < newList.length) {
        await Future.delayed(const Duration(milliseconds: 5));
      }
    }

    // 找出需要移除的种子（分批处理）
    final hashesToRemove = <String>[];
    int processedCount = 0;
    for (var hash in _torrentsMap.keys) {
      if (!newHashes.contains(hash)) {
        hashesToRemove.add(hash);
        processedCount++;

        // 每处理一批后让出控制权
        if (processedCount % _bufferBatchSize == 0) {
          await Future.delayed(const Duration(milliseconds: 5));
        }
      }
    }

    // 移除已删除的种子
    if (hashesToRemove.isNotEmpty) {
      torrents.removeWhere((t) => hashesToRemove.contains(t.hash));
      for (var hash in hashesToRemove) {
        _torrentsMap.remove(hash);
      }
    }

    // 分批更新或添加种子
    bool hasChanges = false;
    int updateCount = 0;

    for (int i = 0; i < newList.length; i += _bufferBatchSize) {
      final end = (i + _bufferBatchSize < newList.length)
          ? i + _bufferBatchSize
          : newList.length;
      final batch = newList.sublist(i, end);

      for (var newTorrent in batch) {
        final hash = newTorrent.hash;
        final existingTorrent = _torrentsMap[hash];

        if (existingTorrent == null) {
          // 新增种子
          torrents.add(newTorrent);
          _torrentsMap[hash] = newTorrent;
          hasChanges = true;
        } else {
          // 检查是否有变化
          if (_hasTorrentChanged(existingTorrent, newTorrent)) {
            final index = torrents.indexWhere((t) => t.hash == hash);
            if (index != -1) {
              torrents[index] = newTorrent;
              _torrentsMap[hash] = newTorrent;
              hasChanges = true;
            }
          }
        }

        updateCount++;
      }

      // 每处理一批后让出控制权，并触发一次更新（如果数据量大）
      if (end < newList.length) {
        if (hasChanges && updateCount % _bufferMaxSize == 0) {
          torrents.refresh();
          hasChanges = false; // 重置标志，避免重复刷新
        }
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }

    // 最终触发一次更新
    if (hasChanges || hashesToRemove.isNotEmpty) {
      torrents.refresh();
    }

    _log.d(
      'Transmission: Buffer 处理完成，更新 ${updateCount} 条，移除 ${hashesToRemove.length} 条',
    );
  }

  /// 增量更新种子列表
  /// 只更新变化的数据，减少内存分配和 UI 重绘
  void _updateTorrentsIncremental(List<TorrentModel> newList) {
    // 如果列表为空，直接赋值
    if (torrents.isEmpty && _torrentsMap.isEmpty) {
      _torrentsMap.clear();
      for (var torrent in newList) {
        _torrentsMap[torrent.hash] = torrent;
      }
      torrents.assignAll(newList);
      return;
    }

    // 创建新列表的 hash 集合，用于快速查找
    final newHashes = <String>{};
    for (var torrent in newList) {
      newHashes.add(torrent.hash);
    }

    // 找出需要移除的种子（存在于旧列表但不在新列表中）
    final hashesToRemove = <String>[];
    for (var hash in _torrentsMap.keys) {
      if (!newHashes.contains(hash)) {
        hashesToRemove.add(hash);
      }
    }

    // 移除已删除的种子
    if (hashesToRemove.isNotEmpty) {
      torrents.removeWhere((t) => hashesToRemove.contains(t.hash));
      for (var hash in hashesToRemove) {
        _torrentsMap.remove(hash);
      }
    }

    // 更新或添加种子
    bool hasChanges = false;
    for (var newTorrent in newList) {
      final hash = newTorrent.hash;
      final existingTorrent = _torrentsMap[hash];

      if (existingTorrent == null) {
        // 新增种子
        torrents.add(newTorrent);
        _torrentsMap[hash] = newTorrent;
        hasChanges = true;
      } else {
        // 检查是否有变化（只比较关键字段，避免不必要的更新）
        if (_hasTorrentChanged(existingTorrent, newTorrent)) {
          final index = torrents.indexWhere((t) => t.hash == hash);
          if (index != -1) {
            torrents[index] = newTorrent;
            _torrentsMap[hash] = newTorrent;
            hasChanges = true;
          }
        }
      }
    }

    // 只有在有变化时才触发响应式更新
    // assignAll 已经会触发更新，所以不需要额外的 refresh()
    if (hasChanges || hashesToRemove.isNotEmpty) {
      // 使用 refresh() 触发响应式更新，但只在有实际变化时
      torrents.refresh();
    }
  }

  /// 检查种子是否有变化（只比较关键字段，提高性能）
  bool _hasTorrentChanged(TorrentModel old, TorrentModel new_) {
    return old.name != new_.name ||
        old.progress != new_.progress ||
        old.dlspeed != new_.dlspeed ||
        old.upspeed != new_.upspeed ||
        old.state != new_.state ||
        old.eta != new_.eta ||
        old.ratio != new_.ratio ||
        old.numSeeds != new_.numSeeds ||
        old.numLeechers != new_.numLeechers ||
        old.category != new_.category ||
        old.tags.length != new_.tags.length ||
        old.lastActivity != new_.lastActivity;
  }

  /// 暂停种子
  @override
  Future<void> pauseTorrent(String hash) async {
    try {
      await _service.pauseTorrents([hash]);
      await refreshTorrents();
    } catch (e) {
      errorMessage.value = '暂停失败: ${e.toString()}';
      _log.e('暂停种子失败: $e');
    }
  }

  /// 恢复种子
  @override
  Future<void> resumeTorrent(String hash) async {
    try {
      await _service.resumeTorrents([hash]);
      await refreshTorrents();
    } catch (e) {
      errorMessage.value = '恢复失败: ${e.toString()}';
      _log.e('恢复种子失败: $e');
    }
  }

  /// 删除种子
  @override
  Future<void> deleteTorrent(String hash, {bool deleteFiles = false}) async {
    try {
      await _service.deleteTorrents([hash], deleteFiles: deleteFiles);
      await refreshTorrents();
    } catch (e) {
      errorMessage.value = '删除失败: ${e.toString()}';
      _log.e('删除种子失败: $e');
    }
  }

  /// 批量暂停种子
  @override
  Future<void> pauseTorrents(List<String> hashes) async {
    try {
      await _service.pauseTorrents(hashes);
      await refreshTorrents();
    } catch (e) {
      errorMessage.value = '暂停失败: ${e.toString()}';
      _log.e('批量暂停种子失败: $e');
    }
  }

  /// 批量恢复种子
  @override
  Future<void> resumeTorrents(List<String> hashes) async {
    try {
      await _service.resumeTorrents(hashes);
      await refreshTorrents();
    } catch (e) {
      errorMessage.value = '恢复失败: ${e.toString()}';
      _log.e('批量恢复种子失败: $e');
    }
  }

  /// 添加种子
  @override
  Future<bool> addTorrent({
    required String torrent,
    String? savePath,
    String? category,
    List<String>? tags,
    bool paused = false,
    bool skipChecking = false,
  }) async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return false;
    }

    try {
      await _service.addTorrent(
        urls: torrent,
        savePath: savePath ?? '',
        category: category,
        tags: tags,
        paused: paused,
        skipChecking: skipChecking,
      );

      // 等待一小段时间，让服务器处理完添加请求
      await Future.delayed(const Duration(milliseconds: 500));

      await refreshTorrents();
      return true;
    } catch (e) {
      errorMessage.value = '添加种子失败: ${e.toString()}';
      _log.e('添加种子失败: $e');
      return false;
    }
  }

  /// 设置种子下载限速
  @override
  Future<bool> setTorrentDownloadLimit(List<String> hashes, int limit) async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return false;
    }

    try {
      await _service.setTorrentDownloadLimit(hashes, limit);
      return true;
    } catch (e) {
      errorMessage.value = '设置下载限速失败: ${e.toString()}';
      _log.e('设置下载限速失败: $e');
      return false;
    }
  }

  /// 设置种子上传限速
  @override
  Future<bool> setTorrentUploadLimit(List<String> hashes, int limit) async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return false;
    }

    try {
      await _service.setTorrentUploadLimit(hashes, limit);
      return true;
    } catch (e) {
      errorMessage.value = '设置上传限速失败: ${e.toString()}';
      _log.e('设置上传限速失败: $e');
      return false;
    }
  }

  /// 设置种子分类（Transmission 使用 labels）
  @override
  Future<bool> setTorrentCategory(List<String> hashes, String category) async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return false;
    }

    try {
      await _service.setTorrentCategory(hashes, category);
      await refreshTorrents();
      return true;
    } catch (e) {
      errorMessage.value = '设置分类失败: ${e.toString()}';
      _log.e('设置分类失败: $e');
      return false;
    }
  }

  /// 设置种子标签（Transmission 使用 labels）
  @override
  Future<bool> setTorrentTags(List<String> hashes, List<String> tags) async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return false;
    }

    try {
      await _service.setTorrentTags(hashes, tags);
      await refreshTorrents();
      return true;
    } catch (e) {
      errorMessage.value = '设置标签失败: ${e.toString()}';
      _log.e('设置标签失败: $e');
      return false;
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
      await refreshTorrents();
      return true;
    } catch (e) {
      errorMessage.value = '强制启动失败: ${e.toString()}';
      _log.e('强制启动失败: $e');
      return false;
    }
  }

  /// 重新检查种子
  @override
  Future<bool> recheckTorrents(List<String> hashes) async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return false;
    }

    try {
      await _service.recheckTorrents(hashes);
      return true;
    } catch (e) {
      errorMessage.value = '重新检查失败: ${e.toString()}';
      _log.e('重新检查失败: $e');
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
      await refreshTorrents();
      return true;
    } catch (e) {
      errorMessage.value = '重命名失败: ${e.toString()}';
      _log.e('重命名失败: $e');
      return false;
    }
  }

  /// 设置种子保存位置
  @override
  Future<bool> setTorrentLocation(List<String> hashes, String location) async {
    if (!isConnected.value) {
      await checkConnection();
      if (!isConnected.value) return false;
    }

    try {
      await _service.setTorrentLocation(hashes, location);
      await refreshTorrents();
      return true;
    } catch (e) {
      errorMessage.value = '设置保存位置失败: ${e.toString()}';
      _log.e('设置保存位置失败: $e');
      return false;
    }
  }

  /// 启动自动刷新
  @override
  void startAutoRefresh() {
    stopAutoRefresh();

    // 如果自动刷新已启用，尝试启动
    if (!autoRefresh.value) {
      return;
    }

    // 如果当前未连接，等待连接成功后再启动（由监听器处理）
    if (!isConnected.value) {
      _log.d('Transmission: 等待连接成功后再启动自动刷新');
      return;
    }

    // 计算刷新间隔（根据种子数量动态调整）
    final interval = _calculateRefreshInterval();

    _log.d('Transmission: 启动自动刷新，间隔 $interval 秒，当前种子数: ${torrents.length}');

    _autoRefreshTimer = Timer.periodic(Duration(seconds: interval), (_) {
      // 如果正在刷新，跳过本次刷新，避免并发刷新导致内存问题
      if (_isRefreshing) {
        _log.d('Transmission: 跳过刷新，上次刷新尚未完成');
        return;
      }

      if (autoRefresh.value && isConnected.value) {
        refreshTorrents();
      } else {
        // 如果自动刷新已禁用或连接断开，停止定时器
        stopAutoRefresh();
      }
    });
  }

  /// 根据种子数量计算刷新间隔（秒）
  /// - 1000 以下：3 秒
  /// - 1000-10000：5 秒
  /// - 10000-30000：10 秒
  /// - 30000-50000：20 秒（大数据量时降低刷新频率，减少内存压力）
  /// - 50000 及以上：30 秒（超大数据量时进一步降低刷新频率）
  int _calculateRefreshInterval() {
    final count = torrents.length;
    if (count < 1000) {
      return 3;
    } else if (count < 10000) {
      return 5;
    } else if (count < 30000) {
      return 10;
    } else if (count < 50000) {
      return 20; // 3万-5万数据使用 20 秒间隔
    } else {
      return 30; // 5万+ 数据使用 30 秒间隔，大幅减少内存压力
    }
  }

  /// 停止自动刷新
  @override
  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  @override
  void onClose() {
    _connectionWorker?.dispose();
    stopAutoRefresh();
    // 清理内存
    torrents.clear();
    _torrentsMap.clear();
    _service.dispose();
    super.onClose();
  }

  @override
  // TODO: implement preferences
  Rxn<QBPreferencesModel> get preferences => throw UnimplementedError();

  @override
  Future<void> refreshPreferences() {
    // TODO: implement refreshPreferences
    throw UnimplementedError();
  }

  @override
  Future<bool> updatePreferences(Map<String, dynamic> preferences) {
    // TODO: implement updatePreferences
    throw UnimplementedError();
  }
}
