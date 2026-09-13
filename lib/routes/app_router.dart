import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/dashboard/screens/home_screen.dart';
import '../features/produce/screens/produce_screen.dart';
import '../features/produce/screens/add_produce_screen.dart';
import '../features/produce/screens/produce_detail_screen.dart';
import '../features/market/screens/market_screen.dart';
import '../features/alerts/screens/alerts_screen.dart';
import '../features/storage/screens/detailed_storage_screen.dart';
import '../features/produce/screens/dispatch_transit_screen.dart';
import '../features/produce/screens/transit_tracker_screen.dart';
import '../features/simulator/screens/hardware_simulator_screen.dart';
import '../features/navigation/main_scaffold.dart';
import '../state/auth_providers.dart';

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

/// Reactive Router notifier that responds to authentication state changes.
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authStateProvider, (_, __) {
      notifyListeners();
    });
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authStateProvider);
    final isLoggingIn = state.matchedLocation == '/login';

    // If auth state is not yet initialized, stay on current path or splash
    if (!authState.isInitialized) {
      return null;
    }

    // If user is not authenticated and trying to access protected routes
    if (!authState.isAuthenticated) {
      return isLoggingIn ? null : '/login';
    }

    // If user is authenticated and navigating to login portal, redirect to Home
    if (isLoggingIn) {
      return '/';
    }

    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    refreshListenable: notifier,
    initialLocation: '/',
    redirect: notifier.redirect,
    routes: _buildRoutes(),
  );
});

/// Fallback static router instance
final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: _buildRoutes(),
);

List<RouteBase> _buildRoutes() {
  return [
    // Dedicated Farmer & Technician Login Portal
    GoRoute(
      path: '/login',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const LoginScreen(),
    ),

    // Detailed Storage & Analytics Route
    GoRoute(
      path: '/storage/:id',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final unitId = state.pathParameters['id'] ?? 'AC-NER-001';
        return DetailedStorageScreen(unitId: unitId);
      },
    ),

    // Produce Intake Form Route
    GoRoute(
      path: '/produce/add',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const AddProduceScreen(),
    ),

    // Produce Detail Route
    GoRoute(
      path: '/produce/detail/:batchId',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final batchId = state.pathParameters['batchId'] ?? 'AC-2026-00125';
        return ProduceDetailScreen(batchId: batchId);
      },
    ),

    // Dispatch Batch to Cold Chain Route
    GoRoute(
      path: '/produce/dispatch/:batchId',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final batchId = state.pathParameters['batchId'] ?? 'AC-2026-00125';
        return DispatchTransitScreen(batchId: batchId);
      },
    ),

    // Transit Live Tracking Route
    GoRoute(
      path: '/produce/transit/:manifestId',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final manifestId =
            state.pathParameters['manifestId'] ?? 'TR-NER-2026-0081';
        return TransitTrackerScreen(manifestId: manifestId);
      },
    ),

    // Developer Hardware Simulator Route
    GoRoute(
      path: '/simulator',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const HardwareSimulatorScreen(),
    ),

    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainScaffold(navigationShell: navigationShell);
      },
      branches: [
        // 1. Home Tab
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),

        // 2. Produce Tab
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/produce',
              builder: (context, state) => const ProduceScreen(),
            ),
          ],
        ),

        // 3. Market Tab
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/market',
              builder: (context, state) => const MarketScreen(),
            ),
          ],
        ),

        // 4. Alerts Tab
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/alerts',
              builder: (context, state) => const AlertsScreen(),
            ),
          ],
        ),
      ],
    ),
  ];
}
