import { useQuery } from '@apollo/client/react';
import { useParams, Link } from 'react-router-dom';
import { GET_HOTEL } from '../api/graphql/queries';
import type { Hotel, Room } from '../types/graphql';

const ROOM_TYPE_CONFIG: Record<string, { label: string; color: string; bg: string }> = {
  STANDARD: { label: 'Standard', color: 'text-blue-700', bg: 'bg-blue-50' },
  DELUXE: { label: 'Deluxe', color: 'text-purple-700', bg: 'bg-purple-50' },
  SUITE: { label: 'Suite', color: 'text-amber-700', bg: 'bg-amber-50' },
};

function RoomCard({ room, hotelId }: { room: Room; hotelId: string }) {
  const config = ROOM_TYPE_CONFIG[room.type] || ROOM_TYPE_CONFIG.STANDARD;

  return (
    <Link
      to={`/hotels/${hotelId}/rooms/${room.id}`}
      className="block bg-white border border-gray-200 rounded-lg p-4 hover:shadow-md hover:border-blue-300 transition-all"
    >
      <div className="flex items-center justify-between">
        <div>
          <h3 className="font-semibold text-gray-900">Room {room.number}</h3>
          <div className="flex items-center gap-2 mt-1">
            <span className={`text-xs font-medium px-2 py-0.5 rounded ${config.bg} ${config.color}`}>
              {config.label}
            </span>
            <span className="text-xs text-gray-500">
              {room.capacity} {room.capacity === 1 ? 'guest' : 'guests'}
            </span>
          </div>
          {room.description && (
            <p className="text-xs text-gray-400 mt-1 line-clamp-1">{room.description}</p>
          )}
        </div>
        <div className="text-right">
          <p className="text-lg font-bold text-blue-600">${room.pricePerNight}</p>
          <p className="text-xs text-gray-400">/night</p>
        </div>
      </div>
    </Link>
  );
}

export function HotelDetailPage() {
  const { hotelId } = useParams<{ hotelId: string }>();
  const { data, loading, error } = useQuery<{ hotel: Hotel }>(GET_HOTEL, {
    variables: { id: hotelId },
  });

  if (loading) {
    return (
      <div className="space-y-4">
        <div className="animate-pulse bg-gray-100 rounded-lg h-8 w-48" />
        {[1, 2, 3].map((i) => (
          <div key={i} className="animate-pulse bg-gray-100 rounded-lg h-20" />
        ))}
      </div>
    );
  }

  if (error || !data?.hotel) {
    return (
      <div className="text-center py-12">
        <p className="text-red-600">{error?.message || 'Hotel not found'}</p>
        <Link to="/" className="text-blue-600 hover:underline mt-4 inline-block">
          Back to hotels
        </Link>
      </div>
    );
  }

  const { hotel } = data;

  return (
    <div>
      <nav className="text-sm text-gray-500 mb-4">
        <Link to="/" className="hover:text-blue-600">Hotels</Link>
        <span className="mx-2">/</span>
        <span className="text-gray-900">{hotel.name}</span>
      </nav>

      <div className="mb-6">
        <h1 className="text-2xl font-bold">{hotel.name}</h1>
        <div className="flex mt-1 mb-1">
          {Array.from({ length: hotel.starRating }).map((_, i) => (
            <span key={i} className="text-amber-500">★</span>
          ))}
        </div>
        <p className="text-sm text-gray-500">{hotel.address}</p>
      </div>

      <h2 className="text-lg font-semibold mb-4">
        Rooms ({hotel.rooms.length})
      </h2>

      <div className="space-y-3">
        {hotel.rooms.map((room) => (
          <RoomCard key={room.id} room={room} hotelId={hotel.id} />
        ))}
      </div>
    </div>
  );
}
