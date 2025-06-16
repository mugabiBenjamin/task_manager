import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();

  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load user by ID
  Future<void> loadUser(String userId) async {
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

  @override
  void dispose() {
    super.dispose();
  }
}
