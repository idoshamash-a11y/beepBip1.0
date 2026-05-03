import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/logging/app_logger.dart';

/// Coarse-grained progress state for "kick off Stripe Connect onboarding"
/// and "kick off booking checkout". Both flows share the same shape:
/// loading → external URL opens → caller may invalidate downstream
/// providers when they navigate back to the app.
class StripeFlowState {
  const StripeFlowState({this.isLoading = false, this.error});

  final bool isLoading;
  final String? error;

  StripeFlowState copyWith({bool? isLoading, String? error}) {
    return StripeFlowState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Triggers the `create-stripe-connect-account` Edge Function and opens
/// the returned onboarding link via `url_launcher`. Exposed as a notifier so
/// the UI can render a loading / error state while the round-trip happens.
final stripeOnboardingProvider =
    StateNotifierProvider<StripeOnboardingController, StripeFlowState>((ref) {
  return StripeOnboardingController();
});

class StripeOnboardingController extends StateNotifier<StripeFlowState> {
  StripeOnboardingController() : super(const StripeFlowState());

  /// Returns the launched URL on success (already opened in the external
  /// browser), or `null` on failure. The caller can read [state.error] for
  /// the user-presentable message.
  Future<String?> startOnboarding(String profileId) async {
    state = const StripeFlowState(isLoading: true);
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'create-stripe-connect-account',
        body: {'profile_id': profileId},
      );
      final data = response.data as Map<String, dynamic>?;
      final url = data?['url'] as String?;
      if (url == null) {
        state = const StripeFlowState(
          error: "Stripe didn't return an onboarding URL.",
        );
        return null;
      }
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      state = const StripeFlowState();
      return url;
    } catch (e, st) {
      AppLogger.e(
        'startOnboarding failed',
        tag: 'stripe',
        error: e,
        stackTrace: st,
      );
      state = StripeFlowState(error: e.toString());
      return null;
    }
  }
}

/// Triggers the `create-booking-checkout` Edge Function and opens the
/// resulting Stripe Checkout URL.
final bookingCheckoutProvider =
    StateNotifierProvider<BookingCheckoutController, StripeFlowState>((ref) {
  return BookingCheckoutController();
});

class BookingCheckoutController extends StateNotifier<StripeFlowState> {
  BookingCheckoutController() : super(const StripeFlowState());

  /// Returns the launched URL on success (already opened in the external
  /// browser). On failure, [state.error] holds a user-presentable message.
  Future<String?> startCheckout({
    required String listingId,
    int quantity = 1,
    DateTime? scheduledFor,
  }) async {
    state = const StripeFlowState(isLoading: true);
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'create-booking-checkout',
        body: {
          'listing_id': listingId,
          'quantity': quantity,
          if (scheduledFor != null)
            'scheduled_for': scheduledFor.toUtc().toIso8601String(),
        },
      );
      final data = response.data as Map<String, dynamic>?;
      final url = data?['url'] as String?;
      if (url == null) {
        state = const StripeFlowState(
          error: "Stripe didn't return a checkout URL.",
        );
        return null;
      }
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      state = const StripeFlowState();
      return url;
    } catch (e, st) {
      AppLogger.e(
        'startCheckout failed',
        tag: 'stripe',
        error: e,
        stackTrace: st,
      );
      state = StripeFlowState(error: e.toString());
      return null;
    }
  }
}
