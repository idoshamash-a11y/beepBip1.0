import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../models/profile_enums.dart';
import '../models/personal_profile_model.dart';
import '../models/business_profile_model.dart';
import '../models/business_hours_model.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get user's profiles
  Future<List<ProfileModel>> getUserProfiles(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('user_id', userId);

      return (response as List)
          .map((json) => ProfileModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Create a new profile
  Future<ProfileModel> createProfile({
    required String userId,
    required ProfileType profileType,
    SubscriptionTier subscriptionTier = SubscriptionTier.free,
  }) async {
    try {
      final response = await _supabase
          .from('profiles')
          .insert({
            'user_id': userId,
            'profile_type': profileType.name,
            'subscription_tier': subscriptionTier.name,
          })
          .select()
          .single();

      return ProfileModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Update profile settings
  Future<ProfileModel> updateProfile({
    required String profileId,
    VisibilityStatus? visibilityStatus,
    LocationSharing? locationSharing,
    SubscriptionTier? subscriptionTier,
    bool? isProfileComplete,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (visibilityStatus != null) {
        updates['visibility_status'] = visibilityStatus.name;
      }
      if (locationSharing != null) {
        updates['location_sharing'] = locationSharing.databaseValue;
      }
      if (subscriptionTier != null) {
        updates['subscription_tier'] = subscriptionTier.name;
      }
      if (isProfileComplete != null) {
        updates['is_profile_complete'] = isProfileComplete;
      }

      final response = await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', profileId)
          .select()
          .single();

      return ProfileModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Create personal profile
  Future<PersonalProfileModel> createPersonalProfile({
    required String profileId,
    required String name,
    String? phone,
    String? photoUrl,
    String? bio,
    List<String>? interests,
    DateTime? dateOfBirth,
    String? gender,
  }) async {
    try {
      final response = await _supabase
          .from('personal_profiles')
          .insert({
            'id': profileId,
            'name': name,
            'phone': phone,
            'photo_url': photoUrl,
            'bio': bio,
            'interests': interests,
            'date_of_birth': dateOfBirth?.toIso8601String(),
            'gender': gender,
          })
          .select()
          .single();

      return PersonalProfileModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Update personal profile
  Future<PersonalProfileModel> updatePersonalProfile({
    required String profileId,
    String? name,
    String? phone,
    String? photoUrl,
    String? bio,
    List<String>? interests,
    DateTime? dateOfBirth,
    String? gender,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (photoUrl != null) updates['photo_url'] = photoUrl;
      if (bio != null) updates['bio'] = bio;
      if (interests != null) updates['interests'] = interests;
      if (dateOfBirth != null) updates['date_of_birth'] = dateOfBirth.toIso8601String();
      if (gender != null) updates['gender'] = gender;

      final response = await _supabase
          .from('personal_profiles')
          .update(updates)
          .eq('id', profileId)
          .select()
          .single();

      return PersonalProfileModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get personal profile
  Future<PersonalProfileModel?> getPersonalProfile(String profileId) async {
    try {
      final response = await _supabase
          .from('personal_profiles')
          .select()
          .eq('id', profileId)
          .single();

      return PersonalProfileModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Create business profile
  Future<BusinessProfileModel> createBusinessProfile({
    required String profileId,
    required String businessName,
    String? logoUrl,
    String? description,
    String? category,
    List<String>? services,
    String? website,
    String? phone,
    String? email,
  }) async {
    try {
      final response = await _supabase
          .from('business_profiles')
          .insert({
            'id': profileId,
            'business_name': businessName,
            'logo_url': logoUrl,
            'description': description,
            'category': category,
            'services': services,
            'website': website,
            'phone': phone,
            'email': email,
          })
          .select()
          .single();

      return BusinessProfileModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Update business profile
  Future<BusinessProfileModel> updateBusinessProfile({
    required String profileId,
    String? businessName,
    String? logoUrl,
    String? description,
    String? category,
    List<String>? services,
    String? website,
    String? phone,
    String? email,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (businessName != null) updates['business_name'] = businessName;
      if (logoUrl != null) updates['logo_url'] = logoUrl;
      if (description != null) updates['description'] = description;
      if (category != null) updates['category'] = category;
      if (services != null) updates['services'] = services;
      if (website != null) updates['website'] = website;
      if (phone != null) updates['phone'] = phone;
      if (email != null) updates['email'] = email;

      final response = await _supabase
          .from('business_profiles')
          .update(updates)
          .eq('id', profileId)
          .select()
          .single();

      return BusinessProfileModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get business profile
  Future<BusinessProfileModel?> getBusinessProfile(String profileId) async {
    try {
      final response = await _supabase
          .from('business_profiles')
          .select()
          .eq('id', profileId)
          .single();

      return BusinessProfileModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Create/Update business hours
  Future<void> upsertBusinessHours(
    String businessProfileId,
    List<BusinessHoursModel> hours,
  ) async {
    try {
      // Delete existing hours
      await _supabase
          .from('business_hours')
          .delete()
          .eq('business_profile_id', businessProfileId);

      // Insert new hours
      final hoursData = hours.map((h) => {
        'business_profile_id': businessProfileId,
        'day_of_week': h.dayOfWeek,
        'open_time': h.openTime,
        'close_time': h.closeTime,
        'is_closed': h.isClosed,
      }).toList();

      await _supabase.from('business_hours').insert(hoursData);
    } catch (e) {
      rethrow;
    }
  }

  // Get business hours
  Future<List<BusinessHoursModel>> getBusinessHours(
    String businessProfileId,
  ) async {
    try {
      final response = await _supabase
          .from('business_hours')
          .select()
          .eq('business_profile_id', businessProfileId)
          .order('day_of_week');

      return (response as List)
          .map((json) => BusinessHoursModel.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Delete profile
  Future<void> deleteProfile(String profileId) async {
    try {
      await _supabase.from('profiles').delete().eq('id', profileId);
    } catch (e) {
      rethrow;
    }
  }
}
