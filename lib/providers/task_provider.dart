import 'package:flutter/foundation.dart';
import '../core/utils/date_helper.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../core/enums/task_status.dart';
import '../core/enums/task_priority.dart';
import '../services/user_service.dart';
import 'auth_provider.dart';
import '../services/email_service.dart';
import '../services/invitation_service.dart';

class TaskProvider extends ChangeNotifier {
  final TaskService _taskService = TaskService();
  final UserService _userService = UserService();
  final InvitationService _invitationService = InvitationService();
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

    if (_authProvider?.isAuthenticated == true &&
        _authProvider?.user?.uid != null) {
      loadTasks(_authProvider!.user!.uid);
    }

    if (_authProvider?.isAuthenticated == false) {
      _tasks.clear();
      _filteredTasks.clear();
      _clearError();
      notifyListeners();
    }
  }

  // Load tasks for current user
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

  // Create new task
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

  // Update existing task
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
      if (task.createdBy != currentUserId) {
        _setError('Only the task creator can update task details');
        _setLoading(false);
        return false;
      }

      await _taskService.updateTask(taskId, updates);
      loadTasks();
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
        _setError('You don\'t have permission to update this task status');
        return false;
      }

      await _taskService.updateTaskStatus(taskId, status.value);
      return true;
    } catch (e) {
      _setError('Failed to update task status: $e');
      return false;
    }
  }

  // Assign task to users
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

      final availableUsers = await _userService.getAvailableUsersForTask('');
      final validUserIds = availableUsers.map((user) => user['id']).toList();
      final invalidUsers = userIds
          .where((id) => !validUserIds.contains(id))
          .toList();

      if (invalidUsers.isNotEmpty) {
        _setError('Some users are not available for assignment');
        return false;
      }

      await _taskService.assignTask(taskId, userIds);
      await _sendAssignmentNotifications(task, userIds);
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
      final assignees = await _userService.getAvailableUsersForTask('');
      final validAssignees = assignees
          .where((user) => userIds.contains(user['id']))
          .toList();
      final creatorData = await _userService.getUserById(task.createdBy);

      if (creatorData == null) {
        if (kDebugMode) {
          print('Creator data not found for task ${task.id}');
        }
        return;
      }

      final creator = {
        'id': creatorData.id,
        'email': creatorData.email,
        'displayName': creatorData.displayName,
        'emailNotifications': creatorData.emailNotifications,
      };

      await EmailService.sendTaskAssignmentNotification(
        task: task,
        assignees: validAssignees,
        creator: creator,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to send email notifications: $e');
      }
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
      if (_statusFilter != null && task.status != _statusFilter) {
        return false;
      }
      if (_priorityFilter != null && task.priority != _priorityFilter) {
        return false;
      }
      if (_labelFilter != null && !task.labels.contains(_labelFilter)) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!task.title.toLowerCase().contains(query) &&
            !task.description.toLowerCase().contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();

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

  // Get user's tasks
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
    final sortedTasks = List<TaskModel>.from(_filteredTasks);
    sortedTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
    starredTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
