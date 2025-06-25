import 'package:flutter/foundation.dart';
import '../core/utils/date_helper.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../core/enums/task_status.dart';
import '../core/enums/task_priority.dart';
import '../services/user_service.dart';
import 'auth_provider.dart';
import '../services/email_service.dart';

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

  // Create new task (with auth check) - CORRECTED
  Future<bool> createTask(TaskModel task) async {
    if (_authProvider?.user?.uid == null) {
      _setError('User not authenticated');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Use createdBy instead of creatorId
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

  // Update existing task (with ownership check) - CORRECTED
  Future<bool> updateTask(String taskId, Map<String, dynamic> updates) async {
    if (_authProvider?.user?.uid == null) {
      _setError('User not authenticated');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Check if user has permission to update task
      final task = await _taskService.getTaskById(taskId);
      if (task == null) {
        _setError('Task not found');
        _setLoading(false);
        return false;
      }

      final currentUserId = _authProvider!.user!.uid;
      // Use createdBy and assignedTo instead of creatorId and assignedUsers
      if (task.createdBy != currentUserId &&
          !task.assignedTo.contains(currentUserId)) {
        _setError('You don\'t have permission to update this task');
        _setLoading(false);
        return false;
      }

      await _taskService.updateTask(taskId, updates);
      loadTasks(); // Reload tasks to reflect changes
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update task: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete task (with ownership check) - CORRECTED
  Future<bool> deleteTask(String taskId) async {
    if (_authProvider?.user?.uid == null) {
      _setError('User not authenticated');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Check if user is the creator
      final task = await _taskService.getTaskById(taskId);
      if (task == null) {
        _setError('Task not found');
        _setLoading(false);
        return false;
      }

      // Use createdBy instead of creatorId
      if (task.createdBy != _authProvider!.user!.uid) {
        _setError('Only the task creator can delete this task');
        _setLoading(false);
        return false;
      }

      await _taskService.deleteTask(taskId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete task: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update task status (with permission check) - CORRECTED
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
      // Use createdBy and assignedTo instead of creatorId and assignedUsers
      if (task.createdBy != currentUserId &&
          !task.assignedTo.contains(currentUserId)) {
        _setError('You don\'t have permission to update this task');
        return false;
      }

      await _taskService.updateTaskStatus(taskId, status.value);
      return true;
    } catch (e) {
      _setError('Failed to update task status: $e');
      return false;
    }
  }

  // Assign task to users (creator only) - CORRECTED
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

      // Assign task first
      await _taskService.assignTask(taskId, userIds);

      // Send email notifications (don't block on failure)
      _sendAssignmentNotifications(task, userIds);

      return true;
    } catch (e) {
      _setError('Failed to assign task: $e');
      return false;
    }
  }

  Future<void> _sendAssignmentNotifications(
    TaskModel task,
    List<String> userIds,
  ) async {
    try {
      // Get assignee details
      final userService = UserService();
      final assignees = await userService.getUsersByIds(userIds);

      // Get creator details
      final creator = await userService.getUserById(task.createdBy);
      if (creator == null) return;

      // Send notifications
      await EmailService.sendTaskAssignmentNotification(
        task: task,
        assignees: assignees,
        creator: creator,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to send email notifications: $e');
      }
      // Don't throw error - email failure shouldn't affect task assignment
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

  // Get user's tasks (created or assigned) - CORRECTED
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

  Map<String, List<TaskModel>> getGroupedTasks() {
    final Map<String, List<TaskModel>> groupedTasks = {};

    // Sort filtered tasks by created date (newest first)
    final sortedTasks = List<TaskModel>.from(_filteredTasks);
    sortedTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Group tasks by date sections
    for (final task in sortedTasks) {
      final sectionHeader = DateHelper.getSectionHeader(task.createdAt);

      if (groupedTasks.containsKey(sectionHeader)) {
        groupedTasks[sectionHeader]!.add(task);
      } else {
        groupedTasks[sectionHeader] = [task];
      }
    }

    return groupedTasks;
  }

  // Get tasks created by user - CORRECTED
  List<TaskModel> getCreatedTasks() {
    if (_authProvider?.user?.uid == null) return [];

    final currentUserId = _authProvider!.user!.uid;
    return _tasks.where((task) => task.createdBy == currentUserId).toList();
  }

  // Get tasks assigned to user - CORRECTED
  List<TaskModel> getAssignedTasks() {
    if (_authProvider?.user?.uid == null) return [];

    final currentUserId = _authProvider!.user!.uid;
    return _tasks
        .where((task) => task.assignedTo.contains(currentUserId))
        .toList();
  }

  List<TaskModel> getStarredTasks() {
    return _tasks.where((task) => task.isStarred).toList();
  }

  Future<bool> toggleTaskStarred(String taskId) async {
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
        _setError('You don\'t have permission to star this task');
        return false;
      }

      await _taskService.toggleTaskStarred(taskId, !task.isStarred);
      return true;
    } catch (e) {
      _setError('Failed to toggle starred status: $e');
      return false;
    }
  }

  Map<String, List<TaskModel>> getGroupedStarredTasks() {
    final Map<String, List<TaskModel>> groupedTasks = {};
    final starredTasks = getStarredTasks();

    // Sort starred tasks by created date (newest first)
    starredTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Group tasks by date sections
    for (final task in starredTasks) {
      final sectionHeader = DateHelper.getSectionHeader(task.createdAt);

      if (groupedTasks.containsKey(sectionHeader)) {
        groupedTasks[sectionHeader]!.add(task);
      } else {
        groupedTasks[sectionHeader] = [task];
      }
    }

    return groupedTasks;
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
