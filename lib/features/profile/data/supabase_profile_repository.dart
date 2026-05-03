import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/supabase_failure_mapper.dart';
import '../../../core/result/result.dart';
import '../domain/profile_repository.dart';
import '../models/business_hours_model.dart';
import '../models/business_profile_model.dart';
import '../models/personal_profile_model.dart';
import '../models/profile_enums.dart';
import '../models/profile_model.dart';

/// Supabase-backed implementation of [ProfileRepository].
///
/// Each method funnels through [Result.guardAsync] + [SupabaseFailureMapper]
/// so callers see a typed failure on the error path. Update methods skip
/// undefined fields rather than overwriting with null, matching the prior
/// behaviour of `ProfileService`.
class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._supabase);

  final SupabaseClient _supabase;

  // --- Profiles -------------------------------------------------------------

  @override
  Future<Result<List<ProfileModel>>> getUserProfiles(String userId) {
    return Result.guardAsync<List<ProfileModel>>(
      () async {
        final rows = await _supabase
            .from('profiles')
            .select()
            .eq('user_id', userId);
        return (rows as List)
            .cast<Map<String, dynamic>>()
            .map(ProfileModel.fromJson)
            .toList();
      },
      onError: SupabaseFailureMapper.map,
    );
  }

  @override
  Future<Result<bool>> hasCompletedAnyProfile(String userId) {
    return Result.guardAsync<bool>(
      () async {
        final rows = await _supabase
            .from('profiles')
            .select('id')
            .eq('user_id', userId)
            .eq('is_profile_complete', true)
            .limit(1);
        return (rows as List).isNotEmpty;
      },
      onError: SupabaseFailureMapper.map,
    );
  }

  @override
  Future<Result<ProfileModel>> createProfile({
    required String userId,
    required ProfileType profileType,
    SubscriptionTier subscriptionTier = SubscriptionTier.free,
  }) {
    // Idempotent: if a profile with the same (user_id, profile_type) already
    // exists (e.g. user is retrying after a partial failure or stale router
    // state), return the existing row instead of failing the unique
    // constraint. We do NOT touch is_profile_complete here -- that is the
    // setup controller's responsibility once all child rows are written.
    return Result.guardAsync<ProfileModel>(
      () async {
        final row = await _supabase
            .from('profiles')
            .upsert(
              {
                'user_id': userId,
                'profile_type': profileType.name,
                'subscription_tier': subscriptionTier.databaseValue,
              },
              onConflict: 'user_id,profile_type',
            )
            .select()
            .single();
        return ProfileModel.fromJson(row);
      },
      onError: SupabaseFailureMapper.map,
    );
  }

  @override
  Future<Result<ProfileModel>> updateProfile({
    required String profileId,
    VisibilityStatus? visibilityStatus,
    LocationSharing? locationSharing,
    SubscriptionTier? subscriptionTier,
    bool? isProfileComplete,
  }) {
    return Result.guardAsync<ProfileModel>(
      () async {
        final updates = <String, dynamic>{};
        if (visibilityStatus != null) {
          updates['visibility_status'] = visibilityStatus.name;
        }
        if (locationSharing != null) {
          updates['location_sharing'] = locationSharing.databaseValue;
        }
        if (subscriptionTier != null) {
          updates['subscription_tier'] = subscriptionTier.databaseValue;
        }
        if (isProfileComplete != null) {
          updates['is_profile_complete'] = isProfileComplete;
        }

        final row = await _supabase
            .from('profiles')
            .update(updates)
            .eq('id', profileId)
            .select()
            .single();
        return ProfileModel.fromJson(row);
      },
      onError: SupabaseFailureMapper.map,
    );
  }

  @override
  Future<Result<void>> deleteProfile(String profileId) {
    return Result.guardAsync<void>(
      () => _supabase.from('profiles').delete().eq('id', profileId),
      onError: SupabaseFailureMapper.map,
    );
  }

  // --- Personal profiles ----------------------------------------------------

  @override
  Future<Result<PersonalProfileModel>> createPersonalProfile({
    required String profileId,
    required String name,
    String? phone,
    String? photoUrl,
    String? bio,
    List<String>? interests,
    DateTime? dateOfBirth,
    String? gender,
  }) {
    // Upsert keyed on the primary key (id, which mirrors profiles.id) so a
    // retry after a partial-failure / stale-router scenario overwrites the
    // existing row with the freshly submitted form values rather than
    // tripping on "duplicate key".
    return Result.guardAsync<PersonalProfileModel>(
      () async {
        final row = await _supabase
            .from('personal_profiles')
            .upsert({
              'id': profileId,
              'name': name,
              'phone': phone,
              'photo_url': photoUrl,
              'bio': bio,
              'interests': interests ?? <String>[],
              'date_of_birth': dateOfBirth?.toIso8601String(),
              'gender': gender,
            })
            .select()
            .single();
        return PersonalProfileModel.fromJson(row);
      },
      onError: SupabaseFailureMapper.map,
    );
  }

  @override
  Future<Result<PersonalProfileModel>> updatePersonalProfile({
    required String profileId,
    String? name,
    String? phone,
    String? photoUrl,
    String? bio,
    List<String>? interests,
    DateTime? dateOfBirth,
    String? gender,
  }) {
    return Result.guardAsync<PersonalProfileModel>(
      () async {
        final updates = <String, dynamic>{};
        if (name != null) updates['name'] = name;
        if (phone != null) updates['phone'] = phone;
        if (photoUrl != null) updates['photo_url'] = photoUrl;
        if (bio != null) updates['bio'] = bio;
        if (interests != null) updates['interests'] = interests;
        if (dateOfBirth != null) {
          updates['date_of_birth'] = dateOfBirth.toIso8601String();
        }
        if (gender != null) updates['gender'] = gender;

        final row = await _supabase
            .from('personal_profiles')
            .update(updates)
            .eq('id', profileId)
            .select()
            .single();
        return PersonalProfileModel.fromJson(row);
      },
      onError: SupabaseFailureMapper.map,
    );
  }

  @override
  Future<Result<PersonalProfileModel?>> getPersonalProfile(String profileId) {
    return Result.guardAsync<PersonalProfileModel?>(
      () async {
        final row = await _supabase
            .from('personal_profiles')
            .select()
            .eq('id', profileId)
            .maybeSingle();
        if (row == null) return null;
        return PersonalProfileModel.fromJson(row);
      },
      onError: SupabaseFailureMapper.map,
    );
  }

  // --- Business profiles ----------------------------------------------------

  @override
  Future<Result<BusinessProfileModel>> createBusinessProfile({
    required String profileId,
    required String businessName,
    String? logoUrl,
    String? coverUrl,
    String? description,
    String? category,
    List<String>? services,
    List<String>? hashtags,
    Map<String, String>? socialHandles,
    String? website,
    String? phone,
    String? email,
  }) {
    // Idempotent upsert -- see createPersonalProfile for rationale.
    return Result.guardAsync<BusinessProfileModel>(
      () async {
        final row = await _supabase
            .from('business_profiles')
            .upsert({
              'id': profileId,
              'business_name': businessName,
              'logo_url': logoUrl,
              'cover_url': coverUrl,
              'description': description,
              'category': category,
              'services': services ?? <String>[],
              'hashtags': hashtags ?? <String>[],
              'social_handles': socialHandles ?? <String, String>{},
              'website': website,
              'phone': phone,
              'email': email,
            })
            .select()
            .single();
        return BusinessProfileModel.fromJson(row);
      },
      onError: SupabaseFailureMapper.map,
    );
  }

  @override
  Future<Result<BusinessProfileModel>> updateBusinessProfile({
    required String profileId,
    String? businessName,
    String? logoUrl,
    String? coverUrl,
    String? description,
    String? category,
    List<String>? services,
    List<String>? hashtags,
    Map<String, String>? socialHandles,
    String? website,
    String? phone,
    String? email,
  }) {
    return Result.guardAsync<BusinessProfileModel>(
      () async {
        final updates = <String, dynamic>{};
        if (businessName != null) updates['business_name'] = businessName;
        if (logoUrl != null) updates['logo_url'] = logoUrl;
        if (coverUrl != null) updates['cover_url'] = coverUrl;
        if (description != null) updates['description'] = description;
        if (category != null) updates['category'] = category;
        if (services != null) updates['services'] = services;
        if (hashtags != null) updates['hashtags'] = hashtags;
        if (socialHandles != null) updates['social_handles'] = socialHandles;
        if (website != null) updates['website'] = website;
        if (phone != null) updates['phone'] = phone;
        if (email != null) updates['email'] = email;

        final row = await _supabase
            .from('business_profiles')
            .update(updates)
            .eq('id', profileId)
            .select()
            .single();
        return BusinessProfileModel.fromJson(row);
      },
      onError: SupabaseFailureMapper.map,
    );
  }

  @override
  Future<Result<BusinessProfileModel?>> getBusinessProfile(String profileId) {
    return Result.guardAsync<BusinessProfileModel?>(
      () async {
        final row = await _supabase
            .from('business_profiles')
            .select()
            .eq('id', profileId)
            .maybeSingle();
        if (row == null) return null;
        return BusinessProfileModel.fromJson(row);
      },
      onError: SupabaseFailureMapper.map,
    );
  }

  // --- Business hours -------------------------------------------------------

  @override
  Future<Result<void>> upsertBusinessHours(
    String businessProfileId,
    List<BusinessHoursModel> hours,
  ) {
    return Result.guardAsync<void>(
      () async {
        // Replace strategy: delete existing rows then insert fresh ones.
        // Wrapped in a single round-trip through the SDK; if either step
        // fails we surface the failure (and accept the brief inconsistency).
        await _supabase
            .from('business_hours')
            .delete()
            .eq('business_profile_id', businessProfileId);

        if (hours.isEmpty) return;

        final payload = hours
            .map((h) => {
                  'business_profile_id': businessProfileId,
                  'day_of_week': h.dayOfWeek,
                  'open_time': h.openTime,
                  'close_time': h.closeTime,
                  'is_closed': h.isClosed,
                })
            .toList();
        await _supabase.from('business_hours').insert(payload);
      },
      onError: SupabaseFailureMapper.map,
    );
  }

  @override
  Future<Result<List<BusinessHoursModel>>> getBusinessHours(
    String businessProfileId,
  ) {
    return Result.guardAsync<List<BusinessHoursModel>>(
      () async {
        final rows = await _supabase
            .from('business_hours')
            .select()
            .eq('business_profile_id', businessProfileId)
            .order('day_of_week');
        return (rows as List)
            .cast<Map<String, dynamic>>()
            .map(BusinessHoursModel.fromJson)
            .toList();
      },
      onError: SupabaseFailureMapper.map,
    );
  }
}
