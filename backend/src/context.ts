import { PrismaClient } from '@prisma/client';
import { Pool } from 'pg';
import { PrismaPg } from '@prisma/adapter-pg';
import { PubSub } from 'graphql-subscriptions';
import { logger } from './utils/logger';
import { DataLoaders, createLoaders } from './utils/loaders';

const connectionString = `${process.env.DATABASE_URL}`;
const pool = new Pool({ connectionString });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });
const pubsub = new PubSub();

export interface Context {
  prisma: PrismaClient;
  pubsub: PubSub;
  logger: typeof logger;
  loaders: DataLoaders;
}

export function createContext(): Context {
  return { prisma, pubsub, logger, loaders: createLoaders(prisma) };
}

export { prisma, pubsub };
