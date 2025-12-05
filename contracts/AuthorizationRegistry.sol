// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title AuthorizationRegistry
 * @dev Registry for managing developer assignments to dApps
 * @notice Admins can assign wallet addresses as Developers for specific dApps
 */
contract AuthorizationRegistry is AccessControl {
    // Role for developers (extensible for future roles)
    bytes32 public constant DEVELOPER_ROLE = keccak256("DEVELOPER_ROLE");

    // Mapping: dAppId => wallet => hasDeveloperRole
    mapping(uint256 => mapping(address => bool)) public dAppDevelopers;

    // Mapping: dAppId => array of developer addresses
    mapping(uint256 => address[]) public dAppDeveloperList;

    // Mapping: wallet => array of dAppIds where wallet is developer
    mapping(address => uint256[]) public developerDApps;

    // Events
    event DeveloperAssigned(
        uint256 indexed dAppId,
        address indexed developer,
        address indexed assignedBy,
        uint256 timestamp
    );
    event DeveloperRevoked(
        uint256 indexed dAppId,
        address indexed developer,
        address indexed revokedBy,
        uint256 timestamp
    );

    /**
     * @dev Constructor sets up default admin role
     */
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Internal function to assign a developer role to a wallet for a specific dApp
     * @param _dAppId ID of the dApp
     * @param _developer Address of the developer to assign
     */
    function _assignDeveloper(
        uint256 _dAppId,
        address _developer
    ) internal {
        require(_dAppId > 0, "AuthorizationRegistry: Invalid dApp ID");
        require(_developer != address(0), "AuthorizationRegistry: Invalid developer address");
        require(
            !dAppDevelopers[_dAppId][_developer],
            "AuthorizationRegistry: Developer already assigned"
        );

        // Add to mapping
        dAppDevelopers[_dAppId][_developer] = true;

        // Add to dApp's developer list if not already present
        bool exists = false;
        for (uint256 i = 0; i < dAppDeveloperList[_dAppId].length; i++) {
            if (dAppDeveloperList[_dAppId][i] == _developer) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            dAppDeveloperList[_dAppId].push(_developer);
        }

        // Add to developer's dApp list if not already present
        exists = false;
        for (uint256 i = 0; i < developerDApps[_developer].length; i++) {
            if (developerDApps[_developer][i] == _dAppId) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            developerDApps[_developer].push(_dAppId);
        }

        emit DeveloperAssigned(_dAppId, _developer, msg.sender, block.timestamp);
    }

    /**
     * @dev Assign a developer role to a wallet for a specific dApp
     * @param _dAppId ID of the dApp
     * @param _developer Address of the developer to assign
     */
    function assignDeveloper(
        uint256 _dAppId,
        address _developer
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _assignDeveloper(_dAppId, _developer);
    }

    /**
     * @dev Internal function to revoke developer role from a wallet for a specific dApp
     * @param _dAppId ID of the dApp
     * @param _developer Address of the developer to revoke
     */
    function _revokeDeveloper(
        uint256 _dAppId,
        address _developer
    ) internal {
        require(_dAppId > 0, "AuthorizationRegistry: Invalid dApp ID");
        require(_developer != address(0), "AuthorizationRegistry: Invalid developer address");
        require(
            dAppDevelopers[_dAppId][_developer],
            "AuthorizationRegistry: Developer not assigned"
        );

        // Remove from mapping
        dAppDevelopers[_dAppId][_developer] = false;

        // Remove from dApp's developer list
        address[] storage devList = dAppDeveloperList[_dAppId];
        for (uint256 i = 0; i < devList.length; i++) {
            if (devList[i] == _developer) {
                devList[i] = devList[devList.length - 1];
                devList.pop();
                break;
            }
        }

        // Remove from developer's dApp list
        uint256[] storage dAppList = developerDApps[_developer];
        for (uint256 i = 0; i < dAppList.length; i++) {
            if (dAppList[i] == _dAppId) {
                dAppList[i] = dAppList[dAppList.length - 1];
                dAppList.pop();
                break;
            }
        }

        emit DeveloperRevoked(_dAppId, _developer, msg.sender, block.timestamp);
    }

    /**
     * @dev Revoke developer role from a wallet for a specific dApp
     * @param _dAppId ID of the dApp
     * @param _developer Address of the developer to revoke
     */
    function revokeDeveloper(
        uint256 _dAppId,
        address _developer
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeDeveloper(_dAppId, _developer);
    }

    /**
     * @dev Check if a wallet has developer role for a specific dApp
     * @param _dAppId ID of the dApp
     * @param _developer Address of the developer to check
     * @return bool True if developer is assigned
     */
    function isDeveloper(
        uint256 _dAppId,
        address _developer
    ) external view returns (bool) {
        return dAppDevelopers[_dAppId][_developer];
    }

    /**
     * @dev Get all developers for a specific dApp
     * @param _dAppId ID of the dApp
     * @return address[] Array of developer addresses
     */
    function getDAppDevelopers(
        uint256 _dAppId
    ) external view returns (address[] memory) {
        return dAppDeveloperList[_dAppId];
    }

    /**
     * @dev Get all dApp IDs where a wallet is assigned as developer
     * @param _developer Address of the developer
     * @return uint256[] Array of dApp IDs
     */
    function getDeveloperDApps(
        address _developer
    ) external view returns (uint256[] memory) {
        return developerDApps[_developer];
    }

    /**
     * @dev Batch assign developers to a dApp
     * @param _dAppId ID of the dApp
     * @param _developers Array of developer addresses to assign
     */
    function batchAssignDevelopers(
        uint256 _dAppId,
        address[] calldata _developers
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_dAppId > 0, "AuthorizationRegistry: Invalid dApp ID");
        for (uint256 i = 0; i < _developers.length; i++) {
            if (_developers[i] != address(0) && !dAppDevelopers[_dAppId][_developers[i]]) {
                _assignDeveloper(_dAppId, _developers[i]);
            }
        }
    }

    /**
     * @dev Batch revoke developers from a dApp
     * @param _dAppId ID of the dApp
     * @param _developers Array of developer addresses to revoke
     */
    function batchRevokeDevelopers(
        uint256 _dAppId,
        address[] calldata _developers
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_dAppId > 0, "AuthorizationRegistry: Invalid dApp ID");
        for (uint256 i = 0; i < _developers.length; i++) {
            if (_developers[i] != address(0) && dAppDevelopers[_dAppId][_developers[i]]) {
                _revokeDeveloper(_dAppId, _developers[i]);
            }
        }
    }
}

