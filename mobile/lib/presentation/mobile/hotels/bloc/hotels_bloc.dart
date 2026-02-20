import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../../domain/entities/hotel.dart';
import '../../../../domain/repositories/hotel_repository.dart';

// Events
sealed class HotelsEvent extends Equatable {
  const HotelsEvent();
  @override
  List<Object?> get props => [];
}

class HotelsLoadRequested extends HotelsEvent {
  const HotelsLoadRequested();
}

class HotelsRefreshRequested extends HotelsEvent {
  const HotelsRefreshRequested();
}

// States
sealed class HotelsState extends Equatable {
  const HotelsState();
  @override
  List<Object?> get props => [];
}

class HotelsInitial extends HotelsState {
  const HotelsInitial();
}

class HotelsLoading extends HotelsState {
  const HotelsLoading();
}

class HotelsLoaded extends HotelsState {
  final List<Hotel> hotels;
  const HotelsLoaded(this.hotels);
  @override
  List<Object?> get props => [hotels];
}

class HotelsError extends HotelsState {
  final Failure failure;
  const HotelsError(this.failure);
  @override
  List<Object?> get props => [failure];
}

// Bloc
class HotelsBloc extends Bloc<HotelsEvent, HotelsState> {
  final HotelRepository _hotelRepository;

  HotelsBloc({required HotelRepository hotelRepository})
      : _hotelRepository = hotelRepository,
        super(const HotelsInitial()) {
    on<HotelsLoadRequested>(_onLoadRequested);
    on<HotelsRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onLoadRequested(
    HotelsLoadRequested event,
    Emitter<HotelsState> emit,
  ) async {
    emit(const HotelsLoading());
    await _loadHotels(emit);
  }

  Future<void> _onRefreshRequested(
    HotelsRefreshRequested event,
    Emitter<HotelsState> emit,
  ) async {
    await _loadHotels(emit);
  }

  Future<void> _loadHotels(Emitter<HotelsState> emit) async {
    final result = await _hotelRepository.getHotels();
    switch (result) {
      case Success(data: final hotels):
        emit(HotelsLoaded(hotels));
      case Fail(failure: final failure):
        emit(HotelsError(failure));
    }
  }
}
