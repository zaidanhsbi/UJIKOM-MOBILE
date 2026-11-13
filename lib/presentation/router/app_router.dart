import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../pages/dashboard_page.dart';
import '../pages/exam_room_page.dart';
import '../pages/login_page.dart';
import '../providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, _) {
    refreshNotifier.value++;
  });
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refreshNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authProvider);
      if (!authState.initialized) return null;

      final isLoggedIn = authState.isAuthenticated;
      final onLogin = state.matchedLocation == '/login';

      if (!isLoggedIn && !onLogin) {
        return '/login';
      }
      if (isLoggedIn && onLogin) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/exam/:id',
        builder: (context, state) {
          final examId = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return ExamRoomPage(examId: examId);
        },
      ),
    ],
  );
});
