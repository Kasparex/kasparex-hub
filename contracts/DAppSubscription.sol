// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Treasury.sol";
import "./AuthorizationRegistry.sol";
import "./DAppRegistry.sol";

/**
 * @title DAppSubscription
 * @dev Per-dApp subscription contract with developer-configurable rates and flexible frequencies
 * @notice Developers can set their own subscription prices and payment frequencies
 */
contract DAppSubscription is Ownable, AccessControl, ReentrancyGuard {
    // Role for dApp developers
    bytes32 public constant DEVELOPER_ROLE = keccak256("DEVELOPER_ROLE");

    // Treasury contract for fee collection
    Treasury public treasury;

    // AuthorizationRegistry contract for checking developer assignments
    AuthorizationRegistry public authorizationRegistry;

    // DAppRegistry contract for getting dApp IDs
    DAppRegistry public dAppRegistry;

    // Kasparex fee percentage (basis points, e.g., 1500 = 15%)
    uint256 public kasparexFeePercentage;

    // Payment frequency types
    enum PaymentFrequency {
        Monthly,    // 30 days
        Quarterly, // 90 days
        Yearly     // 365 days
    }

    // Subscription plan for a dApp
    struct SubscriptionPlan {
        address dAppContract; // Address of the dApp contract
        address developer; // Developer address
        uint256 monthlyPrice; // Base monthly price in wei
        uint256 quarterlyPrice; // Quarterly price in wei
        uint256 yearlyPrice; // Yearly price in wei
        bool isActive; // Whether plan is active
        uint256 createdAt; // When plan was created
    }

    // User subscription to a specific dApp
    struct UserSubscription {
        uint256 expiryTimestamp; // When subscription expires (0 = never subscribed)
        PaymentFrequency frequency; // Payment frequency used
        bool isActive; // Whether subscription is active
    }

    // Mapping from dApp contract address to subscription plan
    mapping(address => SubscriptionPlan) public subscriptionPlans;

    // Mapping from user address to dApp contract address to subscription
    mapping(address => mapping(address => UserSubscription)) public userSubscriptions;

    // Mapping from dApp contract to array of subscribers
    mapping(address => address[]) public dAppSubscribers;

    // Events
    event SubscriptionPlanCreated(
        address indexed dAppContract,
        address indexed developer,
        uint256 monthlyPrice,
        uint256 quarterlyPrice,
        uint256 yearlyPrice,
        uint256 timestamp
    );
    event SubscriptionPlanUpdated(
        address indexed dAppContract,
        uint256 monthlyPrice,
        uint256 quarterlyPrice,
        uint256 yearlyPrice,
        uint256 timestamp
    );
    event SubscriptionPurchased(
        address indexed user,
        address indexed dAppContract,
        PaymentFrequency frequency,
        uint256 amount,
        uint256 expiryTimestamp,
        uint256 timestamp
    );
    event SubscriptionRenewed(
        address indexed user,
        address indexed dAppContract,
        PaymentFrequency frequency,
        uint256 amount,
        uint256 newExpiryTimestamp,
        uint256 timestamp
    );
    event SubscriptionExpired(
        address indexed user,
        address indexed dAppContract,
        uint256 timestamp
    );
    event KasparexFeePercentageUpdated(uint256 oldPercentage, uint256 newPercentage);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);

    /**
     * @dev Constructor sets initial values
     * @param _treasury Address of the Treasury contract
     * @param _authorizationRegistry Address of the AuthorizationRegistry contract
     * @param _dAppRegistry Address of the DAppRegistry contract
     * @param _kasparexFeePercentage Kasparex fee percentage in basis points (default: 1500 = 15%)
     */
    constructor(
        address _treasury,
        address _authorizationRegistry,
        address _dAppRegistry,
        uint256 _kasparexFeePercentage
    ) Ownable(msg.sender) {
        require(_treasury != address(0), "DAppSubscription: Invalid treasury address");
        require(_authorizationRegistry != address(0), "DAppSubscription: Invalid authorization registry address");
        require(_dAppRegistry != address(0), "DAppSubscription: Invalid dApp registry address");
        require(_kasparexFeePercentage <= 10000, "DAppSubscription: Fee cannot exceed 100%");

        treasury = Treasury(_treasury);
        authorizationRegistry = AuthorizationRegistry(_authorizationRegistry);
        dAppRegistry = DAppRegistry(_dAppRegistry);
        kasparexFeePercentage = _kasparexFeePercentage;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Create a subscription plan for a dApp (developer only)
     * @param _dAppContract Address of the dApp contract
     * @param _monthlyPrice Monthly subscription price in wei
     * @param _quarterlyPrice Quarterly subscription price in wei
     * @param _yearlyPrice Yearly subscription price in wei
     */
    function createSubscriptionPlan(
        address _dAppContract,
        uint256 _monthlyPrice,
        uint256 _quarterlyPrice,
        uint256 _yearlyPrice
    ) external {
        require(_dAppContract != address(0), "DAppSubscription: Invalid dApp contract");
        
        // Check if user is authorized: admin, has DEVELOPER_ROLE, or is assigned developer via AuthorizationRegistry
        bool isAuthorized = hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(DEVELOPER_ROLE, msg.sender);
        
        // If not authorized via roles, check AuthorizationRegistry
        if (!isAuthorized) {
            uint256 dAppId = dAppRegistry.getDAppIdByContract(_dAppContract);
            if (dAppId > 0) {
                isAuthorized = authorizationRegistry.isDeveloper(dAppId, msg.sender);
            }
        }
        
        require(isAuthorized, "DAppSubscription: Not authorized");
        require(_monthlyPrice > 0, "DAppSubscription: Monthly price must be greater than 0");
        require(_quarterlyPrice > 0, "DAppSubscription: Quarterly price must be greater than 0");
        require(_yearlyPrice > 0, "DAppSubscription: Yearly price must be greater than 0");

        subscriptionPlans[_dAppContract] = SubscriptionPlan({
            dAppContract: _dAppContract,
            developer: msg.sender,
            monthlyPrice: _monthlyPrice,
            quarterlyPrice: _quarterlyPrice,
            yearlyPrice: _yearlyPrice,
            isActive: true,
            createdAt: block.timestamp
        });

        emit SubscriptionPlanCreated(
            _dAppContract,
            msg.sender,
            _monthlyPrice,
            _quarterlyPrice,
            _yearlyPrice,
            block.timestamp
        );
    }

    /**
     * @dev Update subscription plan prices (developer or admin only)
     * @param _dAppContract Address of the dApp contract
     * @param _monthlyPrice New monthly price in wei
     * @param _quarterlyPrice New quarterly price in wei
     * @param _yearlyPrice New yearly price in wei
     */
    function updateSubscriptionPlan(
        address _dAppContract,
        uint256 _monthlyPrice,
        uint256 _quarterlyPrice,
        uint256 _yearlyPrice
    ) external {
        SubscriptionPlan storage plan = subscriptionPlans[_dAppContract];
        require(plan.dAppContract != address(0), "DAppSubscription: Plan does not exist");
        
        // Check if user is authorized: original developer, admin, or assigned developer via AuthorizationRegistry
        bool isAuthorized = plan.developer == msg.sender || hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
        
        // If not authorized, check AuthorizationRegistry
        if (!isAuthorized) {
            uint256 dAppId = dAppRegistry.getDAppIdByContract(_dAppContract);
            if (dAppId > 0) {
                isAuthorized = authorizationRegistry.isDeveloper(dAppId, msg.sender);
            }
        }
        
        require(isAuthorized, "DAppSubscription: Not authorized");
        require(_monthlyPrice > 0, "DAppSubscription: Monthly price must be greater than 0");
        require(_quarterlyPrice > 0, "DAppSubscription: Quarterly price must be greater than 0");
        require(_yearlyPrice > 0, "DAppSubscription: Yearly price must be greater than 0");

        plan.monthlyPrice = _monthlyPrice;
        plan.quarterlyPrice = _quarterlyPrice;
        plan.yearlyPrice = _yearlyPrice;

        emit SubscriptionPlanUpdated(
            _dAppContract,
            _monthlyPrice,
            _quarterlyPrice,
            _yearlyPrice,
            block.timestamp
        );
    }

    /**
     * @dev Subscribe to a dApp with specified payment frequency
     * @param _dAppContract Address of the dApp contract
     * @param _frequency Payment frequency (Monthly, Quarterly, or Yearly)
     */
    function subscribe(
        address _dAppContract,
        PaymentFrequency _frequency
    ) external payable nonReentrant {
        SubscriptionPlan memory plan = subscriptionPlans[_dAppContract];
        require(plan.dAppContract != address(0), "DAppSubscription: Plan does not exist");
        require(plan.isActive, "DAppSubscription: Plan is not active");

        uint256 price;
        uint256 period;

        if (_frequency == PaymentFrequency.Monthly) {
            price = plan.monthlyPrice;
            period = 30 days;
        } else if (_frequency == PaymentFrequency.Quarterly) {
            price = plan.quarterlyPrice;
            period = 90 days;
        } else if (_frequency == PaymentFrequency.Yearly) {
            price = plan.yearlyPrice;
            period = 365 days;
        } else {
            revert("DAppSubscription: Invalid frequency");
        }

        require(msg.value >= price, "DAppSubscription: Insufficient payment");

        uint256 kasparexFee = (msg.value * kasparexFeePercentage) / 10000;
        uint256 developerAmount = msg.value - kasparexFee;

        // Send Kasparex fee to treasury
        if (kasparexFee > 0) {
            treasury.collectFee{value: kasparexFee}();
        }

        // Send developer amount (net after fee)
        if (developerAmount > 0) {
            (bool success, ) = payable(plan.developer).call{value: developerAmount}("");
            require(success, "DAppSubscription: Developer transfer failed");
        }

        // Calculate new expiry timestamp
        UserSubscription storage userSub = userSubscriptions[msg.sender][_dAppContract];
        uint256 currentExpiry = userSub.expiryTimestamp;
        uint256 newExpiry;

        if (currentExpiry > block.timestamp) {
            // Renew existing active subscription
            newExpiry = currentExpiry + period;
            emit SubscriptionRenewed(
                msg.sender,
                _dAppContract,
                _frequency,
                msg.value,
                newExpiry,
                block.timestamp
            );
        } else {
            // New subscription
            newExpiry = block.timestamp + period;
            emit SubscriptionPurchased(
                msg.sender,
                _dAppContract,
                _frequency,
                msg.value,
                newExpiry,
                block.timestamp
            );

            // Add to subscribers list if not already there
            bool exists = false;
            for (uint256 i = 0; i < dAppSubscribers[_dAppContract].length; i++) {
                if (dAppSubscribers[_dAppContract][i] == msg.sender) {
                    exists = true;
                    break;
                }
            }
            if (!exists) {
                dAppSubscribers[_dAppContract].push(msg.sender);
            }
        }

        userSub.expiryTimestamp = newExpiry;
        userSub.frequency = _frequency;
        userSub.isActive = true;

        // Refund excess payment
        if (msg.value > price) {
            uint256 refund = msg.value - price;
            (bool success, ) = payable(msg.sender).call{value: refund}("");
            require(success, "DAppSubscription: Refund failed");
        }
    }

    /**
     * @dev Check if a user is subscribed to a specific dApp
     * @param _user User address
     * @param _dAppContract dApp contract address
     * @return bool True if subscribed and active
     */
    function isSubscribed(address _user, address _dAppContract) external view returns (bool) {
        UserSubscription memory sub = userSubscriptions[_user][_dAppContract];
        if (!sub.isActive) return false;
        return block.timestamp <= sub.expiryTimestamp;
    }

    /**
     * @dev Get subscription expiry timestamp for a user and dApp
     * @param _user User address
     * @param _dAppContract dApp contract address
     * @return uint256 Expiry timestamp (0 if not subscribed)
     */
    function getExpiryTimestamp(
        address _user,
        address _dAppContract
    ) external view returns (uint256) {
        return userSubscriptions[_user][_dAppContract].expiryTimestamp;
    }

    /**
     * @dev Get subscription plan for a dApp
     * @param _dAppContract dApp contract address
     * @return SubscriptionPlan The subscription plan
     */
    function getSubscriptionPlan(
        address _dAppContract
    ) external view returns (SubscriptionPlan memory) {
        return subscriptionPlans[_dAppContract];
    }

    /**
     * @dev Get all subscribers for a dApp
     * @param _dAppContract dApp contract address
     * @return address[] Array of subscriber addresses
     */
    function getSubscribers(address _dAppContract) external view returns (address[] memory) {
        return dAppSubscribers[_dAppContract];
    }

    /**
     * @dev Update Kasparex fee percentage (only owner)
     * @param _newPercentage New fee percentage in basis points
     */
    function setKasparexFeePercentage(uint256 _newPercentage) external onlyOwner {
        require(_newPercentage <= 10000, "DAppSubscription: Fee cannot exceed 100%");
        uint256 oldPercentage = kasparexFeePercentage;
        kasparexFeePercentage = _newPercentage;
        emit KasparexFeePercentageUpdated(oldPercentage, _newPercentage);
    }

    /**
     * @dev Update Treasury contract address (only owner)
     * @param _treasury New Treasury contract address
     */
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "DAppSubscription: Invalid treasury address");
        address oldTreasury = address(treasury);
        treasury = Treasury(_treasury);
        emit TreasuryUpdated(oldTreasury, _treasury);
    }

    /**
     * @dev Update AuthorizationRegistry contract address (only owner)
     * @param _authorizationRegistry New AuthorizationRegistry contract address
     */
    function setAuthorizationRegistry(address _authorizationRegistry) external onlyOwner {
        require(_authorizationRegistry != address(0), "DAppSubscription: Invalid authorization registry address");
        authorizationRegistry = AuthorizationRegistry(_authorizationRegistry);
    }

    /**
     * @dev Update DAppRegistry contract address (only owner)
     * @param _dAppRegistry New DAppRegistry contract address
     */
    function setDAppRegistry(address _dAppRegistry) external onlyOwner {
        require(_dAppRegistry != address(0), "DAppSubscription: Invalid dApp registry address");
        dAppRegistry = DAppRegistry(_dAppRegistry);
    }

    /**
     * @dev Deactivate a subscription plan (developer or admin only)
     * @param _dAppContract dApp contract address
     */
    function deactivatePlan(address _dAppContract) external {
        SubscriptionPlan storage plan = subscriptionPlans[_dAppContract];
        
        // Check if user is authorized: original developer, admin, or assigned developer via AuthorizationRegistry
        bool isAuthorized = plan.developer == msg.sender || hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
        
        // If not authorized, check AuthorizationRegistry
        if (!isAuthorized) {
            uint256 dAppId = dAppRegistry.getDAppIdByContract(_dAppContract);
            if (dAppId > 0) {
                isAuthorized = authorizationRegistry.isDeveloper(dAppId, msg.sender);
            }
        }
        
        require(isAuthorized, "DAppSubscription: Not authorized");
        plan.isActive = false;
    }

    /**
     * @dev Deactivate a user subscription (admin only)
     * @param _user User address
     * @param _dAppContract dApp contract address
     */
    function deactivateUserSubscription(
        address _user,
        address _dAppContract
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        UserSubscription storage sub = userSubscriptions[_user][_dAppContract];
        if (sub.isActive) {
            sub.isActive = false;
            emit SubscriptionExpired(_user, _dAppContract, block.timestamp);
        }
    }

    /**
     * @dev Grant developer role to an address
     * @param _developer Address to grant role to
     */
    function grantDeveloperRole(address _developer) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(DEVELOPER_ROLE, _developer);
    }

    /**
     * @dev Revoke developer role from an address
     * @param _developer Address to revoke role from
     */
    function revokeDeveloperRole(address _developer) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(DEVELOPER_ROLE, _developer);
    }
}

