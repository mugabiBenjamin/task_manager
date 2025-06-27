import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_helper.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/tasks/task_form.dart';
import '../../widgets/common/app_drawer.dart';

class TaskDetailsScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailsScreen({super.key, required this.taskId});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final GlobalKey<TaskFormState> _formKey = GlobalKey<TaskFormState>();
  TaskModel? _task;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isCreator = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTask();
    });
  }

  Future<void> _loadTask() async {
    final taskProvider = context.read<TaskProvider>();
    final authProvider = context.read<AuthProvider>();
    try {
      final task = await taskProvider.getTaskById(widget.taskId);
      if (task != null) {
        setState(() {
          _task = task;
          _isCreator = authProvider.user?.uid == task.createdBy;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Task not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load task: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.editTaskTitle),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          if (_task != null && _isCreator)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteDialog(context),
            ),
          if (_task != null && _isCreator)
            IconButton(
              icon: const Icon(Icons.assignment),
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.taskAssignment,
                arguments: {
                  'taskId': widget.taskId,
                  'currentAssignees': _task!.assignedTo,
                },
              ),
            ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: AppConstants.errorColor),
              ),
            )
          : _task != null
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                children: [
                  TaskForm(
                    key: _formKey,
                    task: _task,
                    isEditing: _isCreator,
                    submitButtonText: _isCreator
                        ? 'Update Task'
                        : 'Update Status',
                    onSubmit: (updatedTask) =>
                        _updateTask(context, updatedTask),
                    onFormReady: () {},
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Consumer<TaskProvider>(
                    builder: (context, taskProvider, child) {
                      return CustomButton(
                        text: taskProvider.isLoading
                            ? 'Updating...'
                            : _isCreator
                            ? 'Update Task'
                            : 'Update Status',
                        onPressed: taskProvider.isLoading
                            ? null
                            : () {
                                final authProvider = context
                                    .read<AuthProvider>();
                                if (authProvider.user?.uid != null) {
                                  _formKey.currentState?.submitForm(
                                    authProvider.user!.uid,
                                  );
                                }
                              },
                      );
                    },
                  ),
                  Consumer<TaskProvider>(
                    builder: (context, taskProvider, child) {
                      if (taskProvider.errorMessage != null) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            top: AppConstants.defaultPadding,
                          ),
                          child: Text(
                            taskProvider.errorMessage!,
                            style: const TextStyle(
                              color: AppConstants.errorColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  void _updateTask(BuildContext context, TaskModel task) async {
    final taskProvider = context.read<TaskProvider>();
    final authProvider = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (authProvider.user?.uid == null) {
      return;
    }

    bool success;
    if (_isCreator) {
      final updates = {
        'title': task.title,
        'description': task.description,
        'status': task.status.value,
        'priority': task.priority.value,
        'startDate': task.startDate != null
            ? DateHelper.parseDate(
                DateFormat('yyyy-MM-dd').format(task.startDate!),
              )
            : null,
        'dueDate': task.dueDate != null
            ? DateHelper.parseDate(
                DateFormat('yyyy-MM-dd').format(task.dueDate!),
              )
            : null,
        'assignedTo': task.assignedTo,
        'labels': task.labels,
        'updatedAt': DateTime.now(),
      };
      success = await taskProvider.updateTask(widget.taskId, updates);
    } else {
      success = await taskProvider.updateTaskStatus(widget.taskId, task.status);
    }

    if (success && mounted) {
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text(AppConstants.successMessage)),
      );
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final taskProvider = context.read<TaskProvider>();
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              final success = await taskProvider.deleteTask(widget.taskId);
              if (success && mounted) {
                navigator.pop(); // Close dialog
                navigator.pop(); // Close details screen
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Task deleted successfully')),
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppConstants.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}
