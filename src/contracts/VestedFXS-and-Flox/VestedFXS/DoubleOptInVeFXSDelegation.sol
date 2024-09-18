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
// ==================== DoubleOptInVeFXSDelegation ====================
// ====================================================================
// Allows a 1-to-1 exclusive delegation of veFXS
// Delegatee's balance is summed/combined with that of the delegator's
// Mainly used for Snapshot or similar

// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna

import { VeFXSAggregator } from "./VeFXSAggregator.sol";
import { IveFXSStructs } from "./IveFXSStructs.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ICrossDomainMessenger } from "src/contracts/Miscellany/FraxFarmQuitCreditor/ICrossDomainMessenger.sol";
import { OwnedV2AutoMsgSender } from "./OwnedV2AutoMsgSender.sol";

// import "forge-std/console2.sol";

contract DoubleOptInVeFXSDelegation is OwnedV2AutoMsgSender, IveFXSStructs {
    using SafeERC20 for ERC20;

    // ==============================================================================
    // STATE VARIABLES
    // ==============================================================================

    // Instances
    // -------------------------

    /// @notice Fraxtal CrossDomainMessenger
    ICrossDomainMessenger public messenger;

    /// @notice The Fraxtal VeFXSAggregator contract
    VeFXSAggregator public aggregator;

    // Mappings
    // -------------------------

    /// @notice Store the nominated delegatee for a given delegator. Not live until the delegatee also accepts the nomination.
    mapping(address delegator => address nominatedDelegatee) public nominatedDelegatee;

    /// @notice Store the delegatee for a given delegator
    mapping(address delegator => address delegatee) public delegateeFor;

    /// @notice Store the delegator for a given delegatee
    mapping(address delegatee => address delegator) public delegatorFor;

    // Other
    // -------------------------
    uint256 public decimals;
    string public name;
    string public symbol;

    /// @notice If the contract was initialized
    bool wasInitialized;

    /// @dev reserve extra storage for future upgrades
    uint256[50] private __gap;

    // ==============================================================================
    // CONSTRUCTOR & INITIALIZE
    // ==============================================================================

    /// @notice Construct contract
    constructor() {}

    /// @notice Initialize contract
    function initialize(address _owner, address _aggregator) public {
        // Safety checks - no validation on admin in case this is initialized without admin
        if (wasInitialized) revert InitializeFailed();

        // Set misc strings
        decimals = 18;
        name = "Aggregate VeFXS (Delegated)";
        symbol = "veFXS";

        // Set owner for OwnedV2
        owner = _owner;

        // Set the messenger
        messenger = ICrossDomainMessenger(0x4200000000000000000000000000000000000007);

        // Set the VeFXSAggregator
        aggregator = VeFXSAggregator(_aggregator);

        // Set the contract as initialized
        wasInitialized = true;
    }

    // MODIFIERS
    // ===================================================

    // ==============================================================================
    // VIEWS
    // ==============================================================================

    /// @notice Check delegation info for a given address
    /// @param _addr The address to check
    /// @return _addressType Status of the _addr. 0: Undelegated, 1: Delegatee, 2: Delegator
    function delegationInfo(
        address _addr
    ) public view returns (uint256 _addressType, address _delegator, address _delegatee) {
        // Fetch delegators / delegatees, if present
        _delegator = delegatorFor[_addr];
        _delegatee = delegateeFor[_addr];

        // Check to see the type of _addr
        if ((_delegator == address(0)) && (_delegatee != address(0))) {
            // Address is a delegator
            _addressType = 1;
        } else if ((_delegator != address(0)) && (_delegatee == address(0))) {
            // Address is a delegatee
            _addressType = 2;
        } else {
            // Address is undelegated
            // _addressType defaults to 0
        }
    }

    /// @notice Pass through to VeFXSAggregator. Total veFXS of a user from multiple different sources, such as the FPIS Locker, L1VeFXS, and Fraxtal veFXS. Handles delegation if present.
    /// @param _addr The address to check
    /// @return _balance The veFXS balance of the _addr
    function balanceOf(address _addr) public view returns (uint256 _balance) {
        // Get delegation information about the address
        (uint256 _addressType, address _delegator, ) = delegationInfo(_addr);

        // Return depends on the type of the address
        if (_addressType == 0) {
            // Undelegated, so return normally
            _balance = aggregator.ttlCombinedVeFXS(_addr);
        } else if (_addressType == 1) {
            // _addr is a delegator, so return 0
            _balance = 0;
        } else {
            // _addr is a delegatee, so return the delegator's veFXS + delegatee's own veFXS
            _balance = aggregator.ttlCombinedVeFXS(_delegator);
            _balance += aggregator.ttlCombinedVeFXS(_addr);
        }
    }

    /// @notice Same as balanceOf
    /// @param _user The user to check
    /// @return _currBal The veFXS balance
    function ttlCombinedVeFXS(address _user) public view returns (uint256 _currBal) {
        _currBal = balanceOf(_user);
    }

    /// @notice Get all the active locks for a user
    /// @param _account The account to get the locks for
    /// @param _estimateCrudeVeFXS False to save gas. True to add the lock's estimated veFXS
    /// @return _currActiveLocks Array of LockedBalanceExtendedV2 structs (all active locks)
    function getAllCurrActiveLocks(
        address _account,
        bool _estimateCrudeVeFXS
    ) public view returns (LockedBalanceExtendedV2[] memory _currActiveLocks) {
        // Get delegation information about the address
        (uint256 _addressType, address _delegator, ) = delegationInfo(_account);

        // Return depends on the type of the address
        if (_addressType == 0) {
            // Undelegated, so return normally
            _currActiveLocks = aggregator.getAllCurrActiveLocks(_account, _estimateCrudeVeFXS);
        } else if (_addressType == 1) {
            // _account is a delegator, so return nothing
        } else {
            // _account is a delegatee, so return the delegatee's own active locks + the delegator's active locks
            // Fetch all of the locks
            LockedBalanceExtendedV2[] memory _delegateeLocks = aggregator.getAllCurrActiveLocks(
                _account,
                _estimateCrudeVeFXS
            );
            LockedBalanceExtendedV2[] memory _delegatorLocks = aggregator.getAllCurrActiveLocks(
                _delegator,
                _estimateCrudeVeFXS
            );

            // Initialize the return array
            _currActiveLocks = new LockedBalanceExtendedV2[](_delegateeLocks.length + _delegatorLocks.length);

            // Add in the delegatee locks
            for (uint256 i = 0; i < _delegateeLocks.length; ) {
                _currActiveLocks[i] = _delegateeLocks[i];

                unchecked {
                    ++i;
                }
            }

            // Add in the delegator locks
            for (uint256 j = 0; j < _delegatorLocks.length; ) {
                _currActiveLocks[_delegateeLocks.length + j] = _delegatorLocks[j];

                unchecked {
                    ++j;
                }
            }
        }
    }

    /// @notice Get all the expired locks for a user
    /// @param _account The account to get the locks for
    /// @return _expiredLocks Array of LockedBalanceExtendedV2 structs (all expired locks)
    /// @dev Technically could combine with getAllCurrActiveLocks to save gas, but getAllExpiredLocks is mainly intended for a UI
    function getAllExpiredLocks(address _account) public view returns (LockedBalanceExtendedV2[] memory _expiredLocks) {
        // Get delegation information about the address
        (uint256 _addressType, address _delegator, ) = delegationInfo(_account);

        // Return depends on the type of the address
        if (_addressType == 0) {
            // Undelegated, so return normally
            _expiredLocks = aggregator.getAllExpiredLocks(_account);
        } else if (_addressType == 1) {
            // _account is a delegator, so return nothing
        } else {
            // _account is a delegatee, so return the delegatee's own expired locks + the delegator's expired locks
            // Fetch all of the locks
            LockedBalanceExtendedV2[] memory _delegateeLocks = aggregator.getAllExpiredLocks(_account);
            LockedBalanceExtendedV2[] memory _delegatorLocks = aggregator.getAllExpiredLocks(_delegator);

            // Initialize the return array
            _expiredLocks = new LockedBalanceExtendedV2[](_delegateeLocks.length + _delegatorLocks.length);

            // Add in the delegatee locks
            for (uint256 i = 0; i < _delegateeLocks.length; ) {
                _expiredLocks[i] = _delegateeLocks[i];

                unchecked {
                    ++i;
                }
            }

            // Add in the delegator locks
            for (uint256 j = 0; j < _delegatorLocks.length; ) {
                _expiredLocks[_delegateeLocks.length + j] = _delegatorLocks[j];

                unchecked {
                    ++j;
                }
            }
        }
    }

    // ==============================================================================
    // MUTATIVE FUNCTIONS
    // ==============================================================================

    /// @notice Delegatee accepts nomination to be a delegatee
    /// @param _delegator The delegator
    function acceptDelegation(address _delegator) external {
        // Fetch the delegator's nomination
        address nominee = nominatedDelegatee[_delegator];

        // msg.sender -> should be the nominee and become a delegatee
        // _delegator -> the one who originally nominated the nominee/delegatee

        // msg.sender should be the delegator's nominee
        if (nominee != msg.sender) revert SenderNotNominee();

        // Nominee cannot delegate to itself
        if (nominee == _delegator) revert CannotDelegateToSelf();

        // Neither the delegator nor the nominated delegatee should be delegators/delegatees already
        // They would need to rescind first
        // ==============================================================

        // The proposed delegator should not be redelegating to a third address if they are already a delegatee themselves
        if (delegatorFor[_delegator] != address(0)) revert DelegatorAlreadyADelegatee();

        // If proposed delegator is already an existing delegator, they need to rescind first before nominating someone else
        if (delegateeFor[_delegator] != address(0)) revert DelegatorAlreadyADelegator();

        // If nominee is already a delegatee, they need to rescind first before accepting another nomination
        if (delegatorFor[nominee] != address(0)) revert NomineeAlreadyADelegatee();

        // If nominee is already delegating, they need to rescind first before they can become a delegatee
        if (delegateeFor[nominee] != address(0)) revert NomineeAlreadyADelegator();

        // Set the mappings
        delegateeFor[_delegator] = nominee;
        delegatorFor[nominee] = _delegator;

        // Clear the nomination
        nominatedDelegatee[_delegator] = address(0);

        emit NominationAccepted(_delegator, msg.sender);
    }

    /// @notice Nominate the delegatee for the sender address. Delegatee will still have to accept later.
    /// @param _delegatee The address that should receive msg.sender's veFXS voting power
    function nominateDelegatee(address _delegatee) external {
        // Set the nomination
        nominatedDelegatee[msg.sender] = _delegatee;

        emit DelegateeNominated(msg.sender, _delegatee);
    }

    /// @notice Nominate the delegatee for the sender address, from Ethereum. Delegatee will still have to accept later.
    /// @param _delegatee The address that should receive msg.sender's veFXS voting power
    function nominateDelegateeCrossChain(address _delegatee) external {
        // Make sure the direct msg.sender is the messenger
        if (msg.sender != address(messenger)) revert BadSender();

        // Set the nomination
        nominatedDelegatee[messenger.xDomainMessageSender()] = _delegatee;

        emit DelegateeNominated(messenger.xDomainMessageSender(), _delegatee);
    }

    /// @notice Delegator rescinds their delegation
    function rescindDelegationAsDelegator() external {
        // Fetch the delegatee
        address delegatee = delegateeFor[msg.sender];

        // Clear the mappings
        delegateeFor[msg.sender] = address(0);
        delegatorFor[delegatee] = address(0);

        emit DelegationRescinded(msg.sender, msg.sender, delegatee);
    }

    /// @notice Delegator rescinds their delegation. Cross chain version
    function rescindDelegationAsDelegatorCrossChain() external {
        // Fetch the delegatee
        address delegatee = delegateeFor[messenger.xDomainMessageSender()];

        // Clear the mappings
        delegateeFor[messenger.xDomainMessageSender()] = address(0);
        delegatorFor[delegatee] = address(0);

        emit DelegationRescinded(messenger.xDomainMessageSender(), messenger.xDomainMessageSender(), delegatee);
    }

    /// @notice Delegatee rescinds their delegation
    function rescindDelegationAsDelegatee() external {
        // Fetch the delegator
        address delegator = delegatorFor[msg.sender];

        // Clear the mappings
        delegatorFor[msg.sender] = address(0);
        delegateeFor[delegator] = address(0);

        emit DelegationRescinded(msg.sender, delegator, msg.sender);
    }

    // ==============================================================================
    // RESTRICTED FUNCTIONS
    // ==============================================================================

    /// @notice Set the VeFXS aggregator address
    /// @param _vefxsAggregator The address of the new VeFXS aggregator
    function setVefxsAggregator(address _vefxsAggregator) external onlyOwner {
        aggregator = VeFXSAggregator(_vefxsAggregator);

        emit VeFxsAggregatorChanged(_vefxsAggregator);
    }

    // ==============================================================================
    // EVENTS
    // ==============================================================================

    /// @notice When a delegator nominates another address to receive their veFXS
    /// @param delegator The address that is nominating the delegation of their veFXS
    /// @param nominatedDelegatee The address that is being nominated to receiving their veFXS
    event DelegateeNominated(address indexed delegator, address nominatedDelegatee);

    /// @notice When a delegator or delegatee rescinds their delegation
    /// @param sender The address doing the rescinding
    /// @param delegator The delegator
    /// @param delegatee The delegatee
    event DelegationRescinded(address indexed sender, address indexed delegator, address delegatee);

    /// @notice When a delegatee accepts their nomination
    /// @param delegator The address that is nominating the delegation of their veFXS
    /// @param delegatee The address that accepted their delegation
    event NominationAccepted(address indexed delegator, address delegatee);

    /// @notice When the address of the VeFXSAggregator is changed
    /// @param vefxsAggregator The address of the new VeFXS aggregator
    event VeFxsAggregatorChanged(address vefxsAggregator);

    // ==============================================================================
    // ERRORS
    // ==============================================================================

    /// @notice A delegatee needs to rescind first if they want to switch delegators
    error NomineeAlreadyADelegatee();

    /// @notice A delegator needs to rescind first if they want to switch delegatees
    error DelegatorAlreadyADelegator();

    /// @notice Only the CrossDomainMessenger should be the sender
    error BadSender();

    /// @notice You cannot delegate to yourself
    error CannotDelegateToSelf();

    /// @notice The delegator address cannot redelegate to a third address
    error DelegatorAlreadyADelegatee();

    /// @notice Cannot initialize twice
    error InitializeFailed();

    /// @notice The delegatee address cannot redelegate to a third address
    error NomineeAlreadyADelegator();

    /// @notice When the sender is not the nominee
    error SenderNotNominee();
}
