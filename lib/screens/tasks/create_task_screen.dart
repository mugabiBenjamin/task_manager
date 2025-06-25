import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/tasks/task_form.dart';
import '../../widgets/common/app_drawer.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final GlobalKey<TaskFormState> _taskFormKey = GlobalKey<TaskFormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.createTaskTitle),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.taskList,
              (route) => false,
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                if (authProvider.user == null) {
                  return const Center(child: Text('User not authenticated'));
                }
                return TaskForm(
                  key: _taskFormKey,
                  onSubmit: (task) =>
                      _createTask(context, task, authProvider.user!.uid),
                  submitButtonText: 'Create Task',
                );
              },
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                return CustomButton(
                  text: taskProvider.isLoading ? 'Creating...' : 'Create Task',
                  onPressed: taskProvider.isLoading
                      ? null
                      : () => _submitForm(context),
                );
              },
            ),
            if (context.watch<TaskProvider>().errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(
                  top: AppConstants.defaultPadding,
                ),
                child: Text(
                  context.watch<TaskProvider>().errorMessage!,
                  style: const TextStyle(color: AppConstants.errorColor),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _submitForm(BuildContext context) {
    final taskFormState = _taskFormKey.currentState;
    if (taskFormState != null) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user != null) {
        taskFormState.submitForm(authProvider.user!.uid);
      }
    }
  }

  void _createTask(BuildContext context, TaskModel task, String userId) async {
    debugPrint('_createTask called with task: ${task.title}');
    final taskProvider = context.read<TaskProvider>();
    final success = await taskProvider.createTask(task);
    debugPrint('Task creation success: $success');
    if (success && context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.taskList,
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppConstants.successMessage)),
      );
    }
  }
}
