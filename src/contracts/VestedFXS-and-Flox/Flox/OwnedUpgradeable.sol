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
// ======================= OwnedUpgradeable ===========================
// ====================================================================

/**
 * @title OwnedUpgradeable
 * @author Frax Finance
 * @notice The OwnedUpgradeable contract has an owner address, and provides basic access control.
 */
contract OwnedUpgradeable {
    /// Emitted when attempting to initialize an already initialized contract.
    error OwnedAlreadyInitialized();
    /// Emitted when attempting to accept ownership when the caller is not the nominated owner.
    error InvalidOwnershipAcceptance();
    /// Emitted when the owner address is set to the zero address.
    error OwnerCannotBeZeroAddress();
    /// Emitted when the caller is not the owner.
    error OnlyOwner();

    /// Address of the owner of the smart contract.
    address public owner;
    /// Address of the nominated owner of the smart contract.
    address public nominatedOwner;
    /// Used to make sure the contract is initialized only once.
    bool private _initialized;

    /**
     * @notice Used to initialize the smart contract.
     * @param _owner The address of the owner
     */
    function __Owned_init(address _owner) public {
        if (_initialized) revert OwnedAlreadyInitialized();
        if (_owner == address(0)) revert OwnerCannotBeZeroAddress();

        _initialized = true;
        owner = _owner;

        emit OwnerChanged(address(0), _owner);
    }

    /**
     * @notice Allows the current owner to nominate a new owner.
     * @dev Reverts if the caller is not the current owner.
     * @dev Reverts if the nominated owner is the zero address.
     * @param _owner The address of the new owner
     */
    function nominateNewOwner(address _owner) external {
        _onlyOwner();

        if (_owner == address(0)) revert OwnerCannotBeZeroAddress();
        nominatedOwner = _owner;

        emit OwnerNominated(_owner);
    }

    /**
     * @notice Allows the current nominated owner to accept the ownership.
     * @dev Reverts if the caller is not the nominated owner.
     */
    function acceptOwnership() external {
        if (msg.sender != nominatedOwner) revert InvalidOwnershipAcceptance();

        address oldOwner = owner;
        owner = nominatedOwner;
        nominatedOwner = address(0);

        emit OwnerChanged(oldOwner, owner);
    }

    /**
     * @notice Restricts access to the function to the owner.
     * @dev Reverts if the caller is not the owner.
     */
    function _onlyOwner() internal view {
        if (msg.sender != owner) revert OnlyOwner();
    }

    /**
     * @notice Emitted when a new owner is nominated.
     * @param nominatedOwner The address of the nominated owner
     */
    event OwnerNominated(address indexed nominatedOwner);
    /**
     * @notice Emitted when the ownership is transferred.
     * @param previousOwner Address of the previous owner
     * @param newOwner Address of the new owner
     */
    event OwnerChanged(address indexed previousOwner, address indexed newOwner);
}
