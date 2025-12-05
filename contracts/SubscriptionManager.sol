// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./PlatformSubscription.sol";
import "./DAppSubscription.sol";

/**
 * @title SubscriptionManager
 * @dev Unified manager for both platform and per-dApp subscriptions
 * @notice Provides a single interface to check subscription status across both systems
 */
contract SubscriptionManager is Ownable {
    // Platform subscription contract
    PlatformSubscription public platformSubscription;

    // Per-dApp subscription contract
    DAppSubscription public dAppSubscription;

    // Events
    event PlatformSubscriptionUpdated(
        address indexed oldContract,
        address indexed newContract
    );
    event DAppSubscriptionUpdated(
        address indexed oldContract,
        address indexed newContract
    );

    /**
     * @dev Constructor sets up subscription contracts
     * @param _platformSubscription Address of PlatformSubscription contract
     * @param _dAppSubscription Address of DAppSubscription contract
     */
    constructor(
        address _platformSubscription,
        address _dAppSubscription
    ) Ownable(msg.sender) {
        require(
            _platformSubscription != address(0),
            "SubscriptionManager: Invalid platform subscription address"
        );
        require(
            _dAppSubscription != address(0),
            "SubscriptionManager: Invalid dApp subscription address"
        );

        platformSubscription = PlatformSubscription(_platformSubscription);
        dAppSubscription = DAppSubscription(_dAppSubscription);
    }

    /**
     * @dev Check if a user has access to a dApp
     * @notice Returns true if user has platform subscription OR per-dApp subscription
     * @param _user User address
     * @param _dAppContract dApp contract address (optional, 0x0 for platform-only check)
     * @return bool True if user has access
     */
    function hasAccess(
        address _user,
        address _dAppContract
    ) external view returns (bool) {
        // Check platform subscription first (gives access to all dApps)
        try platformSubscription.isSubscribed(_user) returns (bool platformSubscribed) {
            if (platformSubscribed) {
                return true;
            }
        } catch {
            // If check fails, continue to per-dApp check
        }

        // Check per-dApp subscription if dApp contract is provided
        if (_dAppContract != address(0)) {
            try dAppSubscription.isSubscribed(_user, _dAppContract) returns (
                bool dAppSubscribed
            ) {
                if (dAppSubscribed) {
                    return true;
                }
            } catch {
                // If check fails, return false
            }
        }

        return false;
    }

    /**
     * @dev Check if user has platform subscription
     * @param _user User address
     * @return bool True if has platform subscription
     */
    function hasPlatformSubscription(address _user) external view returns (bool) {
        try platformSubscription.isSubscribed(_user) returns (bool subscribed) {
            return subscribed;
        } catch {
            return false;
        }
    }

    /**
     * @dev Check if user has per-dApp subscription
     * @param _user User address
     * @param _dAppContract dApp contract address
     * @return bool True if has per-dApp subscription
     */
    function hasDAppSubscription(
        address _user,
        address _dAppContract
    ) external view returns (bool) {
        try dAppSubscription.isSubscribed(_user, _dAppContract) returns (
            bool subscribed
        ) {
            return subscribed;
        } catch {
            return false;
        }
    }

    /**
     * @dev Check if user is in grace period for platform subscription
     * @param _user User address
     * @return bool True if in grace period
     */
    function isInPlatformGracePeriod(address _user) external view returns (bool) {
        try platformSubscription.isInGracePeriod(_user) returns (bool inGracePeriod) {
            return inGracePeriod;
        } catch {
            return false;
        }
    }

    /**
     * @dev Get platform subscription expiry timestamp
     * @param _user User address
     * @return uint256 Expiry timestamp (0 if not subscribed)
     */
    function getPlatformExpiry(address _user) external view returns (uint256) {
        try platformSubscription.getExpiryTimestamp(_user) returns (uint256 expiry) {
            return expiry;
        } catch {
            return 0;
        }
    }

    /**
     * @dev Get per-dApp subscription expiry timestamp
     * @param _user User address
     * @param _dAppContract dApp contract address
     * @return uint256 Expiry timestamp (0 if not subscribed)
     */
    function getDAppExpiry(
        address _user,
        address _dAppContract
    ) external view returns (uint256) {
        try dAppSubscription.getExpiryTimestamp(_user, _dAppContract) returns (
            uint256 expiry
        ) {
            return expiry;
        } catch {
            return 0;
        }
    }

    /**
     * @dev Update PlatformSubscription contract address (only owner)
     * @param _platformSubscription New PlatformSubscription contract address
     */
    function setPlatformSubscription(address _platformSubscription) external onlyOwner {
        require(
            _platformSubscription != address(0),
            "SubscriptionManager: Invalid platform subscription address"
        );
        address oldContract = address(platformSubscription);
        platformSubscription = PlatformSubscription(_platformSubscription);
        emit PlatformSubscriptionUpdated(oldContract, _platformSubscription);
    }

    /**
     * @dev Update DAppSubscription contract address (only owner)
     * @param _dAppSubscription New DAppSubscription contract address
     */
    function setDAppSubscription(address _dAppSubscription) external onlyOwner {
        require(
            _dAppSubscription != address(0),
            "SubscriptionManager: Invalid dApp subscription address"
        );
        address oldContract = address(dAppSubscription);
        dAppSubscription = DAppSubscription(_dAppSubscription);
        emit DAppSubscriptionUpdated(oldContract, _dAppSubscription);
    }

    /**
     * @dev Get comprehensive subscription status for a user
     * @param _user User address
     * @param _dAppContract dApp contract address (optional)
     * @return platformSubscribed Whether user has platform subscription
     * @return platformExpiry Platform subscription expiry timestamp
     * @return dAppSubscribed Whether user has per-dApp subscription
     * @return dAppExpiry Per-dApp subscription expiry timestamp
     * @return userHasAccess Whether user has access to the dApp
     */
    function getSubscriptionStatus(
        address _user,
        address _dAppContract
    )
        external
        view
        returns (
            bool platformSubscribed,
            uint256 platformExpiry,
            bool dAppSubscribed,
            uint256 dAppExpiry,
            bool userHasAccess
        )
    {
        // Platform subscription
        try platformSubscription.isSubscribed(_user) returns (bool subscribed) {
            platformSubscribed = subscribed;
        } catch {
            platformSubscribed = false;
        }

        try platformSubscription.getExpiryTimestamp(_user) returns (uint256 expiry) {
            platformExpiry = expiry;
        } catch {
            platformExpiry = 0;
        }

        // Per-dApp subscription
        if (_dAppContract != address(0)) {
            try dAppSubscription.isSubscribed(_user, _dAppContract) returns (
                bool subscribed
            ) {
                dAppSubscribed = subscribed;
            } catch {
                dAppSubscribed = false;
            }

            try dAppSubscription.getExpiryTimestamp(_user, _dAppContract) returns (
                uint256 expiry
            ) {
                dAppExpiry = expiry;
            } catch {
                dAppExpiry = 0;
            }
        }

        // Overall access
        userHasAccess = platformSubscribed || dAppSubscribed;
    }
}

