import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../providers/task_provider.dart';
import '../../services/user_service.dart';
import '../../widgets/common/custom_button.dart';
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
  List<String> _selectedAssignees = [];
  List<UserModel> _availableUsers = [];
  bool _isLoading = true;
  String? _errorMessage;
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedAssignees = List.from(widget.currentAssignees);
    _loadUsers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      // Initially load all users; adjust to fetch specific users if needed
      final users = await _userService.searchUsers('');
      setState(() {
        _availableUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load users: $e';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      _searchUsers(query);
    } else {
      _loadUsers();
    }
  }

  Future<void> _searchUsers(String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final users = await _userService.searchUsers(query);
      setState(() {
        _availableUsers = users;
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Users',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: LoadingWidget())
                : _errorMessage != null
                ? Center(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppConstants.errorColor),
                      textAlign: TextAlign.center,
                    ),
                  )
                : _availableUsers.isEmpty
                ? Center(
                    child: Text(
                      'No users found',
                      style: AppConstants.bodyStyle.copyWith(
                        color: AppConstants.textSecondaryColor,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    itemCount: _availableUsers.length,
                    itemBuilder: (context, index) {
                      final user = _availableUsers[index];
                      final isSelected = _selectedAssignees.contains(user.id);
                      return CheckboxListTile(
                        title: Text(user.displayName),
                        subtitle: Text(
                          user.email,
                          style: AppConstants.bodyStyle.copyWith(
                            color: AppConstants.textSecondaryColor,
                            fontSize: 12,
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
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              children: [
                Text(
                  '${_selectedAssignees.length} assignee${_selectedAssignees.length != 1 ? 's' : ''} selected',
                  style: AppConstants.bodyStyle.copyWith(
                    color: AppConstants.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                Consumer<TaskProvider>(
                  builder: (context, taskProvider, child) {
                    return CustomButton(
                      text: taskProvider.isLoading
                          ? 'Saving...'
                          : 'Save Assignees',
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
        ],
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
