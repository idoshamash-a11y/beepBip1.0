import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/supabase_failure_mapper.dart';
import '../../../core/result/result.dart';
import '../domain/post_repository.dart';
import '../models/post_model.dart';

/// Supabase-backed [PostRepository].
///
/// Conventions match `SupabaseListingRepository`: every method funnels
/// through [Result.guardAsync] + [SupabaseFailureMapper], so callers see
/// a typed [Failure] on the error path rather than a Supabase-flavored
/// exception leaking out.
class SupabasePostRepository implements PostRepository {
  SupabasePostRepository(this._supabase);

  final SupabaseClient _supabase;

  // --- Reads ----------------------------------------------------------------

  @override
  Future<Result<List<Post>>> listForNeighborhood({
    required String neighborhoodId,
    int limit = 50,
  }) {
    return Result.guardAsync<List<Post>>(
      () async {
        final rows = await _supabase
            .from('posts')
            .select()
            .eq('neighborhood_id', neighborhoodId)
            .order('created_at', ascending: false)
            .limit(limit);
        return _mapRows(rows);
      },
      onError: SupabaseFailureMapper.map,
    );
  }

  @override
  Future<Result<List<Post>>> listForAuthor(String profileId) {
    return Result.guardAsync<List<Post>>(
      () async {
        final rows = await _supabase
            .from('posts')
            .select()
            .eq('author_profile_id', profileId)
            .order('created_at', ascending: false);
        return _mapRows(rows);
      },
      onError: SupabaseFailureMapper.map,
    );
  }

  @override
  Future<Result<Post?>> getById(String id) {
    return Result.guardAsync<Post?>(
      () async {
        final row = await _supabase
            .from('posts')
            .select()
            .eq('id', id)
            .maybeSingle();
        if (row == null) return null;
        return Post.fromJson(row);
      },
      onError: SupabaseFailureMapper.map,
    );
  }

  // --- Writes ---------------------------------------------------------------

  @override
  Future<Result<Post>> create({
    required String authorProfileId,
    required String neighborhoodId,
    required String content,
    List<String> hashtags = const [],
    List<String> images = const [],
    String? listingId,
    PostVisibility visibility = PostVisibility.public,
  }) {
    return Result.guardAsync<Post>(
      () async {
        final payload = <String, dynamic>{
          'author_profile_id': authorProfileId,
          'neighborhood_id': neighborhoodId,
          'content': content,
          'hashtags': hashtags,
          'images': images,
          'visibility': visibility.databaseValue,
          // expires_at is left to the DB default (NOW + 72h) so the
          // 72-hour decay rule lives in one place.
          if (listingId != null) 'listing_id': listingId,
        };
        final row = await _supabase
            .from('posts')
            .insert(payload)
            .select()
            .single();
        return Post.fromJson(row);
      },
      onError: SupabaseFailureMapper.map,
    );
  }

  @override
  Future<Result<void>> softDelete(String id) {
    return Result.guardAsync<void>(
      () => _supabase
          .from('posts')
          .update({'is_removed': true})
          .eq('id', id),
      onError: SupabaseFailureMapper.map,
    );
  }

  // --- helpers --------------------------------------------------------------

  List<Post> _mapRows(dynamic rows) {
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(Post.fromJson)
        .toList();
  }
}
