import 'dart:convert';
import 'dart:io';
import 'package:altman_downloader_control/utils/log.dart';
import 'package:dio/dio.dart';
import 'package:altman_downloader_control/controller/qbittorrent/qb_dio_client.dart';
import 'package:altman_downloader_control/model/qb_torrent_model.dart';
import 'package:altman_downloader_control/model/qb_rss_item_model.dart';
import 'package:altman_downloader_control/model/qb_main_data_model.dart';
import 'package:altman_downloader_control/model/qb_torrent_properties_model.dart';
import 'package:altman_downloader_control/model/qb_tracker_model.dart';
import 'package:altman_downloader_control/model/qb_torrent_file_model.dart';
import 'package:altman_downloader_control/model/qb_log_model.dart';

/// qBittorrent 服务类
/// 使用原生 Dio 请求处理 qBittorrent WebUI API
class QBService {
  final _client = QBDioClient();
  bool _initialized = false;
  final _log = DownloaderLog();

  bool _dioLooksLikeMissingEndpoint(DioException e) {
    final c = e.response?.statusCode;
    if (c == 404 || c == 405) return true;
    final b = e.response?.data?.toString().toLowerCase() ?? '';
    if (c == 400 &&
        (b.contains('does not exist') ||
            b.contains('endpoint does not exist') ||
            (b.contains('missing') && b.contains('parameter')))) {
      return true;
    }
    return false;
  }

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

      // 尝试登录
      final success = await _client.login();
      _initialized = success;
      return success;
    } catch (e) {
      _initialized = false;
      return false;
    }
  }

  /// 检查连接状态
  Future<bool> checkConnection() async {
    if (!_initialized) return false;
    return await _client.checkConnection();
  }

  /// 获取 qBittorrent 客户端版本
  /// API: GET /api/v2/app/version
  Future<String?> getVersion() async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      final response = await _client.get('api/v2/app/version');

      if (response.statusCode == 200) {
        // 版本信息是纯文本字符串，需要去除首尾空白
        final version = response.data.toString().trim();
        return version.isNotEmpty ? version : null;
      }

      return null;
    } catch (e) {
      _log.e('Get version error: $e');
      return null;
    }
  }

  /// 获取所有种子列表
  Future<List<QBTorrentModel>> getTorrents({
    String? filter,
    String? category,
    String? tag,
    String? sort,
    bool reverse = false,
    int? limit,
    int? offset,
  }) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      final response = await _client.get(
        'api/v2/torrents/info',
        queryParameters: {
          if (filter != null) 'filter': filter,
          if (category != null) 'category': category,
          if (tag != null) 'tag': tag,
          if (sort != null) 'sort': sort,
          'reverse': reverse,
          if (limit != null) 'limit': limit,
          if (offset != null) 'offset': offset,
        },
      );

      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> data = response.data;
        return data.map((json) => QBTorrentModel.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// 获取种子详细信息
  Future<QBTorrentModel?> getTorrentInfo(String hash) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      final torrents = await getTorrents();
      return torrents.firstWhere(
        (t) => t.hash == hash,
        orElse: () => throw Exception('Torrent not found'),
      );
    } catch (e) {
      return null;
    }
  }

  /// 暂停/停止种子（5.x: stop，4.x: 自动回退 pause）
  Future<void> pauseTorrents(List<String> hashes) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      final hashesParam = hashes.join('|');
      final data = {'hashes': hashesParam};
      try {
        await _client.post('api/v2/torrents/stop', data: data);
      } on DioException catch (e) {
        if (_dioLooksLikeMissingEndpoint(e)) {
          _log.d('QB: torrents/stop 不可用，回退 torrents/pause（4.x）');
          await _client.post('api/v2/torrents/pause', data: data);
        } else {
          rethrow;
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 启动/恢复种子（5.x: start，4.x: 自动回退 resume）
  Future<void> resumeTorrents(List<String> hashes) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      final hashesParam = hashes.join('|');
      final data = {'hashes': hashesParam};
      try {
        await _client.post('api/v2/torrents/start', data: data);
      } on DioException catch (e) {
        if (_dioLooksLikeMissingEndpoint(e)) {
          _log.d('QB: torrents/start 不可用，回退 torrents/resume（4.x）');
          await _client.post('api/v2/torrents/resume', data: data);
        } else {
          rethrow;
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 删除种子
  /// API: POST /api/v2/torrents/delete
  Future<void> deleteTorrents(
    List<String> hashes, {
    bool deleteFiles = false,
  }) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      await _client.post(
        'api/v2/torrents/delete',
        data: {'hashes': hashes.join('|'), 'deleteFiles': deleteFiles},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 强制启动种子
  /// API: POST /api/v2/torrents/setForceStart
  Future<void> setForceStart(List<String> hashes, bool value) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      await _client.post(
        'api/v2/torrents/setForceStart',
        data: {'hashes': hashes.join('|'), 'value': value},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 强制重新校验
  /// API: POST /api/v2/torrents/recheck
  Future<void> recheckTorrents(List<String> hashes) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      await _client.post(
        'api/v2/torrents/recheck',
        data: {'hashes': hashes.join('|')},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 设置保存位置
  /// API: POST /api/v2/torrents/setLocation
  Future<void> setLocation(List<String> hashes, String location) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      await _client.post(
        'api/v2/torrents/setLocation',
        data: {'hashes': hashes.join('|'), 'location': location},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 重命名种子
  /// API: POST /api/v2/torrents/rename
  Future<void> renameTorrent(String hash, String newName) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      await _client.post(
        'api/v2/torrents/rename',
        data: {'hash': hash, 'name': newName},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 获取分类列表
  /// API: GET /api/v2/torrents/categories
  /// 返回 Map<String, dynamic>，key 为分类名称，value 为分类信息（包含 savePath）
  Future<Map<String, dynamic>> getCategories() async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      final response = await _client.get('api/v2/torrents/categories');
      if (response.statusCode == 200 && response.data is Map) {
        return response.data as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      rethrow;
    }
  }

  /// 创建分类
  /// API: POST /api/v2/torrents/createCategory
  /// 根据 curl 示例，参数为 category (分类名称) 和 savePath (保存路径，可选)
  Future<void> createCategory({
    required String category,
    String? savePath,
  }) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      final data = <String, dynamic>{'category': category};
      if (savePath != null && savePath.isNotEmpty) {
        data['savePath'] = savePath;
      }
      await _client.post('api/v2/torrents/createCategory', data: data);
    } catch (e) {
      rethrow;
    }
  }

  /// 设置分类
  /// API: POST /api/v2/torrents/setCategory
  Future<void> setCategory(List<String> hashes, String category) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      await _client.post(
        'api/v2/torrents/setCategory',
        data: {'hashes': hashes.join('|'), 'category': category},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 获取所有标签列表
  /// 通过获取所有种子的标签并去重来获取标签列表
  /// 返回去重后的标签列表
  Future<List<String>> getAllTags() async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      final torrents = await getTorrents();
      final tagsSet = <String>{};
      for (var torrent in torrents) {
        tagsSet.addAll(torrent.tags);
      }
      return tagsSet.toList()..sort();
    } catch (e) {
      rethrow;
    }
  }

  /// 添加标签（增量添加，不删除现有标签）
  /// API: POST /api/v2/torrents/addTags
  /// 根据 curl 示例，tags 参数可以是单个标签或多个标签（用逗号分隔）
  Future<void> addTags(List<String> hashes, List<String> tags) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    if (tags.isEmpty) return;

    try {
      await _client.post(
        'api/v2/torrents/addTags',
        data: {'hashes': hashes.join('|'), 'tags': tags.join(',')},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 移除标签（增量移除）
  /// API: POST /api/v2/torrents/removeTags
  Future<void> removeTags(List<String> hashes, List<String> tags) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    if (tags.isEmpty) return;

    try {
      await _client.post(
        'api/v2/torrents/removeTags',
        data: {
          'hashes': hashes.join('|'),
          'tags': tags.join(','), // 移除指定的标签
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 设置标签（先移除所有，再添加新标签）
  /// API: POST /api/v2/torrents/addTags 和 /api/v2/torrents/removeTags
  Future<void> setTags(List<String> hashes, List<String> tags) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      // 先移除所有标签，再添加新标签
      await _client.post(
        'api/v2/torrents/removeTags',
        data: {
          'hashes': hashes.join('|'),
          'tags': '', // 移除所有标签
        },
      );

      if (tags.isNotEmpty) {
        await _client.post(
          'api/v2/torrents/addTags',
          data: {'hashes': hashes.join('|'), 'tags': tags.join(',')},
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 设置下载速度限制
  /// API: POST /api/v2/torrents/setDownloadLimit
  /// limit 为 -1 表示无限制，单位为字节/秒
  Future<void> setDownloadLimit(List<String> hashes, int limit) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      await _client.post(
        'api/v2/torrents/setDownloadLimit',
        data: {'hashes': hashes.join('|'), 'limit': limit},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 设置上传速度限制
  /// API: POST /api/v2/torrents/setUploadLimit
  /// limit 为 -1 表示无限制，单位为字节/秒
  Future<void> setUploadLimit(List<String> hashes, int limit) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      await _client.post(
        'api/v2/torrents/setUploadLimit',
        data: {'hashes': hashes.join('|'), 'limit': limit},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 获取 RSS 列表
  /// API: GET /api/v2/rss/items?withData=true
  Future<QBRssItemsResponse> getRssItems({bool withData = true}) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      final response = await _client.get(
        'api/v2/rss/items',
        queryParameters: {'withData': withData},
      );

      if (response.statusCode == 200 && response.data is Map) {
        return QBRssItemsResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      return QBRssItemsResponse(feeds: {});
    } catch (e) {
      rethrow;
    }
  }

  /// 添加 RSS Feed
  /// API: POST /api/v2/rss/addFeed
  /// 根据 qBittorrent API 规范，即使 path 为空也需要发送 path 参数
  Future<void> addRssFeed({required String url, String? path}) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      await _client.post(
        'api/v2/rss/addFeed',
        data: {
          'url': url,
          'path': path ?? '', // 即使 path 为 null，也发送空字符串
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 删除 RSS Feed
  /// API: POST /api/v2/rss/removeItem
  Future<void> removeRssFeed(String path) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      await _client.post('api/v2/rss/removeItem', data: {'path': path});
    } catch (e) {
      rethrow;
    }
  }

  /// 标记 RSS Item 为已读
  /// API: POST /api/v2/rss/markAsRead
  /// 参数: itemPath (RSS Feed 路径)
  Future<void> markRssAsRead({required String itemPath}) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      await _client.post('api/v2/rss/markAsRead', data: {'itemPath': itemPath});
    } catch (e) {
      rethrow;
    }
  }

  /// 刷新 RSS Feed
  /// API: POST /api/v2/rss/refreshItem
  Future<void> refreshRssFeed(String itemPath) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      await _client.post(
        'api/v2/rss/refreshItem',
        data: {'itemPath': itemPath},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 移动/重命名 RSS Feed
  /// API: POST /api/v2/rss/moveItem
  /// [itemPath] 原始路径
  /// [destPath] 目标路径（新名称）
  Future<void> moveRssItem({
    required String itemPath,
    required String destPath,
  }) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      await _client.post(
        'api/v2/rss/moveItem',
        data: {'itemPath': itemPath, 'destPath': destPath},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 获取主数据（使用 maindata 接口进行增量同步）
  /// API: GET /api/v2/sync/maindata?rid={rid}
  ///
  /// [rid] 响应 ID，用于增量同步。首次调用时传 0 或 null
  ///
  /// 返回 [QBMainDataModel]，包含变更的种子列表、移除的种子和服务器状态
  Future<QBMainDataModel> getMainData({int? rid}) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      final response = await _client.get(
        'api/v2/sync/maindata',
        queryParameters: {if (rid != null) 'rid': rid},
      );

      if (response.statusCode == 200 && response.data is Map) {
        return QBMainDataModel.fromJson(response.data as Map<String, dynamic>);
      }

      throw Exception('Invalid response format');
    } catch (e) {
      rethrow;
    }
  }

  /// 获取应用偏好设置
  /// API: GET /api/v2/app/preferences
  Future<Map<String, dynamic>> getPreferences() async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      final response = await _client.get('api/v2/app/preferences');

      if (response.statusCode == 200 && response.data is Map) {
        return response.data as Map<String, dynamic>;
      }

      throw Exception('Invalid response format');
    } catch (e) {
      rethrow;
    }
  }

  /// 更新应用偏好设置
  /// API: POST /api/v2/app/setPreferences
  /// 注意：qBittorrent API 需要将 JSON 作为表单参数 "json" 传递
  Future<void> setPreferences(Map<String, dynamic> preferences) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      // 过滤掉复杂类型和 null 值，只保留基本类型
      final filteredData = <String, dynamic>{};
      for (final entry in preferences.entries) {
        final value = entry.value;
        // 只保留基本类型：bool, int, double, String
        // 注意：scan_dirs 是 Map，需要特殊处理
        if (value != null) {
          if (value is bool ||
              value is int ||
              value is double ||
              value is String) {
            filteredData[entry.key] = value;
          } else if (value is Map && entry.key == 'scan_dirs') {
            // scan_dirs 是 Map，需要保留
            filteredData[entry.key] = value;
          }
        }
      }

      if (filteredData.isEmpty) {
        throw Exception('没有有效的更新数据');
      }

      // qBittorrent API 需要将 JSON 作为表单参数 "json" 传递
      // 将 Map 转换为 JSON 字符串
      final jsonString = jsonEncode(filteredData);

      // 作为表单数据传递，使用 "json" 作为参数名
      final response = await _client.post(
        'api/v2/app/setPreferences',
        data: {'json': jsonString},
      );

      final sc = response.statusCode ?? 0;
      if (sc != 200 && sc != 204) {
        throw Exception('Failed to update preferences: $sc');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 获取种子属性详情
  /// API: GET /api/v2/torrents/properties?hash={hash}
  Future<QBTorrentPropertiesModel> getTorrentProperties(String hash) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      final response = await _client.get(
        'api/v2/torrents/properties',
        queryParameters: {'hash': hash},
      );

      if (response.statusCode == 200 && response.data is Map) {
        return QBTorrentPropertiesModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      throw Exception('Invalid response format');
    } catch (e) {
      rethrow;
    }
  }

  /// 获取种子 Tracker 列表
  /// API: GET /api/v2/torrents/trackers?hash={hash}
  Future<List<QBTrackerModel>> getTorrentTrackers(String hash) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      final response = await _client.get(
        'api/v2/torrents/trackers',
        queryParameters: {'hash': hash},
      );

      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> data = response.data;
        return data
            .map(
              (json) => QBTrackerModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }

      throw Exception('Invalid response format');
    } catch (e) {
      rethrow;
    }
  }

  /// 添加 Tracker
  /// API: POST /api/v2/torrents/addTrackers
  Future<void> addTrackers(String hash, List<String> urls) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      await _client.post(
        'api/v2/torrents/addTrackers',
        data: {'hash': hash, 'urls': urls.join('\n')},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 编辑 Tracker（新 WebAPI: url，旧版回退 origUrl）
  Future<void> editTracker(String hash, String oldUrl, String newUrl) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      try {
        await _client.post(
          'api/v2/torrents/editTracker',
          data: {'hash': hash, 'url': oldUrl, 'newUrl': newUrl},
        );
      } on DioException catch (e) {
        if (_dioLooksLikeMissingEndpoint(e)) {
          _log.d('QB: editTracker 使用 url 失败，回退 origUrl（旧 WebAPI）');
          await _client.post(
            'api/v2/torrents/editTracker',
            data: {'hash': hash, 'origUrl': oldUrl, 'newUrl': newUrl},
          );
        } else {
          rethrow;
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 移除 Tracker
  /// API: POST /api/v2/torrents/removeTrackers
  Future<void> removeTrackers(String hash, List<String> urls) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      await _client.post(
        'api/v2/torrents/removeTrackers',
        data: {'hash': hash, 'urls': urls.join('|')},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 获取种子文件列表
  /// API: GET /api/v2/torrents/files?hash={hash}
  Future<List<QBTorrentFileModel>> getTorrentFiles(String hash) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      final response = await _client.get(
        'api/v2/torrents/files',
        queryParameters: {'hash': hash},
      );

      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> data = response.data;
        return data
            .map(
              (json) =>
                  QBTorrentFileModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }

      throw Exception('Invalid response format');
    } catch (e) {
      rethrow;
    }
  }

  /// 释放资源
  void dispose() {
    _client.dispose();
    _initialized = false;
  }

  /// 添加 Torrent
  /// API: POST /api/v2/torrents/add
  /// 支持 URL、Magnet 链接或本地文件
  /// 参考 Swift 实现：使用 multipart/form-data 格式上传
  Future<void> addTorrent({
    String? urls,
    List<String>? torrentFilePaths, // 文件路径列表
    required String savePath,
    bool autoTMM = false,
    String? cookie,
    String? rename,
    String? category,
    List<String>? tags,
    bool useDownloadPath = false,
    bool paused = false,
    String? stopCondition,
    bool? skipChecking,
    String? contentLayout,
    int? dlLimit,
    int? upLimit,
  }) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    // 验证至少需要提供 URLs 或文件
    if ((urls == null || urls.isEmpty) &&
        (torrentFilePaths == null || torrentFilePaths.isEmpty)) {
      throw Exception('URLs or torrent files must be provided');
    }

    try {
      // 使用 FormData 支持 multipart/form-data 上传
      final formData = FormData();

      // 1. 添加 torrent 文件
      if (torrentFilePaths != null && torrentFilePaths.isNotEmpty) {
        for (var filePath in torrentFilePaths) {
          final file = File(filePath);
          if (await file.exists()) {
            final fileName = file.path.split('/').last;
            formData.files.add(
              MapEntry(
                'torrents',
                await MultipartFile.fromFile(filePath, filename: fileName),
              ),
            );
          }
        }
      }

      // 2. 添加 URLs（一行一个链接）
      if (urls != null && urls.isNotEmpty) {
        formData.fields.add(MapEntry('urls', urls));
      }

      // 3. 添加其他参数（根据 Swift 实现）
      formData.fields.add(MapEntry('savepath', savePath));

      if (cookie != null && cookie.isNotEmpty) {
        formData.fields.add(MapEntry('cookie', cookie));
      } else {
        formData.fields.add(const MapEntry('cookie', ''));
      }

      if (rename != null && rename.isNotEmpty) {
        formData.fields.add(MapEntry('rename', rename));
      } else {
        formData.fields.add(const MapEntry('rename', ''));
      }

      if (category != null && category.isNotEmpty) {
        formData.fields.add(MapEntry('category', category));
      } else {
        formData.fields.add(const MapEntry('category', ''));
      }

      if (tags != null && tags.isNotEmpty) {
        formData.fields.add(MapEntry('tags', tags.join(', ')));
      } else {
        formData.fields.add(const MapEntry('tags', ''));
      }

      formData.fields.add(
        MapEntry('useDownloadPath', useDownloadPath ? 'true' : 'false'),
      );

      // autoTMM: Swift 中使用 autoTMM
      formData.fields.add(MapEntry('autoTMM', autoTMM ? 'true' : 'false'));

      // paused: Swift 中使用 stopped 而不是 paused
      formData.fields.add(MapEntry('stopped', paused ? 'true' : 'false'));

      // stopCondition: 默认 "None"
      formData.fields.add(MapEntry('stopCondition', stopCondition ?? 'None'));

      // skipChecking: 只在为 true 时发送
      if (skipChecking == true) {
        formData.fields.add(const MapEntry('skip_checking', 'true'));
      }

      // contentLayout: 默认 "Original"
      formData.fields.add(
        MapEntry('contentLayout', contentLayout ?? 'Original'),
      );

      // dlLimit: 如果为 null，发送 "0"（表示不限速）；如果不为 null，发送实际值
      // 注意：qBittorrent API 使用 0 表示不限速，而不是 NaN
      if (dlLimit != null) {
        formData.fields.add(MapEntry('dlLimit', dlLimit.toString()));
      } else {
        formData.fields.add(const MapEntry('dlLimit', '0'));
      }

      // upLimit: 如果为 null，发送 "0"（表示不限速）；如果不为 null，发送实际值
      // 注意：qBittorrent API 使用 0 表示不限速，而不是 NaN
      if (upLimit != null) {
        formData.fields.add(MapEntry('upLimit', upLimit.toString()));
      } else {
        formData.fields.add(const MapEntry('upLimit', '0'));
      }

      // 使用 FormData 发送请求（需要设置 Content-Type 为 multipart/form-data）
      final response = await _client.post(
        'api/v2/torrents/add',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          validateStatus: (status) => status! < 500,
        ),
      );

      final body = _coerceTorrentsAddResponseData(response.data);

      final code = response.statusCode ?? 0;
      if (code == 409) {
        final msg = _torrentsAddErrorBody(body);
        throw Exception(msg ?? '添加种子失败: 全部未能添加');
      }
      if (code != 200 && code != 202) {
        throw Exception('添加种子失败: HTTP $code');
      }

      if (body is Map) {
        final m = Map<String, dynamic>.from(body);
        final fail = (m['failure_count'] as num?)?.toInt() ?? 0;
        final ok = (m['success_count'] as num?)?.toInt() ?? 0;
        final pend = (m['pending_count'] as num?)?.toInt() ?? 0;
        if (fail > 0 && ok == 0 && pend == 0) {
          throw Exception('添加种子失败: ${jsonEncode(m)}');
        }
        return;
      }

      if (body != null && body is String) {
        final responseText = body.toString().trim();
        if (responseText.isNotEmpty &&
            responseText != 'Ok.' &&
            responseText != 'Ok' &&
            responseText.toLowerCase().contains('error')) {
          throw Exception('添加种子失败: $responseText');
        }
      }
    } catch (e) {
      _log.e('Add torrent error: $e');
      rethrow;
    }
  }

  /// 获取日志
  /// API: GET /api/v2/log/main
  ///
  /// [normal] 是否包含普通日志
  /// [info] 是否包含信息日志
  /// [warning] 是否包含警告日志
  /// [critical] 是否包含严重日志
  /// [lastKnownId] 最后已知的日志 ID，用于增量获取（可选）
  ///
  /// 返回 [QBLogResponse]，包含日志条目列表和最后已知的日志 ID
  Future<QBLogResponse> getLogs({
    bool normal = true,
    bool info = true,
    bool warning = true,
    bool critical = true,
    int? lastKnownId,
  }) async {
    if (!_initialized) {
      throw Exception('API not initialized');
    }

    try {
      final response = await _client.get(
        'api/v2/log/main',
        queryParameters: {
          'normal': normal,
          'info': info,
          'warning': warning,
          'critical': critical,
          if (lastKnownId != null) 'last_known_id': lastKnownId,
        },
      );

      if (response.statusCode == 200) {
        // 检查响应数据类型
        if (response.data == null) {
          _log.w('Log response is null, returning empty response');
          return QBLogResponse(id: lastKnownId ?? 0, logs: []);
        }

        if (response.data is List) {
          // API 直接返回日志数组格式（这是最常见的格式）
          return QBLogResponse.fromList(
            response.data as List<dynamic>,
            lastKnownId: lastKnownId,
          );
        } else if (response.data is Map) {
          final data = response.data as Map<String, dynamic>;
          // 检查是否包含必要的字段
          if (data.containsKey('id') || data.containsKey('logs')) {
            return QBLogResponse.fromJson(data);
          } else {
            _log.w(
              'Log response Map missing id or logs fields. Keys: ${data.keys}',
            );
            return QBLogResponse(id: lastKnownId ?? 0, logs: []);
          }
        } else {
          _log.e('Unexpected response type: ${response.data.runtimeType}');
          _log.e('Response data: ${response.data}');
          throw Exception(
            'Invalid response format: expected Map or List, got ${response.data.runtimeType}',
          );
        }
      }

      throw Exception(
        'Invalid response format: status code ${response.statusCode}',
      );
    } catch (e) {
      _log.e('Get logs error: $e');
      rethrow;
    }
  }

  dynamic _coerceTorrentsAddResponseData(dynamic raw) {
    if (raw is Map) return raw;
    if (raw is String) {
      final t = raw.trim();
      if (t.startsWith('{')) {
        try {
          final o = jsonDecode(t);
          if (o is Map) {
            return Map<String, dynamic>.from(o as Map);
          }
        } catch (_) {}
      }
    }
    return raw;
  }

  String? _torrentsAddErrorBody(dynamic data) {
    if (data is Map) {
      try {
        return jsonEncode(data);
      } catch (_) {
        return data.toString();
      }
    }
    if (data is String) {
      final t = data.trim();
      return t.isNotEmpty ? t : null;
    }
    return null;
  }
}
