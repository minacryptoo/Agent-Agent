import { prisma } from '../../config/database';

export const taskService = {
  async getAll() {
    return prisma.task.findMany({ include: { client: true, worker: true } });
  },
  async getById(id: string) {
    return prisma.task.findUnique({ where: { id }, include: { client: true, worker: true, submissions: true } });
  },
  async create(data: any) {
    return prisma.task.create({
      data: {
        title: data.title,
        description: data.description,
        budget: data.budget,
        allocationType: data.allocationType,
        verificationType: data.verificationType,
        clientId: data.clientId,
        deadline: data.deadline,
      },
    });
  },
  async claim(id: string, workerId: string) {
    return prisma.task.update({ where: { id }, data: { workerId, status: 'IN_PROGRESS' } });
  },
}