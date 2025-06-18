import 'package:flutter/foundation.dart';
import '../models/label_model.dart';
import '../services/label_service.dart';
import 'auth_provider.dart';

class LabelProvider extends ChangeNotifier {
  final LabelService _labelService = LabelService();

  List<LabelModel> _labels = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUserId;
  bool _isInitialized = false;
  AuthProvider? _authProvider;

  // Getters
  List<LabelModel> get labels => _labels;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;

  // Update auth provider dependency
  void updateAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;

    // Initialize labels if user is authenticated
    if (authProvider.isAuthenticated && authProvider.user != null) {
      final userId = authProvider.user!.uid;
      if (_currentUserId != userId) {
        initializeForUser(userId);
      }
    } else {
      // Clear data if user is not authenticated
      clearUserData();
    }
  }

  // Initialize labels when user authenticates
  Future<void> initializeForUser(String userId) async {
    if (_currentUserId == userId && _isInitialized) {
      return; // Already initialized for this user
    }

    _currentUserId = userId;
    _isInitialized = false;
    _clearLabels();

    loadLabels(userId);
    _isInitialized = true;
  }

  // Clear data when user logs out
  void clearUserData() {
    _currentUserId = null;
    _isInitialized = false;
    _clearLabels();
    _clearError();
    notifyListeners();
  }

  // Load labels for current user
  void loadLabels(String userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
    }

    _labelService
        .getLabelsByUser(userId)
        .listen(
          (labels) {
            _labels = labels;
            _clearError();
            notifyListeners();
          },
          onError: (error) {
            _setError('Failed to load labels: $error');
          },
        );
  }

  // Create new label
  Future<bool> createLabel(LabelModel label) async {
    if (!_isUserAuthenticated()) return false;

    _setLoading(true);
    _clearError();

    try {
      await _labelService.createLabel(label);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to create label: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update existing label
  Future<bool> updateLabel(String labelId, Map<String, dynamic> updates) async {
    if (!_isUserAuthenticated()) return false;

    _setLoading(true);
    _clearError();

    try {
      await _labelService.updateLabel(labelId, updates);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update label: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete label
  Future<bool> deleteLabel(String labelId) async {
    if (!_isUserAuthenticated()) return false;

    _setLoading(true);
    _clearError();

    try {
      await _labelService.deleteLabel(labelId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete label: $e');
      _setLoading(false);
      return false;
    }
  }

  // Get label by ID
  Future<LabelModel?> getLabelById(String labelId) async {
    if (!_isUserAuthenticated()) return null;

    _clearError();

    try {
      return await _labelService.getLabelById(labelId);
    } catch (e) {
      _setError('Failed to get label: $e');
      return null;
    }
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

  void _clearLabels() {
    _labels = [];
  }
}
