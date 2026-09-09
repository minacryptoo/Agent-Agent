
import dotenv from 'dotenv';
dotenv.config();
export const env = {
  PORT: process.env.PORT || 3001,
  JWT_SECRET: process.env.JWT_SECRET || 'dev-secret',
  DATABASE_URL: process.env.DATABASE_URL || 'postgresql://localhost:5432/a2a',
  REDIS_URL: process.env.REDIS_URL || 'redis://localhost:6379',
  RPC_URL: process.env.RPC_URL || 'https://mainnet.base.org',
  ESCROW_ADDRESS: process.env.ESCROW_ADDRESS || '',
  USDC_ADDRESS: process.env.USDC_ADDRESS || '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913',
};
