import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../../core/logging/app_logger.dart';
import 'data/supabase_business_page_repository.dart';
import 'domain/business_page_bundle.dart';
import 'domain/business_page_repository.dart';

/// Singleton [BusinessPageRepository] bound to the live Supabase client.
/// Tests can `overrideWithValue` an in-memory fake at the container
/// boundary.
final businessPageRepositoryProvider =
    Provider<BusinessPageRepository>((ref) {
  return SupabaseBusinessPageRepository(Supabase.instance.client);
});

/// One bundle per profile id. Family-keyed because the same app session can
/// render multiple business pages (own, plus any business the user navigates
/// to). `autoDispose` is intentional — once the user backs out we don't keep
/// the in-memory cache hot.
final businessPageBundleProvider = FutureProvider.autoDispose
    .family<BusinessPageBundle?, String>((ref, profileId) async {
  final result =
      await ref.read(businessPageRepositoryProvider).getBundle(profileId);
  return result.fold(
    onOk: (bundle) => bundle,
    onErr: (failure) {
      AppLogger.w(
        'businessPageBundleProvider($profileId) failed: ${failure.message}',
        tag: 'business_page',
      );
      throw failure;
    },
  );
});

/// Cheap snapshot of the currently-running `bookings.enabled` feature flag.
/// The page reads this to decide whether to surface the booking CTA at all.
/// Defaults to `false` if the flag row is missing or the fetch fails — fail
/// closed for anything money-related.
final bookingsEnabledFlagProvider = FutureProvider<bool>((ref) async {
  return _readBoolFlag('bookings.enabled', defaultValue: false);
});

/// `bookings.demo_mode` short-circuits the real Stripe calls with a polished
/// mock dialog so we can demo the UX without live Stripe credentials.
/// Defaults to `false` (production-safe). Dev DB seeds it to `true` via
/// `20260501140000_business_page_feature_flags.sql`.
final bookingsDemoModeFlagProvider = FutureProvider<bool>((ref) async {
  return _readBoolFlag('bookings.demo_mode', defaultValue: false);
});

Future<bool> _readBoolFlag(String key, {required bool defaultValue}) async {
  try {
    final row = await Supabase.instance.client
        .from('feature_flags')
        .select('enabled')
        .eq('key', key)
        .maybeSingle();
    return (row?['enabled'] as bool?) ?? defaultValue;
  } catch (e, st) {
    AppLogger.w(
      'feature flag $key fetch failed; defaulting to $defaultValue',
      tag: 'business_page',
      error: e,
      stackTrace: st,
    );
    return defaultValue;
  }
}
