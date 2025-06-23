import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // ADDED: Import for Provider
import '../../core/constants/app_constants.dart';
import '../../core/enums/task_priority.dart';
import '../../core/enums/task_status.dart';
import '../../core/utils/date_helper.dart';
import '../../models/label_model.dart';
import '../../models/task_model.dart';
import '../../providers/label_provider.dart'; // ADDED: Import for LabelProvider

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
                      fontSize: 14,
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
                        color: _getPriorityColor(task.priority),
                      ),
                      Text(
                        task.priority.displayName,
                        style: AppConstants.bodyStyle.copyWith(
                          color: _getPriorityColor(task.priority),
                          fontSize: 14,
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
                          fontSize: 12,
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
                    // ADDED: Wrap label display in Consumer to access LabelProvider
                    builder: (context, labelProvider, child) {
                      return Wrap(
                        spacing: AppConstants.smallPadding,
                        runSpacing: AppConstants.smallPadding,
                        children: task.labels.map((labelId) {
                          // CHANGED: Replace placeholder with actual label data
                          final label = labelProvider.labels.firstWhere(
                            (label) => label.id == labelId,
                            orElse: () => LabelModel(
                              id: labelId,
                              name: 'Unknown',
                              color: '#808080', // Fallback for unknown labels
                              createdBy: '',
                              createdAt: DateTime.now(),
                            ),
                          );
                          return Chip(
                            label: Text(
                              label
                                  .name, // CHANGED: Use label.name instead of 'Label #$labelId'
                              style: AppConstants.bodyStyle.copyWith(
                                fontSize: 12,
                              ),
                            ),
                            backgroundColor:
                                Color(
                                  int.parse(
                                    label.color.replaceFirst('#', '0xFF'),
                                  ),
                                ).withValues(
                                  alpha: 0.2,
                                ), // CHANGED: Use label.color
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
