import { ApolloClient, InMemoryCache, HttpLink, from } from '@apollo/client';
import { ErrorLink } from '@apollo/client/link/error';
import { CombinedGraphQLErrors } from '@apollo/client/errors';
import toast from 'react-hot-toast';
import { API_URL } from '../lib/constants';

const httpLink = new HttpLink({ uri: API_URL });

const errorLink = new ErrorLink(({ error }) => {
  if (error) {
    if (CombinedGraphQLErrors.is(error)) {
      error.errors.forEach(({ message }) => {
        console.error(`[GraphQL error]: ${message}`);
      });
    } else {
      console.error(`[Network error]: ${error}`);
      toast.error('Network error. Please check your connection.');
    }
  }
});

export const apolloClient = new ApolloClient({
  link: from([errorLink, httpLink]),
  cache: new InMemoryCache({
    typePolicies: {
      Room: {
        fields: {
          bookings: {
            merge(_existing, incoming) {
              return incoming;
            },
          },
        },
      },
    },
  }),
  defaultOptions: {
    watchQuery: {
      fetchPolicy: 'cache-and-network',
      errorPolicy: 'all',
    },
    query: {
      fetchPolicy: 'cache-first',
      errorPolicy: 'all',
    },
    mutate: {
      errorPolicy: 'all',
    },
  },
});
