import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/task_priority.dart';
import '../../core/enums/task_status.dart';
import '../../core/utils/date_helper.dart';
import '../../models/label_model.dart';
import '../../models/task_model.dart';
import '../../providers/label_provider.dart';
import '../../providers/task_provider.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onTap;

  const TaskCard({super.key, required this.task, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOverdue =
        DateHelper.isOverdue(task.dueDate) &&
        task.status != TaskStatus.complete;
    final isCompleted = task.status == TaskStatus.complete;

    return Card(
      color: AppConstants.primaryColor.withValues(alpha: 0.05),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        side: BorderSide(
          color: AppConstants.primaryColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: AppConstants.headlineStyle.copyWith(
                            fontSize: 18,
                            color: isOverdue
                                ? AppConstants.errorColor
                                : isCompleted
                                    ? Colors.grey
                                    : AppConstants.textPrimaryColor,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.smallPadding,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                task.status,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(
                                AppConstants.borderRadius / 2,
                              ),
                            ),
                            child: Text(
                              task.status.displayName,
                              style: AppConstants.bodyStyle.copyWith(
                                color: _getStatusColor(task.status),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Consumer<TaskProvider>(
                            builder: (context, taskProvider, child) {
                              return GestureDetector(
                                onTap: () async {
                                  await taskProvider.toggleTaskStarred(task.id);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    task.isStarred ? Icons.star : Icons.star_border,
                                    color: task.isStarred ? Colors.amber : Colors.grey,
                                    size: 20,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (task.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppConstants.smallPadding,
                      ),
                      child: Text(
                        task.description,
                        style: AppConstants.bodyStyle.copyWith(
                          color: isCompleted
                              ? Colors.grey
                              : AppConstants.textSecondaryColor,
                          fontSize: 14,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.priority_high,
                            size: 18,
                            color: isCompleted
                                ? Colors.grey
                                : _getPriorityColor(task.priority),
                          ),
                          Text(
                            task.priority.displayName,
                            style: AppConstants.bodyStyle.copyWith(
                              color: isCompleted
                                  ? Colors.grey
                                  : _getPriorityColor(task.priority),
                              fontSize: 14,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: isOverdue
                                ? AppConstants.errorColor
                                : isCompleted
                                    ? Colors.grey
                                    : AppConstants.textSecondaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            task.dueDate != null
                                ? DateHelper.formatDate(task.dueDate)
                                : 'No due date',
                            style: AppConstants.bodyStyle.copyWith(
                              color: isOverdue
                                  ? AppConstants.errorColor
                                  : isCompleted
                                      ? Colors.grey
                                      : AppConstants.textSecondaryColor,
                              fontSize: 12,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (task.labels.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppConstants.smallPadding,
                      ),
                      child: Consumer<LabelProvider>(
                        builder: (context, labelProvider, child) {
                          return Wrap(
                            spacing: AppConstants.smallPadding,
                            runSpacing: AppConstants.smallPadding,
                            children: task.labels.map((labelId) {
                              final label = labelProvider.labels.firstWhere(
                                (label) => label.id == labelId,
                                orElse: () => LabelModel(
                                  id: labelId,
                                  name: 'Unknown',
                                  color: '#808080',
                                  createdBy: '',
                                  createdAt: DateTime.now(),
                                ),
                              );
                              return Chip(
                                label: Text(
                                  label.name,
                                  style: AppConstants.bodyStyle.copyWith(
                                    fontSize: 12,
                                    color: isCompleted ? Colors.grey : null,
                                    decoration: isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                backgroundColor: Color(
                                  int.parse(
                                    label.color.replaceFirst('#', '0xFF'),
                                  ),
                                ).withValues(
                                  alpha: isCompleted ? 0.1 : 0.2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppConstants.smallPadding,
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
    );
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.notStarted:
        return Colors.grey;
      case TaskStatus.inProgress:
        return AppConstants.primaryColor;
      case TaskStatus.complete:
        return AppConstants.successColor;
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
    }
  }
}