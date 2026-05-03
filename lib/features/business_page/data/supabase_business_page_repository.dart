import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/supabase_failure_mapper.dart';
import '../../../core/result/result.dart';
import '../../listings/models/listing_enums.dart';
import '../../listings/models/listing_model.dart';
import '../../posts/models/post_model.dart';
import '../../profile/models/business_hours_model.dart';
import '../../profile/models/business_profile_model.dart';
import '../../profile/models/profile_model.dart';
import '../domain/business_page_bundle.dart';
import '../domain/business_page_repository.dart';

/// Supabase-backed [BusinessPageRepository].
///
/// One method, multiple parallel `select`s — the assembled bundle is what
/// the page consumes. RLS does the access-control work: a row that's not
/// readable to the current user simply doesn't come back, and we treat
/// "no profile" as a [Result.ok] with `null` data.
class SupabaseBusinessPageRepository implements BusinessPageRepository {
  SupabaseBusinessPageRepository(this._supabase);

  final SupabaseClient _supabase;

  @override
  Future<Result<BusinessPageBundle?>> getBundle(String profileId) {
    return Result.guardAsync<BusinessPageBundle?>(
      () async {
        final profileRow = await _supabase
            .from('profiles')
            .select()
            .eq('id', profileId)
            .maybeSingle();
        if (profileRow == null) return null;
        final profile = ProfileModel.fromJson(profileRow);

        // Fire the rest in parallel — they don't depend on each other.
        final futures = await Future.wait<dynamic>([
          _supabase
              .from('business_profiles')
              .select()
              .eq('id', profileId)
              .maybeSingle(),
          _supabase
              .from('business_hours')
              .select()
              .eq('business_profile_id', profileId)
              .order('day_of_week'),
          // Active listings only — drafts / paused belong on the owner's
          // manage view, not the public page. RLS already filters in the
          // same direction for non-owners; we add the explicit filter so
          // owners viewing their own page see what buyers see.
          _supabase
              .from('listings')
              .select()
              .eq('profile_id', profileId)
              .eq('status', ListingStatus.active.databaseValue)
              .order('created_at', ascending: false),
          _supabase
              .from('posts')
              .select()
              .eq('author_profile_id', profileId)
              .order('created_at', ascending: false)
              .limit(20),
          _supabase
              .from('stripe_accounts')
              .select('charges_enabled')
              .eq('profile_id', profileId)
              .maybeSingle(),
        ]);

        final businessRow = futures[0] as Map<String, dynamic>?;
        final hoursRows = (futures[1] as List).cast<Map<String, dynamic>>();
        final listingRows =
            (futures[2] as List).cast<Map<String, dynamic>>();
        final postRows = (futures[3] as List).cast<Map<String, dynamic>>();
        final stripeRow = futures[4] as Map<String, dynamic>?;

        return BusinessPageBundle(
          profile: profile,
          business: businessRow == null
              ? null
              : BusinessProfileModel.fromJson(businessRow),
          hours: hoursRows.map(BusinessHoursModel.fromJson).toList(),
          activeListings: listingRows.map(Listing.fromJson).toList(),
          recentPosts: postRows.map(Post.fromJson).toList(),
          stripeChargesEnabled:
              (stripeRow?['charges_enabled'] as bool?) ?? false,
        );
      },
      onError: SupabaseFailureMapper.map,
    );
  }
}
