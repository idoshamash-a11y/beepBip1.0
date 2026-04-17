import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/profile/screens/profile_type_selection_screen.dart';
import '../../features/profile/screens/personal_profile_setup_screen.dart';
import '../../features/profile/screens/business_profile_setup_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/map/screens/map_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/messages/screens/chat_screen.dart';
import '../../features/posts/screens/post_creation_screen.dart';
import '../../features/contacts/screens/contact_discovery_screen.dart';
import '../../features/feedback/screens/feedback_screen.dart';
import '../../features/search/screens/search_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState.asData?.value != null;
      final isOnboarded = authState.asData?.value?.userMetadata?['is_profile_complete'] == true;

      final isOnSplash = state.matchedLocation == '/splash';
      final isOnAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isOnOnboarding = state.matchedLocation == '/profile-type' ||
          state.matchedLocation.startsWith('/setup');

      // If not authenticated and not on auth pages, redirect to login
      if (!isAuthenticated && !isOnAuth && !isOnSplash) {
        return '/login';
      }

      // If authenticated but not onboarded, redirect to onboarding
      if (isAuthenticated && !isOnboarded && !isOnOnboarding) {
        return '/profile-type';
      }

      // If authenticated and onboarded, but on auth pages, redirect to home
      if (isAuthenticated && isOnboarded && (isOnAuth || isOnOnboarding)) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/profile-type',
        builder: (context, state) => const ProfileTypeSelectionScreen(),
      ),
      GoRoute(
        path: '/setup/personal',
        builder: (context, state) => const PersonalProfileSetupScreen(),
      ),
      GoRoute(
        path: '/setup/business',
        builder: (context, state) => const BusinessProfileSetupScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/map',
        builder: (context, state) => const MapScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/post/create',
        builder: (context, state) => const PostCreationScreen(),
      ),
      GoRoute(
        path: '/contacts',
        builder: (context, state) => const ContactDiscoveryScreen(),
      ),
      GoRoute(
        path: '/feedback',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return FeedbackScreen(
            targetUserId: extra?['userId'] as String?,
            targetUserName: extra?['userName'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/chat/:userId',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ChatScreen(
            userId: state.pathParameters['userId']!,
            userName: extra?['userName'] as String? ?? 'User',
            userAvatar: extra?['userAvatar'] as String?,
          );
        },
      ),
    ],
  );
});
