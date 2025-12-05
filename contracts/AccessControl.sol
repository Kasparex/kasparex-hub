// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title AccessControl
 * @dev Gas-efficient token-based access control
 * @notice Checks token balance for access, supports time-based holding requirements
 */
contract AccessControl is Ownable {
    // Token address for access control
    IERC20 public accessToken;
    
    // Minimum balance required for access
    uint256 public minBalance;
    
    // Minimum holding time (in seconds, 0 = no time requirement)
    uint256 public minHoldingTime;
    
    // Track when users first acquired tokens
    mapping(address => uint256) public tokenAcquiredAt;
    
    // Cached access status (to reduce repeated checks)
    mapping(address => uint256) public cachedAccessUntil; // Timestamp until which access is cached
    
    // Cache duration (default 1 hour)
    uint256 public cacheDuration = 3600;
    
    // Events
    event AccessTokenUpdated(address indexed oldToken, address indexed newToken);
    event MinBalanceUpdated(uint256 oldBalance, uint256 newBalance);
    event MinHoldingTimeUpdated(uint256 oldTime, uint256 newTime);
    event AccessGranted(address indexed user);
    event AccessDenied(address indexed user, string reason);
    
    /**
     * @dev Constructor
     * @param _accessToken Address of the token used for access control
     * @param _minBalance Minimum token balance required
     * @param _minHoldingTime Minimum holding time in seconds (0 = no requirement)
     */
    constructor(
        address _accessToken,
        uint256 _minBalance,
        uint256 _minHoldingTime
    ) Ownable(msg.sender) {
        require(_accessToken != address(0), "AccessControl: Invalid token address");
        accessToken = IERC20(_accessToken);
        minBalance = _minBalance;
        minHoldingTime = _minHoldingTime;
    }
    
    /**
     * @dev Check if user has access (with caching)
     * @param user User address to check
     * @return hasAccess Whether user has access
     */
    function hasAccess(address user) external view returns (bool) {
        // Check cache first
        if (block.timestamp < cachedAccessUntil[user]) {
            return true;
        }
        
        return _checkAccess(user);
    }
    
    /**
     * @dev Internal function to check access (without cache)
     * @param user User address to check
     * @return hasAccess Whether user has access
     */
    function _checkAccess(address user) internal view returns (bool) {
        // Check balance
        uint256 balance = accessToken.balanceOf(user);
        if (balance < minBalance) {
            return false;
        }
        
        // Check holding time if required
        if (minHoldingTime > 0) {
            uint256 acquiredAt = tokenAcquiredAt[user];
            if (acquiredAt == 0) {
                // User hasn't been tracked yet, assume they just acquired
                return false;
            }
            if (block.timestamp < acquiredAt + minHoldingTime) {
                return false;
            }
        }
        
        return true;
    }
    
    /**
     * @dev Check access and update cache if granted
     * @param user User address to check
     * @return hasAccess Whether user has access
     */
    function checkAndCacheAccess(address user) external returns (bool) {
        bool hasAccess_ = _checkAccess(user);
        
        if (hasAccess_) {
            // Cache access for cacheDuration
            cachedAccessUntil[user] = block.timestamp + cacheDuration;
            emit AccessGranted(user);
        } else {
            emit AccessDenied(user, "Insufficient balance or holding time");
        }
        
        return hasAccess_;
    }
    
    /**
     * @dev Record when user acquired tokens (called by token contract or external)
     * @param user User address
     */
    function recordTokenAcquisition(address user) external {
        if (tokenAcquiredAt[user] == 0) {
            tokenAcquiredAt[user] = block.timestamp;
        }
    }
    
    /**
     * @dev Update access token (only owner)
     * @param _accessToken New token address
     */
    function setAccessToken(address _accessToken) external onlyOwner {
        require(_accessToken != address(0), "AccessControl: Invalid token address");
        address oldToken = address(accessToken);
        accessToken = IERC20(_accessToken);
        emit AccessTokenUpdated(oldToken, _accessToken);
    }
    
    /**
     * @dev Update minimum balance (only owner)
     * @param _minBalance New minimum balance
     */
    function setMinBalance(uint256 _minBalance) external onlyOwner {
        uint256 oldBalance = minBalance;
        minBalance = _minBalance;
        emit MinBalanceUpdated(oldBalance, _minBalance);
    }
    
    /**
     * @dev Update minimum holding time (only owner)
     * @param _minHoldingTime New minimum holding time in seconds
     */
    function setMinHoldingTime(uint256 _minHoldingTime) external onlyOwner {
        uint256 oldTime = minHoldingTime;
        minHoldingTime = _minHoldingTime;
        emit MinHoldingTimeUpdated(oldTime, _minHoldingTime);
    }
    
    /**
     * @dev Update cache duration (only owner)
     * @param _cacheDuration New cache duration in seconds
     */
    function setCacheDuration(uint256 _cacheDuration) external onlyOwner {
        cacheDuration = _cacheDuration;
    }
    
    /**
     * @dev Clear cache for a user (only owner)
     * @param user User address
     */
    function clearCache(address user) external onlyOwner {
        cachedAccessUntil[user] = 0;
    }
}

