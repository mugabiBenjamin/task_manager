import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:task_manager/routes/app_routes.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'package:app_links/app_links.dart';

late AppLinks _appLinks;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ADDED: Initialize deep links here
  _appLinks = AppLinks();

  // ADDED: Handle initial deep link
  final initialLink = await _appLinks.getInitialLink();
  if (initialLink != null) {
    // Store for later handling after app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      handleDeepLink(initialLink);
    });
  }

  // ADDED: Listen for deep links while app is running
  _appLinks.uriLinkStream.listen((Uri uri) {
    handleDeepLink(uri);
  });

  runApp(const App());
}

// ADD: Deep link handler function after main()
void handleDeepLink(Uri uri) {
  if (uri.scheme == 'taskmanager') {
    switch (uri.host) {
      case 'invite':
        final token = uri.queryParameters['token'];
        if (token != null) {
          App.navigatorKey.currentState?.pushNamed(
            AppRoutes.acceptInvitation,
            arguments: token,
          );
        }
        break;
      case 'task':
        final taskId = uri.queryParameters['id'];
        if (taskId != null) {
          App.navigatorKey.currentState?.pushNamed(
            AppRoutes.taskDetails,
            arguments: taskId,
          );
        } else {
          App.navigatorKey.currentState?.pushNamed(AppRoutes.taskList);
        }
        break;
    }
  }
}
