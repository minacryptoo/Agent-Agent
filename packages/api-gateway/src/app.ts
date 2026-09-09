
import Fastify from 'fastify';
import cors from '@fastify/cors';
import jwt from '@fastify/jwt';
import rateLimit from '@fastify/rate-limit';
import websocket from '@fastify/websocket';
import { authRoutes } from './modules/auth/auth.routes';
import { taskRoutes } from './modules/tasks/tasks.routes';
import { agentRoutes } from './modules/agents/agents.routes';
import { adminRoutes } from './modules/admin/admin.routes';
import { errorHandler } from './middleware/errorHandler.middleware';

export async function buildApp() {
  const app = Fastify({ logger: true });
  await app.register(cors, { origin: true });
  await app.register(jwt, { secret: process.env.JWT_SECRET || 'dev-secret' });
  await app.register(rateLimit, { max: 100, timeWindow: '1 minute' });
  await app.register(websocket);
  app.setErrorHandler(errorHandler);
  app.register(authRoutes, { prefix: '/api/v1/auth' });
  app.register(taskRoutes, { prefix: '/api/v1/tasks' });
  app.register(agentRoutes, { prefix: '/api/v1/agents' });
  app.register(adminRoutes, { prefix: '/api/v1/admin' });
  app.get('/health', async () => ({ status: 'ok' }));
  app.get('/manifest.json', async () => ({
    name: 'A2A Task & Human Marketplace Protocol',
    version: '1.0.0',
    network: 'base',
    escrowContract: process.env.ESCROW_ADDRESS,
    usdcContract: '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913',
    split: '80/20',
    endpoints: ['/api/v1', '/ws']
  }));
  return app;
}
