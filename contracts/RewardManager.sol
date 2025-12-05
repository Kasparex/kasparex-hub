// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./DAppToken.sol";
import "./GRIDToken.sol";
import "./ProofOfUtility.sol";

/**
 * @title RewardManager
 * @dev Distributes GRID or dApp tokens based on Proof-of-Utility
 * @notice Mints rewards based on usage events
 */
contract RewardManager is Ownable, ReentrancyGuard {
    // ProofOfUtility contract
    ProofOfUtility public proofOfUtility;
    
    // GRID token
    GRIDToken public gridToken;
    
    // Reward rates per dApp (basis points, e.g., 100 = 1% of action value)
    mapping(address => uint256) public rewardRates; // dApp contract -> reward rate
    
    // Reward type per dApp (GRID or dApp token)
    mapping(address => bool) public useGRID; // true = GRID, false = dApp token
    
    // dApp token contracts
    mapping(address => DAppToken) public dAppTokens; // dApp contract -> token contract
    
    // Events
    event RewardDistributed(
        address indexed user,
        address indexed dAppContract,
        address indexed token,
        uint256 amount,
        string rewardType
    );
    event RewardRateUpdated(address indexed dAppContract, uint256 oldRate, uint256 newRate);
    event RewardTypeUpdated(address indexed dAppContract, bool useGRID);
    event DAppTokenUpdated(address indexed dAppContract, address indexed tokenContract);
    
    /**
     * @dev Constructor
     * @param _proofOfUtility ProofOfUtility contract address
     * @param _gridToken GRID token address
     */
    constructor(address _proofOfUtility, address _gridToken) Ownable(msg.sender) {
        require(_proofOfUtility != address(0), "RewardManager: Invalid ProofOfUtility");
        require(_gridToken != address(0), "RewardManager: Invalid GRID token");
        
        proofOfUtility = ProofOfUtility(_proofOfUtility);
        gridToken = GRIDToken(_gridToken);
    }
    
    /**
     * @dev Distribute reward for a usage event
     * @param user User address
     * @param dAppContract dApp contract address
     * @param actionValue Value of the action (for calculating reward)
     */
    function distributeReward(
        address user,
        address dAppContract,
        uint256 actionValue
    ) public nonReentrant {
        require(user != address(0), "RewardManager: Invalid user");
        require(dAppContract != address(0), "RewardManager: Invalid dApp contract");
        require(msg.sender == address(proofOfUtility), "RewardManager: Only ProofOfUtility can call");
        
        uint256 rewardRate = rewardRates[dAppContract];
        if (rewardRate == 0) {
            return; // No reward configured
        }
        
        uint256 rewardAmount = (actionValue * rewardRate) / 10000;
        if (rewardAmount == 0) {
            return; // No reward to distribute
        }
        
        bool useGRID_ = useGRID[dAppContract];
        
        if (useGRID_) {
            // Distribute GRID token
            require(gridToken.balanceOf(address(this)) >= rewardAmount, "RewardManager: Insufficient GRID");
            require(gridToken.transfer(user, rewardAmount), "RewardManager: GRID transfer failed");
            
            emit RewardDistributed(user, dAppContract, address(gridToken), rewardAmount, "GRID");
        } else {
            // Distribute dApp token
            DAppToken dAppToken = dAppTokens[dAppContract];
            require(address(dAppToken) != address(0), "RewardManager: dApp token not set");
            
            // Mint tokens to user
            dAppToken.mint(user, rewardAmount);
            
            emit RewardDistributed(user, dAppContract, address(dAppToken), rewardAmount, "DAppToken");
        }
    }
    
    /**
     * @dev Batch distribute rewards (gas optimization)
     * @param users Array of user addresses
     * @param dAppContracts Array of dApp contract addresses
     * @param actionValues Array of action values
     */
    function distributeRewardsBatch(
        address[] memory users,
        address[] memory dAppContracts,
        uint256[] memory actionValues
    ) external nonReentrant {
        require(
            users.length == dAppContracts.length &&
            dAppContracts.length == actionValues.length,
            "RewardManager: Array length mismatch"
        );
        require(msg.sender == address(proofOfUtility), "RewardManager: Only ProofOfUtility can call");
        
        for (uint256 i = 0; i < users.length; i++) {
            // Inline distributeReward logic for gas efficiency
            address user = users[i];
            address dAppContract = dAppContracts[i];
            uint256 actionValue = actionValues[i];
            
            require(user != address(0), "RewardManager: Invalid user");
            require(dAppContract != address(0), "RewardManager: Invalid dApp contract");
            
            uint256 rewardRate = rewardRates[dAppContract];
            if (rewardRate == 0) {
                continue; // No reward configured
            }
            
            uint256 rewardAmount = (actionValue * rewardRate) / 10000;
            if (rewardAmount == 0) {
                continue; // No reward to distribute
            }
            
            bool useGRID_ = useGRID[dAppContract];
            
            if (useGRID_) {
                // Distribute GRID token
                require(gridToken.balanceOf(address(this)) >= rewardAmount, "RewardManager: Insufficient GRID");
                require(gridToken.transfer(user, rewardAmount), "RewardManager: GRID transfer failed");
                
                emit RewardDistributed(user, dAppContract, address(gridToken), rewardAmount, "GRID");
            } else {
                // Distribute dApp token
                DAppToken dAppToken = dAppTokens[dAppContract];
                require(address(dAppToken) != address(0), "RewardManager: dApp token not set");
                
                // Mint tokens to user
                dAppToken.mint(user, rewardAmount);
                
                emit RewardDistributed(user, dAppContract, address(dAppToken), rewardAmount, "DAppToken");
            }
        }
    }
    
    /**
     * @dev Set reward rate for a dApp (only owner)
     * @param dAppContract dApp contract address
     * @param rate Reward rate in basis points
     */
    function setRewardRate(address dAppContract, uint256 rate) external onlyOwner {
        require(dAppContract != address(0), "RewardManager: Invalid dApp contract");
        require(rate <= 10000, "RewardManager: Rate cannot exceed 100%");
        
        uint256 oldRate = rewardRates[dAppContract];
        rewardRates[dAppContract] = rate;
        
        emit RewardRateUpdated(dAppContract, oldRate, rate);
    }
    
    /**
     * @dev Set reward type for a dApp (only owner)
     * @param dAppContract dApp contract address
     * @param useGRID_ Whether to use GRID (true) or dApp token (false)
     */
    function setRewardType(address dAppContract, bool useGRID_) external onlyOwner {
        require(dAppContract != address(0), "RewardManager: Invalid dApp contract");
        
        useGRID[dAppContract] = useGRID_;
        emit RewardTypeUpdated(dAppContract, useGRID_);
    }
    
    /**
     * @dev Set dApp token contract (only owner)
     * @param dAppContract dApp contract address
     * @param tokenContract dApp token contract address
     */
    function setDAppToken(address dAppContract, address tokenContract) external onlyOwner {
        require(dAppContract != address(0), "RewardManager: Invalid dApp contract");
        require(tokenContract != address(0), "RewardManager: Invalid token contract");
        
        dAppTokens[dAppContract] = DAppToken(tokenContract);
        emit DAppTokenUpdated(dAppContract, tokenContract);
    }
    
    /**
     * @dev Update ProofOfUtility contract (only owner)
     * @param _proofOfUtility New ProofOfUtility contract address
     */
    function setProofOfUtility(address _proofOfUtility) external onlyOwner {
        require(_proofOfUtility != address(0), "RewardManager: Invalid ProofOfUtility");
        proofOfUtility = ProofOfUtility(_proofOfUtility);
    }
}

