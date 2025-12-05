// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title AffiliateManager
 * @dev Tracks referrals and distributes rewards
 * @notice Handles referral tracking via ?ref= parameter in widget embeds
 */
contract AffiliateManager is Ownable, ReentrancyGuard {
    // Referral structure
    struct Referral {
        address affiliate;
        address user;
        address dAppContract;
        uint256 timestamp;
        bool rewarded;
    }
    
    // Track referrals
    mapping(address => Referral[]) public userReferrals; // user -> referrals
    mapping(address => Referral[]) public affiliateReferrals; // affiliate -> referrals
    mapping(address => mapping(address => uint256)) public referralCounts; // affiliate -> dApp -> count
    
    // Referral rewards (basis points, e.g., 500 = 5%)
    uint256 public referralRewardRate = 500; // 5% default
    
    // Rate limiting (max referrals per affiliate per dApp per day)
    uint256 public maxReferralsPerDay = 100;
    mapping(address => mapping(address => mapping(uint256 => uint256))) public dailyReferralCounts; // affiliate -> dApp -> day -> count
    
    // Reward token (GRID or dApp token)
    IERC20 public rewardToken;
    
    // Events
    event ReferralRecorded(
        address indexed affiliate,
        address indexed user,
        address indexed dAppContract,
        uint256 timestamp
    );
    event ReferralRewarded(
        address indexed affiliate,
        address indexed dAppContract,
        uint256 amount,
        uint256 timestamp
    );
    event ReferralRateUpdated(uint256 oldRate, uint256 newRate);
    event RewardTokenUpdated(address indexed oldToken, address indexed newToken);
    
    /**
     * @dev Constructor
     * @param _rewardToken Address of reward token (GRID or dApp token)
     */
    constructor(address _rewardToken) Ownable(msg.sender) {
        require(_rewardToken != address(0), "AffiliateManager: Invalid reward token");
        rewardToken = IERC20(_rewardToken);
    }
    
    /**
     * @dev Record a referral
     * @param affiliate Affiliate address (from ?ref= parameter)
     * @param user User address
     * @param dAppContract dApp contract address
     */
    function recordReferral(
        address affiliate,
        address user,
        address dAppContract
    ) external nonReentrant {
        require(affiliate != address(0), "AffiliateManager: Invalid affiliate");
        require(user != address(0), "AffiliateManager: Invalid user");
        require(dAppContract != address(0), "AffiliateManager: Invalid dApp contract");
        require(affiliate != user, "AffiliateManager: Cannot refer yourself");
        
        // Check rate limiting
        uint256 day = block.timestamp / 86400; // Days since epoch
        dailyReferralCounts[affiliate][dAppContract][day]++;
        require(
            dailyReferralCounts[affiliate][dAppContract][day] <= maxReferralsPerDay,
            "AffiliateManager: Rate limit exceeded"
        );
        
        Referral memory referral = Referral({
            affiliate: affiliate,
            user: user,
            dAppContract: dAppContract,
            timestamp: block.timestamp,
            rewarded: false
        });
        
        userReferrals[user].push(referral);
        affiliateReferrals[affiliate].push(referral);
        referralCounts[affiliate][dAppContract]++;
        
        emit ReferralRecorded(affiliate, user, dAppContract, block.timestamp);
    }
    
    /**
     * @dev Distribute referral reward
     * @param affiliate Affiliate address
     * @param dAppContract dApp contract address
     * @param actionValue Value of the action (for calculating reward)
     */
    function distributeReferralReward(
        address affiliate,
        address dAppContract,
        uint256 actionValue
    ) external nonReentrant {
        require(affiliate != address(0), "AffiliateManager: Invalid affiliate");
        require(dAppContract != address(0), "AffiliateManager: Invalid dApp contract");
        
        uint256 rewardAmount = (actionValue * referralRewardRate) / 10000;
        if (rewardAmount == 0) {
            return;
        }
        
        require(
            rewardToken.balanceOf(address(this)) >= rewardAmount,
            "AffiliateManager: Insufficient reward balance"
        );
        
        require(
            rewardToken.transfer(affiliate, rewardAmount),
            "AffiliateManager: Reward transfer failed"
        );
        
        emit ReferralRewarded(affiliate, dAppContract, rewardAmount, block.timestamp);
    }
    
    /**
     * @dev Get referral count for an affiliate
     * @param affiliate Affiliate address
     * @param dAppContract dApp contract address
     * @return Referral count
     */
    function getReferralCount(address affiliate, address dAppContract) external view returns (uint256) {
        return referralCounts[affiliate][dAppContract];
    }
    
    /**
     * @dev Get user's referrals
     * @param user User address
     * @return Array of referrals
     */
    function getUserReferrals(address user) external view returns (Referral[] memory) {
        return userReferrals[user];
    }
    
    /**
     * @dev Get affiliate's referrals
     * @param affiliate Affiliate address
     * @return Array of referrals
     */
    function getAffiliateReferrals(address affiliate) external view returns (Referral[] memory) {
        return affiliateReferrals[affiliate];
    }
    
    /**
     * @dev Update referral reward rate (only owner)
     * @param _rate New reward rate in basis points
     */
    function setReferralRewardRate(uint256 _rate) external onlyOwner {
        require(_rate <= 10000, "AffiliateManager: Rate cannot exceed 100%");
        uint256 oldRate = referralRewardRate;
        referralRewardRate = _rate;
        emit ReferralRateUpdated(oldRate, _rate);
    }
    
    /**
     * @dev Update reward token (only owner)
     * @param _rewardToken New reward token address
     */
    function setRewardToken(address _rewardToken) external onlyOwner {
        require(_rewardToken != address(0), "AffiliateManager: Invalid reward token");
        address oldToken = address(rewardToken);
        rewardToken = IERC20(_rewardToken);
        emit RewardTokenUpdated(oldToken, _rewardToken);
    }
    
    /**
     * @dev Update max referrals per day (only owner)
     * @param _maxReferrals New maximum referrals per day
     */
    function setMaxReferralsPerDay(uint256 _maxReferrals) external onlyOwner {
        maxReferralsPerDay = _maxReferrals;
    }
}

