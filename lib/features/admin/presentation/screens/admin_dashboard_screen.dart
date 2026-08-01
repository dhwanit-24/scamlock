import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/routes/app_routes.dart';
import 'admin_pending_users_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign out?'),
                  content: const Text('You will be signed out of ScamLock.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              );
              if (confirmed != true) return;
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed(AppRoutes.login);
              }
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                'Admin Panel',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _AdminCard(
                title: 'Pending Approvals',
                subtitle: 'Review and approve new firm requests',
                icon: Icons.pending_outlined,
                onTap: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.adminPendingUsers,
                  );
                },
              ),
              const SizedBox(height: 16),
              _AdminCard(
                title: 'All Users',
                subtitle: 'Manage member access and subscriptions',
                icon: Icons.people_outlined,
                onTap: () {
                  Navigator.of(context).pushNamed(
                  AppRoutes.adminUserList,
                );  
                },
              ),
              const SizedBox(height: 16),
              _AdminCard(
                title: 'Audit Log',
                subtitle: 'View all admin actions and history',
                icon: Icons.history_outlined,
                onTap: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.adminAuditLog,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, size: 28),
        title: Text(title, style: const TextStyle(fontSize: 16)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}