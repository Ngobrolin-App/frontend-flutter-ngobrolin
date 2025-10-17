import 'package:flutter/foundation.dart';

/// Base class for all ViewModels in the application.
/// Provides common functionality for state management.
class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _disposed = false;

  /// Sets the loading state and notifies listeners
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Sets an error message and notifies listeners
  void setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Clears any error message and notifies listeners
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Safely runs an async operation with loading state management
  Future<T?> runBusyFuture<T>(Future<T> Function() future) async {
    try {
      setLoading(true);
      clearError();
      final result = await future();
      return result;
    } catch (e) {
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
