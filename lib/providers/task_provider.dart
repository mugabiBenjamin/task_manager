import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../core/enums/task_status.dart';
import '../core/enums/task_priority.dart';
import 'auth_provider.dart';

class TaskProvider extends ChangeNotifier {
  final TaskService _taskService = TaskService();
  AuthProvider? _authProvider;

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

  // Update auth provider dependency
  void updateAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;

    // Auto-load tasks when user authenticates
    if (_authProvider?.isAuthenticated == true &&
        _authProvider?.user?.uid != null) {
      loadTasks(_authProvider!.user!.uid);
    }

    // Clear tasks when user signs out
    if (_authProvider?.isAuthenticated == false) {
      _tasks.clear();
      _filteredTasks.clear();
      _clearError();
      notifyListeners();
    }
  }

  // Load tasks for current user (with auth check)
  void loadTasks([String? userId]) {
    final currentUserId = userId ?? _authProvider?.user?.uid;

    if (currentUserId == null) {
      _setError('User not authenticated');
      return;
    }

    _taskService
        .getTasksByUser(currentUserId)
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

  // Create new task (with auth check)
  Future<bool> createTask(TaskModel task) async {
    if (_authProvider?.user?.uid == null) {
      _setError('User not authenticated');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final taskWithCreator = task.copyWith(
        createdBy: _authProvider!.user!.uid,
      );
      await _taskService.createTask(taskWithCreator);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to create task: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update existing task (with ownership check)
  Future<bool> updateTask(String taskId, Map<String, dynamic> updates) async {
    if (_authProvider?.user?.uid == null) {
      _setError('User not authenticated');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final task = await _taskService.getTaskById(taskId);
      if (task == null) {
        _setError('Task not found');
        _setLoading(false);
        return false;
      }

      final currentUserId = _authProvider!.user!.uid;
      if (task.createdBy != currentUserId &&
          !task.assignedTo.contains(currentUserId)) {
        _setError('You don\'t have permission to update this task');
        _setLoading(false);
        return false;
      }

      await _taskService.updateTask(taskId, updates);
      // NEW: Reload tasks to ensure UI reflects the latest data
      loadTasks(currentUserId); // Reload tasks after update
      _setLoading(false);
      notifyListeners(); // NEW: Notify listeners to rebuild UI
      return true;
    } catch (e) {
      _setError('Failed to update task: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete task (with ownership check)
  Future<bool> deleteTask(String taskId) async {
    if (_authProvider?.user?.uid == null) {
      _setError('User not authenticated');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final task = await _taskService.getTaskById(taskId);
      if (task == null) {
        _setError('Task not found');
        _setLoading(false);
        return false;
      }

      if (task.createdBy != _authProvider!.user!.uid) {
        _setError('Only the task creator can delete this task');
        _setLoading(false);
        return false;
      }

      await _taskService.deleteTask(taskId);
      // NEW: Reload tasks after deletion
      loadTasks(_authProvider!.user!.uid);
      _setLoading(false);
      notifyListeners(); // NEW: Notify listeners to rebuild UI
      return true;
    } catch (e) {
      _setError('Failed to delete task: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update task status (with permission check)
  Future<bool> updateTaskStatus(String taskId, TaskStatus status) async {
    if (_authProvider?.user?.uid == null) {
      _setError('User not authenticated');
      return false;
    }

    _clearError();

    try {
      final task = await _taskService.getTaskById(taskId);
      if (task == null) {
        _setError('Task not found');
        return false;
      }

      final currentUserId = _authProvider!.user!.uid;
      if (task.createdBy != currentUserId &&
          !task.assignedTo.contains(currentUserId)) {
        _setError('You don\'t have permission to update this task');
        return false;
      }

      await _taskService.updateTaskStatus(taskId, status.value);
      // NEW: Reload tasks after status update
      loadTasks(currentUserId);
      notifyListeners(); // NEW: Notify listeners to rebuild UI
      return true;
    } catch (e) {
      _setError('Failed to update task status: $e');
      return false;
    }
  }

  // Assign task to users (creator only)
  Future<bool> assignTask(String taskId, List<String> userIds) async {
    if (_authProvider?.user?.uid == null) {
      _setError('User not authenticated');
      return false;
    }

    _clearError();

    try {
      final task = await _taskService.getTaskById(taskId);
      if (task == null) {
        _setError('Task not found');
        return false;
      }

      if (task.createdBy != _authProvider!.user!.uid) {
        _setError('Only the task creator can assign users');
        return false;
      }

      await _taskService.assignTask(taskId, userIds);
      // NEW: Reload tasks after assignment
      loadTasks(_authProvider!.user!.uid);
      notifyListeners(); // NEW: Notify listeners to rebuild UI
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

  // Get user's tasks (created or assigned)
  List<TaskModel> getUserTasks() {
    if (_authProvider?.user?.uid == null) return [];

    final currentUserId = _authProvider!.user!.uid;
    return _tasks
        .where(
          (task) =>
              task.createdBy == currentUserId ||
              task.assignedTo.contains(currentUserId),
        )
        .toList();
  }

  // Get tasks created by user
  List<TaskModel> getCreatedTasks() {
    if (_authProvider?.user?.uid == null) return [];

    final currentUserId = _authProvider!.user!.uid;
    return _tasks.where((task) => task.createdBy == currentUserId).toList();
  }

  // Get tasks assigned to user
  List<TaskModel> getAssignedTasks() {
    if (_authProvider?.user?.uid == null) return [];

    final currentUserId = _authProvider!.user!.uid;
    return _tasks
        .where((task) => task.assignedTo.contains(currentUserId))
        .toList();
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
