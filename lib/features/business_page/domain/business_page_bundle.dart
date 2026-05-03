import '../../listings/models/listing_model.dart';
import '../../posts/models/post_model.dart';
import '../../profile/models/business_hours_model.dart';
import '../../profile/models/business_profile_model.dart';
import '../../profile/models/profile_model.dart';

/// Everything the [BusinessPageScreen] needs to render in one shot.
///
/// We intentionally bundle the pieces (profile + business profile + hours +
/// listings + posts) into a single immutable value so the viewer can render
/// or skeleton without juggling multiple `AsyncValue`s — one `FutureProvider`,
/// one fetch, one rebuild.
class BusinessPageBundle {
  const BusinessPageBundle({
    required this.profile,
    required this.business,
    required this.hours,
    required this.activeListings,
    required this.recentPosts,
    required this.stripeChargesEnabled,
  });

  /// Owning [ProfileModel] (carries verified / founding flags + visibility).
  final ProfileModel profile;

  /// Business-specific extension. May be null in the unlikely case of a
  /// half-set-up account; the viewer treats it as a "page not ready" state.
  final BusinessProfileModel? business;

  /// 7 rows ordered by `day_of_week`. Empty when the owner hasn't set hours.
  final List<BusinessHoursModel> hours;

  /// Active listings authored by [profile], newest first. Drafts / paused /
  /// removed are filtered out by the data layer for non-owners; owners see
  /// everything via [allListings] (separate query) on the edit screen.
  final List<Listing> activeListings;

  /// Recent posts authored by [profile], newest first. Used for the
  /// "Updates" tab.
  final List<Post> recentPosts;

  /// True when the business has connected Stripe and can receive money.
  /// Drives whether the "Book / Reserve / Buy" CTA is shown to buyers.
  final bool stripeChargesEnabled;

  /// Convenience: every listing image, deduped, used for the page's auto
  /// "Photos" strip.
  List<String> get aggregatedListingImages {
    final seen = <String>{};
    final out = <String>[];
    for (final l in activeListings) {
      for (final url in l.images) {
        if (seen.add(url)) out.add(url);
      }
    }
    return out;
  }

  BusinessPageBundle copyWith({
    ProfileModel? profile,
    BusinessProfileModel? business,
    List<BusinessHoursModel>? hours,
    List<Listing>? activeListings,
    List<Post>? recentPosts,
    bool? stripeChargesEnabled,
  }) {
    return BusinessPageBundle(
      profile: profile ?? this.profile,
      business: business ?? this.business,
      hours: hours ?? this.hours,
      activeListings: activeListings ?? this.activeListings,
      recentPosts: recentPosts ?? this.recentPosts,
      stripeChargesEnabled: stripeChargesEnabled ?? this.stripeChargesEnabled,
    );
  }
}
