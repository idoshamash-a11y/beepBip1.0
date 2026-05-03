import '../../../core/result/result.dart';
import '../models/business_hours_model.dart';
import '../models/business_profile_model.dart';
import '../models/personal_profile_model.dart';
import '../models/profile_enums.dart';
import '../models/profile_model.dart';

/// Domain-facing contract for everything related to profiles (personal,
/// business, hours).
///
/// The application layer composes higher-level flows like
/// "create a personal profile and mark setup complete" out of these
/// primitives. Each method returns a [Result] so the failure surface is
/// explicit at the call site.
abstract class ProfileRepository {
  // --- Profiles (the shared envelope) ---------------------------------------

  Future<Result<List<ProfileModel>>> getUserProfiles(String userId);

  /// Cheap check: does the user have at least one row in `profiles` with
  /// `is_profile_complete = true`? Used by the router to decide between the
  /// onboarding flow and the home tab.
  Future<Result<bool>> hasCompletedAnyProfile(String userId);

  Future<Result<ProfileModel>> createProfile({
    required String userId,
    required ProfileType profileType,
    SubscriptionTier subscriptionTier,
  });

  Future<Result<ProfileModel>> updateProfile({
    required String profileId,
    VisibilityStatus? visibilityStatus,
    LocationSharing? locationSharing,
    SubscriptionTier? subscriptionTier,
    bool? isProfileComplete,
  });

  Future<Result<void>> deleteProfile(String profileId);

  // --- Personal profiles ----------------------------------------------------

  Future<Result<PersonalProfileModel>> createPersonalProfile({
    required String profileId,
    required String name,
    String? phone,
    String? photoUrl,
    String? bio,
    List<String>? interests,
    DateTime? dateOfBirth,
    String? gender,
  });

  Future<Result<PersonalProfileModel>> updatePersonalProfile({
    required String profileId,
    String? name,
    String? phone,
    String? photoUrl,
    String? bio,
    List<String>? interests,
    DateTime? dateOfBirth,
    String? gender,
  });

  Future<Result<PersonalProfileModel?>> getPersonalProfile(String profileId);

  // --- Business profiles ----------------------------------------------------

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
  });

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
  });

  Future<Result<BusinessProfileModel?>> getBusinessProfile(String profileId);

  // --- Business hours -------------------------------------------------------

  Future<Result<void>> upsertBusinessHours(
    String businessProfileId,
    List<BusinessHoursModel> hours,
  );

  Future<Result<List<BusinessHoursModel>>> getBusinessHours(
    String businessProfileId,
  );
}
