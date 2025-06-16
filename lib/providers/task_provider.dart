import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../core/enums/task_status.dart';
import '../core/enums/task_priority.dart';

class TaskProvider extends ChangeNotifier {
  final TaskService _taskService = TaskService();

  List<TaskModel> _tasks = [];
  List<TaskModel> _filteredTasks = [];
  bool _isLoading = false;
  String? _errorMessage;
  TaskStatus? _statusFilter;
  TaskPriority? _priorityFilter;
  String? _labelFilter;
  String _searchQuery = '';

  // Getters
  List<TaskModel> get tasks => _filteredTasks;
  List<TaskModel> get allTasks => _tasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  TaskStatus? get statusFilter => _statusFilter;
  TaskPriority? get priorityFilter => _priorityFilter;
  String? get labelFilter => _labelFilter;
  String get searchQuery => _searchQuery;

  // Load tasks for current user
  void loadTasks(String userId) {
    _taskService
        .getTasksByUser(userId)
        .listen(
          (tasks) {
            _tasks = tasks;
            _applyFilters();
            _clearError();
            notifyListeners();
          },
          onError: (error) {
            _setError('Failed to load tasks: $error');
          },
        );
  }

  // Create new task
  Future<bool> createTask(TaskModel task) async {
    _setLoading(true);
    _clearError();

    try {
      await _taskService.createTask(task);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to create task: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update existing task
  Future<bool> updateTask(String taskId, Map<String, dynamic> updates) async {
    _setLoading(true);
    _clearError();

    try {
      await _taskService.updateTask(taskId, updates);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update task: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete task
  Future<bool> deleteTask(String taskId) async {
    _setLoading(true);
    _clearError();

    try {
      await _taskService.deleteTask(taskId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete task: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update task status
  Future<bool> updateTaskStatus(String taskId, TaskStatus status) async {
    _clearError();

    try {
      await _taskService.updateTaskStatus(taskId, status.value);
      return true;
    } catch (e) {
      _setError('Failed to update task status: $e');
      return false;
    }
  }

  // Assign task to users
  Future<bool> assignTask(String taskId, List<String> userIds) async {
    _clearError();

    try {
      await _taskService.assignTask(taskId, userIds);
      return true;
    } catch (e) {
      _setError('Failed to assign task: $e');
      return false;
    }
  }

  // Get task by ID
  Future<TaskModel?> getTaskById(String taskId) async {
    _clearError();

    try {
      return await _taskService.getTaskById(taskId);
    } catch (e) {
      _setError('Failed to get task: $e');
      return null;
    }
  }

  // Filter methods
  void setStatusFilter(TaskStatus? status) {
    _statusFilter = status;
    _applyFilters();
    notifyListeners();
  }

  void setPriorityFilter(TaskPriority? priority) {
    _priorityFilter = priority;
    _applyFilters();
    notifyListeners();
  }

  void setLabelFilter(String? labelId) {
    _labelFilter = labelId;
    _applyFilters();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _statusFilter = null;
    _priorityFilter = null;
    _labelFilter = null;
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }

  // Apply all active filters
  void _applyFilters() {
    _filteredTasks = _tasks.where((task) {
      // Status filter
      if (_statusFilter != null && task.status != _statusFilter) {
        return false;
      }

      // Priority filter
      if (_priorityFilter != null && task.priority != _priorityFilter) {
        return false;
      }

      // Label filter
      if (_labelFilter != null && !task.labels.contains(_labelFilter)) {
        return false;
      }

      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!task.title.toLowerCase().contains(query) &&
            !task.description.toLowerCase().contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort by created date (newest first)
    _filteredTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Get tasks by status
  List<TaskModel> getTasksByStatus(TaskStatus status) {
    return _tasks.where((task) => task.status == status).toList();
  }

  // Get tasks by priority
  List<TaskModel> getTasksByPriority(TaskPriority priority) {
    return _tasks.where((task) => task.priority == priority).toList();
  }

  // Get overdue tasks
  List<TaskModel> getOverdueTasks() {
    final now = DateTime.now();
    return _tasks.where((task) {
      return task.dueDate != null &&
          task.dueDate!.isBefore(now) &&
          task.status != TaskStatus.complete;
    }).toList();
  }

  // Get tasks due today
  List<TaskModel> getTasksDueToday() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _tasks.where((task) {
      return task.dueDate != null &&
          task.dueDate!.isAfter(startOfDay) &&
          task.dueDate!.isBefore(endOfDay) &&
          task.status != TaskStatus.complete;
    }).toList();
  }

  // Get task statistics
  Map<String, int> getTaskStatistics() {
    return {
      'total': _tasks.length,
      'not_started': getTasksByStatus(TaskStatus.notStarted).length,
      'in_progress': getTasksByStatus(TaskStatus.inProgress).length,
      'complete': getTasksByStatus(TaskStatus.complete).length,
      'overdue': getOverdueTasks().length,
      'due_today': getTasksDueToday().length,
    };
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
