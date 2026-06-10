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
  static void _logError(dynamic error, String? message) {
    final errorMessage = message ?? 'An error occurred';
    if (kDebugMode) {
      print('❌ $errorMessage: $error');
      print('Stack trace: ${StackTrace.current}');
    }

    // Send to Firebase Crashlytics
    try {
      FirebaseCrashlytics.instance.recordError(
        error,
        StackTrace.current,
        reason: errorMessage,
        fatal: false,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to send error to Crashlytics: $e');
      }
    }
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

  /// Wrap widget with error boundary
  static Widget withErrorBoundary(
    Widget child, {
    Widget? errorWidget,
    VoidCallback? onError,
  }) {
    return ErrorBoundary(
      errorWidget: errorWidget,
      onError: onError,
      child: child,
    );
  }
}

/// Error boundary widget for catching widget errors
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? errorWidget;
  final VoidCallback? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorWidget,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Reset error state when widget is rebuilt
    _hasError = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      widget.onError?.call();
      return widget.errorWidget ??
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                SizedBox(height: 16),
                Text('Something went wrong'),
              ],
            ),
          );
    }

    return widget.child;
  }

  void didCatchError(Object error, StackTrace stackTrace) {
    setState(() => _hasError = true);
    ErrorHandler._logError(error, 'Widget error boundary caught error');

    // Send to Firebase Crashlytics
    try {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: 'Widget error boundary caught error',
        fatal: false,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to send error boundary error to Crashlytics: $e');
      }
    }
  }
}
