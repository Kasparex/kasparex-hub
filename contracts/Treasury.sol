// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title Treasury
 * @dev Treasury contract for collecting fees and managing revenue distribution
 * @notice This contract collects fees from dApps and manages revenue distribution
 */
contract Treasury is Ownable, ReentrancyGuard {
    // Total fees collected
    uint256 public totalFeesCollected;

    // Revenue distribution percentages (basis points, 10000 = 100%)
    uint256 public treasuryPercentage; // Percentage kept in treasury
    uint256 public developerPercentage; // Percentage for developers
    uint256 public builderPercentage; // Percentage for builders

    // Distribution addresses
    address public developerAddress;
    address public builderAddress;

    // Events
    event FeeCollected(address indexed from, uint256 amount, uint256 timestamp);
    event RevenueDistributed(
        uint256 treasuryAmount,
        uint256 developerAmount,
        uint256 builderAmount,
        uint256 timestamp
    );
    event DistributionPercentagesUpdated(
        uint256 treasuryPercentage,
        uint256 developerPercentage,
        uint256 builderPercentage
    );
    event DistributionAddressesUpdated(
        address developerAddress,
        address builderAddress
    );

    /**
     * @dev Constructor sets initial distribution percentages and addresses
     * @param _treasuryPercentage Percentage for treasury (in basis points)
     * @param _developerPercentage Percentage for developers (in basis points)
     * @param _builderPercentage Percentage for builders (in basis points)
     * @param _developerAddress Address to receive developer share
     * @param _builderAddress Address to receive builder share
     */
    constructor(
        uint256 _treasuryPercentage,
        uint256 _developerPercentage,
        uint256 _builderPercentage,
        address _developerAddress,
        address _builderAddress
    ) Ownable(msg.sender) {
        require(
            _treasuryPercentage + _developerPercentage + _builderPercentage == 10000,
            "Treasury: Percentages must sum to 10000"
        );
        require(
            _developerAddress != address(0),
            "Treasury: Invalid developer address"
        );
        require(_builderAddress != address(0), "Treasury: Invalid builder address");

        treasuryPercentage = _treasuryPercentage;
        developerPercentage = _developerPercentage;
        builderPercentage = _builderPercentage;
        developerAddress = _developerAddress;
        builderAddress = _builderAddress;
    }

    /**
     * @dev Collect fees from dApps
     * @notice This function is called by dApps or FeeCollector to send fees
     */
    function collectFee() external payable nonReentrant {
        require(msg.value > 0, "Treasury: Fee must be greater than 0");
        totalFeesCollected += msg.value;
        emit FeeCollected(msg.sender, msg.value, block.timestamp);
    }

    /**
     * @dev Distribute collected revenue according to percentages
     * @notice Owner can call this to distribute accumulated revenue
     */
    function distributeRevenue() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "Treasury: No balance to distribute");

        uint256 treasuryAmount = (balance * treasuryPercentage) / 10000;
        uint256 developerAmount = (balance * developerPercentage) / 10000;
        uint256 builderAmount = balance - treasuryAmount - developerAmount; // Remainder to builders

        // Treasury amount stays in contract (already in balance)
        if (developerAmount > 0) {
            (bool devSuccess, ) = payable(developerAddress).call{
                value: developerAmount
            }("");
            require(devSuccess, "Treasury: Developer transfer failed");
        }

        if (builderAmount > 0) {
            (bool builderSuccess, ) = payable(builderAddress).call{
                value: builderAmount
            }("");
            require(builderSuccess, "Treasury: Builder transfer failed");
        }

        emit RevenueDistributed(
            treasuryAmount,
            developerAmount,
            builderAmount,
            block.timestamp
        );
    }

    /**
     * @dev Update distribution percentages
     * @param _treasuryPercentage New treasury percentage (basis points)
     * @param _developerPercentage New developer percentage (basis points)
     * @param _builderPercentage New builder percentage (basis points)
     */
    function setDistributionPercentages(
        uint256 _treasuryPercentage,
        uint256 _developerPercentage,
        uint256 _builderPercentage
    ) external onlyOwner {
        require(
            _treasuryPercentage + _developerPercentage + _builderPercentage == 10000,
            "Treasury: Percentages must sum to 10000"
        );
        treasuryPercentage = _treasuryPercentage;
        developerPercentage = _developerPercentage;
        builderPercentage = _builderPercentage;
        emit DistributionPercentagesUpdated(
            _treasuryPercentage,
            _developerPercentage,
            _builderPercentage
        );
    }

    /**
     * @dev Update distribution addresses
     * @param _developerAddress New developer address
     * @param _builderAddress New builder address
     */
    function setDistributionAddresses(
        address _developerAddress,
        address _builderAddress
    ) external onlyOwner {
        require(
            _developerAddress != address(0),
            "Treasury: Invalid developer address"
        );
        require(_builderAddress != address(0), "Treasury: Invalid builder address");
        developerAddress = _developerAddress;
        builderAddress = _builderAddress;
        emit DistributionAddressesUpdated(_developerAddress, _builderAddress);
    }

    /**
     * @dev Get current contract balance
     * @return Current balance in wei
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Emergency withdraw function (only owner)
     * @param amount Amount to withdraw
     * @param to Address to withdraw to
     */
    function emergencyWithdraw(uint256 amount, address payable to)
        external
        onlyOwner
        nonReentrant
    {
        require(to != address(0), "Treasury: Invalid address");
        require(amount <= address(this).balance, "Treasury: Insufficient balance");
        (bool success, ) = to.call{value: amount}("");
        require(success, "Treasury: Transfer failed");
    }
}


