import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_providers.dart';
import '../../auth/providers/auth_state.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final userName = authState is AuthAuthenticated
        ? authState.user.fullName
        : 'there';

    return Scaffold(
      appBar: AppBar(
        title: const Text('TeleCare Home'),
        actions: [
          IconButton(
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back, $userName', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('Phase 4 is now connected to the app with verified-doctor discovery and appointment management.'),
            const SizedBox(height: 16),
            _FeatureCard(
              title: 'Appointments',
              subtitle: 'View verified doctors, create booking requests, and manage approvals.',
              icon: Icons.calendar_month,
              onTap: () => context.go('/appointments'),
            ),
            const SizedBox(height: 12),
            _FeatureCard(
              title: 'Consultations',
              subtitle: 'Continue with your consultation workflow once the session is ready.',
              icon: Icons.videocam_outlined,
              onTap: () => context.go('/consultations'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
