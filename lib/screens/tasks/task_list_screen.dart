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
  final _taskIdController = TextEditingController();
  bool _showTaskIdField = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isAuthenticated) {
        context.read<TaskProvider>().loadTasks(authProvider.user!.uid);
      }
    });
  }

  @override
  void dispose() {
    _taskIdController.dispose();
    super.dispose();
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
            icon: Icon(_showTaskIdField ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showTaskIdField = !_showTaskIdField;
                if (!_showTaskIdField) {
                  _taskIdController.clear();
                }
              });
            },
            tooltip: _showTaskIdField
                ? 'Hide Task ID Search'
                : 'Search by Task ID',
          ),
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
          return Column(
            children: [
              if (_showTaskIdField)
                Container(
                  margin: const EdgeInsets.all(AppConstants.defaultPadding),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppConstants.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Paste the Task ID from your email to view the task details.',
                          style: TextStyle(color: AppConstants.primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_showTaskIdField)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.defaultPadding,
                    vertical: AppConstants.smallPadding,
                  ),
                  child: TextFormField(
                    controller: _taskIdController,
                    decoration: InputDecoration(
                      labelText: 'Enter Task ID',
                      border: const OutlineInputBorder(),
                      helperText: 'Enter the Task ID from the assignment email',
                      helperStyle: TextStyle(color: AppConstants.primaryColor),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () {
                          if (_taskIdController.text.isNotEmpty) {
                            final taskId = _taskIdController.text.trim();
                            final taskExists = taskProvider.tasks.any(
                              (task) => task.id == taskId,
                            );
                            if (taskExists) {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.taskDetails,
                                arguments: taskId,
                              );
                              setState(() {
                                _showTaskIdField = false;
                                _taskIdController.clear();
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Task ID not found. Please check and try again.',
                                  ),
                                  backgroundColor: AppConstants.errorColor,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a Task ID';
                      }
                      return null;
                    },
                    onFieldSubmitted: (value) {
                      if (value.isNotEmpty) {
                        final taskId = value.trim();
                        final taskExists = taskProvider.tasks.any(
                          (task) => task.id == taskId,
                        );
                        if (taskExists) {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.taskDetails,
                            arguments: taskId,
                          );
                          setState(() {
                            _showTaskIdField = false;
                            _taskIdController.clear();
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Task ID not found. Please check and try again.',
                              ),
                              backgroundColor: AppConstants.errorColor,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              Expanded(
                child: taskProvider.tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.task_alt,
                              size: 80,
                              color: Colors.grey,
                            ),
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
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(
                          AppConstants.defaultPadding,
                        ),
                        itemCount: _calculateTotalItems(taskProvider),
                        itemBuilder: (context, index) {
                          final groupedTasks = taskProvider.getGroupedTasks();
                          final sections = groupedTasks.keys.toList();
                          int currentIndex = 0;

                          for (final sectionKey in sections) {
                            final sectionTasks = groupedTasks[sectionKey]!;
                            final sectionSize = 1 + sectionTasks.length;

                            if (index < currentIndex + sectionSize) {
                              final localIndex = index - currentIndex;

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

                          return const SizedBox.shrink();
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.createTask),
        child: const Icon(Icons.add),
      ),
    );
  }

  int _calculateTotalItems(TaskProvider taskProvider) {
    final groupedTasks = taskProvider.getGroupedTasks();
    int totalItems = 0;
    for (final tasks in groupedTasks.values) {
      totalItems += 1 + tasks.length; // 1 for header + tasks count
    }
    return totalItems;
  }
}
