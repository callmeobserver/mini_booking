import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/repositories/hotel_repository.dart';
import '../../../domain/repositories/booking_repository.dart';
import 'bloc/dashboard_bloc.dart';

class DashboardScreen extends StatelessWidget {
  final void Function(String roomId)? onRoomTap;

  const DashboardScreen({super.key, this.onRoomTap});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DashboardBloc(
        hotelRepository: getIt<HotelRepository>(),
        bookingRepository: getIt<BookingRepository>(),
      )..add(const DashboardLoadRequested()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mini Booking Status'),
          centerTitle: true,
          actions: [
            Builder(
              builder: (context) => IconButton(
                onPressed: () => context.read<DashboardBloc>().add(const DashboardRefreshRequested()),
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ),
          ],
        ),
        body: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) => switch (state) {
            DashboardInitial() => const SizedBox.shrink(),
            DashboardLoading() => const Center(child: CircularProgressIndicator()),
            DashboardLoaded(:final hotelStatuses, :final lastRefreshed) => _DashboardContent(
              hotelStatuses: hotelStatuses,
              lastRefreshed: lastRefreshed,
              onRoomTap: onRoomTap,
            ),
            DashboardError(:final failure) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 40, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 12),
                  Text(failure.message, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => context.read<DashboardBloc>().add(const DashboardLoadRequested()),
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

class _DashboardContent extends StatelessWidget {
  final List<HotelStatus> hotelStatuses;
  final DateTime lastRefreshed;
  final void Function(String roomId)? onRoomTap;

  const _DashboardContent({
    required this.hotelStatuses,
    required this.lastRefreshed,
    this.onRoomTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('HH:mm:ss');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              'Last updated: ${timeFormat.format(lastRefreshed)}',
              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
          ...hotelStatuses.map(
            (hotelStatus) => _HotelStatusCard(
              hotelStatus: hotelStatus,
              onRoomTap: onRoomTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _HotelStatusCard extends StatelessWidget {
  final HotelStatus hotelStatus;
  final void Function(String roomId)? onRoomTap;

  const _HotelStatusCard({required this.hotelStatus, this.onRoomTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.hotel, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hotelStatus.hotel.name,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    hotelStatus.hotel.starRating,
                    (_) => const Icon(Icons.star, size: 12, color: Colors.amber),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 4),
            ...hotelStatus.roomStatuses.map(
              (rs) => _RoomStatusRow(roomStatus: rs, onTap: onRoomTap),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomStatusRow extends StatelessWidget {
  final RoomStatus roomStatus;
  final void Function(String roomId)? onTap;

  const _RoomStatusRow({required this.roomStatus, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd');

    return InkWell(
      onTap: onTap != null ? () => onTap!(roomStatus.room.id) : null,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Icon(
              Icons.meeting_room,
              size: 16,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(width: 6),
            Text(
              '#${roomStatus.room.number}',
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 12),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: roomStatus.isOccupiedToday ? Colors.red.shade400 : Colors.green.shade400,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              roomStatus.isOccupiedToday ? 'Occupied' : 'Free',
              style: theme.textTheme.labelSmall?.copyWith(
                color: roomStatus.isOccupiedToday ? Colors.red.shade700 : Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (roomStatus.nearestUpcomingBooking != null)
              Text(
                'Next: ${dateFormat.format(roomStatus.nearestUpcomingBooking!.checkIn)}',
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
              ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 16, color: theme.colorScheme.outline),
          ],
        ),
      ),
    );
  }
}
