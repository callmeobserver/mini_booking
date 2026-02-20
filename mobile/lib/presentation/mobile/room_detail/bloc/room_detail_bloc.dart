import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../../domain/entities/availability.dart';
import '../../../../domain/entities/booking.dart';
import '../../../../domain/repositories/booking_repository.dart';

// Events
sealed class RoomDetailEvent extends Equatable {
  const RoomDetailEvent();
  @override
  List<Object?> get props => [];
}

class RoomDetailLoadRequested extends RoomDetailEvent {
  final String roomId;
  const RoomDetailLoadRequested(this.roomId);
  @override
  List<Object?> get props => [roomId];
}

class RoomDetailDateRangeSelected extends RoomDetailEvent {
  final DateTimeRange range;
  const RoomDetailDateRangeSelected(this.range);
  @override
  List<Object?> get props => [range];
}

class RoomDetailAvailabilityChecked extends RoomDetailEvent {
  const RoomDetailAvailabilityChecked();
}

class RoomDetailBookingCreated extends RoomDetailEvent {
  final String guestName;
  const RoomDetailBookingCreated(this.guestName);
  @override
  List<Object?> get props => [guestName];
}

class RoomDetailBookingCancelled extends RoomDetailEvent {
  final String bookingId;
  const RoomDetailBookingCancelled(this.bookingId);
  @override
  List<Object?> get props => [bookingId];
}

// States
sealed class RoomDetailState extends Equatable {
  const RoomDetailState();
  @override
  List<Object?> get props => [];
}

class RoomDetailInitial extends RoomDetailState {
  const RoomDetailInitial();
}

class RoomDetailLoading extends RoomDetailState {
  const RoomDetailLoading();
}

class RoomDetailLoaded extends RoomDetailState {
  final String roomId;
  final List<Booking> bookings;
  final DateTimeRange? selectedRange;
  final Availability? availability;
  final bool isCheckingAvailability;
  final bool isBookingInProgress;
  final String? cancellingBookingId;
  final Failure? mutationError;

  const RoomDetailLoaded({
    required this.roomId,
    required this.bookings,
    this.selectedRange,
    this.availability,
    this.isCheckingAvailability = false,
    this.isBookingInProgress = false,
    this.cancellingBookingId,
    this.mutationError,
  });

  RoomDetailLoaded copyWith({
    String? roomId,
    List<Booking>? bookings,
    DateTimeRange? Function()? selectedRange,
    Availability? Function()? availability,
    bool? isCheckingAvailability,
    bool? isBookingInProgress,
    String? Function()? cancellingBookingId,
    Failure? Function()? mutationError,
  }) {
    return RoomDetailLoaded(
      roomId: roomId ?? this.roomId,
      bookings: bookings ?? this.bookings,
      selectedRange: selectedRange != null ? selectedRange() : this.selectedRange,
      availability: availability != null ? availability() : this.availability,
      isCheckingAvailability: isCheckingAvailability ?? this.isCheckingAvailability,
      isBookingInProgress: isBookingInProgress ?? this.isBookingInProgress,
      cancellingBookingId: cancellingBookingId != null ? cancellingBookingId() : this.cancellingBookingId,
      mutationError: mutationError != null ? mutationError() : this.mutationError,
    );
  }

  @override
  List<Object?> get props => [
        roomId,
        bookings,
        selectedRange,
        availability,
        isCheckingAvailability,
        isBookingInProgress,
        cancellingBookingId,
        mutationError,
      ];
}

class RoomDetailError extends RoomDetailState {
  final Failure failure;
  const RoomDetailError(this.failure);
  @override
  List<Object?> get props => [failure];
}

// Bloc
class RoomDetailBloc extends Bloc<RoomDetailEvent, RoomDetailState> {
  final BookingRepository _bookingRepository;

  RoomDetailBloc({required BookingRepository bookingRepository})
      : _bookingRepository = bookingRepository,
        super(const RoomDetailInitial()) {
    on<RoomDetailLoadRequested>(_onLoadRequested);
    on<RoomDetailDateRangeSelected>(_onDateRangeSelected);
    on<RoomDetailAvailabilityChecked>(_onAvailabilityChecked);
    on<RoomDetailBookingCreated>(_onBookingCreated);
    on<RoomDetailBookingCancelled>(_onBookingCancelled);
  }

  Future<void> _onLoadRequested(
    RoomDetailLoadRequested event,
    Emitter<RoomDetailState> emit,
  ) async {
    emit(const RoomDetailLoading());

    final result = await _bookingRepository.getBookingsForRoom(event.roomId);
    switch (result) {
      case Success(data: final bookings):
        emit(RoomDetailLoaded(
          roomId: event.roomId,
          bookings: bookings.where((b) => b.status == BookingStatus.confirmed).toList(),
        ));
      case Fail(failure: final failure):
        emit(RoomDetailError(failure));
    }
  }

  void _onDateRangeSelected(
    RoomDetailDateRangeSelected event,
    Emitter<RoomDetailState> emit,
  ) {
    final current = state;
    if (current is RoomDetailLoaded) {
      emit(current.copyWith(
        selectedRange: () => event.range,
        availability: () => null,
        mutationError: () => null,
      ));
    }
  }

  Future<void> _onAvailabilityChecked(
    RoomDetailAvailabilityChecked event,
    Emitter<RoomDetailState> emit,
  ) async {
    final current = state;
    if (current is! RoomDetailLoaded || current.selectedRange == null) return;

    emit(current.copyWith(
      isCheckingAvailability: true,
      mutationError: () => null,
    ));

    final result = await _bookingRepository.checkAvailability(
      roomId: current.roomId,
      checkIn: current.selectedRange!.start,
      checkOut: current.selectedRange!.end,
    );

    final freshState = state;
    if (freshState is! RoomDetailLoaded) return;

    switch (result) {
      case Success(data: final availability):
        emit(freshState.copyWith(
          availability: () => availability,
          isCheckingAvailability: false,
        ));
      case Fail(failure: final failure):
        emit(freshState.copyWith(
          isCheckingAvailability: false,
          mutationError: () => failure,
        ));
    }
  }

  Future<void> _onBookingCreated(
    RoomDetailBookingCreated event,
    Emitter<RoomDetailState> emit,
  ) async {
    final current = state;
    if (current is! RoomDetailLoaded || current.selectedRange == null) return;

    emit(current.copyWith(
      isBookingInProgress: true,
      mutationError: () => null,
    ));

    final result = await _bookingRepository.createBooking(
      roomId: current.roomId,
      checkIn: current.selectedRange!.start,
      checkOut: current.selectedRange!.end,
      guestName: event.guestName,
    );

    final freshState = state;
    if (freshState is! RoomDetailLoaded) return;

    switch (result) {
      case Success(data: final booking):
        emit(freshState.copyWith(
          bookings: [...freshState.bookings, booking],
          isBookingInProgress: false,
          selectedRange: () => null,
          availability: () => null,
        ));
      case Fail(failure: final failure):
        emit(freshState.copyWith(
          isBookingInProgress: false,
          mutationError: () => failure,
        ));
    }
  }

  Future<void> _onBookingCancelled(
    RoomDetailBookingCancelled event,
    Emitter<RoomDetailState> emit,
  ) async {
    final current = state;
    if (current is! RoomDetailLoaded) return;

    emit(current.copyWith(
      cancellingBookingId: () => event.bookingId,
      mutationError: () => null,
    ));

    final result = await _bookingRepository.cancelBooking(event.bookingId);

    final freshState = state;
    if (freshState is! RoomDetailLoaded) return;

    switch (result) {
      case Success():
        emit(freshState.copyWith(
          bookings: freshState.bookings.where((b) => b.id != event.bookingId).toList(),
          cancellingBookingId: () => null,
          availability: () => null,
        ));
      case Fail(failure: final failure):
        emit(freshState.copyWith(
          cancellingBookingId: () => null,
          mutationError: () => failure,
        ));
    }
  }
}
