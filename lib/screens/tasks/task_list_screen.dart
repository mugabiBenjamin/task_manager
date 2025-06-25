import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/tasks/task_card.dart';
import '../../widgets/common/app_drawer.dart';

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
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.userProfile),
          ),
        ],
      ),
      drawer: const AppDrawer(),
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
          return Consumer<TaskProvider>(
            builder: (context, taskProvider, child) {
              // Get grouped tasks
              final groupedTasks = taskProvider.getGroupedTasks();
              final sections = groupedTasks.keys.toList();

              // Calculate total items (sections + tasks)
              int totalItems = 0;
              for (final tasks in groupedTasks.values) {
                totalItems += 1 + tasks.length; // 1 for header + tasks count
              }

              return ListView.builder(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                itemCount: totalItems,
                itemBuilder: (context, index) {
                  int currentIndex = 0;

                  // Find which section this index belongs to
                  for (final sectionKey in sections) {
                    final sectionTasks = groupedTasks[sectionKey]!;
                    final sectionSize =
                        1 + sectionTasks.length; // header + tasks

                    if (index < currentIndex + sectionSize) {
                      final localIndex = index - currentIndex;

                      // Section header
                      if (localIndex == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            top: AppConstants.defaultPadding,
                            bottom: AppConstants.smallPadding,
                          ),
                          child: Text(
                            sectionKey,
                            style: AppConstants.headlineStyle.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.textSecondaryColor,
                            ),
                          ),
                        );
                      }

                      // Task item
                      final task = sectionTasks[localIndex - 1];
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
                    }

                    currentIndex += sectionSize;
                  }

                  // Should never reach here
                  return const SizedBox.shrink();
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
