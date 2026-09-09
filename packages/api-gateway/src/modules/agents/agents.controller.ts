import { FastifyRequest, FastifyReply } from 'fastify';
import { agentService } from './agents.service';

export async function getAgents(request: FastifyRequest, reply: FastifyReply) {
  const agents = await agentService.getAll();
  return reply.send(agents);
}

export async function getAgentById(request: FastifyRequest, reply: FastifyReply) {
  const { id } = request.params as any;
  const agent = await agentService.getById(id);
  return reply.send(agent);
}

export async function registerAgent(request: FastifyRequest, reply: FastifyReply) {
  const agentData = request.body as any;
  const userId = (request as any).user.userId;
  const agent = await agentService.register(userId, agentData);
  return reply.code(201).send(agent);
}