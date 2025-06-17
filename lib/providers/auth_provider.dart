import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../routes/app_routes.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _errorMessage;
  int _failedAttempts = 0;
  DateTime? _lastFailedAttempt;

  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get shouldShowRetryDelay => _failedAttempts >= 3;

  AuthProvider() {
    _initializeAuthListener();
  }

  void _initializeAuthListener() {
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      if (user != null) {
        _resetFailedAttempts();
        loadUserData();
        _navigateToTaskList();
      } else {
        _userModel = null;
        _navigateToLogin();
      }
      notifyListeners();
    });
  }

  void _navigateToTaskList() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey?.currentContext;
      if (context != null) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.taskList, (route) => false);
      }
    });
  }

  void _navigateToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey?.currentContext;
      if (context != null) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      }
    });
  }

  static GlobalKey<NavigatorState>? navigatorKey;
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
  }

  Future<void> loadUserData() async {
    try {
      _userModel = await _authService.getCurrentUserData();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load user data: $e');
    }
  }

  // Enhanced error parsing
  String _parseFirebaseError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          return 'Invalid email or password. Please check your credentials and try again.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please wait a few minutes before trying again.';
        case 'network-request-failed':
          return 'Network error. Please check your connection and try again.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Password is too weak. Please choose a stronger password.';
        case 'email-already-in-use':
          return 'An account with this email already exists.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled. Please contact support.';
        default:
          return 'Authentication failed. Please try again.';
      }
    }
    return error.toString().replaceAll('Exception: ', '');
  }

  // Retry logic with exponential backoff
  bool _canRetryNow() {
    if (_lastFailedAttempt == null) return true;

    final delay = Duration(seconds: _getRetryDelaySeconds());
    return DateTime.now().difference(_lastFailedAttempt!) >= delay;
  }

  int _getRetryDelaySeconds() {
    if (_failedAttempts <= 2) return 0;
    if (_failedAttempts <= 4) return 30;
    if (_failedAttempts <= 6) return 60;
    return 300; // 5 minutes
  }

  void _recordFailedAttempt() {
    _failedAttempts++;
    _lastFailedAttempt = DateTime.now();
  }

  void _resetFailedAttempts() {
    _failedAttempts = 0;
    _lastFailedAttempt = null;
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signUpWithEmailPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      _resetFailedAttempts();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(_parseFirebaseError(e));
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    if (!_canRetryNow()) {
      final remainingSeconds =
          _getRetryDelaySeconds() -
          DateTime.now().difference(_lastFailedAttempt!).inSeconds;
      _setError('Please wait ${remainingSeconds}s before trying again.');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      );
      _resetFailedAttempts();
      _setLoading(false);
      return true;
    } catch (e) {
      _recordFailedAttempt();
      _setError(_parseFirebaseError(e));
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.signInWithGoogle();
      _resetFailedAttempts();
      _setLoading(false);
      return result != null;
    } catch (e) {
      _setError(_parseFirebaseError(e));
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signOut();
      _user = null;
      _userModel = null;
      _resetFailedAttempts();
      _setLoading(false);
    } catch (e) {
      _setError(_parseFirebaseError(e));
      _setLoading(false);
    }
  }

  Future<bool> sendEmailVerification() async {
    _clearError();

    try {
      await _authService.sendEmailVerification();
      return true;
    } catch (e) {
      _setError(_parseFirebaseError(e));
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    _clearError();

    try {
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _setError(_parseFirebaseError(e));
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
