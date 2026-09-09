import { FastifyRequest, FastifyReply } from 'fastify';
import { taskService } from './tasks.service';

export async function getTasks(request: FastifyRequest, reply: FastifyReply) {
  const tasks = await taskService.getAll();
  return reply.send(tasks);
}

export async function getTaskById(request: FastifyRequest, reply: FastifyReply) {
  const { id } = request.params as any;
  const task = await taskService.getById(id);
  return reply.send(task);
}

export async function createTask(request: FastifyRequest, reply: FastifyReply) {
  const taskData = request.body as any;
  const task = await taskService.create(taskData);
  return reply.code(201).send(task);
}

export async function claimTask(request: FastifyRequest, reply: FastifyReply) {
  const { id } = request.params as any;
  const workerId = (request as any).user.userId;
  const task = await taskService.claim(id, workerId);
  return reply.send(task);
}