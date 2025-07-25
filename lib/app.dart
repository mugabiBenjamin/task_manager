import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/label_provider.dart';
import 'providers/task_provider.dart';
import 'providers/user_provider.dart';
import 'routes/app_routes.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/profile/user_profile_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/tasks/create_task_screen.dart';
import 'screens/tasks/labels_screen.dart';
import 'screens/tasks/starred_tasks_screen.dart';
import 'screens/tasks/task_assignment_screen.dart';
import 'screens/tasks/task_details_screen.dart';
import 'screens/tasks/task_list_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    AuthProvider.setNavigatorKey(navigatorKey);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, TaskProvider>(
          create: (_) => TaskProvider(),
          update: (_, auth, previous) => previous!..updateAuthProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, LabelProvider>(
          create: (_) => LabelProvider(),
          update: (_, auth, previous) => previous!..updateAuthProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
          create: (_) => UserProvider(),
          update: (_, auth, previous) => previous!..updateAuthProvider(auth),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Task Manager',
        theme: AppTheme.lightTheme,
        navigatorKey: navigatorKey,
        initialRoute: AppRoutes.login,
        routes: {
          AppRoutes.login: (context) => const LoginScreen(),
          AppRoutes.signup: (context) => const SignupScreen(),
          AppRoutes.taskList: (context) => const TaskListScreen(),
          AppRoutes.taskDetails: (context) => TaskDetailsScreen(
            taskId: ModalRoute.of(context)!.settings.arguments as String,
          ),
          AppRoutes.createTask: (context) => const CreateTaskScreen(),
          AppRoutes.taskAssignment: (context) {
            final args =
                ModalRoute.of(context)!.settings.arguments
                    as Map<String, dynamic>;
            return TaskAssignmentScreen(
              taskId: args['taskId'] as String,
              currentAssignees: args['currentAssignees'] as List<String>,
            );
          },
          AppRoutes.userProfile: (context) => const UserProfileScreen(),
          AppRoutes.settings: (context) => const SettingsScreen(),
          AppRoutes.starredTasks: (context) => const StarredTasksScreen(),
          AppRoutes.labels: (context) => const LabelsScreen(),
        },
      ),
    );
  }
}
