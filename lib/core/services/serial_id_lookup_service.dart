import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../logging/app_logger.dart';

/// Looks up the public `serial_id` (BP-XXXXXX) for arbitrary users / profiles.
///
/// `public.users` is RLS-locked to the owner via `users_select_self`, so a
/// regular `select` against the table only ever returns the caller's row.
/// To surface another account's serial_id (e.g. on a business page hero,
/// or on a post header authored by someone else) we go through a
/// SECURITY DEFINER RPC (`get_serial_id_for_profile` /
/// `get_serial_id_for_user`) that returns *only* the serial_id column —
/// never email/phone.
class SerialIdLookupService {
  SerialIdLookupService(this._supabase);

  final SupabaseClient _supabase;

  /// Resolve a `profiles.id` to its owning user's serial_id. Returns null
  /// when the profile cannot be found, or when the lookup fails (errors are
  /// logged but never thrown — the chip simply doesn't render).
  Future<String?> forProfile(String profileId) async {
    try {
      final result = await _supabase.rpc(
        'get_serial_id_for_profile',
        params: {'p_profile_id': profileId},
      );
      return result is String ? result : null;
    } catch (e, st) {
      AppLogger.w(
        'serial_id lookup (profile $profileId) failed: $e',
        tag: 'serial_id',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Resolve a `users.id` to its serial_id. Same error semantics as
  /// [forProfile].
  Future<String?> forUser(String userId) async {
    try {
      final result = await _supabase.rpc(
        'get_serial_id_for_user',
        params: {'p_user_id': userId},
      );
      return result is String ? result : null;
    } catch (e, st) {
      AppLogger.w(
        'serial_id lookup (user $userId) failed: $e',
        tag: 'serial_id',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }
}

/// Singleton service bound to the live Supabase client.
final serialIdLookupServiceProvider = Provider<SerialIdLookupService>((ref) {
  return SerialIdLookupService(Supabase.instance.client);
});

/// Family that resolves a profile id to its owner's serial_id. Cached for
/// the session — serial_ids never change once issued. Returns null when the
/// profile is unknown or the RPC errored.
final serialIdForProfileProvider =
    FutureProvider.family<String?, String>((ref, profileId) {
  return ref.read(serialIdLookupServiceProvider).forProfile(profileId);
});

/// Family that resolves a user id to its serial_id. See
/// [serialIdForProfileProvider] for caching semantics.
final serialIdForUserProvider =
    FutureProvider.family<String?, String>((ref, userId) {
  return ref.read(serialIdLookupServiceProvider).forUser(userId);
});
