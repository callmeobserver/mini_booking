import { hotelResolvers } from './hotel.resolver';
import { roomResolvers } from './room.resolver';
import { bookingResolvers } from './booking.resolver';
import { dateScalar } from '../../utils/date-scalar';

export const resolvers = {
  Date: dateScalar,

  Query: {
    ...hotelResolvers.Query,
    ...roomResolvers.Query,
    ...bookingResolvers.Query,
  },

  Mutation: {
    ...bookingResolvers.Mutation,
  },

  Subscription: {
    ...bookingResolvers.Subscription,
  },

  Hotel: {
    ...hotelResolvers.Hotel,
  },

  Room: {
    ...roomResolvers.Room,
  },

  Booking: {
    ...bookingResolvers.Booking,
  },
};
