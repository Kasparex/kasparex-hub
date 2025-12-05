// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./FeeCollector.sol";

/**
 * @title SimplePayment
 * @dev Simple payment dApp with automatic fee collection
 * @notice First dApp demonstrating the fee collection pattern
 */
contract SimplePayment is Ownable, ReentrancyGuard {
    // Fee collector contract
    FeeCollector public feeCollector;

    // Fee percentage (basis points, 10000 = 100%)
    uint256 public feePercentage;

    // Payment events
    event PaymentSent(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 fee,
        uint256 timestamp
    );
    event FeeCollected(uint256 amount, uint256 timestamp);
    event FeeCollectorUpdated(address indexed oldCollector, address indexed newCollector);
    event FeePercentageUpdated(uint256 oldPercentage, uint256 newPercentage);

    /**
     * @dev Constructor sets fee collector and fee percentage
     * @param _feeCollector Address of the FeeCollector contract
     * @param _feePercentage Fee percentage in basis points (e.g., 100 = 1%)
     */
    constructor(address _feeCollector, uint256 _feePercentage) Ownable(msg.sender) {
        require(_feeCollector != address(0), "SimplePayment: Invalid fee collector");
        require(_feePercentage <= 1000, "SimplePayment: Fee cannot exceed 10%");
        feeCollector = FeeCollector(_feeCollector);
        feePercentage = _feePercentage;
    }

    /**
     * @dev Send payment to a recipient with automatic fee deduction
     * @param _recipient Address to receive the payment
     * @notice Automatically deducts fee and sends to treasury
     */
    function sendPayment(address _recipient) external payable nonReentrant {
        require(_recipient != address(0), "SimplePayment: Invalid recipient");
        require(msg.value > 0, "SimplePayment: Amount must be greater than 0");

        uint256 fee = (msg.value * feePercentage) / 10000;
        uint256 paymentAmount = msg.value - fee;

        // Send fee to fee collector (which forwards to treasury)
        if (fee > 0) {
            feeCollector.forwardFee{value: fee}();
            emit FeeCollected(fee, block.timestamp);
        }

        // Send payment to recipient
        (bool success, ) = payable(_recipient).call{value: paymentAmount}("");
        require(success, "SimplePayment: Payment transfer failed");

        emit PaymentSent(msg.sender, _recipient, paymentAmount, fee, block.timestamp);
    }

    /**
     * @dev Update fee collector address
     * @param _feeCollector New fee collector address
     */
    function setFeeCollector(address _feeCollector) external onlyOwner {
        require(_feeCollector != address(0), "SimplePayment: Invalid fee collector");
        address oldCollector = address(feeCollector);
        feeCollector = FeeCollector(_feeCollector);
        emit FeeCollectorUpdated(oldCollector, _feeCollector);
    }

    /**
     * @dev Update fee percentage
     * @param _feePercentage New fee percentage in basis points
     */
    function setFeePercentage(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 1000, "SimplePayment: Fee cannot exceed 10%");
        uint256 oldPercentage = feePercentage;
        feePercentage = _feePercentage;
        emit FeePercentageUpdated(oldPercentage, _feePercentage);
    }

    /**
     * @dev Calculate fee for a given amount
     * @param _amount Amount to calculate fee for
     * @return Fee amount
     */
    function calculateFee(uint256 _amount) external view returns (uint256) {
        return (_amount * feePercentage) / 10000;
    }

    /**
     * @dev Get payment amount after fee deduction
     * @param _amount Total amount
     * @return Payment amount after fee
     */
    function getPaymentAmount(uint256 _amount) external view returns (uint256) {
        uint256 fee = (_amount * feePercentage) / 10000;
        return _amount - fee;
    }
}


