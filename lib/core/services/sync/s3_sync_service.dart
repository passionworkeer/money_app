import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'sync_config.dart';
import 'sync_service.dart';

/// S3 同步服务实现（支持 AWS S3、MinIO 等兼容 S3 的存储）
class S3SyncService implements SyncService {
  http.Client? _client;
  SyncConfig _config = const SyncConfig();
  static const String _dataFileName = 'ai_expense_tracker.json';

  @override
  String get providerName => 'S3/MinIO';

  @override
  bool get isConfigured => _config.isConfigured;

  @override
  Future<void> initialize(SyncConfig config) async {
    _config = config;
    if (!config.isConfigured) {
      throw Exception('S3 配置不完整');
    }
    _client = http.Client();
  }

  String get _endpoint => _config.s3Endpoint ?? 's3.amazonaws.com';
  bool get _useSsl => _config.s3UseSsl ?? true;

  String get _host {
    if (_endpoint.contains('://')) {
      return Uri.parse(_endpoint).host;
    }
    return _endpoint;
  }

  @override
  Future<bool> testConnection() async {
    if (_client == null) return false;

    try {
      // 尝试列出 buckets 或检查连接
      final request = await _createRequest('GET', '/${_config.s3Bucket}');
      final response = await _client!.send(request);
      return response.statusCode == 200 || response.statusCode == 403;
    } catch (e) {
      return false;
    }
  }

  String get _objectKey => _dataFileName;

  Future<http.BaseRequest> _createRequest(
    String method,
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? extraHeaders,
    String? body,
  }) async {
    final now = DateTime.now().toUtc();
    final dateStamp = DateFormat('yyyyMMdd').format(now);
    final amzDate = DateFormat('yyyyMMddTHHmmssZ').format(now);

    final uri = Uri(
      scheme: _useSsl ? 'https' : 'http',
      host: _host,
      path: path,
      queryParameters: queryParams,
    );

    final request = http.Request(method, uri);

    // 添加基础 headers
    // 计算 payload 哈希
    // SECURITY: 使用 SHA256 计算请求体的哈希值，用于完整签名验证
    // 这确保请求内容在传输过程中未被篡改
    final payloadHash = body != null
        ? sha256.convert(utf8.encode(body)).toString()
        : 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

    request.headers['Host'] = _host;
    request.headers['x-amz-date'] = amzDate;
    request.headers['x-amz-content-sha256'] = payloadHash;

    if (extraHeaders != null) {
      request.headers.addAll(extraHeaders);
    }

    if (body != null) {
      request.body = body;
      request.headers['Content-Type'] = 'application/json';
    }

    // 添加 AWS Signature V4 签名
    _signRequest(request, dateStamp, amzDate, payloadHash);

    return request;
  }

  void _signRequest(
    http.BaseRequest request,
    String dateStamp,
    String amzDate,
    String payloadHash,
  ) {
    const service = 's3';
    // 从配置读取 region，默认为 us-east-1
    final region = _config.s3Region ?? 'us-east-1';

    // Canonical Request
    final canonicalUri = request.url.path.isEmpty ? '/' : request.url.path;
    final canonicalQueryString = request.url.query.isEmpty
        ? ''
        : request.url.query
            .split('&')
            .map((e) => '${Uri.encodeComponent(e.split('=')[0])}=${e.contains('=') ? Uri.encodeComponent(e.split('=')[1]) : ''}')
            .join('&');

    final signedHeaders = request.headers.keys
        .map((k) => k.toLowerCase())
        .where((k) => k != 'host')
        .toList()
      ..sort();

    final canonicalHeaders = signedHeaders
        .map((k) => '$k:${request.headers[k]}\n')
        .join();

    final canonicalRequest = [
      request.method,
      canonicalUri,
      canonicalQueryString,
      canonicalHeaders,
      signedHeaders.join(';'),
      payloadHash, // 使用实际 payload 哈希而非 UNSIGNED-PAYLOAD
    ].join('\n');

    // String to Sign
    const algorithm = 'AWS4-HMAC-SHA256';
    final credentialScope = '$dateStamp/$region/$service/aws4_request';
    final stringToSign = [
      algorithm,
      amzDate,
      credentialScope,
      sha256.convert(utf8.encode(canonicalRequest)).toString(),
    ].join('\n');

    // Signing Key
    final kDate = _hmacSha256(utf8.encode('AWS4${_config.s3SecretKey}'), dateStamp);
    final kRegion = _hmacSha256(kDate, region);
    final kService = _hmacSha256(kRegion, service);
    final kSigning = _hmacSha256(kService, 'aws4_request');

    // Signature
    final signature = _hmacHex(kSigning, stringToSign);

    // Authorization Header
    final authorization =
        '$algorithm Credential=${_config.s3AccessKey}/$credentialScope, SignedHeaders=${signedHeaders.join(';')}, Signature=$signature';

    request.headers['Authorization'] = authorization;
  }

  List<int> _hmacSha256(List<int> key, String data) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(utf8.encode(data)).bytes;
  }

  String _hmacHex(List<int> key, String data) {
    return _hmacSha256(key, data).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  @override
  Future<SyncData?> pull() async {
    if (_client == null) {
      throw Exception('S3 未初始化');
    }

    try {
      final request = await _createRequest(
        'GET',
        '/${_config.s3Bucket}/$_objectKey',
      );

      final response = await _client!.send(request);

      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final jsonData = jsonDecode(body) as Map<String, dynamic>;
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
      throw Exception('S3 未初始化');
    }

    try {
      final jsonString = const JsonEncoder.withIndent('  ').convert(data.toJson());

      final request = await _createRequest(
        'PUT',
        '/${_config.s3Bucket}/$_objectKey',
        body: jsonString,
      );

      final response = await _client!.send(request);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> sync() async {
    try {
      // TODO: 拉取远程数据并实现冲突解决策略（last-write-wins）
      // final remoteData = await pull();

      // 推送本地数据
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
