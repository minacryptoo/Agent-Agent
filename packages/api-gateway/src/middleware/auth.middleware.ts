import { FastifyRequest, FastifyReply, FastifyNextFunction } from 'fastify';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';

export async function authMiddleware(request: FastifyRequest, reply: FastifyReply, next: FastifyNextFunction) {
  try {
    const token = request.headers.authorization?.replace('Bearer ', '');
    if (!token) throw new Error('No token provided');
    const decoded = jwt.verify(token, env.JWT_SECRET);
    (request as any).user = decoded;
    next();
  } catch (error) {
    reply.code(401).send({ error: 'Unauthorized' });
  }
}