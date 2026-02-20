import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../../domain/entities/hotel.dart';
import '../../../../domain/repositories/hotel_repository.dart';

// Events
sealed class RoomsEvent extends Equatable {
  const RoomsEvent();
  @override
  List<Object?> get props => [];
}

class RoomsLoadRequested extends RoomsEvent {
  final String hotelId;
  const RoomsLoadRequested(this.hotelId);
  @override
  List<Object?> get props => [hotelId];
}

// States
sealed class RoomsState extends Equatable {
  const RoomsState();
  @override
  List<Object?> get props => [];
}

class RoomsInitial extends RoomsState {
  const RoomsInitial();
}

class RoomsLoading extends RoomsState {
  const RoomsLoading();
}

class RoomsLoaded extends RoomsState {
  final Hotel hotel;
  const RoomsLoaded(this.hotel);
  @override
  List<Object?> get props => [hotel];
}

class RoomsError extends RoomsState {
  final Failure failure;
  const RoomsError(this.failure);
  @override
  List<Object?> get props => [failure];
}

// Bloc
class RoomsBloc extends Bloc<RoomsEvent, RoomsState> {
  final HotelRepository _hotelRepository;

  RoomsBloc({required HotelRepository hotelRepository})
      : _hotelRepository = hotelRepository,
        super(const RoomsInitial()) {
    on<RoomsLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    RoomsLoadRequested event,
    Emitter<RoomsState> emit,
  ) async {
    emit(const RoomsLoading());

    final result = await _hotelRepository.getHotelById(event.hotelId);
    switch (result) {
      case Success(data: final hotel):
        emit(RoomsLoaded(hotel));
      case Fail(failure: final failure):
        emit(RoomsError(failure));
    }
  }
}
