import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/location_model.dart';

class LocationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Check and request location permission
  Future<bool> checkAndRequestPermission() async {
    final status = await Permission.location.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.location.request();
      return result.isGranted;
    }

    return false;
  }

  // Get current position
  Future<Position> getCurrentPosition() async {
    final hasPermission = await checkAndRequestPermission();

    if (!hasPermission) {
      throw Exception('Location permission denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Get address from coordinates
  Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isEmpty) return null;

      final place = placemarks.first;
      final parts = [
        place.street,
        place.locality,
        place.administrativeArea,
        place.country,
      ].where((part) => part != null && part.isNotEmpty);

      return parts.join(', ');
    } catch (e) {
      return null;
    }
  }

  // Save location to database
  Future<LocationModel> saveLocation({
    required String profileId,
    required double latitude,
    required double longitude,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    bool isPrimary = false,
    String? locationName,
  }) async {
    try {
      // If this is primary, unset other primary locations
      if (isPrimary) {
        await _supabase
            .from('locations')
            .update({'is_primary': false})
            .eq('profile_id', profileId);
      }

      final response = await _supabase
          .from('locations')
          .insert({
            'profile_id': profileId,
            'latitude': latitude,
            'longitude': longitude,
            'address': address,
            'city': city,
            'state': state,
            'country': country,
            'postal_code': postalCode,
            'is_primary': isPrimary,
            'location_name': locationName,
          })
          .select()
          .single();

      return LocationModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get profile locations
  Future<List<LocationModel>> getProfileLocations(String profileId) async {
    try {
      final response = await _supabase
          .from('locations')
          .select()
          .eq('profile_id', profileId)
          .order('is_primary', ascending: false);

      return (response as List)
          .map((json) => LocationModel.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get nearby profiles
  Future<List<Map<String, dynamic>>> getNearbyProfiles({
    required double latitude,
    required double longitude,
    double radiusInKm = 10.0,
  }) async {
    try {
      // This requires PostGIS extension and earthdistance
      // Call a stored procedure or use RPC
      final response = await _supabase.rpc('get_nearby_profiles', params: {
        'lat': latitude,
        'lng': longitude,
        'radius_km': radiusInKm,
      });

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  // Update location
  Future<LocationModel> updateLocation({
    required String locationId,
    double? latitude,
    double? longitude,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    bool? isPrimary,
    String? locationName,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (latitude != null) updates['latitude'] = latitude;
      if (longitude != null) updates['longitude'] = longitude;
      if (address != null) updates['address'] = address;
      if (city != null) updates['city'] = city;
      if (state != null) updates['state'] = state;
      if (country != null) updates['country'] = country;
      if (postalCode != null) updates['postal_code'] = postalCode;
      if (isPrimary != null) updates['is_primary'] = isPrimary;
      if (locationName != null) updates['location_name'] = locationName;

      final response = await _supabase
          .from('locations')
          .update(updates)
          .eq('id', locationId)
          .select()
          .single();

      return LocationModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Delete location
  Future<void> deleteLocation(String locationId) async {
    try {
      await _supabase.from('locations').delete().eq('id', locationId);
    } catch (e) {
      rethrow;
    }
  }
}
