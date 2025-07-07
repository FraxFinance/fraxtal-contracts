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
import { FloxConverter } from "./FloxConverter.sol";
import { FraxStaker } from "../FraxStaker/FraxStaker.sol";
import { VeFXSAggregator } from "../VestedFXS/VeFXSAggregator.sol";
import { IFloxCapacitorErrors } from "./interfaces/IFloxCapacitorErrors.sol";
import { IFloxCapacitorEvents } from "./interfaces/IFloxCapacitorEvents.sol";

/**
 * @title FloxCapacitor
 * @author Frax Finance
 * @notice A smart contract that allows users to stake FRAX and receive FloxCAP tokens.
 * @dev Used to aggregate user balances to be used to apply conversion boost in FloxConverter. It should be able to
 *  combine FraxStaker balance with scaled and limited veFRAX aggregated balance.
 * @dev The FloxCAP balance is not an ERC-20 token balance, but just a representation of accumulated balance used for
 *  FXTL point to FRAX conversions.
 * @dev We should be able to set delegations for the users (so that the aggregated balances can be compounded to a
 *  single address). We will be able to verify that there are not too many delegations that would cause OOG errors, so
 *  this is not an issue.
 * @dev Scenario: In FraxStaker, Person A --(delegation)--> Person B. Move to FloxCapacitor. Then
 *  Person B --(delegation)--> Person C. Person C will now have A + B + C, but only for the purposes of FXTL point
 *  conversion.
 * @dev It should be able to communicate with FloxConverter to determine how much FRAX the user needs in order to obtain
 *  the maximum boost (referred to as flox stake units). This in turn limits the percentage of balance the veFRAX
 *  sourced balance can represent (so if it's set at 25%, then up to 25% of the FloxCap balance can be sourced from the
 *  scaled veFRAX balance (the veFRAX balance is retrieved by a settable divisor)).
 * @dev The FloxCAP balance represents the amount of FRAX staked by the user.
 */
contract FloxCapacitor is OwnedUpgradeable, IFloxCapacitorErrors, IFloxCapacitorEvents {
    /// @notice Instance of the Frax Staker.
    FraxStaker public fraxStaker;

    /// @notice Instance of the VeFRAX Aggregator.
    VeFXSAggregator public veFRAX;

    /// @notice Instance of the Flox Converter.
    FloxConverter public floxConverter;

    /// @notice The maximum amount of basis points used in calculations to increase precision (equals 100%).
    uint256 public constant MAX_BASIS_POINTS = 1e5;

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

    /// @notice Version of the FloxCAP smart contract.
    string public version;

    /// @notice The amount of basis points used to limit the impact of veFRAX balance in cumulative balance.
    uint256 public veFraxBoostLimitBasisPoints;

    /// @notice The divisor used to convert the veFRAX balance to FloxCAP balance.
    uint8 public veFraxDivisor;

    /// @notice Toggle to signal whether the veFRAX balances should be taken into account.
    bool public useVeFRAX;

    /// @notice Used to make sure the contract is initialized only once.
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
        address payable _fraxStaker,
        address _owner,
        address _veFraxAggregator,
        uint8 _veFraxDivisor,
        string memory _version
    ) public {
        if (_initialized) revert AlreadyInitialized();

        _initialized = true;
        fraxStaker = FraxStaker(_fraxStaker);
        veFRAX = VeFXSAggregator(_veFraxAggregator);
        veFraxBoostLimitBasisPoints = 25_000; // 25% of the total boost can come from veFRAX
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
     * @notice Used to set the Flox Converter address.
     * @dev Can only be called by the owner.
     * @dev The operation will be reverted if the Flox Converter is already initialized.
     * @param _floxConverter The address of the Flox Converter
     */
    function setFloxConverter(address payable _floxConverter) external {
        _onlyOwner();
        if (address(floxConverter) != address(0)) revert AlreadyInitialized();

        floxConverter = FloxConverter(_floxConverter);
    }

    /**
     * @notice Used to retrieve the FloxCAP balance of user.
     * @dev If enabled, the scaled veFRAX balance is added to the FloxCAP balance.
     * @dev The veFRAX balance is scaled by the veFraxDivisor.
     * @dev This sums all of the delegated balaces of the users that delegated to the account.
     * @param account The address to check the balance of
     * @return _floxCapBalance The FloxCAP balance of the `account`
     */
    function balanceOf(address account) public view returns (uint256 _floxCapBalance) {
        // Get account's own balance first
        _floxCapBalance = _balanceOf(account);

        // Reset own balance to 0 if it is delegated to someone else
        if (delegations[account] != address(0)) {
            _floxCapBalance = 0;
        }

        // Loop through incoming delegations
        if (incomingDelegationsCount[account] > 0) {
            for (uint256 i; i < incomingDelegationsCount[account]; ) {
                // Get the delegator and its balance
                address delegator = incomingDelegations[account][i];
                uint256 delegatorBalance = _balanceOf(delegator);

                // Accumulate the balance
                _floxCapBalance += delegatorBalance;

                unchecked {
                    ++i;
                }
            }
        }
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
        _delegate(_delegator, _delegatee);
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
            _delegate(_delegators[i], _delegatees[i]);

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
        if (_delegator == address(0)) revert ZeroAddress();

        _revokeDelegation(_delegator);
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
            if (delegator == address(0)) revert ZeroAddress();

            _revokeDelegation(delegator);

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

        // Need to make sure there are not too many delegations here, or OOG may occur.
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
     * @param account The address to check the balance of
     * @return The balance of the FloxCAP boost token
     */
    function _balanceOf(address account) internal view returns (uint256) {
        uint256 fraxStakerBalance = fraxStaker.balanceOf(account);
        uint256 veFraxBalance = 0;

        if (useVeFRAX) {
            veFraxBalance = _getVeFraxScaledBalance(account);
        }

        return fraxStakerBalance + veFraxBalance;
    }

    /**
     * @notice Used to retrieve the scaled veFRAX balance of the account.
     * @dev The veFRAX balance is scaled by the veFraxDivisor.
     * @dev The veFRAX balance is limited by the percentage of maximum boost required balance based on the FXTL points.
     * @dev This is a cummulative balance of Fraxtal veFRAX, Ethereum veFRAX, and Fraxtal lFPIS.
     * @param account The address to check the balance of
     * @return The scaled veFRAX balance of the account
     */
    function _getVeFraxScaledBalance(address account) internal view returns (uint256) {
        uint256 veFraxBalance = veFRAX.balanceOf(account) / veFraxDivisor;
        uint256 fxtlPoints = floxConverter.getCurrentUserRedemptionEpochFxtlPoints(account);

        if (veFraxBalance == 0 || fxtlPoints == 0) {
            return 0;
        }

        uint256 pointsPerFrax = floxConverter.fxtlPointsPerOneFrax();
        uint256 maxBoostRequiredBalance = (fxtlPoints * 1e18) / pointsPerFrax; // We need to scale up FXTL points to the amount of FRAX decimals

        uint256 veFraxLimit = (maxBoostRequiredBalance * veFraxBoostLimitBasisPoints) / MAX_BASIS_POINTS;

        if (veFraxBalance >= veFraxLimit) {
            return veFraxLimit;
        } else {
            return veFraxBalance;
        }
    }

    /**
     * @notice Used to delegate `_delegator`'s balance to the specified `delegatee`.
     * @dev The operation will be reverted if either of the addresses is zero address.
     * @dev The operation will be reverted if the delegator is delegating to themselves.
     * @dev The operation will be reverted if the delegator already has an active delegation.
     * @param _delegator The address of the user delegating their balance
     * @param _delegatee The address of the user receiving the delegation
     */
    function _delegate(address _delegator, address _delegatee) internal {
        if (_delegator == address(0) || _delegatee == address(0)) revert ZeroAddress();

        if (_delegator == _delegatee) revert CannotDelegateToSelf();
        if (delegations[_delegator] != address(0)) revert AlreadyDelegated();

        delegations[_delegator] = _delegatee;
        incomingDelegations[_delegatee][incomingDelegationsCount[_delegatee]] = _delegator;
        incomingDelegationsCount[_delegatee] = incomingDelegationsCount[_delegatee] + 1;

        emit DelegationAdded(_delegator, _delegatee);
    }

    /**
     * @notice Used to revoke the delegation of the specified delegator.
     * @dev The operation will be reverted if the delegator does not have an active delegation.
     * @param _delegator The address of the user delegating their balance
     */
    function _revokeDelegation(address _delegator) internal {
        address delegatee = delegations[_delegator];
        if (delegatee == address(0)) revert NoActiveDelegations();

        // Find the index of the _delegator
        uint256 index = _findDelegatorIndex(_delegator);

        // Decrement the delegations count for the delegatee
        incomingDelegationsCount[delegatee]--;

        // Change the index of the last delegator in the mapping (not necessarily the provided _delegator) to the index of the soon-to-be-deleted _delegator
        incomingDelegations[delegatee][index] = incomingDelegations[delegatee][incomingDelegationsCount[delegatee]];

        // Set the last index to 0
        incomingDelegations[delegatee][incomingDelegationsCount[delegatee]] = address(0);

        // Set the delegations to 0 for the _delegator
        delegations[_delegator] = address(0);

        emit DelegationRemoved(_delegator, delegatee);
    }

    /**
     * @notice Checks if an address is a Flox contributor.
     * @dev The operation will be reverted if the caller is not a Flox contributor.
     */
    function _onlyFloxContributor() internal view {
        if (!isFloxContributor[msg.sender]) revert NotFloxContributor();
    }
}
