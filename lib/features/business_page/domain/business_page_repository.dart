import '../../../core/result/result.dart';
import 'business_page_bundle.dart';

/// Domain-facing contract for the business page surface.
///
/// One implementation in `data/`. Tests can mock this with an in-memory
/// fake without touching Supabase.
abstract class BusinessPageRepository {
  /// Fetch all the data the public business page renders, in a single
  /// bundle. Returns `null` (Ok branch) if the profile is not visible to
  /// the caller (RLS denied, removed, never existed) — distinct from a
  /// transport failure (Err branch).
  Future<Result<BusinessPageBundle?>> getBundle(String profileId);
}
