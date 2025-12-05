// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title RewardVault
 * @dev Holds pre-minted GRID and dApp tokens for distribution
 * @notice Manages token reserves for RewardManager
 */
contract RewardVault is Ownable, ReentrancyGuard {
    // RewardManager contract
    address public rewardManager;
    
    // Token balances
    mapping(address => uint256) public tokenBalances; // token -> balance
    
    // Events
    event TokensDeposited(address indexed token, uint256 amount, uint256 timestamp);
    event TokensWithdrawn(address indexed token, address indexed to, uint256 amount, uint256 timestamp);
    event RewardManagerUpdated(address indexed oldManager, address indexed newManager);
    
    /**
     * @dev Constructor
     * @param _rewardManager RewardManager contract address
     */
    constructor(address _rewardManager) Ownable(msg.sender) {
        require(_rewardManager != address(0), "RewardVault: Invalid reward manager");
        rewardManager = _rewardManager;
    }
    
    /**
     * @dev Deposit tokens to vault
     * @param token Token address
     * @param amount Amount to deposit
     */
    function deposit(address token, uint256 amount) external nonReentrant {
        require(token != address(0), "RewardVault: Invalid token");
        require(amount > 0, "RewardVault: Invalid amount");
        
        IERC20 tokenContract = IERC20(token);
        require(
            tokenContract.transferFrom(msg.sender, address(this), amount),
            "RewardVault: Transfer failed"
        );
        
        tokenBalances[token] += amount;
        emit TokensDeposited(token, amount, block.timestamp);
    }
    
    /**
     * @dev Withdraw tokens from vault (only RewardManager)
     * @param token Token address
     * @param to Recipient address
     * @param amount Amount to withdraw
     */
    function withdraw(address token, address to, uint256 amount) external nonReentrant {
        require(msg.sender == rewardManager, "RewardVault: Only RewardManager can withdraw");
        require(token != address(0), "RewardVault: Invalid token");
        require(to != address(0), "RewardVault: Invalid recipient");
        require(amount > 0, "RewardVault: Invalid amount");
        require(tokenBalances[token] >= amount, "RewardVault: Insufficient balance");
        
        tokenBalances[token] -= amount;
        
        IERC20 tokenContract = IERC20(token);
        require(
            tokenContract.transfer(to, amount),
            "RewardVault: Transfer failed"
        );
        
        emit TokensWithdrawn(token, to, amount, block.timestamp);
    }
    
    /**
     * @dev Get token balance
     * @param token Token address
     * @return Balance
     */
    function getBalance(address token) external view returns (uint256) {
        return tokenBalances[token];
    }
    
    /**
     * @dev Update RewardManager (only owner)
     * @param _rewardManager New RewardManager address
     */
    function setRewardManager(address _rewardManager) external onlyOwner {
        require(_rewardManager != address(0), "RewardVault: Invalid reward manager");
        address oldManager = rewardManager;
        rewardManager = _rewardManager;
        emit RewardManagerUpdated(oldManager, _rewardManager);
    }
    
    /**
     * @dev Emergency withdraw (only owner)
     * @param token Token address
     * @param to Recipient address
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(address token, address to, uint256 amount) external onlyOwner nonReentrant {
        require(token != address(0), "RewardVault: Invalid token");
        require(to != address(0), "RewardVault: Invalid recipient");
        
        IERC20 tokenContract = IERC20(token);
        require(
            tokenContract.transfer(to, amount),
            "RewardVault: Transfer failed"
        );
        
        if (tokenBalances[token] >= amount) {
            tokenBalances[token] -= amount;
        }
    }
}

