import { FastifyRequest, FastifyReply } from 'fastify';
import { authService } from './auth.service';

export async function login(request: FastifyRequest, reply: FastifyReply) {
  const { email, password } = request.body as any;
  const result = await authService.login(email, password);
  return reply.send(result);
}

export async function register(request: FastifyRequest, reply: FastifyReply) {
  const { email, password, walletAddress } = request.body as any;
  const result = await authService.register(email, password, walletAddress);
  return reply.send(result);
}

export async function verifySIWE(request: FastifyRequest, reply: FastifyReply) {
  const { message, signature } = request.body as any;
  const result = await authService.verifySIWE(message, signature);
  return reply.send(result);
}

export async function generateNonce(request: FastifyRequest, reply: FastifyReply) {
  const nonce = await authService.generateNonce();
  return reply.send({ nonce });
}