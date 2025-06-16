import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/task_priority.dart';
import '../../core/enums/task_status.dart';
import '../../core/utils/date_helper.dart';
import '../../models/task_model.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onTap;

  const TaskCard({super.key, required this.task, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOverdue =
        DateHelper.isOverdue(task.dueDate) &&
        task.status != TaskStatus.complete;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
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
                            : AppConstants.textPrimaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
                      color: AppConstants.textSecondaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: AppConstants.smallPadding),
              Row(
                children: [
                  Icon(
                    Icons.priority_high,
                    size: AppConstants.iconSize,
                    color: _getPriorityColor(task.priority),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    task.priority.displayName,
                    style: AppConstants.bodyStyle.copyWith(
                      color: _getPriorityColor(task.priority),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: AppConstants.defaultPadding),
                  Icon(
                    Icons.calendar_today,
                    size: AppConstants.iconSize,
                    color: isOverdue
                        ? AppConstants.errorColor
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
                          : AppConstants.textSecondaryColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              if (task.labels.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppConstants.smallPadding,
                  ),
                  child: Wrap(
                    spacing: AppConstants.smallPadding,
                    runSpacing: AppConstants.smallPadding,
                    children: task.labels.map((labelId) {
                      // Placeholder for label display; integrate with LabelProvider when available
                      return Chip(
                        label: Text(
                          'Label #$labelId',
                          style: AppConstants.bodyStyle.copyWith(fontSize: 12),
                        ),
                        backgroundColor: AppConstants.textSecondaryColor
                            .withValues(alpha: 0.2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.smallPadding,
                        ),
                      );
                    }).toList(),
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
