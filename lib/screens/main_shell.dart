import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_constants.dart';
import '../routes/app_router.dart';
import '../services/session_manager.dart';
import 'discovery_screen.dart';
import 'matches_screen.dart';
import 'scan_screen.dart';
import 'profile_screen.dart';

/// Main shell with bottom navigation and swipe-between-tabs for authenticated users.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    SessionManager.sessionExpired.addListener(_onSessionExpired);
  }

  @override
  void dispose() {
    _pageController.dispose();
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

  void _navigateTo(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const ClampingScrollPhysics(),
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: const [
          DiscoveryScreen(),
          MatchesScreen(),
          ScanScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppConstants.bgSecondary,
          border: Border(
            top: BorderSide(
              color: AppConstants.borderColor.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _navigateTo,
          backgroundColor: AppConstants.bgSecondary,
          selectedItemColor: AppConstants.accentCyan,
          unselectedItemColor: AppConstants.textMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: [
            _buildNavItem(Icons.explore_outlined, Icons.explore, 'Discover'),
            _buildNavItem(Icons.favorite_outline, Icons.favorite, 'Matches'),
            _buildNavItem(Icons.document_scanner_outlined, Icons.document_scanner, 'Scan'),
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
