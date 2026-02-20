import { ApolloServer } from '@apollo/server';
import { expressMiddleware } from '@as-integrations/express5';
import { ApolloServerPluginDrainHttpServer } from '@apollo/server/plugin/drainHttpServer';
import { makeExecutableSchema } from '@graphql-tools/schema';
import { WebSocketServer } from 'ws';
import { useServer } from 'graphql-ws/use/ws';
import express from 'express';
import http from 'http';
import cors from 'cors';
import { readFileSync } from 'fs';
import { join } from 'path';
import { Context, createContext } from './context';
import { resolvers } from './schema/resolvers';
import { logger } from './utils/logger';

export async function buildServer() {
  const app = express();
  const httpServer = http.createServer(app);

  // Read GraphQL schema
  const typeDefs = readFileSync(
    join(__dirname, 'schema', 'typeDefs', 'schema.graphql'),
    'utf-8'
  );

  const schema = makeExecutableSchema({ typeDefs, resolvers });

  // WebSocket server for subscriptions
  const wsServer = new WebSocketServer({
    server: httpServer,
    path: '/graphql',
  });

  const serverCleanup = useServer(
    {
      schema,
      context: () => createContext(),
    },
    wsServer
  );

  const apolloServer = new ApolloServer<Context>({
    schema,
    plugins: [
      ApolloServerPluginDrainHttpServer({ httpServer }),
      {
        async serverWillStart() {
          return {
            async drainServer() {
              await serverCleanup.dispose();
            },
          };
        },
      },
    ],
    formatError: (formattedError) => {
      logger.error({ err: formattedError }, 'GraphQL Error');
      return formattedError;
    },
  });

  await apolloServer.start();

  // Health check endpoint
  app.get('/health', (_req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
  });

  app.use(
    '/graphql',
    cors<cors.CorsRequest>({
      origin: '*',
      methods: ['GET', 'POST', 'OPTIONS'],
    }),
    express.json(),
    expressMiddleware(apolloServer, {
      context: async () => createContext(),
    })
  );

  return { httpServer, apolloServer, app };
}
