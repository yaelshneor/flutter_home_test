sealed class AppFailure implements Exception {
  const AppFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure([
    super.message = 'Unable to connect. Check your internet connection.',
  ]);
}

final class TimeoutFailure extends AppFailure {
  const TimeoutFailure([
    super.message = 'The request timed out. Please try again.',
  ]);
}

final class ServerFailure extends AppFailure {
  const ServerFailure([
    super.message = 'The server returned an error. Please try again.',
  ]);
}

final class DataFailure extends AppFailure {
  const DataFailure([super.message = 'The server returned invalid data.']);
}

final class CancelledFailure extends AppFailure {
  const CancelledFailure() : super('Request cancelled.');
}

final class PersistenceFailure extends AppFailure {
  const PersistenceFailure([super.message = 'Could not save the favorite.']);
}
