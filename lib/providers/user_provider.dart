import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';

class UserProvider with ChangeNotifier {
  final UserService _userService = UserService();
  UserModel? _currentUser;
  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchCurrentUser(String userId) async {
    _setLoading(true);
    try {
      final user = await _userService.getUserById(userId);
      _currentUser = user;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to fetch user: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateUserProfile(
    String userId, {
    String? displayName,
    String? email,
    String? photoUrl,
  }) async {
    _setLoading(true);
    try {
      await _userService.updateUser(userId, {
        if (displayName != null) 'displayName': displayName,
        if (email != null) 'email': email,
        if (photoUrl != null) 'photoUrl': photoUrl,
      });
      // Fetch updated user to reflect changes
      final updatedUser = await _userService.getUserById(userId);
      _currentUser = updatedUser;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update profile: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> searchUsers(String query) async {
    _setLoading(true);
    try {
      final users = await _userService.searchUsers(query);
      _users = users;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to search users: $e';
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
