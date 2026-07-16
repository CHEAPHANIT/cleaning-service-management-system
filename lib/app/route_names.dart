String dashboardRouteForRole(String role) => switch (role) {
  'admin' => AdminDashboardRoute.route,
  'cleaner' => CleanerDashboardRoute.route,
  _ => CustomerDashboardRoute.route,
};

abstract final class CustomerDashboardRoute {
  static const route = '/customer/dashboard';
}

abstract final class CustomerProfileRoute {
  static const route = '/customer/profile';
}

abstract final class CleanerDashboardRoute {
  static const route = '/cleaner/dashboard';
}

abstract final class CleanerAssignedJobsRoute {
  static const route = '/cleaner/assigned-jobs';
}

abstract final class AdminDashboardRoute {
  static const route = '/admin/dashboard';
}
