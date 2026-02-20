import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/entities/hotel.dart';
import '../../../domain/repositories/hotel_repository.dart';
import 'bloc/hotels_bloc.dart';

class HotelsScreen extends StatelessWidget {
  const HotelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HotelsBloc(hotelRepository: getIt<HotelRepository>())
        ..add(const HotelsLoadRequested()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mini Booking'),
          centerTitle: true,
        ),
        body: BlocBuilder<HotelsBloc, HotelsState>(
          builder: (context, state) => switch (state) {
            HotelsInitial() => const SizedBox.shrink(),
            HotelsLoading() => const Center(child: CircularProgressIndicator()),
            HotelsLoaded(:final hotels) => _HotelsList(hotels: hotels),
            HotelsError(:final failure) => _ErrorView(
              message: failure.message,
              onRetry: () => context.read<HotelsBloc>().add(const HotelsLoadRequested()),
            ),
          },
        ),
      ),
    );
  }
}

class _HotelsList extends StatelessWidget {
  final List<Hotel> hotels;
  const _HotelsList({required this.hotels});

  @override
  Widget build(BuildContext context) {
    if (hotels.isEmpty) {
      return const Center(child: Text('No hotels found'));
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<HotelsBloc>().add(const HotelsRefreshRequested());
        await context.read<HotelsBloc>().stream.firstWhere(
              (state) => state is HotelsLoaded || state is HotelsError,
            );
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: hotels.length,
        itemBuilder: (context, index) => _HotelCard(hotel: hotels[index]),
      ),
    );
  }
}

class _HotelCard extends StatelessWidget {
  final Hotel hotel;
  const _HotelCard({required this.hotel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/hotels/${hotel.id}/rooms', extra: hotel.name),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.hotel, color: theme.colorScheme.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hotel.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: List.generate(
                            hotel.starRating,
                            (_) => Icon(Icons.star, size: 16, color: Colors.amber.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      hotel.address,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${hotel.rooms.length} rooms available',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
