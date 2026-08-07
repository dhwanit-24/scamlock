import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/app_routes.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        scrolledUnderElevation: 0,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: const Text(
          'Admin Dashboard',
          style: AppTypography.cardTitle,
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.canvas,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(AppRadius.lg),
                  ),
                  title: const Text(
                    'Sign out?',
                    style: AppTypography.cardTitle,
                  ),
                  content: const Text(
                    'You will be signed out of ScamLock.',
                    style: AppTypography.body,
                  ),
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
                Navigator.of(context).pushReplacementNamed(
                  AppRoutes.login,
                );
              }
            },
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),

              _AdminCard(
                title: 'Pending Approvals',
                subtitle: 'Review and approve new firm requests',
                icon: Icons.pending_outlined,
                background: AppColors.canvas,
                onTap: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.adminPendingUsers,
                  );
                },
              ),

              const SizedBox(height: AppSpacing.md),

              _AdminCard(
                title: 'All Users',
                subtitle: 'Manage member access and subscriptions',
                icon: Icons.people_outlined,
                background: AppColors.canvas,
                onTap: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.adminUserList,
                  );
                },
              ),

              const SizedBox(height: AppSpacing.md),

              _AdminCard(
                title: 'Audit Log',
                subtitle: 'View all admin actions and history',
                icon: Icons.history_outlined,
                background: AppColors.canvas,
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
    required this.background,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: background,
            borderRadius:
            BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: AppColors.hairline,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.canvas,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppColors.ink,
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.cardTitle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTypography.bodySm,
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right,
                color: AppColors.ink,
              ),
            ],
          ),
        ),
      ),
    );
  }
}