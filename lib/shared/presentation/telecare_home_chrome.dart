import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../features/auth/data/models/user_model.dart';

class TeleCareHomeAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const TeleCareHomeAppBar({
    super.key,
    required this.user,
    this.title = 'TeleCare',
    this.onMenuPressed,
  });

  final UserModel user;
  final String title;
  final VoidCallback? onMenuPressed;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final initial = user.fullName.isNotEmpty
        ? user.fullName[0].toUpperCase()
        : 'U';

    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.black),
          onPressed: onMenuPressed ?? () => Scaffold.of(context).openDrawer(),
          tooltip: 'Menu',
        ),
      ),
      centerTitle: true,
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: [
        const TeleCareNotificationButton(),
        GestureDetector(
          onTap: () => context.go('/profile'),
          child: Padding(
            padding: const EdgeInsets.only(right: 14),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: AppTheme.primarySurface,
              backgroundImage:
                  user.profileImage != null && user.profileImage!.isNotEmpty
                  ? NetworkImage(user.profileImage!)
                  : null,
              child: user.profileImage == null || user.profileImage!.isEmpty
                  ? Text(
                      initial,
                      style: const TextStyle(
                        color: AppTheme.primaryDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

class TeleCareNotificationButton extends StatelessWidget {
  const TeleCareNotificationButton({super.key, this.iconColor = Colors.black});

  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Badge(
        smallSize: 8,
        backgroundColor: AppTheme.alertColor,
        child: Icon(Icons.notifications_none_rounded, color: iconColor),
      ),
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        backgroundColor: Colors.white,
        builder: (context) => const _NotificationsSheet(),
      ),
      tooltip: 'Notifications',
    );
  }
}

class TeleCareDrawer extends StatelessWidget {
  const TeleCareDrawer({
    super.key,
    required this.user,
    required this.items,
    required this.onLogout,
  });

  final UserModel user;
  final List<TeleCareDrawerItem> items;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primarySurface,
                child: Text(
                  user.fullName.isNotEmpty
                      ? user.fullName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                user.fullName,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                user.email,
                style: const TextStyle(color: AppTheme.neutralMedium),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final item in items)
                    ListTile(
                      leading: Icon(item.icon, color: AppTheme.primaryColor),
                      title: Text(
                        item.label,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        context.go(item.route);
                      },
                    ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: AppTheme.errorColor,
              ),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onLogout();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class TeleCareDrawerItem {
  const TeleCareDrawerItem({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

class TrustBadge extends StatelessWidget {
  const TrustBadge({
    super.key,
    required this.label,
    required this.icon,
    this.color = AppTheme.successColor,
    this.backgroundColor = AppTheme.successSurface,
    this.maxWidth = 220,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmergencySosButton extends StatelessWidget {
  const EmergencySosButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'patient-sos',
      backgroundColor: AppTheme.errorColor,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.emergency_rounded),
      label: const Text('SOS'),
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        backgroundColor: Colors.white,
        builder: (context) => const _EmergencySheet(),
      ),
    );
  }
}

class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context) {
    const items = [
      _NotificationEntry(
        Icons.event_available_rounded,
        'Appointment reminder',
        'Your next consultation is coming up.',
      ),
      _NotificationEntry(
        Icons.chat_bubble_rounded,
        'New message',
        'You have a new care-team message.',
      ),
      _NotificationEntry(
        Icons.medication_rounded,
        'Prescription update',
        'A digital prescription was updated.',
      ),
      _NotificationEntry(
        Icons.payments_rounded,
        'Payment update',
        'Your payment status has changed.',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notifications',
            style: TextStyle(
              color: Colors.black,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (final item in items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(item.icon, color: AppTheme.primaryColor),
              title: Text(
                item.title,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                item.body,
                style: const TextStyle(color: AppTheme.neutralMedium),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmergencySheet extends StatelessWidget {
  const _EmergencySheet();

  @override
  Widget build(BuildContext context) {
    const items = [
      _NotificationEntry(
        Icons.contact_phone_rounded,
        'Emergency contacts',
        'Notify saved emergency contacts.',
      ),
      _NotificationEntry(
        Icons.local_hospital_rounded,
        'Hospital',
        'Find nearby healthcare personnel and facilities.',
      ),
      _NotificationEntry(
        Icons.airport_shuttle_rounded,
        'Ambulance',
        'Request ambulance support.',
      ),
      _NotificationEntry(
        Icons.call_rounded,
        'Emergency call',
        'Place an emergency call now.',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Emergency SOS',
            style: TextStyle(
              color: Colors.black,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (final item in items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(item.icon, color: AppTheme.errorColor),
              title: Text(
                item.title,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                item.body,
                style: const TextStyle(color: AppTheme.neutralMedium),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationEntry {
  const _NotificationEntry(this.icon, this.title, this.body);

  final IconData icon;
  final String title;
  final String body;
}
