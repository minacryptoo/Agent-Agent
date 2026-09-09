
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
