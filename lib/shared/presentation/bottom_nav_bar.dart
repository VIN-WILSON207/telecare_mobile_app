import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class TeleCareHomeBackScope extends StatelessWidget {
  const TeleCareHomeBackScope({
    super.key,
    required this.currentPath,
    required this.child,
  });

  final String currentPath;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isHome = currentPath == '/home';
    return PopScope(
      canPop: isHome,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !isHome) {
          context.go('/home');
        }
      },
      child: child,
    );
  }
}

class PatientBottomNavBar extends StatelessWidget {
  final String currentPath;

  const PatientBottomNavBar({super.key, required this.currentPath});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _BottomTabItem(
        icon: Icons.home_rounded,
        activeIcon: Icons.home_rounded,
        label: 'Home',
        route: '/home',
      ),
      _BottomTabItem(
        icon: Icons.calendar_today_rounded,
        activeIcon: Icons.calendar_month_rounded,
        label: 'Appointments',
        route: '/appointments',
      ),
      _BottomTabItem(
        icon: Icons.chat_bubble_outline_rounded,
        activeIcon: Icons.chat_bubble_rounded,
        label: 'Messages',
        route: '/messages',
      ),
      _BottomTabItem(
        icon: Icons.description_outlined,
        activeIcon: Icons.description_rounded,
        label: 'Records',
        route: '/medical-records',
      ),
    ];

    return _CommonBottomNavBar(currentPath: currentPath, tabs: tabs);
  }
}

class DoctorBottomNavBar extends StatelessWidget {
  final String currentPath;

  const DoctorBottomNavBar({super.key, required this.currentPath});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _BottomTabItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        label: 'Home',
        route: '/home',
      ),
      _BottomTabItem(
        icon: Icons.calendar_today_rounded,
        activeIcon: Icons.calendar_month_rounded,
        label: 'Schedule',
        route: '/appointments',
      ),
      _BottomTabItem(
        icon: Icons.people_outline_rounded,
        activeIcon: Icons.people_rounded,
        label: 'Patients',
        route: '/patients',
      ),
      _BottomTabItem(
        icon: Icons.chat_bubble_outline_rounded,
        activeIcon: Icons.chat_bubble_rounded,
        label: 'Messages',
        route: '/messages',
      ),
    ];

    return _CommonBottomNavBar(currentPath: currentPath, tabs: tabs);
  }
}

class _BottomTabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  _BottomTabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}

class _CommonBottomNavBar extends StatelessWidget {
  final String currentPath;
  final List<_BottomTabItem> tabs;

  const _CommonBottomNavBar({required this.currentPath, required this.tabs});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: tabs.map((tab) {
              final isSelected = currentPath == tab.route;
              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isSelected ? null : () => context.go(tab.route),
                    borderRadius: BorderRadius.circular(16),
                    splashColor: AppTheme.primaryColor.withValues(alpha: 0.05),
                    highlightColor: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected ? tab.activeIcon : tab.icon,
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.neutralLight,
                            size: 28,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tab.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : AppTheme.neutralLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 4,
                            width: isSelected ? 4 : 0,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
