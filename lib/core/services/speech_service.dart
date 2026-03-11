import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';

/// 增强的语音识别状态
class EnhancedSpeechStatus {
  final bool isAvailable;
  final bool isOfflineAvailable;
  final bool isListening;
  final bool isProcessing;
  final double? confidence;
  final String? recognizedWords;
  final String? errorMessage;
  final SpeechRecognitionResult? lastResult;

  const EnhancedSpeechStatus({
    required this.isAvailable,
    required this.isOfflineAvailable,
    required this.isListening,
    this.isProcessing = false,
    this.confidence,
    this.recognizedWords,
    this.errorMessage,
    this.lastResult,
  });

  EnhancedSpeechStatus copyWith({
    bool? isAvailable,
    bool? isOfflineAvailable,
    bool? isListening,
    bool? isProcessing,
    double? confidence,
    String? recognizedWords,
    String? errorMessage,
    SpeechRecognitionResult? lastResult,
  }) {
    return EnhancedSpeechStatus(
      isAvailable: isAvailable ?? this.isAvailable,
      isOfflineAvailable: isOfflineAvailable ?? this.isOfflineAvailable,
      isListening: isListening ?? this.isListening,
      isProcessing: isProcessing ?? this.isProcessing,
      confidence: confidence ?? this.confidence,
      recognizedWords: recognizedWords ?? this.recognizedWords,
      errorMessage: errorMessage ?? this.errorMessage,
      lastResult: lastResult ?? this.lastResult,
    );
  }
}

/// 语音识别错误类型
enum SpeechErrorType {
  notAvailable,
  permissionDenied,
  networkError,
  recognitionError,
  timeout,
  unknown,
}

/// 增强语音服务
class EnhancedSpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isOfflineAvailable = false;
  double _lastConfidence = 0.0;
  String _lastRecognizedWords = '';
  String? _lastError;

  // 配置选项
  static const Duration defaultListenDuration = Duration(seconds: 60); // 支持更长语音
  static const Duration defaultPauseDuration = Duration(seconds: 4);
  static const int maxRetries = 3;

  bool get isListening => _isListening;
  bool get isProcessing => _isProcessing;
  bool get isOfflineAvailable => _isOfflineAvailable;
  bool get isInitialized => _isInitialized;
  double get lastConfidence => _lastConfidence;
  String get lastRecognizedWords => _lastRecognizedWords;
  String? get lastError => _lastError;

  /// 初始化语音识别服务
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final isAvailable = await _speech.initialize(
        onError: (error) {
          debugPrint('Speech error: ${error.errorMsg}');
          _lastError = error.errorMsg;
          _isListening = false;
          _isProcessing = false;
        },
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            _isProcessing = false;
          }
        },
      );

      _isInitialized = isAvailable;

      if (isAvailable) {
        await _checkOfflineAvailability();
      }

      return isAvailable;
    } catch (e) {
      debugPrint('Speech initialization failed: $e');
      _lastError = e.toString();
      _isInitialized = false;
      return false;
    }
  }

  /// 检查离线语言包是否可用
  Future<void> _checkOfflineAvailability() async {
    try {
      final locales = await _speech.locales();
      final hasChineseOffline = locales.any((locale) =>
          locale.localeId.contains('zh') &&
          locale.name.contains('离线'));
      _isOfflineAvailable = hasChineseOffline;
      debugPrint('Offline language available: $_isOfflineAvailable');
    } catch (e) {
      debugPrint('Error checking offline availability: $e');
      _isOfflineAvailable = false;
    }
  }

  /// 获取所有可用的语言
  Future<List<stt.LocaleName>> getLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    return await _speech.locales();
  }

  /// 获取当前状态
  EnhancedSpeechStatus getStatus() {
    return EnhancedSpeechStatus(
      isAvailable: _isInitialized,
      isOfflineAvailable: _isOfflineAvailable,
      isListening: _isListening,
      isProcessing: _isProcessing,
      confidence: _lastConfidence > 0 ? _lastConfidence : null,
      recognizedWords: _lastRecognizedWords.isNotEmpty ? _lastRecognizedWords : null,
      errorMessage: _lastError,
    );
  }

  /// 开始语音识别（支持更长输入和重试）
  /// [onResult] - 识别结果回调
  /// [localeId] - 语言ID，默认中文
  /// [listenFor] - 监听时长，默认60秒
  /// [onPartialResult] - 部分结果回调（实时显示识别内容）
  Future<String> listen({
    required Function(String, double?) onResult,
    String localeId = 'zh_CN',
    Duration? listenFor,
    Function(String)? onPartialResult,
    bool enableRetry = true,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        throw SpeechException(
          '语音识别不可用，请确保已授予麦克风权限',
          SpeechErrorType.notAvailable,
        );
      }
    }

    if (_isListening) {
      await stop();
    }

    return enableRetry
        ? _listenWithRetry(
            onResult: onResult,
            localeId: localeId,
            listenFor: listenFor,
            onPartialResult: onPartialResult,
          )
        : _listenOnce(
            onResult: onResult,
            localeId: localeId,
            listenFor: listenFor,
            onPartialResult: onPartialResult,
          );
  }

  /// 带重试的语音识别
  Future<String> _listenWithRetry({
    required Function(String, double?) onResult,
    required String localeId,
    Duration? listenFor,
    Function(String)? onPartialResult,
  }) async {
    int retryCount = 0;
    String lastError = '';

    while (retryCount < maxRetries) {
      try {
        return await _listenOnce(
          onResult: onResult,
          localeId: localeId,
          listenFor: listenFor,
          onPartialResult: onPartialResult,
        );
      } catch (e) {
        retryCount++;
        lastError = e.toString();
        debugPrint('Speech recognition failed (attempt $retryCount): $e');

        // 如果是临时性错误，等待后重试
        if (retryCount < maxRetries && _isTemporaryError(e)) {
          await Future.delayed(Duration(seconds: retryCount * 2));
        }
      }
    }

    throw SpeechException(
      '语音识别失败，已重试$maxRetries次: $lastError',
      SpeechErrorType.recognitionError,
    );
  }

  /// 单次语音识别
  Future<String> _listenOnce({
    required Function(String, double?) onResult,
    required String localeId,
    Duration? listenFor,
    Function(String)? onPartialResult,
  }) async {
    _isListening = true;
    _isProcessing = true;
    _lastError = null;

    final duration = listenFor ?? defaultListenDuration;
    final completer = Completer<String>();

    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        debugPrint('Recognition result: ${result.recognizedWords}, '
            'final: ${result.finalResult}, '
            'confidence: ${result.confidence}');

        _lastConfidence = result.confidence;
        _lastRecognizedWords = result.recognizedWords;

        if (result.finalResult) {
          _isListening = false;
          _isProcessing = false;

          final words = result.recognizedWords;
          onResult(words, result.confidence);

          if (!completer.isCompleted) {
            completer.complete(words);
          }
        } else {
          // 部分结果
          onPartialResult?.call(result.recognizedWords);
        }
      },
      localeId: localeId,
      listenMode: stt.ListenMode.dictation,
      cancelOnError: false,
      partialResults: true,
      listenFor: duration,
      pauseFor: defaultPauseDuration,
    );

    return completer.future.timeout(
      duration,
      onTimeout: () {
        _isListening = false;
        _isProcessing = false;
        _lastError = '语音识别超时';
        return _lastRecognizedWords;
      },
    );
  }

  /// 检查是否为临时性错误
  bool _isTemporaryError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('network') ||
        errorStr.contains('timeout') ||
        errorStr.contains('temporary');
  }

  /// 停止识别
  Future<void> stop() async {
    await _speech.stop();
    _isListening = false;
    _isProcessing = false;
  }

  /// 取消识别
  Future<void> cancel() async {
    await _speech.cancel();
    _isListening = false;
    _isProcessing = false;
    _lastRecognizedWords = '';
    _lastConfidence = 0.0;
  }

  /// 获取置信度描述
  String getConfidenceDescription(double confidence) {
    if (confidence >= 0.8) return '非常高';
    if (confidence >= 0.6) return '高';
    if (confidence >= 0.4) return '中等';
    if (confidence >= 0.2) return '低';
    return '很低';
  }

  /// 获取置信度颜色
  int getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return 0xFF4CAF50; // Green
    if (confidence >= 0.6) return 0xFF8BC34A; // Light Green
    if (confidence >= 0.4) return 0xFFFF9800; // Orange
    if (confidence >= 0.2) return 0xFFFF5722; // Deep Orange
    return 0xFFF44336; // Red
  }

  /// 重置状态
  void reset() {
    _lastRecognizedWords = '';
    _lastConfidence = 0.0;
    _lastError = null;
  }
}

/// 语音识别异常
class SpeechException implements Exception {
  final String message;
  final SpeechErrorType type;

  SpeechException(this.message, this.type);

  @override
  String toString() => 'SpeechException: $message (type: $type)';
}

/// 简化的 SpeechService 别名，保持向后兼容
class SpeechService extends EnhancedSpeechService {
  // 继承所有增强功能
}
