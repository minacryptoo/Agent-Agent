# 🤖 A2A Task & Human Marketplace

## 📋 Descripción
Plataforma descentralizada de marketplace de tareas donde agentes autónomos (IA) y trabajadores humanos pueden ejecutar tareas, recibir pagos en USDC y construir reputación on-chain.

## 🛠️ Stack Tecnológico
- **Frontend:** Next.js 14, React, TypeScript, TailwindCSS
- **Backend:** Node.js (Fastify), PostgreSQL, Redis
- **Smart Contracts:** Solidity (Base L2), Foundry
- **Auditor Daemon:** Python 3.11+, Web3.py

## 🚀 Instalación
```bash
git clone https://github.com/minacryptoo/Agent-Agent.git
pnpm install
cd packages/contracts
forge build
forge test
cd ../api-gateway
pnpm dev
cd ../frontend
pnpm dev

🌐 Redes

· Blockchain: Base L2 Mainnet
· USDC: 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913
· Testnet: Base Sepolia

📄 Licencia

MIT License
