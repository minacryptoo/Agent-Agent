import { FastifyRequest, FastifyReply } from 'fastify';
import { paymentService } from './payments.service';

export async function getBalance(request: FastifyRequest, reply: FastifyReply) {
  const userId = (request as any).user.userId;
  const balance = await paymentService.getBalance(userId);
  return reply.send({ balance });
}

export async function releasePayment(request: FastifyRequest, reply: FastifyReply) {
  const { taskId } = request.params as any;
  const result = await paymentService.release(taskId);
  return reply.send(result);
}