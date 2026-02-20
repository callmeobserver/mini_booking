import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/entities/booking.dart';
import '../../../domain/repositories/booking_repository.dart';
import 'bloc/room_detail_bloc.dart';

class RoomDetailScreen extends StatelessWidget {
  final String roomId;
  final String? roomNumber;
  final String? roomType;

  const RoomDetailScreen({
    super.key,
    required this.roomId,
    this.roomNumber,
    this.roomType,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RoomDetailBloc(bookingRepository: getIt<BookingRepository>())
        ..add(RoomDetailLoadRequested(roomId)),
      child: Scaffold(
        appBar: AppBar(
          title: Text(roomNumber != null ? 'Room $roomNumber' : 'Room Details'),
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
            RoomDetailLoaded() => _RoomDetailContent(state: state),
            RoomDetailError(:final failure) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text(failure.message),
                  const SizedBox(height: 16),
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

class _RoomDetailContent extends StatelessWidget {
  final RoomDetailLoaded state;
  const _RoomDetailContent({required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DateRangeSection(state: state),
          const SizedBox(height: 12),
          _AvailabilitySection(state: state),
          const SizedBox(height: 12),
          _BookingActionSection(state: state),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          _BookingsListSection(state: state),
        ],
      ),
    );
  }
}

class _DateRangeSection extends StatelessWidget {
  final RoomDetailLoaded state;
  const _DateRangeSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      child: InkWell(
        onTap: () async {
          final range = await showDateRangePicker(
            context: context,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            initialDateRange: state.selectedRange,
            builder: (context, child) {
              return Theme(
                data: theme.copyWith(
                  colorScheme: theme.colorScheme.copyWith(
                    primary: theme.colorScheme.primary,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (range != null && context.mounted) {
            context.read<RoomDetailBloc>().add(RoomDetailDateRangeSelected(range));
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.calendar_month, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: state.selectedRange != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Selected dates', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
                          const SizedBox(height: 4),
                          Text(
                            '${dateFormat.format(state.selectedRange!.start)} — ${dateFormat.format(state.selectedRange!.end)}',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      )
                    : Text(
                        'Select check-in & check-out dates',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                      ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvailabilitySection extends StatelessWidget {
  final RoomDetailLoaded state;
  const _AvailabilitySection({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: state.selectedRange != null && !state.isCheckingAvailability
                ? () => context.read<RoomDetailBloc>().add(const RoomDetailAvailabilityChecked())
                : null,
            icon: state.isCheckingAvailability
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.search),
            label: Text(state.isCheckingAvailability ? 'Checking...' : 'Check Availability'),
          ),
        ),
        if (state.availability != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: state.availability!.isAvailable
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: state.availability!.isAvailable ? Colors.green.shade300 : Colors.red.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  state.availability!.isAvailable ? Icons.check_circle : Icons.cancel,
                  color: state.availability!.isAvailable ? Colors.green.shade700 : Colors.red.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.availability!.isAvailable
                        ? 'Room is available for selected dates!'
                        : 'Room is not available. Conflicts with existing booking.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: state.availability!.isAvailable ? Colors.green.shade900 : Colors.red.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _BookingActionSection extends StatefulWidget {
  final RoomDetailLoaded state;
  const _BookingActionSection({required this.state});

  @override
  State<_BookingActionSection> createState() => _BookingActionSectionState();
}

class _BookingActionSectionState extends State<_BookingActionSection> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canBook = widget.state.availability?.isAvailable == true &&
        !widget.state.isBookingInProgress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Guest Name',
            hintText: 'Enter guest name',
            prefixIcon: Icon(Icons.person_outline),
          ),
          enabled: canBook,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: canBook && _nameController.text.trim().isNotEmpty
                ? () {
                    context.read<RoomDetailBloc>().add(
                      RoomDetailBookingCreated(_nameController.text.trim()),
                    );
                    _nameController.clear();
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            icon: widget.state.isBookingInProgress
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.bookmark_add),
            label: Text(widget.state.isBookingInProgress ? 'Booking...' : 'Book Now'),
          ),
        ),
      ],
    );
  }
}

class _BookingsListSection extends StatelessWidget {
  final RoomDetailLoaded state;
  const _BookingsListSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Bookings',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (state.bookings.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.event_available, size: 40, color: theme.colorScheme.outline),
                const SizedBox(height: 8),
                Text(
                  'No active bookings',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
            ),
          )
        else
          ...state.bookings.map(
            (booking) => _BookingTile(
              booking: booking,
              isCancelling: state.cancellingBookingId == booking.id,
              dateFormat: dateFormat,
            ),
          ),
      ],
    );
  }
}

class _BookingTile extends StatelessWidget {
  final Booking booking;
  final bool isCancelling;
  final DateFormat dateFormat;

  const _BookingTile({
    required this.booking,
    required this.isCancelling,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.guestName,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.date_range, size: 14, color: theme.colorScheme.outline),
                      const SizedBox(width: 4),
                      Text(
                        '${dateFormat.format(booking.checkIn)} — ${dateFormat.format(booking.checkOut)}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            isCancelling
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Cancel Booking'),
                          content: Text('Cancel booking for ${booking.guestName}?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('No'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                context.read<RoomDetailBloc>().add(
                                  RoomDetailBookingCancelled(booking.id),
                                );
                              },
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Cancel Booking'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: Icon(Icons.cancel_outlined, color: Colors.red.shade400),
                    tooltip: 'Cancel booking',
                  ),
          ],
        ),
      ),
    );
  }
}
