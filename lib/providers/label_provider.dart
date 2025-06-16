import 'package:flutter/foundation.dart';
import '../models/label_model.dart';
import '../services/label_service.dart';

class LabelProvider extends ChangeNotifier {
  final LabelService _labelService = LabelService();

  List<LabelModel> _labels = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<LabelModel> get labels => _labels;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load labels for current user
  void loadLabels(String userId) {
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
    _clearError();

    try {
      return await _labelService.getLabelById(labelId);
    } catch (e) {
      _setError('Failed to get label: $e');
      return null;
    }
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
