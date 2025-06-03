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
     * @notice Used to track the blacklisted delegatees.
     * @dev This mapping is used to keep track of the delegatees from whom the user refuses to accept delegation.
     * @dev user Address of the user that refuses to accept delegation from the specified delegateee.
     * @dev delegator Address of the user prohibited from delegating to the user.
     * @dev isBlacklisted True if the address is blacklisted.
     */
    mapping(address user => mapping(address delegator => bool isBlacklisted)) public balcklistedDelegators;
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
    /// Minumum balance needed in order to be able to delegate.
    /// @dev This is used to safeguard against empty delegations.
    uint256 public minimumDelegationBalance;
    /// Number of allowed incoming delegations per delegatee.
    /// @dev This needs to be enforced, so the user can't be DDoSed by empty delegations attack.
    uint16 public incomingDelegationsLimit;
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
        minimumDelegationBalance = 10e18; // 10 FRAX
        incomingDelegationsLimit = 500;
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
     * @notice Used to update the incoming delegation limit.
     * @param _incomingDelegationsLimit The new incoming delegation limit
     */
    function updateIncomingDelegationLimit(uint16 _incomingDelegationsLimit) external {
        _onlyFloxContributor();

        uint16 oldIncomingDelegationLimit = incomingDelegationsLimit;
        incomingDelegationsLimit = _incomingDelegationsLimit;

        emit IncomingDelegationLimitUpdated(oldIncomingDelegationLimit, incomingDelegationsLimit);
    }

    /**
     * @notice Used to update the minimum balance needed to delegate.
     * @dev Can only be called by a Flox contributor.
     * @param _minimumDelegationBalance The new minimum delegation balance
     */
    function updateMinimumDelegationBalance(uint256 _minimumDelegationBalance) external {
        _onlyFloxContributor();

        uint256 oldMinimumDelegationBalance = minimumDelegationBalance;
        minimumDelegationBalance = _minimumDelegationBalance;

        emit MinimumDelegationBalanceUpdated(oldMinimumDelegationBalance, minimumDelegationBalance);
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
     * @dev The caller cannot delegate to themselves.
     * @dev If the delegatee already has the maximum number of incoming delegations, the operation will be reverted.
     * @dev The caller cannot delegate if they already have an active delegation.
     * @dev The caller must have a balance greater than the minimum delegation balance.
     * @param _delegatee The address of the user receiving the delegation
     */
    function delegate(address _delegatee) external {
        if (msg.sender == _delegatee) revert CannotDelegateToSelf();
        if (balcklistedDelegators[_delegatee][msg.sender]) revert BlacklistedDelegator();
        if (incomingDelegationsCount[_delegatee] >= incomingDelegationsLimit) revert TooManyIncomingDelegations();
        if (delegations[msg.sender] != address(0)) revert AlreadyDelegated();

        if (_balanceOf(msg.sender) < minimumDelegationBalance) revert InsufficientBalanceForDelegation();

        delegations[msg.sender] = _delegatee;
        incomingDelegations[_delegatee][incomingDelegationsCount[_delegatee]] = msg.sender;
        incomingDelegationsCount[_delegatee] = incomingDelegationsCount[_delegatee] + 1;

        emit DelegationAdded(msg.sender, _delegatee);
    }

    /**
     * @notice Used to revoke the caller's delegation.
     * @dev The caller must have an active delegation.
     */
    function revokeDelegation() external {
        address delegatee = delegations[msg.sender];
        if (delegatee == address(0)) revert NoActiveDelegations();

        uint256 index = _findDelegatorIndex(msg.sender);

        incomingDelegationsCount[delegatee]--;
        incomingDelegations[delegatee][index] = incomingDelegations[delegatee][incomingDelegationsCount[delegatee]];
        incomingDelegations[delegatee][incomingDelegationsCount[delegatee]] = address(0);

        delegations[msg.sender] = address(0);

        emit DelegationRemoved(msg.sender, delegatee);
    }

    /**
     * @notice Used to reject a delegation from the specified delegator.
     * @dev The caller must be the delegatee of the delegator.
     * @dev This also blacklists the delegator from delegating to the caller in the future.
     * @param _delegator The address of the user delegating their balance
     */
    function rejectDelegation(address _delegator) external {
        if (msg.sender != delegations[_delegator]) revert DelegationMismatch();

        uint256 index = _findDelegatorIndex(_delegator);

        incomingDelegationsCount[msg.sender]--;
        incomingDelegations[msg.sender][index] = incomingDelegations[msg.sender][incomingDelegationsCount[msg.sender]];
        incomingDelegations[msg.sender][incomingDelegationsCount[msg.sender]] = address(0);

        delegations[_delegator] = address(0);

        balcklistedDelegators[msg.sender][_delegator] = true;

        emit DelegationRemoved(_delegator, msg.sender);
        emit BlacklistDelegationStatusUpdated(msg.sender, _delegator, true);
    }

    /**
     * @notice Used to remove a delegator from the blacklist.
     * @dev The delegator must be blacklisted by the caller, otherwise the operation will be reverted.
     * @param _delegator The address of the delegator to be removed from the blacklist
     */
    function removeDelegatorFromBlacklist(address _delegator) external {
        if (!balcklistedDelegators[msg.sender][_delegator]) revert NotBlacklistedDelegator();

        balcklistedDelegators[msg.sender][_delegator] = false;

        emit BlacklistDelegationStatusUpdated(msg.sender, _delegator, false);
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
