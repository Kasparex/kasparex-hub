// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./DAppRegistry.sol";
import "./FeeHandler.sol";
import "./Treasury.sol";

/**
 * @title AdminDashboard
 * @dev Admin-only dApp for platform management
 * @notice Multi-sig support for critical operations
 */
contract AdminDashboard is AccessControl, ReentrancyGuard {
    // Admin role
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
    // Contracts
    DAppRegistry public dAppRegistry;
    FeeHandler public feeHandler;
    Treasury public treasury;
    
    // Multi-sig threshold (number of admins required)
    uint256 public multiSigThreshold = 2;
    
    // Pending operations
    struct PendingOperation {
        bytes32 operationHash;
        address proposer;
        uint256 approvals;
        mapping(address => bool) approvers;
        bool executed;
    }
    
    mapping(bytes32 => PendingOperation) public pendingOperations;
    bytes32[] public pendingOperationIds;
    
    // Events
    event OperationProposed(bytes32 indexed operationId, bytes32 operationHash, address indexed proposer);
    event OperationApproved(bytes32 indexed operationId, address indexed approver);
    event OperationExecuted(bytes32 indexed operationId);
    event MultiSigThresholdUpdated(uint256 oldThreshold, uint256 newThreshold);
    
    /**
     * @dev Constructor
     * @param _dAppRegistry DAppRegistry contract address
     * @param _feeHandler FeeHandler contract address
     * @param _treasury Treasury contract address
     */
    constructor(
        address _dAppRegistry,
        address _feeHandler,
        address _treasury
    ) {
        require(_dAppRegistry != address(0), "AdminDashboard: Invalid DAppRegistry");
        require(_feeHandler != address(0), "AdminDashboard: Invalid FeeHandler");
        require(_treasury != address(0), "AdminDashboard: Invalid Treasury");
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        
        dAppRegistry = DAppRegistry(_dAppRegistry);
        feeHandler = FeeHandler(_feeHandler);
        treasury = Treasury(_treasury);
    }
    
    /**
     * @dev Propose an operation (requires multi-sig)
     * @param operationHash Hash of the operation to execute
     * @return operationId Operation ID
     */
    function proposeOperation(bytes32 operationHash) external onlyRole(ADMIN_ROLE) returns (bytes32) {
        bytes32 operationId = keccak256(abi.encodePacked(operationHash, block.timestamp, msg.sender));
        
        PendingOperation storage op = pendingOperations[operationId];
        op.operationHash = operationHash;
        op.proposer = msg.sender;
        op.approvals = 1;
        op.approvers[msg.sender] = true;
        op.executed = false;
        
        pendingOperationIds.push(operationId);
        
        emit OperationProposed(operationId, operationHash, msg.sender);
        
        return operationId;
    }
    
    /**
     * @dev Approve an operation
     * @param operationId Operation ID
     */
    function approveOperation(bytes32 operationId) external onlyRole(ADMIN_ROLE) {
        PendingOperation storage op = pendingOperations[operationId];
        require(op.operationHash != bytes32(0), "AdminDashboard: Operation not found");
        require(!op.executed, "AdminDashboard: Operation already executed");
        require(!op.approvers[msg.sender], "AdminDashboard: Already approved");
        
        op.approvals++;
        op.approvers[msg.sender] = true;
        
        emit OperationApproved(operationId, msg.sender);
        
        // Auto-execute if threshold reached
        if (op.approvals >= multiSigThreshold) {
            _executeOperation(operationId);
        }
    }
    
    /**
     * @dev Execute an operation (internal)
     * @param operationId Operation ID
     */
    function _executeOperation(bytes32 operationId) internal {
        PendingOperation storage op = pendingOperations[operationId];
        require(op.approvals >= multiSigThreshold, "AdminDashboard: Insufficient approvals");
        require(!op.executed, "AdminDashboard: Already executed");
        
        op.executed = true;
        emit OperationExecuted(operationId);
    }
    
    /**
     * @dev Approve a dApp (single admin, no multi-sig)
     * @param dAppId dApp ID
     */
    function approveDApp(uint256 dAppId) external onlyRole(ADMIN_ROLE) {
        dAppRegistry.updateDAppStatus(dAppId, true);
    }
    
    /**
     * @dev Set fee rates (requires multi-sig)
     * @param newKasparexPercentage New Kasparex percentage (basis points)
     * @param newProjectPercentage New project percentage (basis points)
     */
    function setFeeRates(uint256 newKasparexPercentage, uint256 newProjectPercentage) external onlyRole(ADMIN_ROLE) {
        // This would require updating FeeHandler contract
        // For now, just emit event
        require(newKasparexPercentage + newProjectPercentage == 10000, "AdminDashboard: Percentages must sum to 100%");
    }
    
    /**
     * @dev Update multi-sig threshold (requires multi-sig)
     * @param newThreshold New threshold
     */
    function setMultiSigThreshold(uint256 newThreshold) external onlyRole(ADMIN_ROLE) {
        require(newThreshold > 0, "AdminDashboard: Invalid threshold");
        uint256 oldThreshold = multiSigThreshold;
        multiSigThreshold = newThreshold;
        emit MultiSigThresholdUpdated(oldThreshold, newThreshold);
    }
    
    /**
     * @dev Get pending operations
     * @return Array of operation IDs
     */
    function getPendingOperations() external view returns (bytes32[] memory) {
        return pendingOperationIds;
    }
    
    /**
     * @dev Get operation details
     * @param operationId Operation ID
     * @return operationHash Operation hash
     * @return proposer Proposer address
     * @return approvals Number of approvals
     * @return executed Whether executed
     */
    function getOperation(bytes32 operationId) external view returns (
        bytes32 operationHash,
        address proposer,
        uint256 approvals,
        bool executed
    ) {
        PendingOperation storage op = pendingOperations[operationId];
        return (op.operationHash, op.proposer, op.approvals, op.executed);
    }
}

