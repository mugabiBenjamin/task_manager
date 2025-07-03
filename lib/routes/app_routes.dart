import 'package:flutter/material.dart';
import '../screens/auth/accept_invitation_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/tasks/task_list_screen.dart';
import '../screens/tasks/create_task_screen.dart';
import '../screens/tasks/task_details_screen.dart';
import '../screens/tasks/task_assignment_screen.dart';
import '../screens/profile/user_profile_screen.dart';
import '../screens/tasks/starred_tasks_screen.dart';
import '../screens/tasks/labels_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/auth/invite_user_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String taskList = '/task_list';
  static const String createTask = '/create_task';
  static const String taskDetails = '/task_details';
  static const String taskAssignment = '/task_assignment';
  static const String userProfile = '/user_profile';
  static const String starredTasks = '/starred_tasks';
  static const String labels = '/labels';
  static const String settings = '/settings';
  static const String help = '/help';
  static const String inviteUser = '/invite_user';
  static const String acceptInvitation = '/accept_invitation';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginScreen(),
      signup: (context) => const SignupScreen(),
      taskList: (context) => const TaskListScreen(),
      createTask: (context) => const CreateTaskScreen(),
      taskDetails: (context) {
        final args = ModalRoute.of(context)!.settings.arguments;
        if (args is String && args.isNotEmpty) {
          return TaskDetailsScreen(taskId: args);
        }
        return const TaskListScreen();
      },
      taskAssignment: (context) {
        final args = ModalRoute.of(context)!.settings.arguments;
        if (args is Map<String, dynamic> &&
            args['taskId'] is String &&
            args['currentAssignees'] is List<String>) {
          return TaskAssignmentScreen(
            taskId: args['taskId'] as String,
            currentAssignees: args['currentAssignees'] as List<String>,
          );
        }
        return const TaskListScreen();
      },
      userProfile: (context) => const UserProfileScreen(),
      starredTasks: (context) => const StarredTasksScreen(),
      labels: (context) => const LabelsScreen(),
      settings: (context) => const SettingsScreen(),
      inviteUser: (context) => const InviteUserScreen(),
      acceptInvitation: (context) {
        final args = ModalRoute.of(context)!.settings.arguments;
        if (args is String && args.isNotEmpty) {
          return AcceptInvitationScreen(token: args);
        }
        return const LoginScreen();
      },
      help: (context) => const Scaffold(
            body: Center(child: Text('Help screen not implemented')),
          ),
    };
  }
}