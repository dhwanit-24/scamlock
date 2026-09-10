import 'package:flutter/material.dart';

import 'core/routes/app_routes.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'features/auth/presentation/screens/pending_approval_screen.dart';
import 'features/auth/presentation/screens/request_access_screen.dart';
import 'features/admin/presentation/screens/admin_pending_users_screen.dart';
import 'features/admin/presentation/screens/admin_user_list_screen.dart';
import 'features/admin/presentation/screens/admin_audit_log_screen.dart';
import 'features/search/presentation/screens/search_screen.dart';
import 'features/search/presentation/screens/record_detail_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/home/presentation/screens/my_locks_screen.dart';
import 'features/home/presentation/screens/profile_screen.dart';
import 'features/lock/presentation/screens/confirm_lock_screen.dart';
import 'features/lock/presentation/screens/lock_person_screen.dart';
import 'features/auth/presentation/screens/auth_gate_screen.dart';
import 'core/theme/app_theme.dart';
import 'features/support/presentation/screens/contact_support_screen.dart';

class ScamLockApp extends StatelessWidget {
  const ScamLockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScamLock',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AuthGateScreen(),
      routes: {
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.requestAccess: (_) => const RequestAccessScreen(),
        AppRoutes.pendingApproval: (_) => const PendingApprovalScreen(),
        AppRoutes.adminDashboard: (_) => const AdminDashboardScreen(),
        AppRoutes.adminPendingUsers: (_) => const AdminPendingUsersScreen(),
        AppRoutes.adminUserList: (_) => const AdminUserListScreen(),
        AppRoutes.adminAuditLog: (_) => const AdminAuditLogScreen(),
        AppRoutes.home: (_) => const HomeScreen(),
        AppRoutes.search: (_) => const SearchScreen(),
        AppRoutes.recordDetail: (_) => const RecordDetailScreen(),
        AppRoutes.lockPerson: (_) => const LockPersonScreen(),
        AppRoutes.myLocks: (_) => const MyLocksScreen(),
        AppRoutes.profile: (_) => const ProfileScreen(),
        AppRoutes.confirmLock: (_) => const ConfirmLockScreen(),
        AppRoutes.contactSupport: (_) => const ContactSupportScreen(),
      },
    );
  }
}