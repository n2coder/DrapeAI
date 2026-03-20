import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:style_ai/features/auth/providers/auth_provider.dart';
import 'package:style_ai/features/auth/screens/login_screen.dart';
import 'package:style_ai/features/auth/screens/otp_screen.dart';
import 'package:style_ai/features/onboarding/screens/onboarding_screen.dart';
import 'package:style_ai/features/recommendation/screens/home_screen.dart';
import 'package:style_ai/features/recommendation/screens/occasion_screen.dart';
import 'package:style_ai/features/recommendation/screens/outfit_result_screen.dart';
import 'package:style_ai/features/wardrobe/models/clothing_item.dart';
import 'package:style_ai/features/wardrobe/screens/add_clothing_screen.dart';
import 'package:style_ai/features/wardrobe/screens/wardrobe_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<AuthState>(const AuthState());
  ref.listen(authProvider, (_, next) => authNotifier.value = next);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final status = authState.status;
      final location = state.matchedLocation;

      // Still initializing
      if (status == AuthStatus.initial) return null;

      final isAuthRoute = location == '/login' || location == '/otp';
      final isOnboardingRoute = location == '/onboarding';
      final isAppRoute = location.startsWith('/home') ||
          location.startsWith('/wardrobe') ||
          location.startsWith('/add-clothing') ||
          location.startsWith('/occasion') ||
          location.startsWith('/outfit-result');

      switch (status) {
        case AuthStatus.unauthenticated:
        case AuthStatus.error:
          if (!isAuthRoute) return '/login';
          return null;
        case AuthStatus.otpSent:
        case AuthStatus.verifying:
          if (location != '/otp') return '/otp';
          return null;
        case AuthStatus.onboardingRequired:
          if (!isOnboardingRoute) return '/onboarding';
          return null;
        case AuthStatus.authenticated:
          if (isAuthRoute || isOnboardingRoute || location == '/') {
            return '/home';
          }
          return null;
        case AuthStatus.initial:
          return null;
      }
    },
    routes: [
      // Splash / initial
      GoRoute(
        path: '/',
        builder: (context, state) => const _SplashScreen(),
      ),
      // Auth
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: '/otp',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OtpScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      // Onboarding
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      // Home
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HomeScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      // Wardrobe
      GoRoute(
        path: '/wardrobe',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WardrobeScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: '/add-clothing',
        pageBuilder: (context, state) {
          final existingItem = state.extra as ClothingItem?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: AddClothingScreen(existingItem: existingItem),
            transitionsBuilder: _bottomSheetTransition,
          );
        },
      ),
      // Occasion
      GoRoute(
        path: '/occasion',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OccasionScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      // Outfit result
      GoRoute(
        path: '/outfit-result',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OutfitResultScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
    ],
    errorBuilder: (context, state) => _ErrorScreen(error: state.error),
  );
});

// ─── Transition builders ───────────────────────────────────────────────────────

Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}

Widget _slideTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
    ),
    child: child,
  );
}

Widget _bottomSheetTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
    ),
    child: child,
  );
}

// ─── Helper screens ────────────────────────────────────────────────────────────

class _SplashScreen extends ConsumerWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/images/logo.png',
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
          ),
            const SizedBox(height: 20),
            const Text(
              'DrapeAI',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Color(0xFF6C63FF),
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Color(0xFF6C63FF)),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final Exception? error;

  const _ErrorScreen({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(height: 16),
              const Text(
                'Page Not Found',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                error?.toString() ?? 'The page you\'re looking for doesn\'t exist.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
