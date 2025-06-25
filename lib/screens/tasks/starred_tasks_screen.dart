import 'package:flutter/material.dart';
import '../../widgets/common/app_drawer.dart';

class StarredTasksScreen extends StatelessWidget {
  const StarredTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Starred Tasks'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: const Center(child: Text('Starred Tasks - Coming Soon')),
    );
  }
}
