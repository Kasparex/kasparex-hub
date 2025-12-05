// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title LoyaltyPoints
 * @dev Long-term participation tracking (soulbound-like, non-transferable)
 * @notice Tracks user participation, convertible to GRID/KREX later
 */
contract LoyaltyPoints is Ownable {
    // Loyalty point structure
    struct LoyaltyData {
        uint256 totalPoints;
        uint256 participationDays;
        uint256 lastActivity;
        uint256 streakDays;
    }
    
    // User loyalty data
    mapping(address => LoyaltyData) public userLoyalty;
    
    // Points per action type
    mapping(string => uint256) public actionPoints; // actionType -> points
    
    // Minimum activity interval for streak (in seconds, default 1 day)
    uint256 public streakInterval = 86400;
    
    // Events
    event PointsAwarded(
        address indexed user,
        string actionType,
        uint256 points,
        uint256 totalPoints,
        uint256 timestamp
    );
    event StreakUpdated(address indexed user, uint256 streakDays, uint256 timestamp);
    event ActionPointsUpdated(string actionType, uint256 oldPoints, uint256 newPoints);
    
    /**
     * @dev Constructor
     */
    constructor() Ownable(msg.sender) {
        // Set default action points
        actionPoints["vote"] = 10;
        actionPoints["proposal"] = 50;
        actionPoints["payment"] = 5;
        actionPoints["daily_login"] = 1;
    }
    
    /**
     * @dev Award loyalty points for an action
     * @param user User address
     * @param actionType Type of action performed
     */
    function awardPoints(address user, string memory actionType) external {
        require(user != address(0), "LoyaltyPoints: Invalid user");
        
        uint256 points = actionPoints[actionType];
        if (points == 0) {
            return; // No points for this action
        }
        
        LoyaltyData storage loyalty = userLoyalty[user];
        loyalty.totalPoints += points;
        loyalty.lastActivity = block.timestamp;
        
        // Update participation days
        uint256 daysSinceLastActivity = (block.timestamp - loyalty.lastActivity) / streakInterval;
        if (daysSinceLastActivity >= 1) {
            loyalty.participationDays++;
            
            // Update streak
            if (daysSinceLastActivity == 1) {
                loyalty.streakDays++;
            } else {
                loyalty.streakDays = 1; // Reset streak
            }
            
            emit StreakUpdated(user, loyalty.streakDays, block.timestamp);
        }
        
        emit PointsAwarded(user, actionType, points, loyalty.totalPoints, block.timestamp);
    }
    
    /**
     * @dev Batch award points (gas optimization)
     * @param users Array of user addresses
     * @param actionTypes Array of action types
     */
    function awardPointsBatch(address[] memory users, string[] memory actionTypes) external {
        require(users.length == actionTypes.length, "LoyaltyPoints: Array length mismatch");
        
        for (uint256 i = 0; i < users.length; i++) {
            // Inline the awardPoints logic to avoid function call overhead
            address user = users[i];
            string memory actionType = actionTypes[i];
            
            require(user != address(0), "LoyaltyPoints: Invalid user");
            
            uint256 points = actionPoints[actionType];
            if (points == 0) {
                continue; // No points for this action
            }
            
            LoyaltyData storage loyalty = userLoyalty[user];
            loyalty.totalPoints += points;
            loyalty.lastActivity = block.timestamp;
            
            // Update participation days
            uint256 daysSinceLastActivity = (block.timestamp - loyalty.lastActivity) / streakInterval;
            if (daysSinceLastActivity >= 1) {
                loyalty.participationDays++;
                
                // Update streak
                if (daysSinceLastActivity == 1) {
                    loyalty.streakDays++;
                } else {
                    loyalty.streakDays = 1; // Reset streak
                }
                
                emit StreakUpdated(user, loyalty.streakDays, block.timestamp);
            }
            
            emit PointsAwarded(user, actionType, points, loyalty.totalPoints, block.timestamp);
        }
    }
    
    /**
     * @dev Get user's loyalty data
     * @param user User address
     * @return LoyaltyData struct
     */
    function getUserLoyalty(address user) external view returns (LoyaltyData memory) {
        return userLoyalty[user];
    }
    
    /**
     * @dev Get user's total points
     * @param user User address
     * @return Total points
     */
    function getTotalPoints(address user) external view returns (uint256) {
        return userLoyalty[user].totalPoints;
    }
    
    /**
     * @dev Get user's streak
     * @param user User address
     * @return Streak days
     */
    function getStreak(address user) external view returns (uint256) {
        return userLoyalty[user].streakDays;
    }
    
    /**
     * @dev Set points for an action type (only owner)
     * @param actionType Action type
     * @param points Points to award
     */
    function setActionPoints(string memory actionType, uint256 points) external onlyOwner {
        uint256 oldPoints = actionPoints[actionType];
        actionPoints[actionType] = points;
        emit ActionPointsUpdated(actionType, oldPoints, points);
    }
    
    /**
     * @dev Update streak interval (only owner)
     * @param _interval New interval in seconds
     */
    function setStreakInterval(uint256 _interval) external onlyOwner {
        streakInterval = _interval;
    }
}

