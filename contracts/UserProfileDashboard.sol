// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./ProfileRegistry.sol";

/**
 * @title UserProfileDashboard
 * @dev Wallet-connected dApp for user profile management
 * @notice Stores profile data as IPFS CIDs (cost-efficient)
 */
contract UserProfileDashboard is Ownable, ReentrancyGuard {
    // ProfileRegistry contract
    ProfileRegistry public profileRegistry;
    
    // Events
    event ProfileUpdated(address indexed user, string ipfsCID, uint256 timestamp);
    event PreferencesUpdated(address indexed user, bytes preferences, uint256 timestamp);
    event SocialLinked(address indexed user, string platform, string handle, uint256 timestamp);
    
    /**
     * @dev Constructor
     * @param _profileRegistry ProfileRegistry contract address
     */
    constructor(address _profileRegistry) Ownable(msg.sender) {
        require(_profileRegistry != address(0), "UserProfileDashboard: Invalid profile registry");
        profileRegistry = ProfileRegistry(_profileRegistry);
    }
    
    /**
     * @dev Update user profile (IPFS CID)
     * @param ipfsCID IPFS CID for profile metadata
     */
    function updateProfile(string memory ipfsCID) external nonReentrant {
        require(bytes(ipfsCID).length > 0, "UserProfileDashboard: Invalid IPFS CID");
        
        profileRegistry.setProfileCID(msg.sender, ipfsCID);
        
        emit ProfileUpdated(msg.sender, ipfsCID, block.timestamp);
    }
    
    /**
     * @dev Set user preferences
     * @param preferences Encoded preferences data
     */
    function setPreferences(bytes memory preferences) external {
        profileRegistry.setPreferences(msg.sender, preferences);
        
        emit PreferencesUpdated(msg.sender, preferences, block.timestamp);
    }
    
    /**
     * @dev Link social media account
     * @param platform Platform name (e.g., "twitter", "telegram")
     * @param handle Platform handle/username
     */
    function linkSocial(string memory platform, string memory handle) external {
        require(bytes(platform).length > 0, "UserProfileDashboard: Invalid platform");
        require(bytes(handle).length > 0, "UserProfileDashboard: Invalid handle");
        
        // Store in ProfileRegistry (could extend ProfileRegistry to support social links)
        emit SocialLinked(msg.sender, platform, handle, block.timestamp);
    }
    
    /**
     * @dev Set icon color preference
     * @param colorHex Hex color code
     */
    function setIconColor(string memory colorHex) external {
        require(bytes(colorHex).length > 0, "UserProfileDashboard: Invalid color");
        
        // Store color preference (could be part of preferences)
        emit PreferencesUpdated(msg.sender, abi.encodePacked("iconColor:", colorHex), block.timestamp);
    }
    
    /**
     * @dev Get user profile CID
     * @param user User address
     * @return IPFS CID
     */
    function getProfileCID(address user) external view returns (string memory) {
        return profileRegistry.getProfileCID(user);
    }
}

