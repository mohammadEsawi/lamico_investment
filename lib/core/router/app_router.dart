import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/auth/screens/verify_email_screen.dart';
import '../../features/auth/screens/access_request_screen.dart';
import '../../features/shared/screens/splash_screen.dart';
import '../../features/shared/screens/chat_screen.dart';
import '../../features/shared/screens/notifications_screen.dart';
import '../../features/shared/screens/profile_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_analytics_screen.dart';
import '../../features/admin/screens/admin_users_screen.dart';
import '../../features/admin/screens/admin_machines_screen.dart';
import '../../features/admin/screens/admin_shifts_screen.dart';
import '../../features/admin/screens/admin_attendance_screen.dart';
import '../../features/admin/screens/admin_payroll_screen.dart';
import '../../features/admin/screens/admin_settings_screen.dart';
import '../../features/admin/screens/admin_audit_logs_screen.dart';
import '../../features/admin/screens/admin_registration_requests_screen.dart';
import '../../features/admin/screens/admin_worker_overview_screen.dart';
import '../../features/engineer/screens/engineer_dashboard_screen.dart';
import '../../features/engineer/screens/engineer_maintenance_screen.dart';
import '../../features/engineer/screens/engineer_quality_screen.dart';
import '../../features/engineer/screens/engineer_machines_screen.dart';
import '../../features/engineer/screens/engineer_spare_parts_screen.dart';
import '../../features/engineer/screens/engineer_inventory_screen.dart';
import '../../features/engineer/screens/engineer_documents_screen.dart';
import '../../features/accountant/screens/accountant_dashboard_screen.dart';
import '../../features/accountant/screens/accountant_invoices_screen.dart';
import '../../features/accountant/screens/accountant_receivables_screen.dart';
import '../../features/accountant/screens/accountant_payables_screen.dart';
import '../../features/accountant/screens/accountant_suppliers_screen.dart';
import '../../features/accountant/screens/accountant_expenses_screen.dart';
import '../../features/accountant/screens/accountant_reports_screen.dart';
import '../../features/accountant/screens/accountant_budget_screen.dart';
import '../../features/worker/screens/worker_dashboard_screen.dart';
import '../../features/worker/screens/worker_production_screen.dart';
import '../../features/worker/screens/worker_attendance_screen.dart';
import '../../features/worker/screens/worker_tools_screen.dart';
import '../../features/worker/screens/worker_electricity_screen.dart';
import '../../features/admin/screens/admin_production_screen.dart';
import '../../features/sales_rep/screens/sales_dashboard_screen.dart';
import '../../features/sales_rep/screens/sales_customers_screen.dart';
import '../../features/sales_rep/screens/sales_quotations_screen.dart';
import '../../features/sales_rep/screens/sales_visits_screen.dart';
import '../../features/sales_rep/screens/sales_targets_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash',          builder: (c, s) => const SplashScreen()),
    GoRoute(path: '/login',           builder: (c, s) => const LoginScreen()),
    GoRoute(path: '/register',        builder: (c, s) => const RegisterScreen()),
    GoRoute(path: '/forgot-password', builder: (c, s) => const ForgotPasswordScreen()),
    GoRoute(path: '/reset-password',  builder: (c, s) => const ResetPasswordScreen()),
    GoRoute(path: '/verify-email',    builder: (c, s) => const VerifyEmailScreen()),
    GoRoute(path: '/access-request',  builder: (c, s) => const AccessRequestScreen()),
    GoRoute(path: '/chat',            builder: (c, s) => const ChatScreen()),
    GoRoute(path: '/notifications',   builder: (c, s) => const NotificationsScreen()),
    GoRoute(path: '/profile',         builder: (c, s) => const ProfileScreen()),
    // Admin
    GoRoute(path: '/admin',           builder: (c, s) => const AdminDashboardScreen()),
    GoRoute(path: '/admin/analytics', builder: (c, s) => const AdminAnalyticsScreen()),
    GoRoute(path: '/admin/users',     builder: (c, s) => const AdminUsersScreen()),
    GoRoute(path: '/admin/machines',  builder: (c, s) => const AdminMachinesScreen()),
    GoRoute(path: '/admin/shifts',    builder: (c, s) => const AdminShiftsScreen()),
    GoRoute(path: '/admin/attendance',builder: (c, s) => const AdminAttendanceScreen()),
    GoRoute(path: '/admin/payroll',   builder: (c, s) => const AdminPayrollScreen()),
    GoRoute(path: '/admin/settings',  builder: (c, s) => const AdminSettingsScreen()),
    GoRoute(path: '/admin/audit',     builder: (c, s) => const AdminAuditLogsScreen()),
    GoRoute(path: '/admin/requests',  builder: (c, s) => const AdminRegistrationRequestsScreen()),
    GoRoute(path: '/admin/workers',    builder: (c, s) => const AdminWorkerOverviewScreen()),
    GoRoute(path: '/admin/production', builder: (c, s) => const AdminProductionScreen()),
    // Engineer
    GoRoute(path: '/engineer',             builder: (c, s) => const EngineerDashboardScreen()),
    GoRoute(path: '/engineer/maintenance', builder: (c, s) => const EngineerMaintenanceScreen()),
    GoRoute(path: '/engineer/quality',     builder: (c, s) => const EngineerQualityScreen()),
    GoRoute(path: '/engineer/machines',    builder: (c, s) => const EngineerMachinesScreen()),
    GoRoute(path: '/engineer/spare-parts', builder: (c, s) => const EngineerSparePartsScreen()),
    GoRoute(path: '/engineer/inventory',   builder: (c, s) => const EngineerInventoryScreen()),
    GoRoute(path: '/engineer/documents',   builder: (c, s) => const EngineerDocumentsScreen()),
    // Accountant
    GoRoute(path: '/accountant',              builder: (c, s) => const AccountantDashboardScreen()),
    GoRoute(path: '/accountant/invoices',     builder: (c, s) => const AccountantInvoicesScreen()),
    GoRoute(path: '/accountant/receivables',  builder: (c, s) => const AccountantReceivablesScreen()),
    GoRoute(path: '/accountant/payables',     builder: (c, s) => const AccountantPayablesScreen()),
    GoRoute(path: '/accountant/suppliers',    builder: (c, s) => const AccountantSuppliersScreen()),
    GoRoute(path: '/accountant/expenses',     builder: (c, s) => const AccountantExpensesScreen()),
    GoRoute(path: '/accountant/reports',      builder: (c, s) => const AccountantReportsScreen()),
    GoRoute(path: '/accountant/budget',       builder: (c, s) => const AccountantBudgetScreen()),
    // Worker
    GoRoute(path: '/worker',             builder: (c, s) => const WorkerDashboardScreen()),
    GoRoute(path: '/worker/production',  builder: (c, s) => const WorkerProductionScreen()),
    GoRoute(path: '/worker/attendance',  builder: (c, s) => const WorkerAttendanceScreen()),
    GoRoute(path: '/worker/tools',        builder: (c, s) => const WorkerToolsScreen()),
    GoRoute(path: '/worker/electricity',  builder: (c, s) => const WorkerElectricityScreen()),
    // Sales Rep
    GoRoute(path: '/sales',            builder: (c, s) => const SalesDashboardScreen()),
    GoRoute(path: '/sales/customers',  builder: (c, s) => const SalesCustomersScreen()),
    GoRoute(path: '/sales/quotations', builder: (c, s) => const SalesQuotationsScreen()),
    GoRoute(path: '/sales/visits',     builder: (c, s) => const SalesVisitsScreen()),
    GoRoute(path: '/sales/targets',    builder: (c, s) => const SalesTargetsScreen()),
  ],
);
