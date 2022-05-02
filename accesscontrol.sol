// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;


// Contract to restrict the function call to specific users of that role
contract AccessControl {
    // Roll names can be variable in length, so by taking hash of them we are converting hthem all to bytes32, this way we can save gas.
    // roll => account => bool
    mapping(bytes32 => mapping(address => bool)) public roles;

    bytes32 private constant ADMIN = keccak256(abi.encodePacked("ADMIN"));
    bytes32 private constant USER = keccak256(abi.encodePacked("USER"));

    constructor () {
        _grantRole(ADMIN, msg.sender);
    }
    event GrantRole(bytes32 indexed _role, address indexed _account);
    event RevokeRole(bytes32 indexed _role, address indexed _account);

    function _grantRole(bytes32 _role, address _account) internal {
        roles[_role][_account] = true;
    }

    modifier onlyAllowed(bytes32 _role) {
        require(roles[_role][msg.sender], "Not authorise");
        _;
    }

    function grantRole(bytes32 _role, address _account) external onlyAllowed(ADMIN) {
        _grantRole(_role, _account);
        emit GrantRole(_role, _account);
    }

    function revokeRole(bytes32 _role, address _account) external onlyAllowed(ADMIN) {
        roles[_role][_account] = false;
        emit RevokeRole(_role, _account);
    }

}