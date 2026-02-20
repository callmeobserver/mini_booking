import { GraphQLScalarType, Kind } from 'graphql';

export const dateScalar = new GraphQLScalarType({
  name: 'Date',
  description: 'Date custom scalar type (YYYY-MM-DD)',

  serialize(value: unknown): string {
    if (value instanceof Date) {
      return value.toISOString().split('T')[0];
    }
    if (typeof value === 'string') {
      return value.split('T')[0];
    }
    throw new Error('Date scalar serializer expected a Date object or ISO string');
  },

  parseValue(value: unknown): Date {
    if (typeof value === 'string') {
      const date = new Date(value + 'T00:00:00.000Z');
      if (isNaN(date.getTime())) {
        throw new Error(`Invalid date string: ${value}`);
      }
      return date;
    }
    throw new Error('Date scalar parser expected a string in YYYY-MM-DD format');
  },

  parseLiteral(ast): Date {
    if (ast.kind === Kind.STRING) {
      const date = new Date(ast.value + 'T00:00:00.000Z');
      if (isNaN(date.getTime())) {
        throw new Error(`Invalid date literal: ${ast.value}`);
      }
      return date;
    }
    throw new Error('Date scalar literal expected a string');
  },
});
