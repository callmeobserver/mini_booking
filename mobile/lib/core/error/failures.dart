import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error. Check your connection.']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error occurred.']);
}

class BookingConflictFailure extends Failure {
  const BookingConflictFailure([super.message = 'Booking dates conflict with an existing reservation.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
