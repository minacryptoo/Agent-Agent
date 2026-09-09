import { FastifyRequest, FastifyReply } from 'fastify';

export async function errorHandler(error: any, request: FastifyRequest, reply: FastifyReply) {
  console.error(error);
  reply.status(500).send({
    error: 'Internal Server Error',
    message: error.message,
  });
}
