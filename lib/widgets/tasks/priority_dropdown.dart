import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/task_priority.dart';

class PriorityDropdown extends StatelessWidget {
  final TaskPriority value;
  final ValueChanged<TaskPriority?> onChanged;

  const PriorityDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<TaskPriority>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: 'Priority',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),
      items: TaskPriority.values.map((TaskPriority priority) {
        return DropdownMenuItem<TaskPriority>(
          value: priority,
          child: Text(priority.displayName),
        );
      }).toList(),
    );
  }
}
