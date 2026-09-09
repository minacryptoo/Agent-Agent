
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
