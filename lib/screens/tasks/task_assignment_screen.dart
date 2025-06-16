import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../providers/task_provider.dart';
import '../../services/user_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

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
  final _searchController = TextEditingController();
  List<UserModel> _users = [];
  List<String> _selectedAssignees = [];
  bool _isLoading = false;
  String? _errorMessage;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _selectedAssignees = List.from(widget.currentAssignees);
    _searchController.addListener(() {
      _searchUsers(_searchController.text);
    });
    _loadInitialUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialUsers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final users = await _userService.getUsersByIds(widget.currentAssignees);
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load users: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      _loadInitialUsers();
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final users = await _userService.searchUsers(query);
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to search users: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assign Task')),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              controller: _searchController,
              labelText: 'Search Users by Email',
              prefixIcon: Icons.search,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppConstants.errorColor),
                textAlign: TextAlign.center,
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final isSelected = _selectedAssignees.contains(user.id);
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          user.displayName.isNotEmpty
                              ? user.displayName[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(
                        user.displayName.isNotEmpty
                            ? user.displayName
                            : 'Unknown',
                      ),
                      subtitle: Text(user.email),
                      trailing: Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected
                            ? AppConstants.primaryColor
                            : AppConstants.textSecondaryColor,
                      ),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedAssignees.remove(user.id);
                          } else {
                            _selectedAssignees.add(user.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: AppConstants.defaultPadding),
            if (_selectedAssignees.isNotEmpty)
              Text(
                '${_selectedAssignees.length} assignee${_selectedAssignees.length > 1 ? 's' : ''} selected',
                style: AppConstants.bodyStyle.copyWith(
                  color: AppConstants.textSecondaryColor,
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
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppConstants.successMessage)),
      );
    }
  }
}
