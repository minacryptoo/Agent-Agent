import { FastifyRequest, FastifyReply } from 'fastify';
import { adminService } from './admin.service';

export async function getStats(request: FastifyRequest, reply: FastifyReply) {
  const stats = await adminService.getStats();
  return reply.send(stats);
}

export async function getUsers(request: FastifyRequest, reply: FastifyReply) {
  const users = await adminService.getUsers();
  return reply.send(users);
}