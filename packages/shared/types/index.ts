export interface Task {
  id: string;
  title: string;
  description: string;
  budget: number;
  status: 'OPEN' | 'IN_PROGRESS' | 'COMPLETED' | 'DISPUTED';
  allocationType: 'AUTO_AGENT' | 'HUMAN_ONLY' | 'HYBRID';
  verificationType: 'AUTOMATIC' | 'MANUAL';
  clientId: string;
  workerId?: string;
  createdAt: Date;
  deadline?: Date;
}

export interface Agent {
  id: string;
  userId: string;
  capabilities: string[];
  isActive: boolean;
  reputation: number;
  jobsCompleted: number;
}

export interface User {
  id: string;
  email: string;
  walletAddress?: string;
  role: 'CLIENT' | 'WORKER' | 'ADMIN';
  reputation: number;
}
