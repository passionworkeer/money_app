import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'sync_config.dart';
import 'sync_service.dart';

/// WebDAV 同步服务实现
class WebDAVSyncService implements SyncService {
  http.Client? _client;
  SyncConfig _config = const SyncConfig();
  static const String _dataFileName = 'ai_expense_tracker.json';

  @override
  String get providerName => 'WebDAV';

  @override
  bool get isConfigured => _config.isConfigured;

  @override
  Future<void> initialize(SyncConfig config) async {
    _config = config;
    if (!config.isConfigured) {
      throw Exception('WebDAV 配置不完整');
    }
    _client = http.Client();
  }

  String get _baseUrl => _config.webdavUrl!.replaceAll(RegExp(r'/$'), '');

  String get _filePath => '$_baseUrl/$_dataFileName';

  /// 获取认证 Headers
  ///
  /// SECURITY WARNING:
  /// - Basic Auth with Base64 encoding is NOT encryption
  /// - Credentials are sent as "username:password" base64 encoded
  /// - Anyone intercepting the request can easily decode credentials
  /// - HTTP传输是完全明文的，攻击者可以轻易截获和篡改数据
  ///
  /// MANDATORY FOR PRODUCTION:
  /// 1. MUST use HTTPS to encrypt the entire connection
  /// 2. WebDAV server must be configured with SSL/TLS
  /// 3. Verify server certificate to prevent MITM attacks
  /// 4. Consider using OAuth 2.0 if supported by server
  ///
  /// Example secure URL format:
  /// - Correct: https://your-server.com/webdav (HTTPS required)
  /// - WRONG:   http://your-server.com/webdav (insecure!)
  Map<String, String> get _authHeaders {
    final credentials = base64Encode(
      utf8.encode('${_config.webdavUsername}:${_config.webdavPassword}'),
    );
    return {
      'Authorization': 'Basic $credentials',
    };
  }

  @override
  Future<bool> testConnection() async {
    if (_client == null) return false;

    try {
      // 尝试 PROPFIND 请求来检查服务器是否可达
      final response = await _client!.request(
        HttpMethod.PROPFIND,
        _baseUrl,
        headers: {
          ..._authHeaders,
          'Depth': '0',
        },
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 207; // 207 Multi-Status 表示成功
    } catch (e) {
      return false;
    }
  }

  @override
  Future<SyncData?> pull() async {
    if (_client == null) {
      throw Exception('WebDAV 未初始化');
    }

    try {
      final response = await _client!.get(
        Uri.parse(_filePath),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return SyncData.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        // 文件不存在，返回空数据
        return SyncData(
          expenses: [],
          budgets: [],
          timestamp: DateTime.now(),
        );
      } else {
        throw Exception('拉取数据失败: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> push(SyncData data) async {
    if (_client == null) {
      throw Exception('WebDAV 未初始化');
    }

    try {
      final jsonString = const JsonEncoder.withIndent('  ').convert(data.toJson());

      // 检查文件是否已存在
      final existsResponse = await _client!.head(
        Uri.parse(_filePath),
        headers: _authHeaders,
      );

      http.Response response;
      if (existsResponse.statusCode == 200) {
        // 文件存在，使用 PUT 更新
        response = await _client!.put(
          Uri.parse(_filePath),
          headers: {
            ..._authHeaders,
            'Content-Type': 'application/json',
          },
          body: jsonString,
        );
      } else {
        // 文件不存在，使用 PUT 创建
        response = await _client!.put(
          Uri.parse(_filePath),
          headers: {
            ..._authHeaders,
            'Content-Type': 'application/json',
          },
          body: jsonString,
        );
      }

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> sync() async {
    try {
      // 拉取远程数据
      final remoteData = await pull();

      // TODO: 实现冲突解决策略（last-write-wins）

      // 推送本地数据
      // 这里需要从数据库获取最新数据
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    _client?.close();
    _client = null;
  }
}

/// HTTP 方法枚举
enum HttpMethod {
  GET,
  PUT,
  DELETE,
  PROPFIND,
}

extension HttpMethodExtension on HttpMethod {
  String get value {
    switch (this) {
      case HttpMethod.GET:
        return 'GET';
      case HttpMethod.PUT:
        return 'PUT';
      case HttpMethod.DELETE:
        return 'DELETE';
      case HttpMethod.PROPFIND:
        return 'PROPFIND';
    }
  }
}

extension httpClientExtension on http.Client {
  Future<http.Response> request(
    HttpMethod method,
    String url, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    final request = http.Request(method.value, Uri.parse(url));
    if (headers != null) {
      request.headers.addAll(headers);
    }
    if (body != null) {
      request.body = body.toString();
    }

    final streamedResponse = await send(request);
    return await http.Response.fromStream(streamedResponse);
  }
}
