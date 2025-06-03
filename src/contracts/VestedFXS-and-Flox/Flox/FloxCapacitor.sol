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
// ======================== Flox Capacitor ============================
// ====================================================================

import { OwnedUpgradeable } from "./OwnedUpgradeable.sol";
import { FraxStaker } from "../FraxStaker/FraxStaker.sol";
import { VeFXSAggregator } from "../VestedFXS/VeFXSAggregator.sol";
import { IERC20 } from "@openzeppelin-4/contracts/token/ERC20/IERC20.sol";
import { IFloxCapacitorErrors } from "./interfaces/IFloxCapacitorErrors.sol";
import { IFloxCapacitorEvents } from "./interfaces/IFloxCapacitorEvents.sol";

/**
 * @title FloxCapacitor
 * @author Frax Finance
 * @notice A smart contract that allows users to stake FRAX and receive FloxCAP tokens.
 * @dev The FloxCAP token is not transferable.
 * @dev The balance of the FloxCAP token represents the amount of FRAX staked by the user.
 */
contract FloxCapacitor is OwnedUpgradeable, IFloxCapacitorErrors, IFloxCapacitorEvents {
    /// Instance of the Frax Staker.
    FraxStaker public fraxStaker;
    /// Instance of the VeFRAX Aggregator.
    VeFXSAggregator public veFRAX;

    /**
     * @notice Used to track the Flox contributors.
     * @dev contributor Address of the Flox contributor.
     * @dev isContributor True if the address is a Flox contributor.
     */
    mapping(address contributor => bool isContributor) public isFloxContributor;
    /**
     * @notice Used to track the Flox Capacitor delegations.
     * @dev user Address of the user delegating their balance.
     * @dev delegatee Address of the user receiving the delegation.
     */
    mapping(address user => address delegatee) public delegations;
    /**
     * @notice Used to track the incoming delegations.
     * @dev delegatee Address of the user receiving the delegation.
     * @dev index Index of the incoming delegation.
     * @dev user Address of the user delegating their balance.
     */
    mapping(address delegatee => mapping(uint256 index => address user)) public incomingDelegations;
    /**
     * @notice Used to track the number of incoming delegations.
     * @dev delegatee Address of the user receiving the delegation.
     * @dev count Number of incoming delegations.
     */
    mapping(address delegatee => uint256 count) public incomingDelegationsCount;

    /// Version of the FloxCAP smart contract.
    string public version;
    /// The divisor used to convert the veFRAX balance to FloxCAP balance.
    uint8 public veFraxDivisor;
    /// Variable to track if the contract is paused.
    bool public isPaused;
    /// Toggle to signal whether the veFRAX balances should be taken into account.
    bool public useVeFRAX;
    /// Used to make sure the contract is initialized only once.
    bool private _initialized;

    /// @dev reserve extra storage for future upgrades
    uint256[50] private __gap;

    /**
     * @notice Used to initialize the smart contract.
     * @dev The initial owner is set as the deployer of the smart contract.
     * @param _fraxStaker Address of the Frax Staker
     * @param _owner Address of the owner of the smart contract
     * @param _veFraxAggregator Address of the VeFRAX Aggregator
     * @param _veFraxDivisor Divisor used to convert the veFRAX balance to FloxCAP balance
     * @param _version Version of the FloxCAP smart contract
     */
    function initialize(
        address _fraxStaker,
        address _owner,
        address _veFraxAggregator,
        uint8 _veFraxDivisor,
        string memory _version
    ) public {
        if (_initialized) revert AlreadyInitialized();

        _initialized = true;
        fraxStaker = FraxStaker(_fraxStaker);
        veFRAX = VeFXSAggregator(_veFraxAggregator);
        veFraxDivisor = _veFraxDivisor;
        version = _version;

        useVeFRAX = true;

        emit VeFRAXDivisorUpdated(0, veFraxDivisor);

        __Owned_init(_owner);
    }

    /**
     * @notice Adds a Flox contributor.
     * @dev Can only be called by the owner.
     * @param _contributor The address of the Flox contributor to add
     */
    function addFloxContributor(address _contributor) external {
        _onlyOwner();
        if (isFloxContributor[_contributor]) revert AlreadyFloxContributor();
        isFloxContributor[_contributor] = true;
        emit FloxContributorAdded(_contributor);
    }

    /**
     * @notice Removes a Flox contributor.
     * @dev Can only be called by the owner.
     * @param _contributor The address of the Flox contributor to remove
     */
    function removeFloxContributor(address _contributor) external {
        _onlyOwner();
        if (!isFloxContributor[_contributor]) revert NotFloxContributor();
        isFloxContributor[_contributor] = false;
        emit FloxContributorRemoved(_contributor);
    }

    /**
     * @notice Stops the operation of the smart contract.
     * @dev Can only be called by a Flox contributor.
     * @dev Can only be called if the contract is operational.
     */
    function stopOperation() external {
        _onlyFloxContributor();
        if (isPaused) revert ContractPaused();
        isPaused = true;
        emit OperationPaused(isPaused, block.timestamp);
    }

    /**
     * @notice Enables the operation of the smart contract.
     * @dev Can only be called by the owner.
     * @dev Can only be called if the contract is paused.
     */
    function restartOperation() external {
        _onlyOwner();
        if (!isPaused) revert ContractOperational();
        isPaused = false;
        emit OperationPaused(isPaused, block.timestamp);
    }

    /**
     * @notice Used to update the divisor used to scale the veFRAX balance.
     * @dev Can only be called by a Flox contributor.
     * @dev The divisor shouldn't be zero.
     * @param _veFraxDivisor The new divisor for veFRAX
     */
    function updateVeFraxDivisor(uint8 _veFraxDivisor) external {
        _onlyFloxContributor();
        if (_veFraxDivisor == 0) revert InvalidVeFRAXDivisor();

        uint8 oldVeFRAXdivisor = veFraxDivisor;
        veFraxDivisor = _veFraxDivisor;

        emit VeFRAXDivisorUpdated(oldVeFRAXdivisor, veFraxDivisor);
    }

    /**
     * @notice Used to enable the use of veFRAX balances to calculate the total user boost.
     * @dev Can only be called by a Flox contributor.
     * @dev The operation will be reverted if the contract is already using veFRAX balances.
     */
    function enableVeFraxUse() external {
        _onlyFloxContributor();

        if (useVeFRAX) revert AlreadyUsingVeFRAX();
        useVeFRAX = true;

        emit VeFraxUseEnabled();
    }

    /**
     * @notice Used to disable the use of veFRAX balances to calculate the total user boost.
     * @dev Can only be called by a Flox contributor.
     * @dev The operation will be reverted if the contract is not using veFRAX balances.
     */
    function disableVeFraxUse() external {
        _onlyFloxContributor();

        if (!useVeFRAX) revert NotUsingVeFRAX();
        useVeFRAX = false;

        emit VeFraxUseDisabled();
    }

    /**
     * @notice Used to retrieve the balance of the FloxCAP boost token.
     * @dev If enabled, the scaled veFRAX balance is added to the FloxCAP balance.
     * @dev The veFRAX balance is scaled by the veFraxDivisor.
     * @dev This sums all of the delegated balaces of the users that delegated to the account.
     * @param account The address to check the balance of
     * @return The balance of the FloxCAP boost token
     */
    function balanceOf(address account) public view returns (uint256) {
        uint256 floxCapBalance = _balanceOf(account);

        if (delegations[account] != address(0)) {
            floxCapBalance = 0;
        }

        if (incomingDelegationsCount[account] > 0) {
            for (uint256 i; i < incomingDelegationsCount[account]; ) {
                address delegator = incomingDelegations[account][i];
                uint256 delegatorBalance = _balanceOf(delegator);
                floxCapBalance += delegatorBalance;

                unchecked {
                    ++i;
                }
            }
        }

        return floxCapBalance;
    }

    /**
     * @notice Used to delegate the caller's balance to the specified delegatee.
     * @dev Can only be called by a Flox contributor.
     * @dev The delegator cannot delegate to themselves.
     * @dev The delegator cannot delegate if they already have an active delegation.
     * @param _delegator The address of the user delegating their balance
     * @param _delegatee The address of the user receiving the delegation
     */
    function delegate(address _delegator, address _delegatee) external {
        _onlyFloxContributor();

        if (_delegator == _delegatee) revert CannotDelegateToSelf();
        if (delegations[_delegator] != address(0)) revert AlreadyDelegated();

        delegations[_delegator] = _delegatee;
        incomingDelegations[_delegatee][incomingDelegationsCount[_delegatee]] = _delegator;
        incomingDelegationsCount[_delegatee] = incomingDelegationsCount[_delegatee] + 1;

        emit DelegationAdded(_delegator, _delegatee);
    }

    /**
     * @notice Used to assing multiple delegations in a single transaction.
     * @dev Can only be called by a Flox contributor.
     * @dev The delegators and delegatees arrays must have the same length.
     * @dev The delegator cannot delegate to themselves.
     * @dev The delegator cannot delegate if they already have an active delegation.
     * @dev The delegations will be assigned in the order they are provided in the arrays.
     * @param _delegators An array of addresses delegating their balances
     * @param _delegatees An array of addresses receiving the delegations
     */
    function bulkDelegate(address[] memory _delegators, address[] memory _delegatees) external {
        _onlyFloxContributor();

        if (_delegators.length != _delegatees.length) revert ArrayLengthMismatch();

        for (uint256 i; i < _delegators.length; ) {
            address delegator = _delegators[i];
            address delegatee = _delegatees[i];

            if (delegator == delegatee) revert CannotDelegateToSelf();
            if (delegations[delegator] != address(0)) revert AlreadyDelegated();

            delegations[delegator] = delegatee;
            incomingDelegations[delegatee][incomingDelegationsCount[delegatee]] = delegator;
            incomingDelegationsCount[delegatee] = incomingDelegationsCount[delegatee] + 1;

            emit DelegationAdded(delegator, delegatee);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Used to revoke the caller's delegation.
     * @dev Can only be called by a Flox contributor.
     * @dev The delegator must have an active delegation.
     * @param _delegator The address of the user delegating their balance
     */
    function revokeDelegation(address _delegator) external {
        _onlyFloxContributor();

        address delegatee = delegations[_delegator];
        if (delegatee == address(0)) revert NoActiveDelegations();

        uint256 index = _findDelegatorIndex(_delegator);

        incomingDelegationsCount[delegatee]--;
        incomingDelegations[delegatee][index] = incomingDelegations[delegatee][incomingDelegationsCount[delegatee]];
        incomingDelegations[delegatee][incomingDelegationsCount[delegatee]] = address(0);

        delegations[_delegator] = address(0);

        emit DelegationRemoved(_delegator, delegatee);
    }

    /**
     * @notice Used to revoke multiple delegations in a single transaction.
     * @dev Can only be called by a Flox contributor.
     * @dev The delegator must have an active delegation.
     * @param _delegators An array of addresses delegating their balances
     */
    function bulkRevokeDelegation(address[] memory _delegators) external {
        _onlyFloxContributor();

        for (uint256 i; i < _delegators.length; ) {
            address delegator = _delegators[i];
            address delegatee = delegations[delegator];

            if (delegatee == address(0)) revert NoActiveDelegations();

            uint256 index = _findDelegatorIndex(delegator);

            incomingDelegationsCount[delegatee]--;
            incomingDelegations[delegatee][index] = incomingDelegations[delegatee][incomingDelegationsCount[delegatee]];
            incomingDelegations[delegatee][incomingDelegationsCount[delegatee]] = address(0);

            delegations[delegator] = address(0);

            emit DelegationRemoved(delegator, delegatee);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Used to find the index of the delegator in the incoming delegations array.
     * @dev The operation will be reverted if the caller is not a delegator.
     * @param _delegator The address of the delegator
     * @return The index of the delegator in the incoming delegations array
     */
    function _findDelegatorIndex(address _delegator) internal view returns (uint256) {
        address delegatee = delegations[_delegator];
        uint256 allIncomingDelegations = incomingDelegationsCount[delegatee];

        for (uint256 i; i < allIncomingDelegations; ) {
            if (incomingDelegations[delegatee][i] == _delegator) {
                return i;
            }

            unchecked {
                ++i;
            }
        }

        revert NoActiveDelegations();
    }

    /**
     * @notice Used to retrieve the balance of the FloxCAP boost token.
     * @dev If enabled, the scaled veFRAX balance is added to the FloxCAP balance.
     * @dev The veFRAX balance is scaled by the veFraxDivisor.
     * @param account The address to check the balance of
     * @return The balance of the FloxCAP boost token
     */
    function _balanceOf(address account) internal view returns (uint256) {
        uint256 sFraxBalance = fraxStaker.balanceOf(account);

        if (useVeFRAX) {
            uint256 veFRAXBalance = veFRAX.balanceOf(account);
            return (veFRAXBalance / veFraxDivisor) + sFraxBalance;
        }

        return sFraxBalance;
    }

    /**
     * @notice Checks if an address is a Flox contributor.
     * @dev The operation will be reverted if the caller is not a Flox contributor.
     */
    function _onlyFloxContributor() internal view {
        if (!isFloxContributor[msg.sender]) revert NotFloxContributor();
    }
}
