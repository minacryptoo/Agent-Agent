import bcrypt from 'bcryptjs';
import { prisma } from '../../config/database';
import jwt from 'jsonwebtoken';
import { env } from '../../config/env';
import { SiweMessage } from 'siwe';
import { ethers } from 'ethers';

export const authService = {
  async login(email: string, password: string) {
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user || !user.password) throw new Error('Invalid credentials');
    const valid = await bcrypt.compare(password, user.password);
    if (!valid) throw new Error('Invalid credentials');
    const token = jwt.sign({ userId: user.id, role: user.role }, env.JWT_SECRET, { expiresIn: '24h' });
    return { token, user };
  },
  async register(email: string, password: string, walletAddress?: string) {
    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await prisma.user.create({
      data: { email, password: hashedPassword, walletAddress, role: 'CLIENT' },
    });
    const token = jwt.sign({ userId: user.id, role: user.role }, env.JWT_SECRET, { expiresIn: '24h' });
    return { token, user };
  },
  async verifySIWE(message: string, signature: string) {
    try {
      const siweMessage = new SiweMessage(message);
      const fields = await siweMessage.verify({ signature });
      return { valid: true, address: fields.data.address, chainId: fields.data.chainId };
    } catch (error) {
      return { valid: false, error: 'Invalid signature' };
    }
  },
  async generateNonce() {
    return ethers.hexlify(ethers.randomBytes(16));
  },
}