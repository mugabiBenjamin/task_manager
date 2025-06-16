import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/tasks/task_form.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.createTaskTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            if (authProvider.user == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return Column(
              children: [
                TaskForm(
                  onSubmit: (task) =>
                      _createTask(context, task, authProvider.user!.uid),
                  submitButtonText: 'Create Task',
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
            );
          },
        ),
      ),
    );
  }

  void _createTask(BuildContext context, TaskModel task, String userId) async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final success = await taskProvider.createTask(task);
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppConstants.successMessage)),
      );
    }
  }
}
