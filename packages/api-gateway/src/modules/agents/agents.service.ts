import { prisma } from '../../config/database';

export const agentService = {
  async getAll() {
    return prisma.agent.findMany({ include: { user: true } });
  },
  async getById(id: string) {
    return prisma.agent.findUnique({ where: { id }, include: { user: true } });
  },
  async register(userId: string, data: any) {
    return prisma.agent.create({ data: { userId, capabilities: data.capabilities || [], isActive: true } });
  },
}