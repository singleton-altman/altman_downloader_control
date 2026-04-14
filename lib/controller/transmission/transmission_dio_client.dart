import 'dart:convert';
import 'package:altman_downloader_control/utils/log.dart';
import 'package:dio/dio.dart';

/// Transmission Dio 客户端
/// 专门用于 Transmission RPC API 请求
class TransmissionDioClient {
  late Dio _dio;
  String? _baseUrl;
  String? _username;
  String? _password;
  String? _sessionId;
  int _requestId = 1;

  final DownloaderLog _log = DownloaderLog();

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
        headers: {'Content-Type': 'application/json', 'Accept': '*/*'},
      ),
    );

    // 添加错误日志拦截器
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          _log.e('Transmission API Error: ${error.message}');
          _log.e('URL: ${error.requestOptions.uri}');
          if (error.response != null) {
            _log.e('Response: ${error.response?.data}');
          }
          handler.next(error);
        },
      ),
    );
  }

  /// 获取认证头
  Map<String, dynamic> _getAuthHeaders() {
    final headers = <String, dynamic>{
      'Content-Type': 'application/json',
      'Accept': '*/*',
    };

    // 添加 Origin 和 Referer
    if (_baseUrl != null) {
      try {
        final uri = Uri.parse(_baseUrl!);
        final origin =
            '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';
        headers['Origin'] = origin;
        headers['Referer'] = '$origin/transmission/web/';
      } catch (e) {
        _log.w('Failed to parse base URL for headers: $e');
      }
    }

    // 添加 HTTP Basic Auth
    if (_username != null && _password != null) {
      final credentials = '$_username:$_password';
      final credentialsBytes = utf8.encode(credentials);
      final base64Credentials = base64Encode(credentialsBytes);
      headers['Authorization'] = 'Basic $base64Credentials';
    }

    // 添加 Session ID（如果存在）
    if (_sessionId != null) {
      headers['X-Transmission-Session-Id'] = _sessionId!;
    }

    return headers;
  }

  /// 执行 RPC 请求
  Future<Response> rpcRequest({
    required String method,
    Map<String, dynamic>? arguments,
  }) async {
    if (_baseUrl == null) {
      throw Exception('Client not initialized');
    }

    final url = '${_baseUrl!}/transmission/rpc';
    final headers = _getAuthHeaders();

    final requestBody = <String, dynamic>{
      'method': method,
      'tag': _requestId++,
    };

    if (arguments != null) {
      requestBody['arguments'] = arguments;
    }

    _log.d(
      'Transmission RPC request - Method: $method, Tag: ${_requestId - 1}',
    );

    try {
      final response = await _dio.post(
        url,
        data: requestBody,
        options: Options(
          headers: headers,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      // 处理 409 状态码（Session ID 冲突）
      if (response.statusCode == 409) {
        final sessionId = response.headers.value('X-Transmission-Session-Id');
        if (sessionId != null) {
          _sessionId = sessionId;
          _log.d(
            'Transmission session ID updated from 409 response: $sessionId',
          );
          // 重新发送请求
          return await rpcRequest(method: method, arguments: arguments);
        }
      }

      // 处理其他错误状态码
      if (response.statusCode != null &&
          (response.statusCode! < 200 || response.statusCode! >= 300)) {
        _log.e('Transmission HTTP error - Status: ${response.statusCode}');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'HTTP ${response.statusCode}',
        );
      }

      // 更新 Session ID（如果响应中有）
      final sessionId = response.headers.value('X-Transmission-Session-Id');
      if (sessionId != null) {
        _sessionId = sessionId;
        _log.d('Transmission session ID updated: $sessionId');
      }

      return response;
    } catch (e) {
      if (e is DioException) {
        rethrow;
      }
      throw DioException(
        requestOptions: RequestOptions(path: url),
        error: e,
      );
    }
  }

  /// 登录（获取 Session ID）
  Future<bool> login() async {
    try {
      // 第一次尝试：不带 session ID
      _sessionId = null;
      final response = await rpcRequest(method: 'session-get');

      if (response.statusCode == 200) {
        // 解析响应，检查是否成功
        final data = response.data;
        if (data is Map && data['result'] == 'success') {
          _log.d('Transmission login successful, session ID: $_sessionId');
          return true;
        }
      }

      return false;
    } catch (e) {
      _log.e('Transmission login error: $e');
      // 清空 session ID 并重试
      _sessionId = null;
      try {
        final response = await rpcRequest(method: 'session-get');
        if (response.statusCode == 200) {
          final data = response.data;
          if (data is Map && data['result'] == 'success') {
            _log.d(
              'Transmission login retry successful, session ID: $_sessionId',
            );
            return true;
          }
        }
      } catch (e2) {
        _log.e('Transmission login retry error: $e2');
      }
      return false;
    }
  }

  /// 检查连接状态
  Future<bool> checkConnection() async {
    try {
      final response = await rpcRequest(method: 'session-get');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['result'] == 'success') {
          return true;
        }
      }

      return false;
    } catch (e) {
      _log.e('Transmission connection check error: $e');
      // 如果连接失败，尝试重新登录
      return await login();
    }
  }

  /// 关闭客户端并清理资源
  void dispose() {
    _dio.close();
    _baseUrl = null;
    _username = null;
    _password = null;
    _sessionId = null;
    _requestId = 1;
  }

  /// 获取基础 URL
  String? get baseUrl => _baseUrl;

  /// 获取 Session ID
  String? get sessionId => _sessionId;
}
