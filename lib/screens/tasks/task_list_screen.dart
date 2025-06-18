import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/tasks/task_card.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  @override
  void initState() {
    super.initState();
    // Schedule provider access after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isAuthenticated) {
        context.read<TaskProvider>().loadTasks(authProvider.user!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.taskListTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.userProfile),
          ),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          if (taskProvider.isLoading) {
            return const Center(child: LoadingWidget());
          }
          if (taskProvider.errorMessage != null) {
            return Center(
              child: Text(
                taskProvider.errorMessage!,
                style: const TextStyle(color: AppConstants.errorColor),
              ),
            );
          }
          if (taskProvider.tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.task_alt, size: 80, color: Colors.grey),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Text(
                    AppConstants.noTasksMessage,
                    style: AppConstants.bodyStyle.copyWith(
                      color: AppConstants.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  Text(
                    AppConstants.addTaskPrompt,
                    style: AppConstants.bodyStyle.copyWith(
                      color: AppConstants.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            itemCount: taskProvider.tasks.length,
            itemBuilder: (context, index) {
              final task = taskProvider.tasks[index];
              return TaskCard(
                task: task,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.taskDetails,
                    arguments: task.id,
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.createTask),
        child: const Icon(Icons.add),
      ),
    );
  }
}
