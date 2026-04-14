import 'package:altman_downloader_control/controller/downloader_config.dart';
import 'package:altman_downloader_control/model/qb_preferences_model.dart';
import 'package:altman_downloader_control/model/server_state_model.dart';
import 'package:altman_downloader_control/model/torrent_item_model.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 下载器控制器协议（Protocol）
/// 定义所有下载器控制器必须实现的基本方法
abstract class DownloaderControllerProtocol extends GetxController {
  // 构造函数
  DownloaderControllerProtocol({required this.config});

  Future<void> refreshPreferences();

  final preferences = Rxn<QBPreferencesModel>();

  Future<bool> updatePreferences(Map<String, dynamic> preferences);

  /// 下载器配置
  DownloaderConfig? config;

  /// 连接状态
  Rx<bool> get isConnected;

  /// 加载状态
  Rx<bool> get isLoading;

  /// 错误信息
  Rx<String> get errorMessage;

  /// 检查连接状态
  /// 返回是否连接成功
  Future<bool> checkConnection();

  /// 刷新种子列表
  /// 获取所有种子的完整列表
  Future<void> refreshTorrents();

  /// 暂停种子
  /// [hash] 种子的唯一标识符（hash）
  Future<void> pauseTorrent(String hash);

  /// 恢复种子
  /// [hash] 种子的唯一标识符（hash）
  Future<void> resumeTorrent(String hash);

  /// 删除种子
  /// [hash] 种子的唯一标识符（hash）
  /// [deleteFiles] 是否同时删除文件
  Future<void> deleteTorrent(String hash, {bool deleteFiles = false});

  /// 批量暂停种子
  /// [hashes] 种子的唯一标识符列表
  Future<void> pauseTorrents(List<String> hashes);

  /// 批量恢复种子
  /// [hashes] 种子的唯一标识符列表
  Future<void> resumeTorrents(List<String> hashes);

  /// 添加种子
  /// [torrent] 可以是 torrent 文件的 URL、文件路径或磁力链接
  /// [savePath] 保存路径（可选）
  /// [category] 分类（可选）
  /// [tags] 标签列表（可选）
  /// [paused] 是否暂停添加
  /// [skipChecking] 是否跳过检查
  /// 返回添加是否成功
  Future<bool> addTorrent({
    required String torrent,
    String? savePath,
    String? category,
    List<String>? tags,
    bool paused = false,
    bool skipChecking = false,
  });

  /// 设置种子下载限速
  /// [hashes] 种子的唯一标识符列表
  /// [limit] 限速值（字节/秒），-1 表示无限制
  /// 返回设置是否成功
  Future<bool> setTorrentDownloadLimit(List<String> hashes, int limit);

  /// 设置种子上传限速
  /// [hashes] 种子的唯一标识符列表
  /// [limit] 限速值（字节/秒），-1 表示无限制
  /// 返回设置是否成功
  Future<bool> setTorrentUploadLimit(List<String> hashes, int limit);

  /// 设置种子分类
  /// [hashes] 种子的唯一标识符列表
  /// [category] 分类名称
  /// 返回设置是否成功
  Future<bool> setTorrentCategory(List<String> hashes, String category);

  /// 设置种子标签
  /// [hashes] 种子的唯一标识符列表
  /// [tags] 标签列表
  /// 返回设置是否成功
  Future<bool> setTorrentTags(List<String> hashes, List<String> tags);

  /// 强制启动种子
  /// [hashes] 种子的唯一标识符列表
  /// [value] 是否强制启动
  /// 返回设置是否成功
  Future<bool> forceStartTorrents(List<String> hashes, bool value);

  /// 重新检查种子
  /// [hashes] 种子的唯一标识符列表
  /// 返回操作是否成功
  Future<bool> recheckTorrents(List<String> hashes);

  /// 重命名种子
  /// [hash] 种子的唯一标识符
  /// [newName] 新名称
  /// 返回操作是否成功
  Future<bool> renameTorrent(String hash, String newName);

  /// 设置种子保存位置
  /// [hashes] 种子的唯一标识符列表
  /// [location] 新的保存位置
  /// 返回操作是否成功
  Future<bool> setTorrentLocation(List<String> hashes, String location);

  /// 获取版本信息
  /// 返回版本字符串，如果获取失败返回 null
  Future<String?> getVersion();

  /// 刷新版本信息
  Future<void> refreshVersion();

  /// 启动自动刷新
  void startAutoRefresh();

  /// 停止自动刷新
  void stopAutoRefresh();

  /// 自动刷新开关
  Rx<bool> get autoRefresh;

  /// 获取通用格式的种子列表
  /// 所有下载器控制器应该提供此方法，返回统一的 TorrentModel 列表
  List<TorrentModel> get torrentsUniversal;

  /// 获取通用格式的服务器状态
  /// 所有下载器控制器应该提供此方法，返回统一的 ServerStateModel
  ServerStateModel? get serverStateUniversal;
}

extension DownloaderControllerLocalCacheX on DownloaderControllerProtocol {
  String get cacheDownloaderId {
    final id = config?.id;
    if (id != null && id.isNotEmpty) return id;
    final type = config?.type.name ?? 'unknown';
    final url = config?.url ?? '';
    final username = config?.username ?? '';
    return '$type|$url|$username';
  }

  String get filterPreferenceKey => 'downloader_filter_$cacheDownloaderId';
  String get legacyFilterPreferenceKey =>
      'qb_filter_${config?.id ?? 'default'}';
  String get sortPreferenceKey => 'downloader_sort_$cacheDownloaderId';

  Future<void> saveFilterPreference(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(filterPreferenceKey, value);
  }

  Future<String?> loadFilterPreference() async {
    final preferences = await SharedPreferences.getInstance();
    final current = preferences.getString(filterPreferenceKey);
    if (current != null && current.isNotEmpty) return current;
    final legacy = preferences.getString(legacyFilterPreferenceKey);
    if (legacy != null && legacy.isNotEmpty) {
      await preferences.setString(filterPreferenceKey, legacy);
      return legacy;
    }
    return null;
  }

  Future<void> clearFilterPreference() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(filterPreferenceKey);
  }

  Future<void> saveSortPreference(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(sortPreferenceKey, value);
  }

  Future<String?> loadSortPreference() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(sortPreferenceKey);
  }
}
