import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/pages/home/home_page.dart';
import '../presentation/pages/add_expense/add_expense_page.dart';
import '../presentation/pages/statistics/statistics_page.dart';
import '../presentation/pages/history/history_page.dart';
import '../presentation/pages/calendar/calendar_page.dart';
import '../presentation/pages/settings/settings_page.dart';
import '../presentation/pages/report/report_page.dart';
import '../presentation/pages/automation/automation_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomePage(),
          ),
        ),
        GoRoute(
          path: '/statistics',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: StatisticsPage(),
          ),
        ),
        GoRoute(
          path: '/history',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HistoryPage(),
          ),
        ),
        GoRoute(
          path: '/calendar',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CalendarPage(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/add-expense',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final expenseId = state.uri.queryParameters['id'];
        return AddExpensePage(expenseId: expenseId);
      },
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/report',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ReportPage(),
    ),
    GoRoute(
      path: '/automation',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AutomationPage(),
    ),
  ],
);

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: '首页',
                  isSelected: _calculateSelectedIndex(context) == 0,
                  onTap: () => _onItemTapped(0, context),
                ),
                _NavItem(
                  icon: Icons.pie_chart_rounded,
                  label: '统计',
                  isSelected: _calculateSelectedIndex(context) == 1,
                  onTap: () => _onItemTapped(1, context),
                ),
                _NavItem(
                  icon: Icons.history_rounded,
                  label: '记录',
                  isSelected: _calculateSelectedIndex(context) == 2,
                  onTap: () => _onItemTapped(2, context),
                ),
                _NavItem(
                  icon: Icons.calendar_month_rounded,
                  label: '日历',
                  isSelected: _calculateSelectedIndex(context) == 3,
                  onTap: () => _onItemTapped(3, context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location == '/') return 0;
    if (location == '/statistics') return 1;
    if (location == '/history') return 2;
    if (location == '/calendar') return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/statistics');
        break;
      case 2:
        context.go('/history');
        break;
      case 3:
        context.go('/calendar');
        break;
    }
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2196F3).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF2196F3) : Colors.grey.shade400,
              size: 26,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF2196F3),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
