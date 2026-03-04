import 'package:flutter/material.dart';
import '../config/app_constants.dart';
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
