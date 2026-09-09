import { FastifyInstance } from 'fastify';
import { getTasks, getTaskById, createTask, claimTask } from './tasks.controller';
import { authMiddleware } from '../../middleware/auth.middleware';

export async function taskRoutes(app: FastifyInstance) {
  app.get('/', getTasks);
  app.get('/:id', getTaskById);
  app.post('/create', { preHandler: authMiddleware }, createTask);
  app.post('/:id/claim', { preHandler: authMiddleware }, claimTask);
}