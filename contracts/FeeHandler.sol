// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title FeeHandler
 * @dev Handles KAS fee splitting (60% Kasparex, 40% Project)
 * @notice Receives fees from dApp actions and distributes them
 */
contract FeeHandler is Ownable, ReentrancyGuard {
    // Treasury addresses
    address public kasparexTreasury;
    address public projectTreasury;
    
    // Split percentages (basis points, 10000 = 100%)
    uint256 public constant KASPAREX_PERCENTAGE = 6000; // 60%
    uint256 public constant PROJECT_PERCENTAGE = 4000;  // 40%
    
    // Fee tracking
    uint256 public totalFeesCollected;
    mapping(address => uint256) public projectFees; // Track fees per project
    
    // Events
    event FeeReceived(
        address indexed from,
        address indexed projectTreasury,
        uint256 totalAmount,
        uint256 kasparexAmount,
        uint256 projectAmount,
        uint256 timestamp
    );
    event TreasuryUpdated(
        address indexed oldKasparexTreasury,
        address indexed newKasparexTreasury,
        address oldProjectTreasury,
        address newProjectTreasury
    );
    
    /**
     * @dev Constructor
     * @param _kasparexTreasury Kasparex treasury address
     * @param _projectTreasury Default project treasury address
     */
    constructor(address _kasparexTreasury, address _projectTreasury) Ownable(msg.sender) {
        require(_kasparexTreasury != address(0), "FeeHandler: Invalid Kasparex treasury");
        require(_projectTreasury != address(0), "FeeHandler: Invalid project treasury");
        
        kasparexTreasury = _kasparexTreasury;
        projectTreasury = _projectTreasury;
    }
    
    /**
     * @dev Receive fees and split them
     * @param _projectTreasury Project treasury address (if different from default)
     */
    function collectFee(address _projectTreasury) external payable nonReentrant {
        require(msg.value > 0, "FeeHandler: Fee must be greater than 0");
        
        address projectTreasury_ = _projectTreasury != address(0) 
            ? _projectTreasury 
            : projectTreasury;
        
        // Calculate splits
        uint256 kasparexAmount = (msg.value * KASPAREX_PERCENTAGE) / 10000;
        uint256 projectAmount = msg.value - kasparexAmount; // Remainder to project
        
        totalFeesCollected += msg.value;
        projectFees[projectTreasury_] += projectAmount;
        
        // Transfer to treasuries
        (bool kasparexSuccess, ) = payable(kasparexTreasury).call{value: kasparexAmount}("");
        require(kasparexSuccess, "FeeHandler: Kasparex transfer failed");
        
        (bool projectSuccess, ) = payable(projectTreasury_).call{value: projectAmount}("");
        require(projectSuccess, "FeeHandler: Project transfer failed");
        
        emit FeeReceived(
            msg.sender,
            projectTreasury_,
            msg.value,
            kasparexAmount,
            projectAmount,
            block.timestamp
        );
    }
    
    /**
     * @dev Batch collect fees (gas optimization)
     * @param _projectTreasuries Array of project treasury addresses
     */
    function collectFeesBatch(address[] memory _projectTreasuries) external payable nonReentrant {
        require(msg.value > 0, "FeeHandler: Fee must be greater than 0");
        require(_projectTreasuries.length > 0, "FeeHandler: Empty project treasuries");
        
        uint256 feePerProject = msg.value / _projectTreasuries.length;
        uint256 kasparexAmount = (msg.value * KASPAREX_PERCENTAGE) / 10000;
        uint256 totalProjectAmount = msg.value - kasparexAmount;
        uint256 projectAmountPerTreasury = totalProjectAmount / _projectTreasuries.length;
        
        totalFeesCollected += msg.value;
        
        // Transfer to Kasparex treasury
        (bool kasparexSuccess, ) = payable(kasparexTreasury).call{value: kasparexAmount}("");
        require(kasparexSuccess, "FeeHandler: Kasparex transfer failed");
        
        // Transfer to each project treasury
        for (uint256 i = 0; i < _projectTreasuries.length; i++) {
            if (_projectTreasuries[i] != address(0)) {
                projectFees[_projectTreasuries[i]] += projectAmountPerTreasury;
                (bool success, ) = payable(_projectTreasuries[i]).call{value: projectAmountPerTreasury}("");
                require(success, "FeeHandler: Project transfer failed");
            }
        }
    }
    
    /**
     * @dev Update treasury addresses (only owner)
     * @param _kasparexTreasury New Kasparex treasury address
     * @param _projectTreasury New default project treasury address
     */
    function setTreasuries(address _kasparexTreasury, address _projectTreasury) external onlyOwner {
        require(_kasparexTreasury != address(0), "FeeHandler: Invalid Kasparex treasury");
        require(_projectTreasury != address(0), "FeeHandler: Invalid project treasury");
        
        address oldKasparex = kasparexTreasury;
        address oldProject = projectTreasury;
        
        kasparexTreasury = _kasparexTreasury;
        projectTreasury = _projectTreasury;
        
        emit TreasuryUpdated(oldKasparex, _kasparexTreasury, oldProject, _projectTreasury);
    }
    
    /**
     * @dev Get total fees collected for a project
     * @param _projectTreasury Project treasury address
     * @return Total fees collected
     */
    function getProjectFees(address _projectTreasury) external view returns (uint256) {
        return projectFees[_projectTreasury];
    }
}

