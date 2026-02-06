import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../presentation/screens/login_screen.dart';
import '../presentation/screens/set_password_screen.dart';
import '../presentation/screens/dashboard_screen.dart';
import '../presentation/screens/asset_list_screen.dart';
import '../presentation/screens/rebalance_screen.dart';
import '../presentation/screens/history_screen.dart';
import '../presentation/screens/settings_screen.dart';

/// 路由配置
class AppRouter {
  static const String login = '/login';
  static const String setPassword = '/set-password';
  static const String dashboard = '/';
  static const String assets = '/assets';
  static const String rebalance = '/rebalance';
  static const String history = '/history';
  static const String settings = '/settings';

  static final GoRouter router = GoRouter(
    initialLocation: login,
    routes: [
      GoRoute(
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: setPassword,
        builder: (context, state) => const SetPasswordScreen(),
      ),
      GoRoute(
        path: dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: assets,
        builder: (context, state) => const AssetListScreen(),
      ),
      GoRoute(
        path: rebalance,
        builder: (context, state) => const RebalanceScreen(),
      ),
      GoRoute(
        path: history,
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
