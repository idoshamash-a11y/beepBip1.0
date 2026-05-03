import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/business_page/presentation/screens/business_page_edit_screen.dart';
import '../../features/business_page/presentation/screens/business_page_screen.dart';
import '../../features/contacts/screens/contact_discovery_screen.dart';
import '../../features/dev/screens/dev_mockups_screen.dart';
import '../../features/feedback/screens/feedback_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/listings/providers/listings_providers.dart';
import '../../features/listings/screens/listing_detail_screen.dart';
import '../../features/listings/screens/listing_form_screen.dart';
import '../../features/listings/screens/listings_browse_screen.dart';
import '../../features/map/screens/map_screen.dart';
import '../../features/messages/screens/chat_screen.dart';
import '../../features/posts/screens/post_creation_screen.dart';
import '../../features/profile/screens/business_profile_setup_screen.dart';
import '../../features/profile/screens/personal_profile_setup_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/profile_type_selection_screen.dart';
import '../../features/search/screens/search_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final onboardingAsync = ref.read(onboardingStateProvider);

      final currentPath = state.matchedLocation;
      final isOnSplash = currentPath == '/splash';
      final isOnAuth =
          currentPath == '/login' || currentPath == '/register';
      final isOnOnboarding = currentPath == '/profile-type' ||
          currentPath.startsWith('/setup');

      // While auth state is loading for the very first time, stay on splash.
      // The screen itself will navigate forward when data arrives.
      if (auth.isLoading && isOnSplash) return null;

      final signedIn = auth.asData?.value != null;

      if (!signedIn) {
        return (isOnAuth || isOnSplash) ? null : '/login';
      }

      // Signed in: route based on onboarding state. If we don't know it yet,
      // keep the user where they are rather than bouncing them around.
      final onboarding = onboardingAsync.asData?.value;
      if (onboarding == null) return null;

      switch (onboarding) {
        case OnboardingState.signedOut:
          return '/login';
        case OnboardingState.needsProfile:
          return isOnOnboarding ? null : '/profile-type';
        case OnboardingState.ready:
          if (isOnAuth || isOnOnboarding || isOnSplash) return '/home';
          return null;
      }
    },
    // Riverpod → GoRouter bridge: rebuild redirects when the providers we
    // consult above change. Without this, sign-in wouldn't redirect until
    // the next navigation action.
    refreshListenable: _RiverpodRouterRefresh(ref),
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
        path: '/listings',
        builder: (context, state) => const ListingsBrowseScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const ListingFormScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ListingDetailScreen(listingId: id);
            },
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) {
                  // We need the existing Listing for the form's pre-fill.
                  // Reading the cached value from the family provider gives
                  // us O(1) access; if it's not yet cached (deep link) we
                  // briefly bounce to detail which loads it.
                  final id = state.pathParameters['id']!;
                  return Consumer(
                    builder: (context, ref, _) {
                      final async = ref.watch(listingByIdProvider(id));
                      return async.when(
                        loading: () => const Scaffold(
                          body: Center(child: CircularProgressIndicator()),
                        ),
                        error: (err, _) => Scaffold(
                          body: Center(child: Text(err.toString())),
                        ),
                        data: (listing) {
                          if (listing == null) {
                            return const Scaffold(
                              body: Center(
                                child: Text("This listing isn't available."),
                              ),
                            );
                          }
                          return ListingFormScreen(existing: listing);
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/business/:profileId',
        builder: (context, state) {
          final id = state.pathParameters['profileId']!;
          return BusinessPageScreen(profileId: id);
        },
        routes: [
          GoRoute(
            path: 'manage',
            builder: (context, state) {
              final id = state.pathParameters['profileId']!;
              return BusinessPageEditScreen(profileId: id);
            },
          ),
        ],
      ),
      // Dev-only utility for seeding/clearing mockup accounts. The screen
      // itself early-returns on release builds, so this route stays inert
      // in production even if accidentally pushed.
      GoRoute(
        path: '/dev/mockups',
        builder: (context, state) => const DevMockupsScreen(),
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

/// Bridge that makes GoRouter re-run its redirect when Riverpod providers
/// relevant to navigation change. Without this, a sign-in wouldn't cause a
/// redirect until the user triggered navigation some other way.
class _RiverpodRouterRefresh extends ChangeNotifier {
  _RiverpodRouterRefresh(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(onboardingStateProvider, (_, __) => notifyListeners());
  }
}
