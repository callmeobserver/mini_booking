import { useQuery } from '@apollo/client/react';
import { Link } from 'react-router-dom';
import { GET_HOTELS } from '../api/graphql/queries';
import type { Hotel } from '../types/graphql';

export function HotelsPage() {
  const { data, loading, error, refetch } = useQuery<{ hotels: Hotel[] }>(GET_HOTELS);

  if (loading) {
    return (
      <div className="space-y-4">
        <h1 className="text-2xl font-bold">Hotels</h1>
        {[1, 2].map((i) => (
          <div key={i} className="animate-pulse bg-gray-100 rounded-lg h-36" />
        ))}
      </div>
    );
  }

  if (error) {
    return (
      <div className="text-center py-12">
        <p className="text-red-600 mb-4">{error.message}</p>
        <button
          onClick={() => refetch()}
          className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
        >
          Retry
        </button>
      </div>
    );
  }

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Hotels</h1>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {data?.hotels.map((hotel) => (
          <Link
            key={hotel.id}
            to={`/hotels/${hotel.id}`}
            className="block bg-white border border-gray-200 rounded-xl p-6 hover:shadow-lg hover:border-blue-300 transition-all"
          >
            <div className="flex items-start justify-between">
              <div>
                <h2 className="text-lg font-semibold text-gray-900">{hotel.name}</h2>
                <div className="flex mt-1 mb-2">
                  {Array.from({ length: hotel.starRating }).map((_, i) => (
                    <span key={i} className="text-amber-500">★</span>
                  ))}
                </div>
                <p className="text-sm text-gray-500 flex items-center gap-1">
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                  </svg>
                  {hotel.address}
                </p>
              </div>
              <span className="text-sm bg-blue-50 text-blue-700 px-3 py-1 rounded-full font-medium">
                {hotel.rooms.length} rooms
              </span>
            </div>
          </Link>
        ))}
      </div>
    </div>
  );
}
