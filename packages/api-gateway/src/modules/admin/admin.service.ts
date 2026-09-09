import { prisma } from '../../config/database';

export const adminService = {
  async getStats() {
    const [users, tasks, agents] = await Promise.all([
      prisma.user.count(),
      prisma.task.count(),
      prisma.agent.count(),
    ]);
    return { users, tasks, agents };
  },
  async getUsers() {
    return prisma.user.findMany();
  },
}