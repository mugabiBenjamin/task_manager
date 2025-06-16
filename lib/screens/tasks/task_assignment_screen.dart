import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/task_provider.dart';
import '../../providers/user_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_widget.dart';

class TaskAssignmentScreen extends StatefulWidget {
  final String taskId;
  final List<String> currentAssignees;

  const TaskAssignmentScreen({
    super.key,
    required this.taskId,
    required this.currentAssignees,
  });

  @override
  State<TaskAssignmentScreen> createState() => _TaskAssignmentScreenState();
}

class _TaskAssignmentScreenState extends State<TaskAssignmentScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _selectedAssignees = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _selectedAssignees = List.from(widget.currentAssignees);
    // Load initial assignees
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (_selectedAssignees.isNotEmpty) {
        userProvider.loadUsersByIds(_selectedAssignees);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Task'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.userProfile),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              controller: _searchController,
              labelText: 'Search Users by Email',
              prefixIcon: Icons.search,
              onChanged: (value) {
                setState(() {
                  _isSearching = value.isNotEmpty;
                });
                Provider.of<UserProvider>(
                  context,
                  listen: false,
                ).searchUsers(value.trim());
              },
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              'Selected Assignees (${_selectedAssignees.length})',
              style: AppConstants.subtitleStyle,
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Expanded(
              child: Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  if (userProvider.isLoading) {
                    return const Center(child: LoadingWidget());
                  }
                  if (userProvider.errorMessage != null) {
                    return Center(
                      child: Text(
                        userProvider.errorMessage!,
                        style: const TextStyle(color: AppConstants.errorColor),
                      ),
                    );
                  }
                  final users = userProvider.users;
                  if (users.isEmpty && !_isSearching) {
                    return Center(
                      child: Text(
                        'No assignees selected',
                        style: AppConstants.bodyStyle.copyWith(
                          color: AppConstants.textSecondaryColor,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final isSelected = _selectedAssignees.contains(user.id);
                      return CheckboxListTile(
                        title: Text(
                          user.displayName.isNotEmpty
                              ? user.displayName
                              : user.email,
                        ),
                        subtitle: Text(
                          user.email,
                          style: AppConstants.bodyStyle.copyWith(
                            color: AppConstants.textSecondaryColor,
                          ),
                        ),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedAssignees.add(user.id);
                            } else {
                              _selectedAssignees.remove(user.id);
                            }
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                return CustomButton(
                  text: taskProvider.isLoading ? 'Saving...' : 'Save Assignees',
                  onPressed: taskProvider.isLoading ? null : _saveAssignees,
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
    );
  }

  void _saveAssignees() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final success = await taskProvider.assignTask(
      widget.taskId,
      _selectedAssignees,
    );
    if (success && mounted) {
      Navigator.pop(context, _selectedAssignees);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppConstants.successMessage)),
      );
    }
  }
}
