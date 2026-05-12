import 'package:altman_downloader_control/utils/log.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';

/// qBittorrent Dio 客户端
/// 专门用于 qBittorrent WebUI API 请求
class QBDioClient {
  late Dio _dio;
  String? _baseUrl;
  String? _username;
  String? _password;
  final CookieJar _cookieJar = CookieJar();
  final DownloaderLog _log = DownloaderLog();

  String _shortBody(dynamic data) {
    if (data == null) return '(null)';
    final s = data.toString();
    if (s.length > 400) return '${s.substring(0, 400)}…';
    return s;
  }

  String _safeRequestData(RequestOptions o) {
    final data = o.data;
    if (data == null) return '';
    if (data is Map && o.path.contains('auth/login')) {
      final m = Map<String, dynamic>.from(data as Map);
      if (m['password'] != null) m['password'] = '***';
      return m.toString();
    }
    final s = data.toString();
    if (s.length > 400) return '${s.substring(0, 400)}…';
    return s;
  }

  String _setCookieSummary(Response r) {
    final list = r.headers.map.entries
        .where((e) => e.key.toLowerCase() == 'set-cookie')
        .expand((e) => e.value)
        .toList();
    if (list.isEmpty) return '-';
    return list
        .map((c) => c.split('=').first)
        .where((n) => n.isNotEmpty)
        .join(', ');
  }

  void _attachLogging() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final extra = _safeRequestData(options);
          final cookieNote =
              options.headers['Cookie'] != null ? ' hasCookieHdr' : '';
          _log.d(
            'QB HTTP → ${options.method} ${options.uri}$cookieNote'
            '${extra.isNotEmpty ? ' $extra' : ''}',
          );
          handler.next(options);
        },
        onResponse: (response, handler) {
          _log.d(
            'QB HTTP ← ${response.statusCode} ${response.requestOptions.uri} '
            'Set-Cookie[${_setCookieSummary(response)}] '
            'body ${_shortBody(response.data)}',
          );
          handler.next(response);
        },
        onError: (error, handler) {
          final r = error.response;
          if (r != null) {
            _log.w(
              'QB HTTP × ${r.statusCode} ${r.requestOptions.uri} '
              'Set-Cookie[${_setCookieSummary(r)}] '
              'body ${_shortBody(r.data)} ${error.message}',
            );
          } else {
            _log.e(
              'QB HTTP × ${error.requestOptions.uri} ${error.type} '
              '${error.message}',
            );
          }
          handler.next(error);
        },
      ),
    );
  }

  /// 初始化客户端
  void initialize({
    required String baseUrl,
    String? username,
    String? password,
  }) {
    _baseUrl = baseUrl;
    _username = username;
    _password = password;

    // 确保 URL 格式正确
    String formattedUrl = baseUrl;
    if (!formattedUrl.endsWith('/')) {
      formattedUrl = '$formattedUrl/';
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: formattedUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      ),
    );

    // 添加 Cookie 管理器（qBittorrent 使用 Cookie 进行认证）
    _dio.interceptors.add(CookieManager(_cookieJar));
    _attachLogging();
  }

  /// 登录到 qBittorrent
  Future<bool> login() async {
    if (_username == null || _password == null) {
      // 如果没有提供用户名密码，尝试访问看看是否已经登录
      return await checkConnection();
    }

    try {
      final response = await _dio.post(
        'api/v2/auth/login',
        data: {'username': _username, 'password': _password},
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final code = response.statusCode ?? 0;
      final data = response.data;
      if (code == 401) {
        _log.w('QB login: 401 凭据无效或需其它认证方式 data ${_shortBody(data)}');
        return false;
      }
      if (code >= 400) {
        _log.w('QB login: HTTP $code data ${_shortBody(data)}');
        return false;
      }

      if (data == null) {
        final ok = code == 200 || code == 204;
        if (!ok) _log.w('QB login: 无 body 且 status=$code');
        return ok;
      }
      if (data is String) {
        final t = data.trim();
        if (t == 'Fails.' || t == 'Fails') {
          _log.w('QB login: 服务端返回 Fails');
          return false;
        }
        if (t.isEmpty) return code == 200 || code == 204;
        final ok = t == 'Ok.' || t == 'Ok';
        if (!ok) _log.w('QB login: 未知响应文本 ${_shortBody(t)}');
        return ok;
      }
      _log.d('QB login: 非字符串 body ${_shortBody(data)} 按 2xx 判定');
      return code >= 200 && code < 300;
    } catch (e, st) {
      _log.e('QB login 异常: $e\n$st');
      return false;
    }
  }

  /// 检查连接状态（通过获取版本信息）
  Future<bool> checkConnection() async {
    try {
      final response = await _dio.get(
        'api/v2/app/version',
        options: Options(validateStatus: (status) => status != null && status < 500),
      );

      final code = response.statusCode ?? 0;
      if (code == 403 || code == 401) {
        _log.d('QB checkConnection: $code 需要会话，尝试 login');
        if (_username != null && _password != null) {
          return await login();
        }
        return false;
      }

      if (code == 200) return true;
      _log.w('QB checkConnection: 未预期 status=$code body ${_shortBody(response.data)}');
      return false;
    } catch (e, st) {
      _log.e('QB checkConnection 异常: $e\n$st');
      if (_username != null && _password != null) {
        return await login();
      }
      return false;
    }
  }

  /// GET 请求
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      // 检查是否需要登录
      if (!await checkConnection()) {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          error: 'Not authenticated',
        );
      }

      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      if (e is DioException) {
        final sc = e.response?.statusCode;
        if (sc == 403 || sc == 401) {
          if (await login()) {
            return await _dio.get(
              path,
              queryParameters: queryParameters,
              options: options,
            );
          }
        }
      }
      rethrow;
    }
  }

  /// POST 请求
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      // 检查是否需要登录
      if (!await checkConnection()) {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          error: 'Not authenticated',
        );
      }

      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      if (e is DioException) {
        final sc = e.response?.statusCode;
        if (sc == 403 || sc == 401) {
          if (await login()) {
            return await _dio.post(
              path,
              data: data,
              queryParameters: queryParameters,
              options: options,
            );
          }
        }
      }
      rethrow;
    }
  }

  /// 关闭客户端并清理资源
  void dispose() {
    _dio.close();
    _baseUrl = null;
    _username = null;
    _password = null;
  }

  /// 获取基础 URL
  String? get baseUrl => _baseUrl;
}
