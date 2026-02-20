import { buildServer } from './server';
import { logger } from './utils/logger';

const PORT = parseInt(process.env.PORT || '4000', 10);

async function main() {
  const { httpServer } = await buildServer();

  httpServer.listen(PORT, () => {
    logger.info(`Server ready at http://localhost:${PORT}/graphql`);
    logger.info(`Subscriptions ready at ws://localhost:${PORT}/graphql`);
    logger.info(`Health check at http://localhost:${PORT}/health`);
  });
}

main().catch((err) => {
  logger.fatal(err, 'Failed to start server');
  process.exit(1);
});
