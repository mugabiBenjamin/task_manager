import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/tasks/task_list_screen.dart';
import '../screens/tasks/create_task_screen.dart';
// Placeholder imports for screens to be implemented
// import '../screens/tasks/task_details_screen.dart';
// import '../screens/tasks/task_assignment_screen.dart';
// import '../screens/profile/user_profile_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String taskList = '/task_list';
  static const String createTask = '/create_task';
  static const String taskDetails = '/task_details';
  static const String taskAssignment = '/task_assignment';
  static const String userProfile = '/user_profile';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginScreen(),
      signup: (context) => const SignupScreen(),
      taskList: (context) => const TaskListScreen(),
      createTask: (context) => const CreateTaskScreen(),
      taskDetails: (context) => const Scaffold(
        body: Center(child: Text('Task Details Screen - Coming Soon')),
      ),
      taskAssignment: (context) => const Scaffold(
        body: Center(child: Text('Task Assignment Screen - Coming Soon')),
      ),
      userProfile: (context) => const Scaffold(
        body: Center(child: Text('User Profile Screen - Coming Soon')),
      ),
    };
  }
}
