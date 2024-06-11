// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ===============================Owned================================
// ====================================================================

/// @title Owned
/// @notice The Owned contract has an owner address, and provides basic access control.
contract Owned {
    error InvalidOwnershipAcceptance();
    error OwnerCannotBeZeroAddress();
    error OnlyOwner();

    address public owner;
    address public nominatedOwner;

    constructor(address _owner) {
        if (_owner == address(0)) revert OwnerCannotBeZeroAddress();
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external {
        _onlyOwner();
        if (_owner == address(0)) revert OwnerCannotBeZeroAddress();
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        if (msg.sender != nominatedOwner) revert InvalidOwnershipAcceptance();
        address oldOwner = owner;
        owner = nominatedOwner;
        nominatedOwner = address(0);
        emit OwnerChanged(oldOwner, owner);
    }

    function _onlyOwner() internal view {
        if (msg.sender != owner) revert OnlyOwner();
    }

    event OwnerNominated(address indexed nominatedOwner);
    event OwnerChanged(address indexed previousOwner, address indexed newOwner);
}
