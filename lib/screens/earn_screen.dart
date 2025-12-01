import 'package:flutter/material.dart';
import 'tasks/tasks_screen.dart';
import 'games/games_screen.dart';

class EarnScreen extends StatefulWidget {
  const EarnScreen({super.key});

  @override
  State<EarnScreen> createState() => _EarnScreenState();
}

class _EarnScreenState extends State<EarnScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Earn Rewards'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryColor,
          labelColor: primaryColor,
          unselectedLabelColor: onSurfaceVariant,
          tabs: const [
            Tab(text: 'Tasks', icon: Icon(Icons.assignment_outlined)),
            Tab(text: 'Games', icon: Icon(Icons.sports_esports_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [TasksScreen(), GamesScreen()],
      ),
    );
  }
}
