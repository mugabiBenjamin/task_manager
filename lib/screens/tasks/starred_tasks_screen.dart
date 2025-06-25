import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/tasks/task_card.dart';

class StarredTasksScreen extends StatelessWidget {
  const StarredTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Starred Tasks'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          final groupedStarredTasks = taskProvider.getGroupedStarredTasks();

          if (groupedStarredTasks.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_border, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No starred tasks yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Star tasks to see them here',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final sections = groupedStarredTasks.keys.toList();
          int totalItems = 0;
          for (final tasks in groupedStarredTasks.values) {
            totalItems += 1 + tasks.length;
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: totalItems,
            itemBuilder: (context, index) {
              int currentIndex = 0;

              for (final sectionKey in sections) {
                final sectionTasks = groupedStarredTasks[sectionKey]!;
                final sectionSize = 1 + sectionTasks.length;

                if (index < currentIndex + sectionSize) {
                  final localIndex = index - currentIndex;

                  if (localIndex == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: Text(
                        sectionKey,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }

                  final task = sectionTasks[localIndex - 1];
                  return TaskCard(
                    task: task,
                    onTap: null, // CHANGED: Non-clickable cards
                  );
                }

                currentIndex += sectionSize;
              }

              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}
