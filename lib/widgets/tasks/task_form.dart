import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/task_priority.dart';
import '../../core/enums/task_status.dart';
import '../../core/utils/date_helper.dart';
import '../../core/utils/validators.dart';
import '../../models/task_model.dart';
import '../common/custom_text_field.dart';
import 'status_dropdown.dart';
import 'priority_dropdown.dart';

class TaskForm extends StatefulWidget {
  final TaskModel? task;
  final Function(TaskModel) onSubmit;
  final String submitButtonText;

  const TaskForm({
    super.key,
    this.task,
    required this.onSubmit,
    this.submitButtonText = 'Save Task',
  });

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _startDateController;
  late TextEditingController _dueDateController;
  late TaskStatus _selectedStatus;
  late TaskPriority _selectedPriority;
  late List<String> _selectedAssignees;
  late List<String> _selectedLabels;

  @override
  void initState() {
    super.initState();
    // Initialize controllers and state based on provided task or defaults
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _startDateController = TextEditingController(
      text: widget.task?.startDate != null
          ? DateFormat('yyyy-MM-dd').format(widget.task!.startDate!)
          : '',
    );
    _dueDateController = TextEditingController(
      text: widget.task?.dueDate != null
          ? DateFormat('yyyy-MM-dd').format(widget.task!.dueDate!)
          : '',
    );
    _selectedStatus = widget.task?.status ?? TaskStatus.notStarted;
    _selectedPriority = widget.task?.priority ?? TaskPriority.medium;
    _selectedAssignees = widget.task?.assignedTo ?? [];
    _selectedLabels = widget.task?.labels ?? [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _startDateController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            controller: _titleController,
            labelText: 'Task Title',
            validator: Validators.validateTaskTitle,
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          CustomTextField(
            controller: _descriptionController,
            labelText: 'Description',
            maxLines: 4,
            validator: Validators.validateTaskDescription,
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          StatusDropdown(
            value: _selectedStatus,
            onChanged: (TaskStatus? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedStatus = newValue;
                });
              }
            },
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          PriorityDropdown(
            value: _selectedPriority,
            onChanged: (TaskPriority? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedPriority = newValue;
                });
              }
            },
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          CustomTextField(
            controller: _startDateController,
            labelText: 'Start Date',
            readOnly: true,
            onTap: () => _selectDate(context, isStartDate: true),
            validator: (value) =>
                Validators.validateDate(value, allowPast: true),
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          CustomTextField(
            controller: _dueDateController,
            labelText: 'Due Date',
            readOnly: true,
            onTap: () => _selectDate(context, isStartDate: false),
            validator: Validators.validateDate,
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          ListTile(
            title: const Text('Assignees'),
            trailing: const Icon(Icons.person_add),
            onTap: () {
              // TODO: Navigate to TaskAssignmentScreen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Assignee selection coming soon!'),
                ),
              );
            },
          ),
          if (_selectedAssignees.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppConstants.smallPadding,
              ),
              child: Text(
                '${_selectedAssignees.length} assignee${_selectedAssignees.length > 1 ? 's' : ''} selected',
                style: AppConstants.bodyStyle.copyWith(
                  color: AppConstants.textSecondaryColor,
                ),
              ),
            ),
          const SizedBox(height: AppConstants.defaultPadding),
          ListTile(
            title: const Text('Labels'),
            trailing: const Icon(Icons.label),
            onTap: () {
              // TODO: Integrate with LabelProvider when implemented
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Label selection coming soon!')),
              );
            },
          ),
          if (_selectedLabels.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppConstants.smallPadding,
              ),
              child: Text(
                '${_selectedLabels.length} label${_selectedLabels.length > 1 ? 's' : ''} selected',
                style: AppConstants.bodyStyle.copyWith(
                  color: AppConstants.textSecondaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _selectDate(
    BuildContext context, {
    required bool isStartDate,
  }) async {
    final initialDate = isStartDate
        ? DateHelper.getDefaultStartDate()
        : DateHelper.getDefaultDueDate();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {
        if (isStartDate) {
          _startDateController.text = formattedDate;
        } else {
          _dueDateController.text = formattedDate;
        }
      });
    }
  }

  void submitForm(String userId) {
    if (_formKey.currentState!.validate()) {
      final task = TaskModel(
        id: widget.task?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        status: _selectedStatus,
        priority: _selectedPriority,
        startDate: DateHelper.parseDate(_startDateController.text),
        dueDate: DateHelper.parseDate(_dueDateController.text),
        createdBy: widget.task?.createdBy ?? userId,
        assignedTo: _selectedAssignees.isEmpty && widget.task == null
            ? [userId]
            : _selectedAssignees,
        labels: _selectedLabels,
        createdAt: widget.task?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      widget.onSubmit(task);
    }
  }
}
