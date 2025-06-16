import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_helper.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/tasks/task_form.dart';

class TaskDetailsScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailsScreen({super.key, required this.taskId});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  TaskModel? _task;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  Future<void> _loadTask() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    try {
      final task = await taskProvider.getTaskById(widget.taskId);
      if (task != null) {
        setState(() {
          _task = task;
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
        actions: [
          if (_task != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteDialog(context),
            ),
        ],
      ),
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
                    task: _task,
                    submitButtonText: 'Update Task',
                    onSubmit: (updatedTask) =>
                        _updateTask(context, updatedTask),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Consumer<TaskProvider>(
                    builder: (context, taskProvider, child) {
                      return CustomButton(
                        text: taskProvider.isLoading
                            ? 'Updating...'
                            : 'Update Task',
                        onPressed: taskProvider.isLoading
                            ? null
                            : () => _updateTask(context, _task!),
                      );
                    },
                  ),
                  if (Provider.of<TaskProvider>(context).errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppConstants.defaultPadding,
                      ),
                      child: Text(
                        Provider.of<TaskProvider>(context).errorMessage!,
                        style: const TextStyle(color: AppConstants.errorColor),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  void _updateTask(BuildContext context, TaskModel task) async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

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
          ? DateHelper.parseDate(DateFormat('yyyy-MM-dd').format(task.dueDate!))
          : null,
      'assignedTo': task.assignedTo,
      'labels': task.labels,
      'updatedAt': DateTime.now(),
    };

    final success = await taskProvider.updateTask(widget.taskId, updates);
    if (success) {
      if (!mounted)
        return; // Guard against using context if widget is unmounted
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
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
              final taskProvider = Provider.of<TaskProvider>(
                context,
                listen: false,
              );
              final success = await taskProvider.deleteTask(widget.taskId);
              if (success && mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close details screen
                ScaffoldMessenger.of(context).showSnackBar(
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
