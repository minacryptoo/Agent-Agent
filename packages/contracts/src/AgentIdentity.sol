
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
