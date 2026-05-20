import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_constants.dart';
import '../routes/app_router.dart';
import '../services/session_manager.dart';
import 'dashboard_screen.dart';
import 'scan_screen.dart';
import 'match_screen.dart';
import 'profile_screen.dart';

/// Main shell with bottom navigation for authenticated users.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    DashboardScreen(),
    ScanScreen(),
    MatchScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    SessionManager.sessionExpired.addListener(_onSessionExpired);
  }

  @override
  void dispose() {
    SessionManager.sessionExpired.removeListener(_onSessionExpired);
    super.dispose();
  }

  void _onSessionExpired() {
    if (!SessionManager.sessionExpired.value) return;
    SessionManager.sessionExpired.value = false;

    if (!mounted) return;
    context.go(AppRouter.login);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your session has expired. Please sign in again.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppConstants.borderColor.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: [
            _buildNavItem(Icons.dashboard_outlined, Icons.dashboard, 'Home'),
            _buildNavItem(Icons.document_scanner_outlined, Icons.document_scanner, 'Scan'),
            _buildNavItem(Icons.favorite_outline, Icons.favorite, 'Match'),
            _buildNavItem(Icons.person_outline, Icons.person, 'Profile'),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData outlinedIcon,
    IconData filledIcon,
    String label,
  ) {
    return BottomNavigationBarItem(
      icon: Icon(outlinedIcon),
      activeIcon: ShaderMask(
        shaderCallback: (bounds) =>
            AppConstants.accentGradient.createShader(bounds),
        child: Icon(filledIcon, color: Colors.white),
      ),
      label: label,
    );
  }
}
