import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/entities/booking.dart';
import '../../../domain/repositories/booking_repository.dart';
import '../../mobile/room_detail/bloc/room_detail_bloc.dart';

class DesktopRoomDetailScreen extends StatelessWidget {
  final String roomId;

  const DesktopRoomDetailScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RoomDetailBloc(bookingRepository: getIt<BookingRepository>())
        ..add(RoomDetailLoadRequested(roomId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Room Bookings'),
          leading: const BackButton(),
        ),
        body: BlocConsumer<RoomDetailBloc, RoomDetailState>(
          listenWhen: (previous, current) {
            if (previous is RoomDetailLoaded && current is RoomDetailLoaded) {
              return current.mutationError != null && previous.mutationError == null;
            }
            return false;
          },
          listener: (context, state) {
            if (state is RoomDetailLoaded && state.mutationError != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.mutationError!.message),
                  backgroundColor: Colors.red.shade700,
                ),
              );
            }
          },
          builder: (context, state) => switch (state) {
            RoomDetailInitial() => const SizedBox.shrink(),
            RoomDetailLoading() => const Center(child: CircularProgressIndicator()),
            RoomDetailLoaded() => _DesktopBookingsTable(state: state),
            RoomDetailError(:final failure) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 40, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 12),
                  Text(failure.message),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => context.read<RoomDetailBloc>().add(RoomDetailLoadRequested(roomId)),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          },
        ),
      ),
    );
  }
}

class _DesktopBookingsTable extends StatelessWidget {
  final RoomDetailLoaded state;
  const _DesktopBookingsTable({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy-MM-dd');

    if (state.bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 40, color: theme.colorScheme.outline),
            const SizedBox(height: 8),
            Text('No active bookings', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: DataTable(
        columnSpacing: 16,
        columns: const [
          DataColumn(label: Text('Guest')),
          DataColumn(label: Text('Check-in')),
          DataColumn(label: Text('Check-out')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Action')),
        ],
        rows: state.bookings.map((booking) {
          final isCancelling = state.cancellingBookingId == booking.id;
          return DataRow(
            cells: [
              DataCell(Text(booking.guestName, style: const TextStyle(fontSize: 12))),
              DataCell(Text(dateFormat.format(booking.checkIn), style: const TextStyle(fontSize: 12))),
              DataCell(Text(dateFormat.format(booking.checkOut), style: const TextStyle(fontSize: 12))),
              DataCell(_StatusBadge(status: booking.status)),
              DataCell(
                isCancelling
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : booking.status == BookingStatus.confirmed
                        ? InkWell(
                            onTap: () => context.read<RoomDetailBloc>().add(
                              RoomDetailBookingCancelled(booking.id),
                            ),
                            child: Icon(Icons.cancel_outlined, size: 18, color: Colors.red.shade400),
                          )
                        : const SizedBox.shrink(),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final BookingStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isConfirmed = status == BookingStatus.confirmed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isConfirmed ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isConfirmed ? Colors.green.shade300 : Colors.grey.shade300,
        ),
      ),
      child: Text(
        isConfirmed ? 'Active' : 'Cancelled',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isConfirmed ? Colors.green.shade700 : Colors.grey.shade600,
        ),
      ),
    );
  }
}
