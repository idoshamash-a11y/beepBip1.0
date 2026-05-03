/// Typed failure hierarchy for the app.
///
/// Every repository and controller that can fail returns a [Failure] on the
/// error path instead of throwing. Exceptions are considered bugs; [Failure]s
/// are considered expected, recoverable conditions that the UI should be able
/// to render and the user should be able to act on.
///
/// Why a sealed class?
///   * `switch` exhaustiveness — the compiler forces us to handle each case
///     wherever we map failures to UI state, so we can't "forget" about a
///     new failure variant.
///   * Zero dependency on any particular backend SDK — keeps the domain pure.
///   * Small and ergonomic — no reflection, no runtime type tests sprinkled
///     across the code.
///
/// When a new failure mode appears, add a variant here and update the
/// presentation layer `switch`es. Avoid subclassing [UnknownFailure]; prefer
/// introducing an explicit named case so the failure is visible in code review.
sealed class Failure {
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  const Failure(this.message, {this.cause, this.stackTrace});

  @override
  String toString() => '$runtimeType($message)';
}

// --- Network / transport -----------------------------------------------------

/// No usable network connectivity. Distinct from a server error so the UI can
/// show a "you're offline" state and silently retry when the connection is back.
final class NoConnectionFailure extends Failure {
  const NoConnectionFailure({super.cause, super.stackTrace})
      : super('No network connection.');
}

/// Reached the server but it returned an unexpected status / payload, or the
/// operation timed out. Implies retry-with-backoff is safe.
final class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode, super.cause, super.stackTrace});
}

/// The request took too long. Usually a subclass of server failure but
/// distinguished so UIs can copy-tailor ("taking longer than usual...").
final class TimeoutFailure extends Failure {
  const TimeoutFailure({super.cause, super.stackTrace})
      : super('The request took too long.');
}

// --- Auth --------------------------------------------------------------------

/// User is not signed in but the operation requires it.
final class UnauthenticatedFailure extends Failure {
  const UnauthenticatedFailure({super.cause, super.stackTrace})
      : super('You need to sign in to continue.');
}

/// Credentials were rejected (wrong password, invalid OTP, expired magic link).
final class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure({String? message, super.cause, super.stackTrace})
      : super(message ?? 'Those credentials didn\'t work.');
}

/// Signed in but the profile doesn't have permission for this resource.
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({super.cause, super.stackTrace})
      : super('You don\'t have access to this.');
}

/// Account is disabled / banned / awaiting email verification, etc.
final class AccountNotUsableFailure extends Failure {
  const AccountNotUsableFailure(super.message, {super.cause, super.stackTrace});
}

// --- Validation --------------------------------------------------------------

/// Client-side or server-side validation rejected the payload. Field-level
/// errors can be attached via [fieldErrors] so forms can highlight them.
final class ValidationFailure extends Failure {
  final Map<String, String> fieldErrors;

  const ValidationFailure(
    super.message, {
    this.fieldErrors = const {},
    super.cause,
    super.stackTrace,
  });
}

// --- Resource ----------------------------------------------------------------

/// Item requested doesn't exist (or is hidden from this caller).
final class NotFoundFailure extends Failure {
  const NotFoundFailure({String? message, super.cause, super.stackTrace})
      : super(message ?? 'Not found.');
}

/// Two writes collided (unique constraint, optimistic concurrency, etc.).
final class ConflictFailure extends Failure {
  const ConflictFailure(super.message, {super.cause, super.stackTrace});
}

/// Caller is making requests too fast; includes suggested [retryAfter] window.
final class RateLimitedFailure extends Failure {
  final Duration? retryAfter;
  const RateLimitedFailure({this.retryAfter, super.cause, super.stackTrace})
      : super('Slow down a bit and try again in a moment.');
}

// --- Domain ------------------------------------------------------------------

/// A precondition of a business operation wasn't met (e.g. tried to confirm a
/// booking that was already cancelled). The message is user-presentable.
final class DomainFailure extends Failure {
  const DomainFailure(super.message, {super.cause, super.stackTrace});
}

/// Payment-specific failure. Separate from [ServerFailure] so presentation
/// can distinguish "declined card" from "Supabase is down".
final class PaymentFailure extends Failure {
  final String? code; // e.g. Stripe decline_code
  const PaymentFailure(super.message, {this.code, super.cause, super.stackTrace});
}

// --- Escape hatch ------------------------------------------------------------

/// Fallback for genuinely unclassified errors. Avoid reaching for this — prefer
/// adding a new variant above so the failure surface remains legible in code
/// review and exhaustive switches keep their value.
final class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.cause, super.stackTrace});
}
