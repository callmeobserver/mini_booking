import { useState } from 'react';
import { useQuery, useMutation, useLazyQuery } from '@apollo/client/react';
import { useParams, Link } from 'react-router-dom';
import toast from 'react-hot-toast';
import { GET_ROOM, GET_BOOKINGS, CHECK_AVAILABILITY, CREATE_BOOKING, CANCEL_BOOKING } from '../api/graphql/queries';
import { formatDate, toInputDate } from '../lib/date-utils';
import type { Room, Booking, AvailabilityResult, BookingResult } from '../types/graphql';

export function RoomDetailPage() {
  const { hotelId, roomId } = useParams<{ hotelId: string; roomId: string }>();
  const [checkIn, setCheckIn] = useState('');
  const [checkOut, setCheckOut] = useState('');
  const [guestName, setGuestName] = useState('');

  const { data: roomData } = useQuery<{ room: Room }>(GET_ROOM, { variables: { id: roomId } });
  const { data: bookingsData, loading: bookingsLoading, refetch: refetchBookings } =
    useQuery<{ bookings: Booking[] }>(GET_BOOKINGS, { variables: { roomId } });

  const [checkAvailability, { data: availData, loading: checkingAvail }] =
    useLazyQuery<{ checkAvailability: AvailabilityResult }>(CHECK_AVAILABILITY, {
      fetchPolicy: 'network-only',
    });

  const [createBooking, { loading: creating }] = useMutation<{ createBooking: BookingResult }>(CREATE_BOOKING);
  const [cancelBooking] = useMutation<{ cancelBooking: BookingResult }>(CANCEL_BOOKING);

  const room = roomData?.room;
  const bookings: Booking[] = bookingsData?.bookings?.filter((b) => b.status === 'CONFIRMED') ?? [];
  const availability = availData?.checkAvailability;

  const handleCheckAvailability = () => {
    if (!checkIn || !checkOut) return;
    checkAvailability({
      variables: { input: { roomId, checkIn, checkOut } },
    });
  };

  const handleCreateBooking = async () => {
    if (!checkIn || !checkOut || !guestName.trim()) return;
    try {
      const result = await createBooking({
        variables: {
          input: { roomId, checkIn, checkOut, guestName: guestName.trim() },
        },
      });
      if (result.data?.createBooking.success) {
        toast.success('Booking created successfully!');
        setCheckIn('');
        setCheckOut('');
        setGuestName('');
        refetchBookings();
      }
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Failed to create booking';
      toast.error(message);
    }
  };

  const handleCancelBooking = async (bookingId: string, name: string) => {
    if (!confirm(`Cancel booking for ${name}?`)) return;
    try {
      const result = await cancelBooking({ variables: { input: { bookingId } } });
      if (result.data?.cancelBooking.success) {
        toast.success('Booking cancelled');
        refetchBookings();
      }
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Failed to cancel booking';
      toast.error(message);
    }
  };

  return (
    <div>
      <nav className="text-sm text-gray-500 mb-4">
        <Link to="/" className="hover:text-blue-600">Hotels</Link>
        <span className="mx-2">/</span>
        <Link to={`/hotels/${hotelId}`} className="hover:text-blue-600">{room?.hotel?.name || 'Hotel'}</Link>
        <span className="mx-2">/</span>
        <span className="text-gray-900">Room {room?.number || ''}</span>
      </nav>

      {room && (
        <div className="mb-6">
          <h1 className="text-2xl font-bold">Room {room.number}</h1>
          <div className="flex items-center gap-3 mt-2">
            <span className="text-sm font-medium px-2 py-1 rounded bg-blue-50 text-blue-700">
              {room.type}
            </span>
            <span className="text-sm text-gray-500">{room.capacity} guests</span>
            <span className="text-lg font-bold text-blue-600">${room.pricePerNight}/night</span>
          </div>
          {room.description && <p className="text-sm text-gray-500 mt-2">{room.description}</p>}
        </div>
      )}

      {/* Availability & Booking Section */}
      <div className="bg-white border border-gray-200 rounded-xl p-6 mb-6">
        <h2 className="text-lg font-semibold mb-4">Check Availability & Book</h2>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Check-in</label>
            <input
              type="date"
              value={checkIn}
              min={toInputDate(new Date())}
              onChange={(e) => { setCheckIn(e.target.value); }}
              className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Check-out</label>
            <input
              type="date"
              value={checkOut}
              min={checkIn || toInputDate(new Date())}
              onChange={(e) => { setCheckOut(e.target.value); }}
              className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
        </div>

        <button
          onClick={handleCheckAvailability}
          disabled={!checkIn || !checkOut || checkingAvail}
          className="w-full mb-4 px-4 py-2 bg-gray-100 text-gray-700 rounded-md hover:bg-gray-200 disabled:opacity-50 disabled:cursor-not-allowed text-sm font-medium"
        >
          {checkingAvail ? 'Checking...' : 'Check Availability'}
        </button>

        {availability && (
          <div
            className={`mb-4 p-3 rounded-md text-sm font-medium ${
              availability.available
                ? 'bg-green-50 text-green-800 border border-green-200'
                : 'bg-red-50 text-red-800 border border-red-200'
            }`}
          >
            {availability.available
              ? '✓ Room is available for selected dates!'
              : '✗ Room is not available. Conflicts with existing booking.'}
          </div>
        )}

        <div className="mb-4">
          <label className="block text-sm font-medium text-gray-700 mb-1">Guest Name</label>
          <input
            type="text"
            value={guestName}
            onChange={(e) => setGuestName(e.target.value)}
            placeholder="Enter guest name"
            disabled={!availability?.available}
            className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-50"
          />
        </div>

        <button
          onClick={handleCreateBooking}
          disabled={!availability?.available || !guestName.trim() || creating}
          className="w-full px-4 py-2.5 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed text-sm font-medium"
        >
          {creating ? 'Booking...' : 'Book Now'}
        </button>
      </div>

      {/* Bookings List */}
      <div className="bg-white border border-gray-200 rounded-xl p-6">
        <h2 className="text-lg font-semibold mb-4">Current Bookings</h2>

        {bookingsLoading ? (
          <div className="animate-pulse space-y-3">
            {[1, 2].map((i) => <div key={i} className="bg-gray-100 rounded-md h-16" />)}
          </div>
        ) : bookings.length === 0 ? (
          <p className="text-sm text-gray-500 text-center py-6">No active bookings</p>
        ) : (
          <div className="space-y-3">
            {bookings.map((booking) => (
              <div
                key={booking.id}
                className="flex items-center justify-between border border-gray-100 rounded-lg p-4"
              >
                <div>
                  <p className="font-medium text-gray-900">{booking.guestName}</p>
                  <p className="text-sm text-gray-500">
                    {formatDate(booking.checkIn)} — {formatDate(booking.checkOut)}
                  </p>
                </div>
                <button
                  onClick={() => handleCancelBooking(booking.id, booking.guestName)}
                  className="text-sm px-3 py-1.5 text-red-600 hover:bg-red-50 rounded-md transition-colors"
                >
                  Cancel
                </button>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
