import { FastifyInstance } from 'fastify';
import { login, register, verifySIWE, generateNonce } from './auth.controller';

export async function authRoutes(app: FastifyInstance) {
  app.post('/login', login);
  app.post('/register', register);
  app.post('/siwe/nonce', generateNonce);
  app.post('/siwe/verify', verifySIWE);
}
