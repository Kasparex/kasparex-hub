// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./Treasury.sol";

/**
 * @title PlatformSubscription
 * @dev Platform-wide subscription contract for fixed monthly KAS payments
 * @notice Users pay a fixed monthly fee set by Kasparex to access all premium dApps
 */
contract PlatformSubscription is Ownable, ReentrancyGuard {
    // Treasury contract for fee collection
    Treasury public treasury;

    // Fixed monthly subscription price (in wei)
    uint256 public monthlyPrice;

    // Subscription period in seconds (default: 30 days)
    uint256 public subscriptionPeriod;

    // Grace period in seconds (default: 7 days)
    uint256 public gracePeriod;

    // Kasparex fee percentage (basis points, e.g., 1500 = 15%)
    uint256 public kasparexFeePercentage;

    // Subscription info for each user
    struct Subscription {
        uint256 expiryTimestamp; // When subscription expires (0 = never subscribed)
        bool isActive; // Whether subscription is currently active
    }

    // Mapping from user address to subscription
    mapping(address => Subscription) public subscriptions;

    // Events
    event SubscriptionPurchased(
        address indexed user,
        uint256 amount,
        uint256 expiryTimestamp,
        uint256 timestamp
    );
    event SubscriptionRenewed(
        address indexed user,
        uint256 amount,
        uint256 newExpiryTimestamp,
        uint256 timestamp
    );
    event SubscriptionExpired(address indexed user, uint256 timestamp);
    event MonthlyPriceUpdated(uint256 oldPrice, uint256 newPrice);
    event SubscriptionPeriodUpdated(uint256 oldPeriod, uint256 newPeriod);
    event GracePeriodUpdated(uint256 oldPeriod, uint256 newPeriod);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);

    /**
     * @dev Constructor sets initial values
     * @param _treasury Address of the Treasury contract
     * @param _monthlyPrice Monthly subscription price in wei
     * @param _subscriptionPeriod Subscription period in seconds (default: 30 days)
     * @param _gracePeriod Grace period in seconds (default: 7 days)
     * @param _kasparexFeePercentage Kasparex fee percentage in basis points (default: 1500 = 15%)
     */
    constructor(
        address _treasury,
        uint256 _monthlyPrice,
        uint256 _subscriptionPeriod,
        uint256 _gracePeriod,
        uint256 _kasparexFeePercentage
    ) Ownable(msg.sender) {
        require(_treasury != address(0), "PlatformSubscription: Invalid treasury address");
        require(_monthlyPrice > 0, "PlatformSubscription: Price must be greater than 0");
        require(_kasparexFeePercentage <= 10000, "PlatformSubscription: Fee cannot exceed 100%");

        treasury = Treasury(_treasury);
        monthlyPrice = _monthlyPrice;
        subscriptionPeriod = _subscriptionPeriod;
        gracePeriod = _gracePeriod;
        kasparexFeePercentage = _kasparexFeePercentage;
    }

    /**
     * @dev Purchase or renew a platform subscription
     * @notice Users pay the fixed monthly price to access all premium dApps
     */
    function subscribe() external payable nonReentrant {
        require(msg.value >= monthlyPrice, "PlatformSubscription: Insufficient payment");

        uint256 kasparexFee = (msg.value * kasparexFeePercentage) / 10000;

        // Send Kasparex fee to treasury
        if (kasparexFee > 0) {
            treasury.collectFee{value: kasparexFee}();
        }

        // Calculate new expiry timestamp
        uint256 currentExpiry = subscriptions[msg.sender].expiryTimestamp;
        uint256 newExpiry;

        if (currentExpiry > block.timestamp) {
            // Renew existing active subscription
            newExpiry = currentExpiry + subscriptionPeriod;
            emit SubscriptionRenewed(msg.sender, msg.value, newExpiry, block.timestamp);
        } else {
            // New subscription
            newExpiry = block.timestamp + subscriptionPeriod;
            emit SubscriptionPurchased(msg.sender, msg.value, newExpiry, block.timestamp);
        }

        subscriptions[msg.sender] = Subscription({
            expiryTimestamp: newExpiry,
            isActive: true
        });

        // Refund excess payment
        if (msg.value > monthlyPrice) {
            uint256 refund = msg.value - monthlyPrice;
            (bool success, ) = payable(msg.sender).call{value: refund}("");
            require(success, "PlatformSubscription: Refund failed");
        }
    }

    /**
     * @dev Check if a user has an active subscription
     * @param _user Address to check
     * @return bool True if subscription is active
     */
    function isSubscribed(address _user) external view returns (bool) {
        Subscription memory sub = subscriptions[_user];
        if (!sub.isActive) return false;
        
        // Check if subscription has expired (including grace period)
        if (sub.expiryTimestamp > 0 && block.timestamp > sub.expiryTimestamp + gracePeriod) {
            return false;
        }
        
        return block.timestamp <= sub.expiryTimestamp;
    }

    /**
     * @dev Check if a user is in grace period
     * @param _user Address to check
     * @return bool True if in grace period
     */
    function isInGracePeriod(address _user) external view returns (bool) {
        Subscription memory sub = subscriptions[_user];
        if (!sub.isActive || sub.expiryTimestamp == 0) return false;
        
        return block.timestamp > sub.expiryTimestamp && 
               block.timestamp <= sub.expiryTimestamp + gracePeriod;
    }

    /**
     * @dev Get subscription expiry timestamp for a user
     * @param _user Address to check
     * @return uint256 Expiry timestamp (0 if not subscribed)
     */
    function getExpiryTimestamp(address _user) external view returns (uint256) {
        return subscriptions[_user].expiryTimestamp;
    }

    /**
     * @dev Update monthly subscription price (only owner)
     * @param _newPrice New monthly price in wei
     */
    function setMonthlyPrice(uint256 _newPrice) external onlyOwner {
        require(_newPrice > 0, "PlatformSubscription: Price must be greater than 0");
        uint256 oldPrice = monthlyPrice;
        monthlyPrice = _newPrice;
        emit MonthlyPriceUpdated(oldPrice, _newPrice);
    }

    /**
     * @dev Update subscription period (only owner)
     * @param _newPeriod New subscription period in seconds
     */
    function setSubscriptionPeriod(uint256 _newPeriod) external onlyOwner {
        require(_newPeriod > 0, "PlatformSubscription: Period must be greater than 0");
        uint256 oldPeriod = subscriptionPeriod;
        subscriptionPeriod = _newPeriod;
        emit SubscriptionPeriodUpdated(oldPeriod, _newPeriod);
    }

    /**
     * @dev Update grace period (only owner)
     * @param _newPeriod New grace period in seconds
     */
    function setGracePeriod(uint256 _newPeriod) external onlyOwner {
        uint256 oldPeriod = gracePeriod;
        gracePeriod = _newPeriod;
        emit GracePeriodUpdated(oldPeriod, _newPeriod);
    }

    /**
     * @dev Update Kasparex fee percentage (only owner)
     * @param _newPercentage New fee percentage in basis points
     */
    function setKasparexFeePercentage(uint256 _newPercentage) external onlyOwner {
        require(_newPercentage <= 10000, "PlatformSubscription: Fee cannot exceed 100%");
        kasparexFeePercentage = _newPercentage;
    }

    /**
     * @dev Update Treasury contract address (only owner)
     * @param _treasury New Treasury contract address
     */
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "PlatformSubscription: Invalid treasury address");
        address oldTreasury = address(treasury);
        treasury = Treasury(_treasury);
        emit TreasuryUpdated(oldTreasury, _treasury);
    }

    /**
     * @dev Deactivate a subscription (admin function for expired subscriptions)
     * @param _user Address to deactivate
     */
    function deactivateSubscription(address _user) external onlyOwner {
        if (subscriptions[_user].isActive) {
            subscriptions[_user].isActive = false;
            emit SubscriptionExpired(_user, block.timestamp);
        }
    }

    /**
     * @dev Get contract balance
     * @return uint256 Current balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Withdraw funds to treasury (only owner)
     * @param _amount Amount to withdraw
     */
    function withdrawToTreasury(uint256 _amount) external onlyOwner nonReentrant {
        require(_amount <= address(this).balance, "PlatformSubscription: Insufficient balance");
        treasury.collectFee{value: _amount}();
    }
}

