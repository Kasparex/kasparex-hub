// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title DAppToken
 * @dev Standardized ERC-20 token for dApps with fixed allocation
 * @notice Allocation: 80% Use-to-mint, 10% Liquidity, 5% Treasury, 3% Dev, 2% Airdrops
 */
contract DAppToken is ERC20, Ownable, ReentrancyGuard {
    // Fixed total supply (e.g., 1M tokens)
    uint256 public immutable MAX_SUPPLY;
    
    // Allocation percentages (basis points, 10000 = 100%)
    uint256 public constant USE_TO_MINT_PERCENTAGE = 8000; // 80%
    uint256 public constant LIQUIDITY_PERCENTAGE = 1000;   // 10%
    uint256 public constant TREASURY_PERCENTAGE = 500;     // 5%
    uint256 public constant DEV_PERCENTAGE = 300;          // 3%
    uint256 public constant AIRDROP_PERCENTAGE = 200;      // 2%
    
    // Allocation addresses
    address public rewardVault;      // 80% - Use-to-mint rewards
    address public liquidityReserve; // 10% - Locked until DEX
    address public treasury;         // 5% - Kasparex + Project
    address public devAddress;       // 3% - Dev/maintenance
    address public airdropAddress;   // 2% - Airdrops & bonuses
    
    // Minting control
    address public minter; // RewardManager or ProofOfUtility contract
    bool public mintingEnabled = true;
    bool public burnEnabled = false;
    
    // Events
    event MinterUpdated(address indexed oldMinter, address indexed newMinter);
    event MintingToggled(bool enabled);
    event BurnToggled(bool enabled);
    event AllocationDistributed(
        address rewardVault,
        address liquidityReserve,
        address treasury,
        address devAddress,
        address airdropAddress
    );
    
    /**
     * @dev Constructor sets up token with fixed supply and allocation
     * @param _name Token name
     * @param _symbol Token symbol
     * @param _maxSupply Maximum supply (e.g., 1_000_000 * 10^18)
     * @param _rewardVault Address for use-to-mint rewards
     * @param _liquidityReserve Address for liquidity reserve
     * @param _treasury Address for treasury
     * @param _devAddress Address for dev/maintenance
     * @param _airdropAddress Address for airdrops
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        address _rewardVault,
        address _liquidityReserve,
        address _treasury,
        address _devAddress,
        address _airdropAddress
    ) ERC20(_name, _symbol) Ownable(msg.sender) {
        require(_maxSupply > 0, "DAppToken: Invalid max supply");
        require(_rewardVault != address(0), "DAppToken: Invalid reward vault");
        require(_liquidityReserve != address(0), "DAppToken: Invalid liquidity reserve");
        require(_treasury != address(0), "DAppToken: Invalid treasury");
        require(_devAddress != address(0), "DAppToken: Invalid dev address");
        require(_airdropAddress != address(0), "DAppToken: Invalid airdrop address");
        
        MAX_SUPPLY = _maxSupply;
        rewardVault = _rewardVault;
        liquidityReserve = _liquidityReserve;
        treasury = _treasury;
        devAddress = _devAddress;
        airdropAddress = _airdropAddress;
        
        // Distribute initial allocation
        _distributeAllocation();
    }
    
    /**
     * @dev Distribute tokens according to allocation percentages
     */
    function _distributeAllocation() internal {
        uint256 useToMint = (MAX_SUPPLY * USE_TO_MINT_PERCENTAGE) / 10000;
        uint256 liquidity = (MAX_SUPPLY * LIQUIDITY_PERCENTAGE) / 10000;
        uint256 treasuryAmount = (MAX_SUPPLY * TREASURY_PERCENTAGE) / 10000;
        uint256 devAmount = (MAX_SUPPLY * DEV_PERCENTAGE) / 10000;
        uint256 airdropAmount = MAX_SUPPLY - useToMint - liquidity - treasuryAmount - devAmount; // Remainder for airdrops
        
        _mint(rewardVault, useToMint);
        _mint(liquidityReserve, liquidity);
        _mint(treasury, treasuryAmount);
        _mint(devAddress, devAmount);
        _mint(airdropAddress, airdropAmount);
        
        emit AllocationDistributed(
            rewardVault,
            liquidityReserve,
            treasury,
            devAddress,
            airdropAddress
        );
    }
    
    /**
     * @dev Mint tokens (only by minter)
     * @param to Address to mint to
     * @param amount Amount to mint
     */
    function mint(address to, uint256 amount) external {
        require(msg.sender == minter, "DAppToken: Only minter can mint");
        require(mintingEnabled, "DAppToken: Minting disabled");
        require(totalSupply() + amount <= MAX_SUPPLY, "DAppToken: Exceeds max supply");
        
        _mint(to, amount);
    }
    
    /**
     * @dev Burn tokens (if enabled)
     * @param amount Amount to burn
     */
    function burn(uint256 amount) external {
        require(burnEnabled, "DAppToken: Burning disabled");
        _burn(msg.sender, amount);
    }
    
    /**
     * @dev Set minter address (only owner)
     * @param _minter New minter address
     */
    function setMinter(address _minter) external onlyOwner {
        require(_minter != address(0), "DAppToken: Invalid minter");
        address oldMinter = minter;
        minter = _minter;
        emit MinterUpdated(oldMinter, _minter);
    }
    
    /**
     * @dev Toggle minting (only owner)
     * @param _enabled Whether minting is enabled
     */
    function setMintingEnabled(bool _enabled) external onlyOwner {
        mintingEnabled = _enabled;
        emit MintingToggled(_enabled);
    }
    
    /**
     * @dev Enable burning after full emission (only owner)
     * @param _enabled Whether burning is enabled
     */
    function setBurnEnabled(bool _enabled) external onlyOwner {
        burnEnabled = _enabled;
        emit BurnToggled(_enabled);
    }
    
    /**
     * @dev Get remaining mintable supply
     */
    function getRemainingSupply() external view returns (uint256) {
        return MAX_SUPPLY - totalSupply();
    }
}

