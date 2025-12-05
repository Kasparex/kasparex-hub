// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Treasury.sol";

/**
 * @title FeeCollector
 * @dev Interface contract for dApps to send fees to Treasury
 * @notice Provides a simple interface for collecting fees from dApp transactions
 */
contract FeeCollector is Ownable {
    // Treasury contract address
    Treasury public treasury;

    // Events
    event FeeForwarded(address indexed from, uint256 amount, uint256 timestamp);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);

    /**
     * @dev Constructor sets the Treasury contract address
     * @param _treasury Address of the Treasury contract
     */
    constructor(address _treasury) Ownable(msg.sender) {
        require(_treasury != address(0), "FeeCollector: Invalid treasury address");
        treasury = Treasury(_treasury);
    }

    /**
     * @dev Forward fees to Treasury
     * @notice This function receives fees and forwards them to the Treasury contract
     */
    function forwardFee() external payable {
        require(msg.value > 0, "FeeCollector: Fee must be greater than 0");
        treasury.collectFee{value: msg.value}();
        emit FeeForwarded(msg.sender, msg.value, block.timestamp);
    }

    /**
     * @dev Update Treasury contract address
     * @param _treasury New Treasury contract address
     */
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "FeeCollector: Invalid treasury address");
        address oldTreasury = address(treasury);
        treasury = Treasury(_treasury);
        emit TreasuryUpdated(oldTreasury, _treasury);
    }
}


