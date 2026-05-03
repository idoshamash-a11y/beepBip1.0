import 'package:beepbip/features/business_page/domain/business_page_bundle.dart';
import 'package:beepbip/features/listings/models/listing_enums.dart';
import 'package:beepbip/features/listings/models/listing_model.dart';
import 'package:beepbip/features/profile/models/business_profile_model.dart';
import 'package:beepbip/features/profile/models/profile_enums.dart';
import 'package:beepbip/features/profile/models/profile_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Most of the page repository is direct Supabase querying, but the
/// `aggregatedListingImages` getter is pure logic and worth pinning down —
/// it's what drives the auto-photos strip on the public page, and we don't
/// want it to silently start emitting duplicates if a listing repeats an
/// image URL across slots, or if two listings share an image.
void main() {
  test('aggregatedListingImages dedupes while preserving listing order', () {
    final now = DateTime.parse('2026-05-01T12:00:00Z');
    final profile = ProfileModel(
      id: 'p1',
      userId: 'u1',
      profileType: ProfileType.business,
      createdAt: now,
      updatedAt: now,
    );
    final business = BusinessProfileModel(
      id: 'p1',
      businessName: 'Test Co',
      createdAt: now,
      updatedAt: now,
    );

    Listing listing(String id, List<String> images) {
      return Listing(
        id: id,
        profileId: 'p1',
        neighborhoodId: 'n1',
        type: ListingType.service,
        title: 'L $id',
        priceCents: 1000,
        images: images,
        status: ListingStatus.active,
        createdAt: now,
        updatedAt: now,
      );
    }

    final bundle = BusinessPageBundle(
      profile: profile,
      business: business,
      hours: const [],
      activeListings: [
        listing('a', ['https://x/1', 'https://x/2']),
        listing('b', ['https://x/2', 'https://x/3']),
      ],
      recentPosts: const [],
      stripeChargesEnabled: false,
    );

    expect(
      bundle.aggregatedListingImages,
      ['https://x/1', 'https://x/2', 'https://x/3'],
    );
  });

  test('aggregatedListingImages handles empty listings gracefully', () {
    final now = DateTime.parse('2026-05-01T12:00:00Z');
    final bundle = BusinessPageBundle(
      profile: ProfileModel(
        id: 'p1',
        userId: 'u1',
        profileType: ProfileType.business,
        createdAt: now,
        updatedAt: now,
      ),
      business: BusinessProfileModel(
        id: 'p1',
        businessName: 'Empty Co',
        createdAt: now,
        updatedAt: now,
      ),
      hours: const [],
      activeListings: const [],
      recentPosts: const [],
      stripeChargesEnabled: false,
    );

    expect(bundle.aggregatedListingImages, isEmpty);
  });
}
