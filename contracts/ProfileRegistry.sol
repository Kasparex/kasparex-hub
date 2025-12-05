// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ProfileRegistry
 * @dev On-chain profile storage (IPFS CIDs)
 * @notice Maps wallet address to IPFS CID, minimal on-chain storage
 */
contract ProfileRegistry is Ownable {
    // Profile structure
    struct Profile {
        string ipfsCID; // IPFS CID for profile metadata
        string displayName; // Optional on-chain display name
        bool verified; // Verified status
        bytes preferences; // Encoded preferences
        uint256 updatedAt; // Last update timestamp
    }
    
    // User profiles
    mapping(address => Profile) public profiles;
    
    // Verified addresses (for badge display)
    mapping(address => bool) public verifiedAddresses;
    
    // Events
    event ProfileUpdated(address indexed user, string ipfsCID, uint256 timestamp);
    event DisplayNameUpdated(address indexed user, string displayName, uint256 timestamp);
    event VerificationUpdated(address indexed user, bool verified, uint256 timestamp);
    event PreferencesUpdated(address indexed user, bytes preferences, uint256 timestamp);
    
    /**
     * @dev Constructor
     */
    constructor() Ownable(msg.sender) {}
    
    /**
     * @dev Set profile IPFS CID
     * @param user User address
     * @param ipfsCID IPFS CID for profile metadata
     */
    function setProfileCID(address user, string memory ipfsCID) external {
        require(user != address(0), "ProfileRegistry: Invalid user");
        require(bytes(ipfsCID).length > 0, "ProfileRegistry: Invalid IPFS CID");
        
        // Only user or owner can update
        require(msg.sender == user || msg.sender == owner(), "ProfileRegistry: Not authorized");
        
        profiles[user].ipfsCID = ipfsCID;
        profiles[user].updatedAt = block.timestamp;
        
        emit ProfileUpdated(user, ipfsCID, block.timestamp);
    }
    
    /**
     * @dev Set display name (optional on-chain field)
     * @param user User address
     * @param displayName Display name
     */
    function setDisplayName(address user, string memory displayName) external {
        require(user != address(0), "ProfileRegistry: Invalid user");
        require(msg.sender == user || msg.sender == owner(), "ProfileRegistry: Not authorized");
        
        profiles[user].displayName = displayName;
        emit DisplayNameUpdated(user, displayName, block.timestamp);
    }
    
    /**
     * @dev Set verified status (only owner)
     * @param user User address
     * @param verified Verified status
     */
    function setVerified(address user, bool verified) external onlyOwner {
        require(user != address(0), "ProfileRegistry: Invalid user");
        
        profiles[user].verified = verified;
        verifiedAddresses[user] = verified;
        
        emit VerificationUpdated(user, verified, block.timestamp);
    }
    
    /**
     * @dev Set preferences
     * @param user User address
     * @param preferences Encoded preferences
     */
    function setPreferences(address user, bytes memory preferences) external {
        require(user != address(0), "ProfileRegistry: Invalid user");
        require(msg.sender == user || msg.sender == owner(), "ProfileRegistry: Not authorized");
        
        profiles[user].preferences = preferences;
        emit PreferencesUpdated(user, preferences, block.timestamp);
    }
    
    /**
     * @dev Get profile
     * @param user User address
     * @return Profile struct
     */
    function getProfile(address user) external view returns (Profile memory) {
        return profiles[user];
    }
    
    /**
     * @dev Get profile IPFS CID
     * @param user User address
     * @return IPFS CID
     */
    function getProfileCID(address user) external view returns (string memory) {
        return profiles[user].ipfsCID;
    }
    
    /**
     * @dev Batch update profiles (only owner, gas optimization)
     * @param users Array of user addresses
     * @param ipfsCIDs Array of IPFS CIDs
     */
    function batchUpdateProfiles(address[] memory users, string[] memory ipfsCIDs) external onlyOwner {
        require(users.length == ipfsCIDs.length, "ProfileRegistry: Array length mismatch");
        
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i] != address(0) && bytes(ipfsCIDs[i]).length > 0) {
                profiles[users[i]].ipfsCID = ipfsCIDs[i];
                profiles[users[i]].updatedAt = block.timestamp;
                emit ProfileUpdated(users[i], ipfsCIDs[i], block.timestamp);
            }
        }
    }
}

