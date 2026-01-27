import 'package:flutter/foundation.dart';

/// Application-wide logging utility.
/// Automatically filters debug logs in production builds.
class AppLogger {
  /// Logs debug information (only shown in debug mode).
  static void debug(String message, [String? tag]) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag]' : '[DEBUG]';
      debugPrint('$prefix $message');
    }
  }

  /// Logs informational messages (only shown in debug mode).
  static void info(String message, [String? tag]) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag]' : '[INFO]';
      debugPrint('$prefix $message');
    }
  }

  /// Logs warnings (shown in all modes).
  static void warning(String message, [String? tag]) {
    final prefix = tag != null ? '[$tag]' : '[WARNING]';
    debugPrint('$prefix $message');
  }

  /// Logs errors with optional error object and stack trace.
  /// In production, this should integrate with crash reporting (Firebase Crashlytics).
  static void error(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    final prefix = tag != null ? '[$tag]' : '[ERROR]';
    debugPrint('$prefix $message');
    
    if (error != null) {
      debugPrint('Error details: $error');
    }
    
    if (stackTrace != null) {
      debugPrint('Stack trace:\n$stackTrace');
    }

    // TODO: In production, send to Firebase Crashlytics
    // if (kReleaseMode) {
    //   FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: message);
    // }
  }

  /// Logs network requests (only in debug mode).
  static void network(String method, String url, {int? statusCode, dynamic body}) {
    if (kDebugMode) {
      debugPrint('[NETWORK] $method $url');
      if (statusCode != null) {
        debugPrint('[NETWORK] Status: $statusCode');
      }
      if (body != null) {
        debugPrint('[NETWORK] Body: $body');
      }
    }
  }

  /// Logs database operations (only in debug mode).
  static void database(String operation, {String? table, dynamic data}) {
    if (kDebugMode) {
      final tableInfo = table != null ? ' on $table' : '';
      debugPrint('[DATABASE] $operation$tableInfo');
      if (data != null) {
        debugPrint('[DATABASE] Data: $data');
      }
    }
  }

  /// Logs user actions (for analytics/debugging).
  static void userAction(String action, {Map<String, dynamic>? properties}) {
    if (kDebugMode) {
      debugPrint('[USER_ACTION] $action');
      if (properties != null) {
        debugPrint('[USER_ACTION] Properties: $properties');
      }
    }

    // TODO: In production, send to analytics
    // Analytics.logEvent(action, parameters: properties);
  }
}
