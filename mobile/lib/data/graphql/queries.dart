const String getHotelsQuery = r'''
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
''';

const String getHotelQuery = r'''
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
''';

const String getRoomQuery = r'''
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
''';

const String getBookingsQuery = r'''
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
''';

const String checkAvailabilityQuery = r'''
  query CheckAvailability($input: CheckAvailabilityInput!) {
    checkAvailability(input: $input) {
      available
      conflictingBookings {
        id
        guestName
        checkIn
        checkOut
        status
      }
    }
  }
''';

const String createBookingMutation = r'''
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
''';

const String cancelBookingMutation = r'''
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
        createdAt
      }
    }
  }
''';
