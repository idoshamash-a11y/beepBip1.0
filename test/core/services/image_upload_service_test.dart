import 'package:beepbip/core/services/image_upload_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImageUploadFeature.pathSegment', () {
    test('produces stable, kebab-case path segments', () {
      // The Storage RLS in migration 14 keys off the *first* path segment
      // (the user id). The feature segment that comes next is informational,
      // but we still pin it down here because URLs persisted in the database
      // depend on these strings — changing one would orphan historical rows.
      expect(ImageUploadFeature.listings.pathSegment, 'listings');
      expect(ImageUploadFeature.posts.pathSegment, 'posts');
      expect(ImageUploadFeature.profilePhotos.pathSegment, 'profile-photos');
      expect(ImageUploadFeature.businessLogos.pathSegment, 'business-logos');
      expect(ImageUploadFeature.businessCovers.pathSegment, 'business-covers');
    });

    test('every enum value has a non-empty segment', () {
      for (final f in ImageUploadFeature.values) {
        expect(f.pathSegment, isNotEmpty);
        expect(f.pathSegment.contains(' '), isFalse,
            reason: 'segments are used as URL components');
      }
    });
  });
}
