import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/supabase_failure_mapper.dart';
import '../../../core/result/result.dart';
import '../domain/listing_repository.dart';
import '../models/listing_enums.dart';
import '../models/listing_model.dart';

/// Supabase-backed [ListingRepository].
///
/// Same conventions as `SupabaseProfileRepository`:
///   * Every method returns a [Result], wrapping its body in
///     [Result.guardAsync] + [SupabaseFailureMapper] so the failure surface
///     is typed at the call site.
///   * Updates skip undefined fields (null) instead of nulling the column.
class SupabaseListingRepository implements ListingRepository {
  SupabaseListingRepository(this._supabase);

  final SupabaseClient _supabase;

  // --- Reads ----------------------------------------------------------------

  @override
  Future<Result<List<Listing>>> listForNeighborhood({
    required String neighborhoodId,
    int limit = 50,
  }) {
    return Result.guardAsync<List<Listing>>(
      () async {
        final rows = await _supabase
            .from('listings')
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
  Future<Result<List<Listing>>> listForOwner(String profileId) {
    return Result.guardAsync<List<Listing>>(
      () async {
        final rows = await _supabase
            .from('listings')
            .select()
            .eq('profile_id', profileId)
            .order('created_at', ascending: false);
        return _mapRows(rows);
      },
      onError: SupabaseFailureMapper.map,
    );
  }

  @override
  Future<Result<Listing?>> getById(String id) {
    return Result.guardAsync<Listing?>(
      () async {
        final row = await _supabase
            .from('listings')
            .select()
            .eq('id', id)
            .maybeSingle();
        if (row == null) return null;
        return Listing.fromJson(row);
      },
      onError: SupabaseFailureMapper.map,
    );
  }

  // --- Writes ---------------------------------------------------------------

  @override
  Future<Result<Listing>> create({
    required String profileId,
    required String neighborhoodId,
    required ListingType type,
    required String title,
    required int priceCents,
    String? description,
    String currency = 'USD',
    int? durationMinutes,
    int? capacity,
    int? stock,
    List<String> hashtags = const [],
    List<String> images = const [],
    ListingStatus status = ListingStatus.draft,
    DateTime? startsAt,
    DateTime? endsAt,
  }) {
    return Result.guardAsync<Listing>(
      () async {
        final payload = <String, dynamic>{
          'profile_id': profileId,
          'neighborhood_id': neighborhoodId,
          'type': type.name,
          'title': title,
          'description': description,
          'price_cents': priceCents,
          'currency': currency,
          'duration_minutes': durationMinutes,
          'capacity': capacity,
          'stock': stock,
          'hashtags': hashtags,
          'images': images,
          'status': status.databaseValue,
          'starts_at': startsAt?.toIso8601String(),
          'ends_at': endsAt?.toIso8601String(),
        };
        final row = await _supabase
            .from('listings')
            .insert(payload)
            .select()
            .single();
        return Listing.fromJson(row);
      },
      onError: SupabaseFailureMapper.map,
    );
  }

  @override
  Future<Result<Listing>> update({
    required String id,
    ListingType? type,
    String? title,
    String? description,
    int? priceCents,
    String? currency,
    int? durationMinutes,
    int? capacity,
    int? stock,
    List<String>? hashtags,
    List<String>? images,
    ListingStatus? status,
    DateTime? startsAt,
    DateTime? endsAt,
  }) {
    return Result.guardAsync<Listing>(
      () async {
        final updates = <String, dynamic>{};
        if (type != null) updates['type'] = type.name;
        if (title != null) updates['title'] = title;
        if (description != null) updates['description'] = description;
        if (priceCents != null) updates['price_cents'] = priceCents;
        if (currency != null) updates['currency'] = currency;
        if (durationMinutes != null) {
          updates['duration_minutes'] = durationMinutes;
        }
        if (capacity != null) updates['capacity'] = capacity;
        if (stock != null) updates['stock'] = stock;
        if (hashtags != null) updates['hashtags'] = hashtags;
        if (images != null) updates['images'] = images;
        if (status != null) updates['status'] = status.databaseValue;
        if (startsAt != null) {
          updates['starts_at'] = startsAt.toIso8601String();
        }
        if (endsAt != null) updates['ends_at'] = endsAt.toIso8601String();

        final row = await _supabase
            .from('listings')
            .update(updates)
            .eq('id', id)
            .select()
            .single();
        return Listing.fromJson(row);
      },
      onError: SupabaseFailureMapper.map,
    );
  }

  @override
  Future<Result<void>> delete(String id) {
    return Result.guardAsync<void>(
      () => _supabase.from('listings').delete().eq('id', id),
      onError: SupabaseFailureMapper.map,
    );
  }

  // --- helpers --------------------------------------------------------------

  List<Listing> _mapRows(dynamic rows) {
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(Listing.fromJson)
        .toList();
  }
}
