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
// ======================= Delegation Registry ========================
// ====================================================================

import { OwnedV2 } from "src/contracts/VestedFXS-and-Flox/VestedFXS/OwnedV2.sol";
import { IDelegationRegistryEvents } from "./IDelegationRegistryEvents.sol";

/**
 * @title DelegationRegistry
 * @author Frax Finance
 * @notice The DelegationRegistry contract is used to manage delegations of Frax incentives and points.
 */
contract DelegationRegistry is OwnedV2, IDelegationRegistryEvents {
    mapping(address => bool) public isFraxContributor;
    mapping(address => bool) public selfManagingDelegations;
    mapping(address => bool) public delegationManagementDisabled;
    mapping(address => address) internal delegations;

    /**
     * @notice Used to initialize the smart contract.
     * @dev The initial owner is set as the deployer of the smart contract.
     */
    constructor() OwnedV2(msg.sender) {}

    /**
     * @notice Sets the delegation for the caller.
     * @dev Once the delegation is set for self, the Frax contributors and delegatees can no longer manage the
     *  delegation of that address.
     * @dev This will be reverted if the delegate has disabled delegation management.
     * @param delegatee Address to delegate to
     */
    function setDelegationForSelf(address delegatee) external {
        if (!selfManagingDelegations[msg.sender]) selfManagingDelegations[msg.sender] = true;
        if (delegationManagementDisabled[msg.sender]) revert DelegationManagementDisabled();

        address previousDelegatee = delegations[msg.sender];
        delegations[msg.sender] = delegatee;
        emit DelegationUpdated(msg.sender, previousDelegatee, delegatee);
    }

    /**
     * @notice Removes the delegation for the caller.
     * @dev Once the delegation is removed for self, the Frax contributors and delegatees can no longer manage the
     *  delegation of that address.
     * @dev This will be reverted if the delegate has disabled delegation management.
     * @dev The delegation is removed by setting the delegatee to the zero address.
     */
    function removeDelegationForSelf() external {
        if (!selfManagingDelegations[msg.sender]) selfManagingDelegations[msg.sender] = true;
        if (delegationManagementDisabled[msg.sender]) revert DelegationManagementDisabled();

        address delegatee = delegations[msg.sender];
        delete delegations[msg.sender];
        emit DelegationUpdated(msg.sender, delegatee, address(0));
    }

    /**
     * @notice Disables self-managing delegations for the caller.
     * @dev Once the self-managing delegations are disabled for the caller, the Frax contributors and delegatees can
     *  manage the delegations of that address.
     */
    function disableSelfManagingDelegations() external {
        if (!selfManagingDelegations[msg.sender]) revert SelfManagingDelegationsDisabled();
        selfManagingDelegations[msg.sender] = false;
    }

    /**
     * @notice Disables delegation management for the caller.
     * @dev Once the delegation management is disabled for the caller, the Frax contributors and delegatees can no
     *  longer manage the delegations of that address. The delegations can not be managed by the caller either.
     * @dev The operation will be reverted if the delegation management is already disabled for the caller.
     */
    function disableDelegationManagement() external {
        if (delegationManagementDisabled[msg.sender]) revert DelegationManagementDisabled();
        delegationManagementDisabled[msg.sender] = true;
    }

    /**
     * @notice Sets the delegation for a delegator.
     * @dev This can be used by Frax contributors and delegatees to manage the delegations of other addresses until the
     *  delegator sets or removes the delegation for self.
     * @param delegator Address to set the delegation for
     * @param delegatee Address to delegate to
     */
    function setDelegation(address delegator, address delegatee) external {
        if (selfManagingDelegations[delegator]) revert SelfManagingDelegations();
        if (!isFraxContributor[msg.sender] && delegations[delegator] != msg.sender) {
            revert NotFraxContributorOrDelegatee();
        }
        if (delegationManagementDisabled[delegator]) revert DelegationManagementDisabled();

        address previousDelegatee = delegations[delegator];
        delegations[delegator] = delegatee;
        emit DelegationUpdated(delegator, previousDelegatee, delegatee);
    }

    /**
     * @notice Removes the delegation for a delegator.
     * @dev This can be used by Frax contributors and delegatees to remove the delegations of other addresses until the
     *  delegator sets or removes the delegation for self.
     * @dev The delegation is removed by setting the delegatee to the zero address.
     * @param delegator Address to remove the delegation for
     */
    function removeDelegation(address delegator) external {
        if (selfManagingDelegations[delegator]) revert SelfManagingDelegations();
        if (!isFraxContributor[msg.sender] && delegations[delegator] != msg.sender) {
            revert NotFraxContributorOrDelegatee();
        }
        if (delegationManagementDisabled[delegator]) revert DelegationManagementDisabled();

        address delegatee = delegations[delegator];
        delete delegations[delegator];
        emit DelegationUpdated(delegator, delegatee, address(0));
    }

    /**
     * @notice Sets delegations for multiple delegators as Frax contributor.
     * @dev This can be used by Frax contributors to manage the delegations of multiple addresses until they set or
     *  remove delegations for self.
     * @dev The `delegators` and `delegatees` arrays must be the same length.
     * @dev If any of the `delegators` are self-managing, the operation will be reverted.
     * @param delegators An array of addresses to set the delegations for
     * @param delegatees An array of addresses to delegate to
     */
    function bulkSetDelegationsAsFraxContributor(address[] memory delegators, address[] memory delegatees) external {
        _onlyFraxContributor();
        if (delegators.length != delegatees.length) revert ArrayLengthMismatch();

        address previousDelegatee;
        for (uint256 i; i < delegators.length; ) {
            if (selfManagingDelegations[delegators[i]]) revert SelfManagingDelegations();
            if (delegationManagementDisabled[delegators[i]]) revert DelegationManagementDisabled();

            previousDelegatee = delegations[delegators[i]];
            delegations[delegators[i]] = delegatees[i];
            emit DelegationUpdated(delegators[i], previousDelegatee, delegatees[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Removes delegations for multiple delegators as Frax contributor.
     * @dev This can be used by Frax contributors to remove the delegations of multiple addresses until they set or
     *  remove the delegations for self.
     * @dev If any of the `delegators` are self-managing, the operation will be reverted.
     * @param delegators An array of addresses to remove the delegations for
     */
    function bulkRemoveDelegationsAsFraxContributor(address[] memory delegators) external {
        _onlyFraxContributor();

        address delegatee;
        for (uint256 i; i < delegators.length; ) {
            if (selfManagingDelegations[delegators[i]]) revert SelfManagingDelegations();
            if (delegationManagementDisabled[delegators[i]]) revert DelegationManagementDisabled();

            delegatee = delegations[delegators[i]];
            delete delegations[delegators[i]];
            emit DelegationUpdated(delegators[i], delegatee, address(0));

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Sets delegations for multiple delegators as delegatee.
     * @dev This can be used by delegatee to manage the delegations of multiple addresses until they set or remove
     *  delegations for self.
     * @dev The `delegators` and `delegatees` arrays must be the same length.
     * @dev If any of the `delegators` are self-managing, the operation will be reverted.
     * @param delegators An array of addresses to set the delegations for
     * @param delegatees An array of addresses to delegate to
     */
    function bulkSetDelegationsAsDelegatee(address[] memory delegators, address[] memory delegatees) external {
        if (delegators.length != delegatees.length) revert ArrayLengthMismatch();

        address previousDelegatee;
        for (uint256 i; i < delegators.length; ) {
            if (selfManagingDelegations[delegators[i]]) revert SelfManagingDelegations();
            if (msg.sender != delegations[delegators[i]]) revert NotDelegatee();
            if (delegationManagementDisabled[delegators[i]]) revert DelegationManagementDisabled();

            previousDelegatee = delegations[delegators[i]];
            delegations[delegators[i]] = delegatees[i];
            emit DelegationUpdated(delegators[i], previousDelegatee, delegatees[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Removes delegations for multiple delegators as delegatee.
     * @dev This can be used by delegatee to remove the delegations of multiple addresses until they set or remove the
     *  delegations for self.
     * @dev If any of the `delegators` are self-managing, the operation will be reverted.
     * @param delegators An array of addresses to remove the delegations for
     */
    function bulkRemoveDelegationsAsDelegatee(address[] memory delegators) external {
        address delegatee;
        for (uint256 i; i < delegators.length; ) {
            if (selfManagingDelegations[delegators[i]]) revert SelfManagingDelegations();
            if (msg.sender != delegations[delegators[i]]) revert NotDelegatee();
            if (delegationManagementDisabled[delegators[i]]) revert DelegationManagementDisabled();

            delegatee = delegations[delegators[i]];
            delete delegations[delegators[i]];
            emit DelegationUpdated(delegators[i], delegatee, address(0));

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Adds an address as a Frax contributor.
     * @dev This can only be called by the owner of the smart contract.
     * @dev The operation will be reverted if the address is already a Frax contributor.
     * @param contributor Address to add as a Frax contributor
     */
    function addFraxContributor(address contributor) external {
        _onlyOwner();

        if (isFraxContributor[contributor]) revert AlreadyFraxContributor();

        isFraxContributor[contributor] = true;
        emit FraxContributorAdded(contributor);
    }

    /**
     * @notice Removes an address as a Frax contributor.
     * @dev This can only be called by the owner of the smart contract.
     * @dev The operation will be reverted if the address is not a Frax contributor.
     * @param contributor Address to remove as a Frax contributor
     */
    function removeFraxContributor(address contributor) external {
        _onlyOwner();

        if (!isFraxContributor[contributor]) revert NotFraxContributor();

        isFraxContributor[contributor] = false;
        emit FraxContributorRemoved(contributor);
    }

    /**
     * @notice Re-enables delegation management for an address.
     * @dev This can only be called by a Frax contributor.
     * @dev The operation will be reverted if the delegation management is already enabled for the address.
     * @dev This function is intended to be called in the occasion that the delegation management was disabled by
     *  mistake or if the delegatee address was compromised.
     * @dev If you require to re-enable the delegation management for an address, please contact the Frax team.
     * @param delegator Address to re-enable the delegation management for
     */
    function reenableDelegationManagement(address delegator) external {
        _onlyFraxContributor();

        if (!delegationManagementDisabled[delegator]) revert DelegationManagementEnabled();

        delegationManagementDisabled[delegator] = false;
    }

    /**
     * @notice Gets the delegation for a delegator.
     * @dev If the delegation is not set for the delegator, the delegator is the delegatee.
     * @param delegator Address to get the delegation for
     * @return Address that the delegator is delegating to
     */
    function delegationsOf(address delegator) external view returns (address) {
        address delegatee;

        delegatee = delegations[delegator] == address(0) ? delegator : delegations[delegator];

        return delegatee;
    }

    /**
     * @notice Gets the delegations for multiple delegators.
     * @dev If the delegation is not set for a delegator, the delegator is the delegatee.
     * @param delegators An array of addresses to get the delegations for
     * @return An array of addresses that the delegators are delegating to
     */
    function bulkDelegationsOf(address[] memory delegators) external view returns (address[] memory) {
        address[] memory delegatees = new address[](delegators.length);

        for (uint256 i; i < delegators.length; ) {
            delegatees[i] = delegations[delegators[i]] == address(0) ? delegators[i] : delegations[delegators[i]];

            unchecked {
                ++i;
            }
        }

        return delegatees;
    }

    /**
     * @notice Checks if the msg sender is a Frax contributor.
     * @dev It the msg.sender is not a Frax contributor, the operation will be reverted.
     */
    function _onlyFraxContributor() internal view {
        if (!isFraxContributor[msg.sender]) revert NotFraxContributor();
    }

    /// @notice The address is already a Frax contributor
    error AlreadyFraxContributor();

    /// @notice The array lengths are mismatched
    error ArrayLengthMismatch();

    /// @notice The delegation management is already disabled
    error DelegationManagementDisabled();

    /// @notice The delegation management is already enabled
    error DelegationManagementEnabled();

    /// @notice Only the delegatee is allowed to perform this action
    error NotDelegatee();

    /// @notice Only a Frax contributor is allowed to perform this action
    error NotFraxContributor();

    /// @notice Only a Frax contributor or delegatee is allowed to perform this action
    error NotFraxContributorOrDelegatee();

    /// @notice The delegator is managing their own delegations and is the only address allowed to perform this action
    error SelfManagingDelegations();

    /// @notice The delegator is not managing their own delegations
    error SelfManagingDelegationsDisabled();
}
