import { gql } from '@apollo/client';

export const GET_HOTELS = gql`
  query GetHotels {
    hotels {
      id
      name
      address
      starRating
      imageUrl
      rooms {
        id
        number
        type
        pricePerNight
        capacity
        description
      }
    }
  }
`;

export const GET_HOTEL = gql`
  query GetHotel($id: ID!) {
    hotel(id: $id) {
      id
      name
      address
      starRating
      imageUrl
      rooms {
        id
        number
        type
        pricePerNight
        capacity
        description
      }
    }
  }
`;

export const GET_ROOM = gql`
  query GetRoom($id: ID!) {
    room(id: $id) {
      id
      number
      type
      pricePerNight
      capacity
      description
      hotel {
        id
        name
      }
    }
  }
`;

export const GET_BOOKINGS = gql`
  query GetBookings($roomId: ID!) {
    bookings(roomId: $roomId) {
      id
      guestName
      guestEmail
      checkIn
      checkOut
      status
      createdAt
    }
  }
`;

export const CHECK_AVAILABILITY = gql`
  query CheckAvailability($input: CheckAvailabilityInput!) {
    checkAvailability(input: $input) {
      available
      conflictingBookings {
        id
        guestName
        checkIn
        checkOut
      }
    }
  }
`;

export const CREATE_BOOKING = gql`
  mutation CreateBooking($input: CreateBookingInput!) {
    createBooking(input: $input) {
      success
      message
      booking {
        id
        guestName
        guestEmail
        checkIn
        checkOut
        status
        createdAt
      }
    }
  }
`;

export const CANCEL_BOOKING = gql`
  mutation CancelBooking($input: CancelBookingInput!) {
    cancelBooking(input: $input) {
      success
      message
      booking {
        id
        guestName
        checkIn
        checkOut
        status
      }
    }
  }
`;
