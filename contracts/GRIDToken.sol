// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title GRIDToken
 * @dev GRID token - Global Reward and Incentive Distribution token
 * @notice Fixed max supply (10B GRID), deflationary (burns on conversion/spend)
 */
contract GRIDToken is ERC20, Ownable, ReentrancyGuard {
    // Fixed max supply: 10B GRID
    uint256 public constant MAX_SUPPLY = 10_000_000_000 * 10**18;
    
    // Reward vault for pre-minted tokens
    address public rewardVault;
    
    // Burn tracking
    uint256 public totalBurned;
    
    // Events
    event TokensBurned(address indexed from, uint256 amount);
    event RewardVaultUpdated(address indexed oldVault, address indexed newVault);
    
    /**
     * @dev Constructor pre-mints all tokens to reward vault
     * @param _rewardVault Address to receive pre-minted tokens
     */
    constructor(address _rewardVault) ERC20("GRID Token", "GRID") Ownable(msg.sender) {
        require(_rewardVault != address(0), "GRIDToken: Invalid reward vault");
        rewardVault = _rewardVault;
        
        // Pre-mint all tokens to reward vault
        _mint(_rewardVault, MAX_SUPPLY);
    }
    
    /**
     * @dev Burn tokens (deflationary mechanism)
     * @param amount Amount to burn
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
        totalBurned += amount;
        emit TokensBurned(msg.sender, amount);
    }
    
    /**
     * @dev Burn tokens from a specific address (for conversions)
     * @param from Address to burn from
     * @param amount Amount to burn
     */
    function burnFrom(address from, uint256 amount) external {
        _spendAllowance(from, msg.sender, amount);
        _burn(from, amount);
        totalBurned += amount;
        emit TokensBurned(from, amount);
    }
    
    /**
     * @dev Update reward vault address (only owner)
     * @param _rewardVault New reward vault address
     */
    function setRewardVault(address _rewardVault) external onlyOwner {
        require(_rewardVault != address(0), "GRIDToken: Invalid reward vault");
        address oldVault = rewardVault;
        rewardVault = _rewardVault;
        emit RewardVaultUpdated(oldVault, _rewardVault);
    }
    
    /**
     * @dev Get circulating supply (total supply - burned)
     */
    function circulatingSupply() external view returns (uint256) {
        return totalSupply() - totalBurned;
    }
    
    /**
     * @dev Get burn percentage of max supply
     */
    function burnPercentage() external view returns (uint256) {
        if (MAX_SUPPLY == 0) return 0;
        return (totalBurned * 10000) / MAX_SUPPLY; // Basis points
    }
}

