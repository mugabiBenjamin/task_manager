import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../routes/app_routes.dart';
import '../services/invitation_service.dart';
import '../services/user_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  late final UserService _userService;
  late final InvitationService _invitationService;
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

  UserModel? _cachedUserModel;
  bool _hasLoadedUserData = false;

  AuthProvider() {
    _initializeServices();
    _initializeAuthListener();
  }

  void _initializeServices() {
    _userService = UserService();
    _invitationService = InvitationService();

    // Set up the circular dependencies after creation
    _userService.setInvitationService(_invitationService);
    _invitationService.setUserService(_userService);
  }

  void _initializeAuthListener() {
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      if (user != null) {
        _resetFailedAttempts();
        if (!_hasLoadedUserData) {
          loadUserData();
        }
        _navigateToTaskList();
      } else {
        _userModel = null;
        _clearUserCache();
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

  void updateUserModel(UserModel userModel) {
    _userModel = userModel;
    _cachedUserModel = userModel;
    _hasLoadedUserData = true;
    notifyListeners();
  }

  Future<void> loadUserData() async {
    if (_hasLoadedUserData && _cachedUserModel != null) {
      _userModel = _cachedUserModel;
      notifyListeners();
      return;
    }

    try {
      _userModel = await _authService.getCurrentUserData();
      if (_userModel != null) {
        _cachedUserModel = _userModel;
        _hasLoadedUserData = true;
      } else if (_user != null) {
        _userModel = UserModel.fromFirebaseUser(_user!);
        _cachedUserModel = _userModel;
      }
      notifyListeners();
    } catch (e) {
      if (_user != null) {
        _userModel = UserModel.fromFirebaseUser(_user!);
        _cachedUserModel = _userModel;
        notifyListeners();
      } else {
        _setError('Failed to load user data: $e');
      }
    }
  }

  void _clearUserCache() {
    _cachedUserModel = null;
    _hasLoadedUserData = false;
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
        case 'requires-recent-login':
          return 'Please sign out and sign back in to complete this action.';
        case 'expired-action-code':
          return 'This verification link has expired. Please request a new one.';
        case 'invalid-action-code':
          return 'This verification link is invalid. Please request a new one.';
        case 'missing-email':
          return 'Please enter your email address.';
        case 'missing-password':
          return 'Please enter your password.';
        case 'credential-already-in-use':
          return 'This account is already linked to another user.';
        case 'account-exists-with-different-credential':
          return 'An account with this email already exists. Please sign in with your email and password.';
        default:
          return 'Authentication failed. Please try again.';
      }
    }
    if (error.toString().contains('Invalid or expired invitation')) {
      return 'The invitation link is invalid or has expired.';
    }
    if (error.toString().contains('Failed to accept invitation')) {
      return 'Failed to accept invitation. Please try again.';
    }
    return error.toString().replaceAll('Exception: ', '');
  }

  bool _canRetryNow() {
    if (_lastFailedAttempt == null) return true;
    final delay = Duration(seconds: _getRetryDelaySeconds());
    return DateTime.now().difference(_lastFailedAttempt!) >= delay;
  }

  int _getRetryDelaySeconds() {
    if (_failedAttempts <= 2) return 0;
    if (_failedAttempts <= 4) return 30;
    if (_failedAttempts <= 6) return 60;
    return 300;
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
    String? invitationToken,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signUpWithEmailPassword(
        email: email,
        password: password,
        displayName: displayName,
        invitationToken: invitationToken,
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

  Future<bool> signInWithGoogle({String? invitationToken}) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.signInWithGoogle(
        invitationToken: invitationToken,
      );
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

  Future<void> refreshEmailVerificationStatus() async {
    if (_user == null) return;

    try {
      await _user!.reload();
      _user = _authService.currentUser;

      if (_userModel != null) {
        _userModel = _userModel!.copyWith(
          isEmailVerified: _user!.emailVerified,
        );
        _cachedUserModel = _userModel;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to refresh email verification: $e');
    }
  }

  Future<bool> sendEmailVerification() async {
    _clearError();

    try {
      await _authService.sendEmailVerification();
      _startPeriodicVerificationCheck();
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

  Future<bool> verifyInvitationToken(String token, String displayName) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _invitationService.acceptInvitation(
        token,
        displayName,
      );
      _setLoading(false);
      return success;
    } catch (e) {
      _setError(_parseFirebaseError(e));
      _setLoading(false);
      return false;
    }
  }

  Future<bool> acceptInvitation(String token, String displayName) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _invitationService.acceptInvitation(
        token,
        displayName,
      );
      if (success) {
        debugPrint('Invitation accepted for token: $token');
        await loadUserData();
        // ADDED: Navigate to sign-in or token-entry screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final context = navigatorKey?.currentContext;
          if (context != null) {
            Navigator.of(context).pushNamed(
              AppRoutes.login,
            ); // Navigate to login screen for manual sign-in
          }
        });
      }
      _setLoading(false);
      return success;
    } catch (e) {
      debugPrint('Failed to accept invitation for token: $token: $e');
      _setError(_parseFirebaseError(e));
      _setLoading(false);
      return false;
    }
  }

  Future<bool> declineInvitation(String token) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _invitationService.declineInvitation(token);
      _setLoading(false);
      return success;
    } catch (e) {
      _setError(_parseFirebaseError(e));
      _setLoading(false);
      return false;
    }
  }

  Timer? _verificationCheckTimer;

  void _startPeriodicVerificationCheck() {
    _verificationCheckTimer?.cancel();
    _verificationCheckTimer = Timer.periodic(const Duration(seconds: 5), (
      timer,
    ) async {
      await refreshEmailVerificationStatus();
      if (_userModel?.isEmailVerified == true || timer.tick > 120) {
        timer.cancel();
      }
    });
  }

  Future<bool> deleteAccount() async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _authService.deleteAccount();
      if (success) {
        _user = null;
        _userModel = null;
        _clearUserCache();
        _resetFailedAttempts();
        _setLoading(false);
        return true;
      }
      return false;
    } catch (e) {
      _setError(_parseFirebaseError(e));
      _setLoading(false);
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
