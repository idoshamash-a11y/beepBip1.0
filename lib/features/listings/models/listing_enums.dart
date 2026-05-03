/// What kind of thing this listing represents.
///
/// The enum mirrors the Postgres `listing_type` enum verbatim, so the
/// `name` of each value is also its database value.
enum ListingType {
  service,
  item,
  event;

  String get displayName {
    switch (this) {
      case ListingType.service:
        return 'Service';
      case ListingType.item:
        return 'Item';
      case ListingType.event:
        return 'Event';
    }
  }

  /// Short helper text shown next to the choice in the form.
  String get hint {
    switch (this) {
      case ListingType.service:
        return 'Bookable slot (e.g. a 60-min haircut, a yoga class).';
      case ListingType.item:
        return 'Stocked product the buyer takes away.';
      case ListingType.event:
        return 'Has a fixed start + end date and capacity.';
    }
  }

  static ListingType fromString(String value) {
    return ListingType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => ListingType.service,
    );
  }
}

/// Lifecycle of a listing. Mirrors the Postgres `listing_status` enum verbatim.
enum ListingStatus {
  draft,
  active,
  paused,
  soldOut,
  removed;

  String get displayName {
    switch (this) {
      case ListingStatus.draft:
        return 'Draft';
      case ListingStatus.active:
        return 'Active';
      case ListingStatus.paused:
        return 'Paused';
      case ListingStatus.soldOut:
        return 'Sold out';
      case ListingStatus.removed:
        return 'Removed';
    }
  }

  /// Database value. Most enum names match 1:1; `soldOut` is the exception
  /// since the Postgres enum uses snake_case (`sold_out`).
  String get databaseValue {
    switch (this) {
      case ListingStatus.draft:
        return 'draft';
      case ListingStatus.active:
        return 'active';
      case ListingStatus.paused:
        return 'paused';
      case ListingStatus.soldOut:
        return 'sold_out';
      case ListingStatus.removed:
        return 'removed';
    }
  }

  static ListingStatus fromString(String value) {
    switch (value) {
      case 'draft':
        return ListingStatus.draft;
      case 'active':
        return ListingStatus.active;
      case 'paused':
        return ListingStatus.paused;
      case 'sold_out':
        return ListingStatus.soldOut;
      case 'removed':
        return ListingStatus.removed;
      default:
        return ListingStatus.draft;
    }
  }
}
