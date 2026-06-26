import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/data/models/user_model.dart';

import '../../core/theme/app_theme.dart';

/// Consistent top app bar for main tab screens with profile avatar top-right.
class TeleCareTabAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TeleCareTabAppBar({
    super.key,
    required this.title,
    required this.user,
    this.showBackButton = false,
    this.showProfileButton = true,
  });

  final String title;
  final UserModel user;
  final bool showBackButton;
  final bool showProfileButton;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final initial = user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U';

    return AppBar(
      backgroundColor: AppTheme.primaryColor,
      automaticallyImplyLeading: false,

      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go('/home');
                }
              },
            )
          : null,
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      actions: [
        if (showProfileButton)
          GestureDetector(
            onTap: () => context.go('/profile'),
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                backgroundImage: user.profileImage != null && user.profileImage!.isNotEmpty
                    ? NetworkImage(user.profileImage!)
                    : null,
                child: user.profileImage == null || user.profileImage!.isEmpty
                    ? Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      )
                    : null,
              ),
            ),
          ),
      ],
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryDark, AppTheme.primaryColor],
          ),
        ),
      ),
    );
  }
}
