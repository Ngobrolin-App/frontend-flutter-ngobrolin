import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

/// Base class for all ViewModels in the application.
class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _successMessage;
  String? get successMessage => _successMessage;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _disposed = false;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setSuccess(String? message) {
    _successMessage = message;
    notifyListeners();
  }

  void setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Safely runs an async operation with loading state management and flexible logging
  Future<T?> runBusyFuture<T>(
    Future<T> Function() future, {
    String? logName, // Example: 'SettingsViewModel'
    String? logContext, // Example: 'initSettings()'
  }) async {
    try {
      setLoading(true);
      clearError();
      final result = await future();
      return result;
    } catch (e, stackTrace) {
      // If logName or logContext is filled, print the log
      if (logContext != null || logName != null) {
        developer.log(
          '${logContext ?? "Unknown Method"} error: $e',
          name: logName ?? 'BaseViewModel',
          error: e,
          stackTrace: stackTrace, // So it's easy to track in the console
        );
      }

      setError(e.toString());
      return null;
    } finally {
      setLoading(false);
    }
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
