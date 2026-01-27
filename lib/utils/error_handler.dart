import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized error handling utility for the application.
/// Provides user-friendly error messages and handles different error types.
class ErrorHandler {
  /// Shows an error message to the user via SnackBar.
  static void handleError(
    BuildContext context,
    dynamic error, {
    String? customMessage,
    Duration duration = const Duration(seconds: 4),
  }) {
    final String userMessage = _getUserFriendlyMessage(error, customMessage);
    
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(userMessage),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
        duration: duration,
      ),
    );
  }

  /// Shows a success message to the user.
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        duration: duration,
      ),
    );
  }

  /// Shows a warning message to the user.
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange[700],
        behavior: SnackBarBehavior.floating,
        duration: duration,
      ),
    );
  }

  /// Converts errors to user-friendly messages.
  static String _getUserFriendlyMessage(dynamic error, String? customMessage) {
    if (customMessage != null && customMessage.isNotEmpty) {
      return customMessage;
    }

    if (error is SocketException) {
      return 'No internet connection. Please check your network and try again.';
    }
    
    if (error is TimeoutException) {
      return 'Request timed out. Please try again.';
    }
    
    if (error is HttpException) {
      return 'Unable to connect to server. Please try again later.';
    }
    
    if (error is PostgrestException) {
      // Handle specific database errors
      if (error.code == '23505') {
        return 'This item already exists.';
      }
      return 'Database error: ${error.message}';
    }
    
    if (error is FormatException) {
      return 'Invalid data format. Please check your input.';
    }

    // Generic fallback
    return 'An error occurred. Please try again.';
  }

  /// Shows an error dialog for critical errors that need user attention.
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) async {
    if (!context.mounted) return;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onAction();
              },
              child: Text(actionLabel),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
