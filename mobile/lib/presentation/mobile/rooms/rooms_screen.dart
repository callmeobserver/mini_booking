import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/entities/room.dart';
import '../../../domain/repositories/hotel_repository.dart';
import 'bloc/rooms_bloc.dart';

class RoomsScreen extends StatelessWidget {
  final String hotelId;
  final String hotelName;

  const RoomsScreen({
    super.key,
    required this.hotelId,
    required this.hotelName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RoomsBloc(hotelRepository: getIt<HotelRepository>())
        ..add(RoomsLoadRequested(hotelId)),
      child: Scaffold(
        appBar: AppBar(
          title: Text(hotelName.isNotEmpty ? hotelName : 'Rooms'),
        ),
        body: BlocBuilder<RoomsBloc, RoomsState>(
          builder: (context, state) => switch (state) {
            RoomsInitial() => const SizedBox.shrink(),
            RoomsLoading() => const Center(child: CircularProgressIndicator()),
            RoomsLoaded(:final hotel) => ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: hotel.rooms.length,
              itemBuilder: (context, index) => _RoomCard(
                room: hotel.rooms[index],
                hotelId: hotelId,
              ),
            ),
            RoomsError(:final failure) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text(failure.message),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.read<RoomsBloc>().add(RoomsLoadRequested(hotelId)),
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

class _RoomCard extends StatelessWidget {
  final Room room;
  final String hotelId;

  const _RoomCard({required this.room, required this.hotelId});

  String get _roomTypeLabel => switch (room.type.toUpperCase()) {
    'STANDARD' => 'Standard',
    'DELUXE' => 'Deluxe',
    'SUITE' => 'Suite',
    _ => room.type,
  };

  IconData get _roomTypeIcon => switch (room.type.toUpperCase()) {
    'SUITE' => Icons.king_bed,
    'DELUXE' => Icons.bed,
    _ => Icons.single_bed,
  };

  Color _roomTypeColor(BuildContext context) => switch (room.type.toUpperCase()) {
    'SUITE' => Colors.purple.shade700,
    'DELUXE' => Colors.blue.shade700,
    _ => Theme.of(context).colorScheme.primary,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () => context.push(
          '/hotels/$hotelId/rooms/${room.id}',
          extra: {'roomNumber': room.number, 'roomType': _roomTypeLabel},
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _roomTypeColor(context).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_roomTypeIcon, color: _roomTypeColor(context)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Room ${room.number}',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _roomTypeColor(context).withAlpha(25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _roomTypeLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: _roomTypeColor(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.people_outline, size: 14, color: theme.colorScheme.outline),
                        const SizedBox(width: 2),
                        Text(
                          '${room.capacity}',
                          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${room.pricePerNight.toStringAsFixed(0)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    '/night',
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
