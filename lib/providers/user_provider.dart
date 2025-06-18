import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'auth_provider.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();

  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _errorMessage;
  AuthProvider? _authProvider;

  // Getters
  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Update auth provider dependency
  void updateAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;

    // Clear users if not authenticated
    if (!authProvider.isAuthenticated) {
      _users = [];
      _clearError();
      notifyListeners();
    }
  }

  // Load user by ID
  Future<void> loadUser(String userId) async {
    if (!_isUserAuthenticated()) return;

    _setLoading(true);
    _clearError();

    try {
      final user = await _userService.getUserById(userId);
      if (user != null) {
        _users = [user];
      }
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load user: $e');
      _setLoading(false);
    }
  }

  // Load multiple users by IDs
  Future<void> loadUsersByIds(List<String> userIds) async {
    if (!_isUserAuthenticated()) return;

    _setLoading(true);
    _clearError();

    try {
      _users = await _userService.getUsersByIds(userIds);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load users: $e');
      _setLoading(false);
    }
  }

  // Search users by query
  Future<void> searchUsers(String query) async {
    if (!_isUserAuthenticated()) return;

    if (query.isEmpty) {
      _users = [];
      notifyListeners();
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      _users = await _userService.searchUsers(query);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to search users: $e');
      _setLoading(false);
    }
  }

  // Update user profile
  Future<bool> updateUser(String userId, Map<String, dynamic> updates) async {
    if (!_isUserAuthenticated()) return false;

    _setLoading(true);
    _clearError();

    try {
      await _userService.updateUser(userId, updates);
      await loadUser(userId); // Refresh user data
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update user: $e');
      _setLoading(false);
      return false;
    }
  }

  // Get user stream
  void streamUser(String userId) {
    if (!_isUserAuthenticated()) return;

    _userService
        .getUserStream(userId)
        .listen(
          (user) {
            if (user != null) {
              _users = [user];
              _clearError();
            } else {
              _users = [];
              _setError('User not found');
            }
            notifyListeners();
          },
          onError: (error) {
            _setError('Failed to stream user: $error');
          },
        );
  }

  // Check if user is authenticated
  bool _isUserAuthenticated() {
    if (_authProvider == null || !_authProvider!.isAuthenticated) {
      _setError('User not authenticated');
      return false;
    }
    return true;
  }

  // Private helper methods
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
