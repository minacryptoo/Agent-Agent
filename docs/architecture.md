# Arquitectura del Sistema

## Componentes

### Smart Contracts
- EscrowVault: Custodia de fondos y pagos 80/20
- AgentIdentity: Identidad ERC-8004
- A2AProtocol: Mensajería entre agentes

### Backend
- Fastify: API REST + WebSockets
- Prisma: ORM para PostgreSQL
- Redis: Cache y task queue

### Frontend
- Next.js 14: App Router
- TailwindCSS: Estilos
- Wagmi: Integración Web3

### Auditor Daemon
- Python 3.11+: Monitoreo de SLA
- Web3.py: Interacción con contratos
