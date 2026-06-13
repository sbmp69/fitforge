import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/coach/coach_screen.dart';
import '../screens/home/home_screen.dart';

import '../screens/meals/meals_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/onboarding/physique_onboarding_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/progress/progress_screen.dart';
import '../screens/shell/main_shell.dart';
import '../screens/workout/workout_screen.dart';

class AppRouter {
  static GoRouter create() {
    return GoRouter(
      initialLocation: '/',
      redirect: (context, state) async {
        final prefs = await SharedPreferences.getInstance();
        final onboarded = prefs.getBool(AppConstants.onboardingKey) ?? false;
        final loggedIn = Supabase.instance.client.auth.currentSession != null;
        final loc = state.matchedLocation;

        if (!onboarded && loc != '/onboarding') return '/onboarding';
        if (onboarded && !loggedIn && !loc.startsWith('/login') && !loc.startsWith('/signup') && loc != '/onboarding') {
          return '/login';
        }
        if (loggedIn && (loc == '/login' || loc == '/signup' || loc == '/onboarding' || loc == '/')) {
          return '/home';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
        GoRoute(path: '/physique-onboarding', builder: (_, __) => const PhysiqueOnboardingScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, __) => const HomeScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/workout', builder: (_, __) => const WorkoutScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/coach', builder: (_, __) => const CoachScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/meals', builder: (_, __) => const MealsScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/progress', builder: (_, __) => const ProgressScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen())]),
          ],
        ),
      ],
    );
  }
}
