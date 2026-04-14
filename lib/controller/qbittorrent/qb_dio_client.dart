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

    // 添加错误日志拦截器
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          if (error.response != null) {}
          handler.next(error);
        },
      ),
    );
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
        options: Options(validateStatus: (status) => status! < 500),
      );

      // qBittorrent 登录成功返回 "Ok."，失败返回 "Fails."
      final responseText = response.data.toString().trim();
      return responseText == 'Ok.' || responseText == 'Ok';
    } catch (e) {
      return false;
    }
  }

  /// 检查连接状态（通过获取版本信息）
  Future<bool> checkConnection() async {
    try {
      final response = await _dio.get(
        'api/v2/app/version',
        options: Options(validateStatus: (status) => status! < 500),
      );

      // 如果返回 403，说明需要登录
      if (response.statusCode == 403) {
        if (_username != null && _password != null) {
          return await login();
        }
        return false;
      }

      return response.statusCode == 200;
    } catch (e) {
      // 如果连接失败，尝试重新登录
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
      // 如果是认证错误，尝试重新登录
      if (e is DioException && e.response?.statusCode == 403) {
        if (await login()) {
          return await _dio.get(
            path,
            queryParameters: queryParameters,
            options: options,
          );
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
      // 如果是认证错误，尝试重新登录
      if (e is DioException && e.response?.statusCode == 403) {
        if (await login()) {
          return await _dio.post(
            path,
            data: data,
            queryParameters: queryParameters,
            options: options,
          );
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
