// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./DAppToken.sol";
import "./GRIDToken.sol";
import "./RewardManager.sol";

/**
 * @title ProofOfUtility
 * @dev Tracks on-chain usage events and mints rewards
 * @notice Gas-efficient P-o-U tracking with batch processing
 */
contract ProofOfUtility is Ownable, ReentrancyGuard {
    // RewardManager contract
    RewardManager public rewardManager;
    
    // Usage event structure
    struct UsageEvent {
        address user;
        address dAppContract;
        uint256 dAppId;
        string actionType; // e.g., "vote", "proposal", "payment"
        uint256 timestamp;
    }
    
    // Track events per user
    mapping(address => UsageEvent[]) public userEvents;
    
    // Track events per dApp
    mapping(address => UsageEvent[]) public dAppEvents;
    
    // Event counter
    uint256 public totalEvents;
    
    // Events
    event UsageEventRecorded(
        address indexed user,
        address indexed dAppContract,
        uint256 indexed dAppId,
        string actionType,
        uint256 timestamp
    );
    event RewardMinted(
        address indexed user,
        address indexed token,
        uint256 amount,
        string rewardType
    );
    event RewardManagerUpdated(address indexed oldManager, address indexed newManager);
    
    /**
     * @dev Constructor
     * @param _rewardManager Address of RewardManager contract
     */
    constructor(address _rewardManager) Ownable(msg.sender) {
        require(_rewardManager != address(0), "ProofOfUtility: Invalid reward manager");
        rewardManager = RewardManager(_rewardManager);
    }
    
    /**
     * @dev Record a usage event (called by dApp contracts)
     * @param user Address of the user
     * @param dAppContract Address of the dApp contract
     * @param dAppId ID of the dApp
     * @param actionType Type of action performed
     */
    function recordUsage(
        address user,
        address dAppContract,
        uint256 dAppId,
        string memory actionType
    ) public {
        require(user != address(0), "ProofOfUtility: Invalid user");
        require(dAppContract != address(0), "ProofOfUtility: Invalid dApp contract");
        
        UsageEvent memory event_ = UsageEvent({
            user: user,
            dAppContract: dAppContract,
            dAppId: dAppId,
            actionType: actionType,
            timestamp: block.timestamp
        });
        
        userEvents[user].push(event_);
        dAppEvents[dAppContract].push(event_);
        totalEvents++;
        
        emit UsageEventRecorded(user, dAppContract, dAppId, actionType, block.timestamp);
    }
    
    /**
     * @dev Record multiple usage events in batch (gas optimization)
     * @param users Array of user addresses
     * @param dAppContracts Array of dApp contract addresses
     * @param dAppIds Array of dApp IDs
     * @param actionTypes Array of action types
     */
    function recordUsageBatch(
        address[] memory users,
        address[] memory dAppContracts,
        uint256[] memory dAppIds,
        string[] memory actionTypes
    ) external {
        require(
            users.length == dAppContracts.length &&
            dAppContracts.length == dAppIds.length &&
            dAppIds.length == actionTypes.length,
            "ProofOfUtility: Array length mismatch"
        );
        
        for (uint256 i = 0; i < users.length; i++) {
            // Inline recordUsage logic for gas efficiency
            address user = users[i];
            address dAppContract = dAppContracts[i];
            uint256 dAppId = dAppIds[i];
            string memory actionType = actionTypes[i];
            
            require(user != address(0), "ProofOfUtility: Invalid user");
            require(dAppContract != address(0), "ProofOfUtility: Invalid dApp contract");
            
            UsageEvent memory event_ = UsageEvent({
                user: user,
                dAppContract: dAppContract,
                dAppId: dAppId,
                actionType: actionType,
                timestamp: block.timestamp
            });
            
            userEvents[user].push(event_);
            dAppEvents[dAppContract].push(event_);
            totalEvents++;
            
            emit UsageEventRecorded(user, dAppContract, dAppId, actionType, block.timestamp);
        }
    }
    
    /**
     * @dev Get user's usage events
     * @param user User address
     * @return Array of usage events
     */
    function getUserEvents(address user) external view returns (UsageEvent[] memory) {
        return userEvents[user];
    }
    
    /**
     * @dev Get dApp's usage events
     * @param dAppContract dApp contract address
     * @return Array of usage events
     */
    function getDAppEvents(address dAppContract) external view returns (UsageEvent[] memory) {
        return dAppEvents[dAppContract];
    }
    
    /**
     * @dev Get user's event count
     * @param user User address
     * @return Event count
     */
    function getUserEventCount(address user) external view returns (uint256) {
        return userEvents[user].length;
    }
    
    /**
     * @dev Record usage and distribute reward (called by dApp contracts)
     * @param user Address of the user
     * @param dAppContract Address of the dApp contract
     * @param dAppId ID of the dApp
     * @param actionType Type of action performed
     * @param actionValue Value of the action (for reward calculation)
     */
    function recordUsageAndReward(
        address user,
        address dAppContract,
        uint256 dAppId,
        string memory actionType,
        uint256 actionValue
    ) public {
        require(user != address(0), "ProofOfUtility: Invalid user");
        require(dAppContract != address(0), "ProofOfUtility: Invalid dApp contract");
        
        // Record usage event
        UsageEvent memory event_ = UsageEvent({
            user: user,
            dAppContract: dAppContract,
            dAppId: dAppId,
            actionType: actionType,
            timestamp: block.timestamp
        });
        
        userEvents[user].push(event_);
        dAppEvents[dAppContract].push(event_);
        totalEvents++;
        
        emit UsageEventRecorded(user, dAppContract, dAppId, actionType, block.timestamp);
        
        // Distribute reward if actionValue > 0
        if (actionValue > 0) {
            rewardManager.distributeReward(user, dAppContract, actionValue);
        }
    }
    
    /**
     * @dev Update reward manager (only owner)
     * @param _rewardManager New reward manager address
     */
    function setRewardManager(address _rewardManager) external onlyOwner {
        require(_rewardManager != address(0), "ProofOfUtility: Invalid reward manager");
        address oldManager = address(rewardManager);
        rewardManager = RewardManager(_rewardManager);
        emit RewardManagerUpdated(oldManager, _rewardManager);
    }
}

