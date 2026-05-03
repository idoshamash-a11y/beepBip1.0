import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'watermark_service.dart';

/// Logical group an upload belongs to. Used as a path segment under the
/// owner's folder and helps humans browsing the bucket; not enforced by RLS.
enum ImageUploadFeature {
  listings,
  posts,
  profilePhotos,
  businessLogos,
  businessCovers;

  String get pathSegment => switch (this) {
        ImageUploadFeature.listings => 'listings',
        ImageUploadFeature.posts => 'posts',
        ImageUploadFeature.profilePhotos => 'profile-photos',
        ImageUploadFeature.businessLogos => 'business-logos',
        ImageUploadFeature.businessCovers => 'business-covers',
      };
}

/// Pipeline that watermarks an image with the owner's `serial_id` and
/// uploads it to the `user-uploads` Supabase Storage bucket.
///
/// Object key layout: `<userId>/<feature>/<uuid>.jpg`. The first segment is
/// what RLS keys off (see migration 14 — `20260501120000_storage_user_uploads.sql`).
class ImageUploadService {
  ImageUploadService({
    required SupabaseClient supabase,
    WatermarkService? watermarkService,
    Uuid? uuid,
    String bucket = 'user-uploads',
  })  : _supabase = supabase,
        _watermark = watermarkService ?? const WatermarkService(),
        _uuid = uuid ?? const Uuid(),
        _bucket = bucket;

  final SupabaseClient _supabase;
  final WatermarkService _watermark;
  final Uuid _uuid;
  final String _bucket;

  /// Watermark [bytes] with [serialId], upload to `<userId>/<feature>/<uuid>.jpg`,
  /// and return the public URL.
  Future<String> uploadUserImage({
    required String userId,
    required String serialId,
    required ImageUploadFeature feature,
    required Uint8List bytes,
  }) async {
    final stamped = await _watermark.apply(bytes, serialId: serialId);
    final path = '$userId/${feature.pathSegment}/${_uuid.v4()}.jpg';

    await _supabase.storage.from(_bucket).uploadBinary(
          path,
          stamped,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: false,
          ),
        );

    return _supabase.storage.from(_bucket).getPublicUrl(path);
  }
}

/// Singleton [ImageUploadService] bound to the live Supabase client. Override
/// at the container boundary in tests.
final imageUploadServiceProvider = Provider<ImageUploadService>((ref) {
  return ImageUploadService(supabase: Supabase.instance.client);
});
