export interface Hotel {
  id: string;
  name: string;
  address: string;
  starRating: number;
  imageUrl?: string;
  rooms: Room[];
}

export interface Room {
  id: string;
  number: string;
  type: 'STANDARD' | 'DELUXE' | 'SUITE';
  pricePerNight: number;
  capacity: number;
  description?: string;
  hotel?: { id: string; name: string };
}

export interface Booking {
  id: string;
  guestName: string;
  guestEmail?: string;
  checkIn: string;
  checkOut: string;
  status: 'CONFIRMED' | 'CANCELLED';
  createdAt: string;
}

export interface AvailabilityResult {
  available: boolean;
  conflictingBookings: Booking[];
}

export interface BookingResult {
  success: boolean;
  message: string;
  booking: Booking;
}
