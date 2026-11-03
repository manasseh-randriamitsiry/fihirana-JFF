import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:fihirana/l10n/app_localizations.dart';

/// Centralized error handling utility
class ErrorHandler {
  /// Handle errors in a consistent way
  static void handleError(
    dynamic error, {
    String? message,
    String? title,
    VoidCallback? onRetry,
    bool showSnackbar = true,
    bool logError = true,
  }) {
    if (logError) {
      _logError(error, message);
    }

    if (showSnackbar) {
      _showErrorSnackbar(error, message ?? title, null);
    }
  }

  /// Handle errors with context (for widgets)
  static void handleErrorWithContext(
    BuildContext context,
    dynamic error, {
    String? message,
    String? title,
    VoidCallback? onRetry,
    bool showDialog = false,
    bool showSnackbar = true,
    bool logError = true,
  }) {
    if (logError) {
      _logError(error, message);
    }

    if (showDialog && context.mounted) {
      _showErrorDialog(context, error,
          title: title, message: message, onRetry: onRetry);
    } else if (showSnackbar) {
      _showErrorSnackbar(error, message ?? title, context);
    }
  }

  /// Log error to console and error reporting service
  static void _logError(dynamic error, String? message,
      [StackTrace? stackTrace]) {
    final errorMessage = message ?? 'An error occurred';
    if (kDebugMode) {
      print('❌ $errorMessage: $error');
      print('Stack trace: ${stackTrace ?? StackTrace.current}');
    }

    // Send to Firebase Crashlytics
    try {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace ?? StackTrace.current,
        reason: errorMessage,
        fatal: false,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to send error to Crashlytics: $e');
      }
    }
  }

  /// Install the widget-level error boundary.
  ///
  /// Flutter sends build failures to [ErrorWidget.builder], which is the only
  /// hook that can replace them: left alone, a failed subtree shows the red
  /// box in debug and renders nothing in release. Debug keeps the red box
  /// because it carries the diagnostic the developer needs.
  static void installWidgetErrorBoundary() {
    if (kDebugMode) return;

    ErrorWidget.builder = (FlutterErrorDetails details) {
      _logError(details.exception, 'Widget build failed', details.stack);
      return const Material(
        child: Center(
          child: Icon(Icons.error_outline, size: 48, color: Colors.red),
        ),
      );
    };
  }

  /// Show error snackbar
  static void _showErrorSnackbar(
      dynamic error, String? message, BuildContext? context) {
    final errorMessage = _getErrorMessage(error, message);
    final title =
        context != null ? AppLocalizations.of(context).error : 'Error';
    Get.snackbar(
      title,
      errorMessage,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade900,
      duration: const Duration(seconds: 4),
      icon: Icon(
        Icons.error_outline,
        color: Colors.red.shade900,
      ),
    );
  }

  /// Show error dialog
  static void _showErrorDialog(
    BuildContext context,
    dynamic error, {
    String? title,
    String? message,
    VoidCallback? onRetry,
  }) {
    final errorMessage = _getErrorMessage(error, message);
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title ?? l10n.error),
        content: Text(errorMessage),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: Text(l10n.retry),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  /// Get user-friendly error message
  static String _getErrorMessage(dynamic error, String? customMessage) {
    if (customMessage != null) return customMessage;

    if (error is String) return error;

    // Handle common error types
    if (error.toString().contains('network') ||
        error.toString().contains('connection')) {
      return 'Network connection error. Please check your internet connection.';
    }

    if (error.toString().contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    if (error.toString().contains('permission') ||
        error.toString().contains('denied')) {
      return 'Permission denied. Please check app permissions.';
    }

    if (error.toString().contains('not found') ||
        error.toString().contains('404')) {
      return 'Resource not found. Please try again later.';
    }

    // Default error message
    return 'Something went wrong. Please try again.';
  }

  /// Handle async operations with error handling
  static Future<T?> handleAsync<T>(
    Future<T> Function() operation, {
    String? errorMessage,
    bool showError = true,
    T? defaultValue,
  }) async {
    try {
      return await operation();
    } catch (e) {
      if (showError) {
        handleError(e, message: errorMessage);
      }
      return defaultValue;
    }
  }
}
