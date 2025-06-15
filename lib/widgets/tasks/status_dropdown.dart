import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/task_status.dart';

class StatusDropdown extends StatelessWidget {
  final TaskStatus value;
  final ValueChanged<TaskStatus?> onChanged;

  const StatusDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<TaskStatus>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),
      items: TaskStatus.values.map((TaskStatus status) {
        return DropdownMenuItem<TaskStatus>(
          value: status,
          child: Text(status.displayName),
        );
      }).toList(),
    );
  }
}
