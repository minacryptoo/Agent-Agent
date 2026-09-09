import { prisma } from '../../config/database';

export const paymentService = {
  async getBalance(userId: string) {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    return user?.reputation || 0;
  },
  async release(taskId: string) {
    return { success: true, taskId };
  },
}