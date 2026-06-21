import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
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
import '../../features/engineer/screens/engineer_electricity_screen.dart';
import '../../features/engineer/screens/engineer_production_screen.dart';
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
import '../../features/admin/screens/admin_reports_screen.dart';
import '../../features/admin/screens/admin_electricity_screen.dart';
import '../../features/admin/screens/admin_performance_screen.dart';
import '../../features/admin/screens/admin_ai_screen.dart';
import '../../features/admin/screens/admin_maintenance_screen.dart';
import '../../features/admin/screens/admin_machine_health_screen.dart';
import '../../features/admin/screens/admin_maintenance_costs_screen.dart';
import '../../features/admin/screens/admin_spare_parts_screen.dart';
import '../../features/engineer/screens/engineer_maintenance_schedule_screen.dart';
import '../../features/engineer/screens/engineer_machine_health_screen.dart';
import '../../features/engineer/screens/engineer_maintenance_costs_screen.dart';
import '../../features/engineer/screens/engineer_spare_part_requests_screen.dart';
import '../../features/engineer/screens/engineer_raw_material_alerts_screen.dart';
import '../../features/engineer/screens/engineer_attendance_screen.dart';
import '../../features/sales_rep/screens/sales_dashboard_screen.dart';
import '../../features/sales_rep/screens/sales_customers_screen.dart';
import '../../features/sales_rep/screens/sales_quotations_screen.dart';
import '../../features/sales_rep/screens/sales_visits_screen.dart';
import '../../features/sales_rep/screens/sales_targets_screen.dart';
import '../../features/sales_rep/screens/sales_sales_screen.dart';
import '../../features/worker/screens/worker_payroll_screen.dart';
import '../../features/shared/screens/inventory_screen.dart';
import '../../features/admin/screens/admin_bank_reconciliation_screen.dart';
import '../../features/admin/screens/admin_tax_filings_screen.dart';
import '../../features/admin/screens/admin_purchases_screen.dart';
import '../../features/admin/screens/admin_customer_returns_screen.dart';
import '../../features/admin/screens/admin_cost_analysis_screen.dart';
import '../../features/admin/screens/admin_approval_workflows_screen.dart';
import '../../features/admin/screens/admin_financial_settings_screen.dart';
import '../../features/engineer/screens/engineer_support_machine_screen.dart';

String _roleHome(String role) {
  switch (role) {
    case 'ADMIN':      return '/admin';
    case 'ENGINEER':   return '/engineer';
    case 'ACCOUNTANT': return '/accountant';
    case 'WORKER':     return '/worker';
    case 'SALES_REP':  return '/sales';
    default:           return '/login';
  }
}

final appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    final loc = state.matchedLocation;
    const publicPaths = {
      '/splash', '/login', '/register', '/forgot-password',
      '/reset-password', '/verify-email', '/access-request',
    };
    if (publicPaths.contains(loc)) return null;

    final user = AuthService.currentUser;
    if (user == null) return '/login';

    final role = user.role.toUpperCase();
    if (loc.startsWith('/admin')      && role != 'ADMIN')      return _roleHome(role);
    if (loc.startsWith('/engineer')   && role != 'ENGINEER')   return _roleHome(role);
    if (loc.startsWith('/accountant') && role != 'ACCOUNTANT') return _roleHome(role);
    if (loc.startsWith('/worker')     && role != 'WORKER')     return _roleHome(role);
    if (loc.startsWith('/sales')      && role != 'SALES_REP')  return _roleHome(role);
    return null;
  },
  routes: [
    GoRoute(path: '/splash',          builder: (c, s) => const SplashScreen()),
    GoRoute(path: '/login',           builder: (c, s) => const LoginScreen()),
    GoRoute(path: '/register',        builder: (c, s) => const RegisterScreen()),
    GoRoute(path: '/forgot-password', builder: (c, s) => const ForgotPasswordScreen()),
    GoRoute(path: '/reset-password',  builder: (c, s) => ResetPasswordScreen(
        token: s.uri.queryParameters['token'] ?? '')),
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
    GoRoute(path: '/admin/reports',            builder: (c, s) => const AdminReportsScreen()),
    GoRoute(path: '/admin/electricity',        builder: (c, s) => const AdminElectricityScreen()),
    GoRoute(path: '/admin/performance',        builder: (c, s) => const AdminPerformanceScreen()),
    GoRoute(path: '/admin/ai',                 builder: (c, s) => const AdminAiScreen()),
    GoRoute(path: '/admin/maintenance',        builder: (c, s) => const AdminMaintenanceScreen()),
    GoRoute(path: '/admin/machine-health',     builder: (c, s) => const AdminMachineHealthScreen()),
    GoRoute(path: '/admin/maintenance-costs',  builder: (c, s) => const AdminMaintenanceCostsScreen()),
    GoRoute(path: '/admin/spare-parts',              builder: (c, s) => const AdminSparePartsScreen()),
    GoRoute(path: '/admin/bank-reconciliation',       builder: (c, s) => const AdminBankReconciliationScreen()),
    GoRoute(path: '/admin/tax-filings',               builder: (c, s) => const AdminTaxFilingsScreen()),
    GoRoute(path: '/admin/purchases',                 builder: (c, s) => const AdminPurchasesScreen()),
    GoRoute(path: '/admin/customer-returns',          builder: (c, s) => const AdminCustomerReturnsScreen()),
    GoRoute(path: '/admin/cost-analysis',             builder: (c, s) => const AdminCostAnalysisScreen()),
    GoRoute(path: '/admin/approval-workflows',        builder: (c, s) => const AdminApprovalWorkflowsScreen()),
    GoRoute(path: '/admin/financial-settings',        builder: (c, s) => const AdminFinancialSettingsScreen()),
    // Engineer (new)
    GoRoute(path: '/engineer/maintenance-schedule', builder: (c, s) => const EngineerMaintenanceScheduleScreen()),
    GoRoute(path: '/engineer/machine-health',       builder: (c, s) => const EngineerMachineHealthScreen()),
    GoRoute(path: '/engineer/maintenance-costs',    builder: (c, s) => const EngineerMaintenanceCostsScreen()),
    GoRoute(path: '/engineer/spare-part-requests',  builder: (c, s) => const EngineerSparePartRequestsScreen()),
    GoRoute(path: '/engineer/raw-material-alerts',  builder: (c, s) => const EngineerRawMaterialAlertsScreen()),
    GoRoute(path: '/engineer/attendance',           builder: (c, s) => const EngineerAttendanceScreen()),
    // Engineer
    GoRoute(path: '/engineer',             builder: (c, s) => const EngineerDashboardScreen()),
    GoRoute(path: '/engineer/maintenance', builder: (c, s) => const EngineerMaintenanceScreen()),
    GoRoute(path: '/engineer/quality',     builder: (c, s) => const EngineerQualityScreen()),
    GoRoute(path: '/engineer/machines',    builder: (c, s) => const EngineerMachinesScreen()),
    GoRoute(path: '/engineer/spare-parts', builder: (c, s) => const EngineerSparePartsScreen()),
    GoRoute(path: '/engineer/inventory',   builder: (c, s) => const EngineerInventoryScreen()),
    GoRoute(path: '/engineer/documents',    builder: (c, s) => const EngineerDocumentsScreen()),
    GoRoute(path: '/engineer/electricity', builder: (c, s) => const EngineerElectricityScreen()),
    GoRoute(path: '/engineer/production',       builder: (c, s) => const EngineerProductionScreen()),
    GoRoute(path: '/engineer/support-machine',  builder: (c, s) => const EngineerSupportMachineScreen()),
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
    GoRoute(path: '/worker/tools',       builder: (c, s) => const WorkerToolsScreen()),
    GoRoute(path: '/worker/electricity', builder: (c, s) => const WorkerElectricityScreen()),
    GoRoute(path: '/worker/payroll',     builder: (c, s) => const WorkerPayrollScreen()),
    // Shared
    GoRoute(path: '/inventory',        builder: (c, s) => const InventoryScreen()),
    // Sales Rep
    GoRoute(path: '/sales',            builder: (c, s) => const SalesDashboardScreen()),
    GoRoute(path: '/sales/sales',      builder: (c, s) => const SalesSalesScreen()),
    GoRoute(path: '/sales/customers',  builder: (c, s) => const SalesCustomersScreen()),
    GoRoute(path: '/sales/quotations', builder: (c, s) => const SalesQuotationsScreen()),
    GoRoute(path: '/sales/visits',     builder: (c, s) => const SalesVisitsScreen()),
    GoRoute(path: '/sales/targets',    builder: (c, s) => const SalesTargetsScreen()),
  ],
);
