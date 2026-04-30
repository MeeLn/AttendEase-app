import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FaceRecognitionResult {
  const FaceRecognitionResult({
    required this.success,
    required this.message,
    required this.faceRegistered,
  });

  final bool success;
  final String message;
  final bool faceRegistered;
}

class FaceRecognitionService {
  static const MethodChannel _channel = MethodChannel(
    'attendease/face_recognition',
  );

  static Future<bool> hasRegisteredFace(String userKey) async {
    if (!_isAndroid) {
      return false;
    }
    final exists = await _channel.invokeMethod<bool>('hasRegisteredFace', {
      'userKey': userKey,
    });
    return exists ?? false;
  }

  static Future<FaceRecognitionResult> registerFace(String userKey) {
    return _invoke('registerFace', userKey);
  }

  static Future<FaceRecognitionResult> recognizeFace(String userKey) {
    return _invoke('recognizeFace', userKey);
  }

  static Future<FaceRecognitionResult> _invoke(
    String method,
    String userKey,
  ) async {
    if (!_isAndroid) {
      return const FaceRecognitionResult(
        success: false,
        message: 'Face recognition is currently available only on Android.',
        faceRegistered: false,
      );
    }
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(method, {
        'userKey': userKey,
      });
      return FaceRecognitionResult(
        success: result?['success'] == true,
        message:
            (result?['message'] as String?) ?? 'No response from recognizer.',
        faceRegistered: result?['faceRegistered'] == true,
      );
    } on PlatformException catch (error) {
      return FaceRecognitionResult(
        success: false,
        message: error.message ?? 'Face recognition failed.',
        faceRegistered: false,
      );
    } on MissingPluginException {
      return const FaceRecognitionResult(
        success: false,
        message: 'Face recognition plugin is unavailable on this platform.',
        faceRegistered: false,
      );
    }
  }

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}
