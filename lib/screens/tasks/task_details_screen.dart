import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/task_status.dart';
import '../../core/utils/date_helper.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../providers/task_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart'; // NEW: Import AuthProvider
import '../../routes/app_routes.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/tasks/status_dropdown.dart';

class TaskDetailsScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailsScreen({super.key, required this.taskId});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  late Future<TaskModel?> _taskFuture;
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  TaskStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _taskFuture = context.read<TaskProvider>().getTaskById(widget.taskId);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final userProvider = context.watch<UserProvider>();
    final authProvider = context
        .watch<AuthProvider>(); // NEW: Access AuthProvider

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          // CHANGED: Use authProvider instead of taskProvider and simplify task creator check
          if (authProvider.isAuthenticated)
            FutureBuilder<TaskModel?>(
              future: taskProvider.getTaskById(widget.taskId),
              builder: (context, snapshot) {
                if (snapshot.hasData &&
                    snapshot.data != null &&
                    snapshot.data!.createdBy == authProvider.user!.uid) {
                  return IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _showDeleteDialog(context),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
        ],
      ),
      body: FutureBuilder<TaskModel?>(
        future: _taskFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingWidget());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: AppConstants.errorColor),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Task not found'));
          }

          final task = snapshot.data!;
          _descriptionController.text = task.description;
          _selectedStatus ??= task.status;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title, style: AppConstants.headlineStyle),
                  const SizedBox(height: AppConstants.defaultPadding),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  StatusDropdown(
                    value: _selectedStatus!,
                    onChanged: (TaskStatus? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedStatus = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Text(
                    'Priority: ${task.priority.displayName}',
                    style: AppConstants.bodyStyle,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Text(
                    'Start Date: ${DateHelper.formatDate(task.startDate)}',
                    style: AppConstants.bodyStyle,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Text(
                    'Due Date: ${DateHelper.formatDate(task.dueDate)}',
                    style: AppConstants.bodyStyle,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Text(
                    'Created By: ${userProvider.users.firstWhere(
                      (user) => user.id == task.createdBy,
                      orElse: () => UserModel(id: '', email: 'Unknown', displayName: 'Unknown', createdAt: DateTime.now(), isEmailVerified: false),
                    ).displayName}',
                    style: AppConstants.bodyStyle,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  ListTile(
                    title: const Text('Assignees'),
                    trailing: const Icon(Icons.person_add),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.taskAssignment,
                        arguments: {
                          'taskId': task.id,
                          'currentAssignees': task.assignedTo,
                        },
                      );
                    },
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Wrap(
                    spacing: AppConstants.smallPadding,
                    runSpacing: AppConstants.smallPadding,
                    children: task.labels.map((labelId) {
                      return Chip(
                        label: Text(
                          'Label #$labelId',
                          style: AppConstants.bodyStyle.copyWith(fontSize: 12),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppConstants.largePadding),
                  CustomButton(
                    text: 'Save Changes',
                    onPressed: () => _updateTask(context, task),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _updateTask(BuildContext context, TaskModel task) async {
    if (_formKey.currentState!.validate()) {
      final taskProvider = context.read<TaskProvider>();
      final updates = {
        'description': _descriptionController.text.trim(),
        'status': _selectedStatus!.value,
        'updatedAt': DateTime.now(),
      };

      final success = await taskProvider.updateTask(widget.taskId, updates);
      if (success && mounted) {
        taskProvider.loadTasks(
          context.read<AuthProvider>().user?.uid,
        ); // CHANGED: Use AuthProvider for user ID
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppConstants.successMessage)),
        );
      }
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
