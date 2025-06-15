import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/task_priority.dart';
import '../../core/enums/task_status.dart';
import '../../core/utils/date_helper.dart';
import '../../core/utils/validators.dart';
import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/tasks/priority_dropdown.dart';
import '../../widgets/tasks/status_dropdown.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startDateController = TextEditingController();
  final _dueDateController = TextEditingController();
  TaskStatus _selectedStatus = TaskStatus.notStarted;
  TaskPriority _selectedPriority = TaskPriority.medium;
  List<String> _selectedAssignees = [];
  List<String> _selectedLabels = [];

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
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.createTaskTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
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
              const SizedBox(height: AppConstants.defaultPadding),
              ListTile(
                title: const Text('Labels'),
                trailing: const Icon(Icons.label),
                onTap: () {
                  // TODO: Integrate with LabelProvider when implemented
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Label selection coming soon!'),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppConstants.largePadding),
              Consumer<TaskProvider>(
                builder: (context, taskProvider, child) {
                  return CustomButton(
                    text: taskProvider.isLoading
                        ? 'Creating...'
                        : 'Create Task',
                    onPressed: taskProvider.isLoading ? null : _createTask,
                  );
                },
              ),
              if (Provider.of<TaskProvider>(context).errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppConstants.defaultPadding,
                  ),
                  child: Text(
                    Provider.of<TaskProvider>(context).errorMessage!,
                    style: const TextStyle(color: AppConstants.errorColor),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
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

  void _createTask() async {
    if (_formKey.currentState!.validate()) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user!.uid;

      final task = TaskModel(
        id: '', // Will be set by Firestore
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        status: _selectedStatus,
        priority: _selectedPriority,
        startDate: DateHelper.parseDate(_startDateController.text),
        dueDate: DateHelper.parseDate(_dueDateController.text),
        createdBy: userId,
        assignedTo: _selectedAssignees.isEmpty ? [userId] : _selectedAssignees,
        labels: _selectedLabels,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await taskProvider.createTask(task);
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppConstants.successMessage)),
        );
      }
    }
  }
}
