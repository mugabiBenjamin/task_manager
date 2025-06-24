import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';

const TextStyle drawerTextStyle = TextStyle(fontWeight: FontWeight.bold);

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      child: Drawer(
        child: Column(
          children: [
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final userModel = authProvider.userModel;
                final firebaseUser = authProvider.user;

                String displayName = '';
                String email = '';

                if (userModel != null) {
                  displayName = userModel.displayName;
                  email = userModel.email;
                } else if (firebaseUser != null) {
                  displayName = firebaseUser.displayName ?? '';
                  email = firebaseUser.email ?? '';
                }

                return UserAccountsDrawerHeader(
                  accountName: Text(
                    displayName.isNotEmpty ? displayName : 'User',
                    style: drawerTextStyle,
                  ),
                  accountEmail: Text(email, style: drawerTextStyle),
                  currentAccountPicture: CircleAvatar(
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
            // Menu items
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('New Task', style: drawerTextStyle),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.createTask);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile', style: drawerTextStyle),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.userProfile);
              },
            ),
            ListTile(
              leading: const Icon(Icons.label),
              title: const Text('Labels', style: drawerTextStyle),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.labels);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Starred', style: drawerTextStyle),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.starredTasks);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings', style: drawerTextStyle),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.settings);
              },
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help', style: drawerTextStyle),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.help);
              },
            ),
            const Spacer(),
            // Logout button at bottom
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.errorColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _showSignOutDialog(context),
                  child: const Text('Sign Out'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              Navigator.pop(context); // Close drawer
              if (context.mounted) {
                await context.read<AuthProvider>().signOut();
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
