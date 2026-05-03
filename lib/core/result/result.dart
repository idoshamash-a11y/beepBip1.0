import '../errors/failure.dart';

/// Functional result type: either an [Ok] holding a value, or an [Err] holding
/// a [Failure]. Used as the return type of every repository / controller
/// method that can fail in an expected way.
///
/// Rationale:
///   * Makes the error path part of the method signature instead of a hidden
///     throw. Consumers must acknowledge failure at the call site.
///   * Plays well with `switch` pattern matching (Dart 3) for exhaustive
///     handling in the presentation layer.
///   * Avoids pulling in heavier deps like `fpdart` or `dartz` for such a
///     small primitive — and keeps behavior predictable.
///
/// Conventions:
///   * Never put successful-but-empty state in [Err]; use `Ok(null)` or
///     `Ok(const [])`.
///   * A method that cannot fail returns a plain `Future<T>`, not `Result<T>`.
sealed class Result<T> {
  const Result();

  /// Convenient factories.
  const factory Result.ok(T value) = Ok<T>;
  const factory Result.err(Failure failure) = Err<T>;

  /// Run [body], converting thrown exceptions into a generic [UnknownFailure].
  /// Prefer catching expected errors inside [body] and returning a specific
  /// failure variant; this is the last-resort safety net.
  static Future<Result<T>> guardAsync<T>(
    Future<T> Function() body, {
    Failure Function(Object error, StackTrace stack)? onError,
  }) async {
    try {
      final value = await body();
      return Ok(value);
    } catch (e, st) {
      final failure = onError?.call(e, st) ??
          UnknownFailure(e.toString(), cause: e, stackTrace: st);
      return Err(failure);
    }
  }

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  /// Returns the value or null. Prefer pattern matching for exhaustive handling.
  T? get valueOrNull => switch (this) {
        Ok<T>(value: final v) => v,
        Err<T>() => null,
      };

  /// Returns the failure or null.
  Failure? get failureOrNull => switch (this) {
        Ok<T>() => null,
        Err<T>(failure: final f) => f,
      };

  /// Collapses both branches into a single value. Useful in UI mappers.
  R fold<R>({
    required R Function(T value) onOk,
    required R Function(Failure failure) onErr,
  }) {
    return switch (this) {
      Ok<T>(value: final v) => onOk(v),
      Err<T>(failure: final f) => onErr(f),
    };
  }

  /// Map the success value, preserving failure as-is.
  Result<R> map<R>(R Function(T value) f) {
    return switch (this) {
      Ok<T>(value: final v) => Ok(f(v)),
      Err<T>(failure: final fail) => Err(fail),
    };
  }

  /// Chain another fallible step. Short-circuits on the first failure.
  Result<R> flatMap<R>(Result<R> Function(T value) f) {
    return switch (this) {
      Ok<T>(value: final v) => f(v),
      Err<T>(failure: final fail) => Err(fail),
    };
  }

  /// Async version of [flatMap].
  Future<Result<R>> flatMapAsync<R>(Future<Result<R>> Function(T value) f) {
    return switch (this) {
      Ok<T>(value: final v) => f(v),
      Err<T>(failure: final fail) => Future.value(Err<R>(fail)),
    };
  }

  /// Run a side effect on success, keep the result unchanged.
  Result<T> tap(void Function(T value) f) {
    if (this case Ok<T>(value: final v)) f(v);
    return this;
  }

  /// Run a side effect on failure, keep the result unchanged.
  Result<T> tapErr(void Function(Failure failure) f) {
    if (this case Err<T>(failure: final fail)) f(fail);
    return this;
  }
}

final class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);

  @override
  String toString() => 'Ok($value)';
}

final class Err<T> extends Result<T> {
  final Failure failure;
  const Err(this.failure);

  @override
  String toString() => 'Err($failure)';
}
