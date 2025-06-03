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
// =========================== Frax Staker ============================
// ====================================================================

import { OwnedUpgradeable } from "../Flox/OwnedUpgradeable.sol";
import { FraxStakerStructs } from "./interfaces/FraxStakerStructs.sol";

/**
 * @title FraxStaker
 * @author Frax Finance
 * @notice A smart contract that allows users to stake FRAX.
 * @dev Delegating one's stake doesn't transfer the balance to the delegatee, so the full deposit can be retrieved by
 *  the staker.
 * @dev This smart contract supports single-hop fractional delegation. This means that a staker can delegate their stake,
 *  but the delegatee cannot delegate further delegate the accumulated delegations. Fractional delegation means that a
 *  staker can delegate a parta of their stake to multiple delegatees.
 */
contract FraxStaker is OwnedUpgradeable, FraxStakerStructs {
    /// Address that is the recipient of slashed stakes.
    address public SLASHING_RECIPIENT;
    /// Address of the proposed SLASHING_RECIPIENT.
    address public proposedSlashingRecipient;
    /// Timestamp at which the proposed slashing recipient can be accepted
    uint256 public proposedSlashingRecipientTimestamp;
    /// @notice Time delay between the proposal and the acceptance of the new slashing recipient.
    /// @dev We shouldn't be able to update the slashing recipient time delay as this would potentially nullify its
    ///  purpose.
    uint256 public slashingRecipientUpdateDelay;

    /**
     * @notice Used to track the blacklisted stakers.
     * @dev staker Address of the staker.
     * @dev isBlacklisted True if the address is blacklisted.
     */
    mapping(address staker => bool isBlacklisted) public blacklist;
    /**
     * @notice Used to track the delegations of the users.
     * @dev staker Address of the staker.
     * @dev delegatee Address of the delegatee.
     * @dev amount Amount of FRAX delegated.
     */
    mapping(address staker => mapping(address delegatee => uint256 amount)) public delegations;
    /**
     * @notice Used to keep track of the frozen stakers.
     * @dev address Address of the staker.
     * @dev isFrozen Whether the staker's stake is frozen or not.
     */
    mapping(address staker => bool isFrozen) public isFrozenStaker;
    /**
     * @notice Used to track the Frax contributors.
     * @dev contributor Address of the Frax contributor.
     * @dev isContributor True if the address is a Frax contributor.
     */
    mapping(address contributor => bool isContributor) public isFraxContributor;
    /**
     * @notice Used to track the Frax sentinels.
     * @dev Frax sentinels are the addresses that can freeze, unfreeze, slash, and blacklist stakers.
     * @dev sentinel Address of the sentinel.
     * @dev isSentinel True if the address is a sentinel.
     */
    mapping(address sentinel => bool isSentinel) public isFraxSentinel;
    /**
     * @notice Used to track the stakes of the users.
     * @dev staker Address of the staker.
     * @dev stake Stake of the user.
     */
    mapping(address staker => Stake stake) public stakes;
    /**
     * @notice Used to track the staker's active delegatees.
     * @dev This mapping is used to bypass the need to index events in order to determine all of the staker's delegatees.
     * @dev staker Address of the staker.
     * @dev delegateeIndex Index of the delegatee.
     * @dev delegatee Address of the delegatee.
     */
    mapping(address staker => mapping(uint8 delegateeIndex => address delegatee)) public stakerDelegatees;

    /// The cooldown required before a staker can withdraw their stake.
    uint256 public withdrawalCooldown;
    /// Version of the FraxCAP smart contract.
    string public version;
    /// Variable to track if the contract is paused.
    bool public isPaused;
    /// Used to make sure the contract is initialized only once.
    bool private _initialized;

    /// @dev reserve extra storage for future upgrades
    uint256[50] private __gap;

    /**
     * @notice Used to initialize the smart contract.
     * @dev The initial owner is set as the deployer of the smart contract.
     * @dev The initial withdrawal cooldown is set for 90 days.
     * @dev The initial slashing recipient update delay is set for 7 days.
     * @param _owner Address of the owner of the smart contract
     * @param _version Version of the FraxCAP smart contract
     */
    function initialize(address _owner, string memory _version) public {
        if (_initialized) revert AlreadyInitialized();

        _initialized = true;
        SLASHING_RECIPIENT = address(0xdead);
        version = _version;

        withdrawalCooldown = 90 days;
        slashingRecipientUpdateDelay = 7 days;

        __Owned_init(_owner);
    }

    /**
     * @notice Returns the balance of the specified address.
     * @dev The balance is zero if the address is blacklisted, frozen, or has initiated a withdrawal.
     * @dev This is a sum of the staker's stake and the amount delegated to them, minus the amount they have delegated
     *  to others.
     * @param account Address to check the balance of
     * @return The balance of the specified address
     */
    function balanceOf(address account) public view returns (uint256) {
        if (blacklist[account] || isFrozenStaker[account] || stakes[account].initiatedWithdrawal) {
            return 0;
        }

        Stake memory stake = stakes[account];

        return (stake.amountStaked - stake.amountDelegated + stake.amountDelegatedToStaker);
    }

    /**
     * @notice Returns the total supply of FRAX staked in the contract.
     * @return The total supply of FRAX staked in the contract
     */
    function totalSupply() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Stakes FRAX for the caller.
     * @dev The operation will be reverted if the contract is paused.
     * @dev The operation will be reverted if the staker's stake is frozen.
     * @dev The operation will be reverted if the staker is blacklisted.
     * @dev The amount of FRAX to stake is the value sent with the transaction.
     */
    function stakeFrax() external payable {
        _onlyWhenOperational();
        _onlyWhenNotFrozen(msg.sender);
        _onlyWhenNotBlacklisted(msg.sender);
        _stake(msg.value, msg.sender);
    }

    /**
     * @notice Initiates the withdrawal of the staker's stake.
     * @dev The operation will be reverted if the contract is paused.
     * @dev The operation will be reverted if the staker's stake is frozen.
     * @dev The operation will be reverted if the staker is blacklisted.
     * @dev This operation will revoke all delegations of the staker's stake.
     */
    function initiateWithdrawal() external {
        _onlyWhenOperational();
        _onlyWhenNotFrozen(msg.sender);
        _onlyWhenNotBlacklisted(msg.sender);
        _revokeAllDelegations(msg.sender);
        _initiateWithdrawal(msg.sender);
    }

    /**
     * @notice Withdraws the staker's stake.
     * @dev The operation will be reverted if the contract is paused.
     * @dev The operation will be reverted if the staker's stake is frozen.
     * @dev Blacklisted stakers can withdraw their remaining stake.
     */
    function withdrawStake() external {
        _onlyWhenOperational();
        _onlyWhenNotFrozen(msg.sender);
        _withdrawStake(msg.sender);
    }

    /**
     * @notice Delegates a part of the staker's stake to another staker.
     * @dev The operation will be reverted if the contract is paused.
     * @dev The operation will be reverted if the staker's stake is frozen.
     * @dev The operation will be reverted if the delegatee's stake is frozen.
     * @dev The operation will be reverted if the staker is blacklisted.
     * @dev The operation will be reverted if the delegateee is blacklisted.
     * @param _delegatee Address of the delegatee
     * @param _amount Amount of FRAX to delegate
     */
    function delegateStake(address _delegatee, uint256 _amount) external {
        _onlyWhenOperational();
        _onlyWhenNotFrozen(msg.sender);
        _onlyWhenNotFrozen(_delegatee);
        _onlyWhenNotBlacklisted(msg.sender);
        _onlyWhenNotBlacklisted(_delegatee);

        _delegate(msg.sender, _delegatee, _amount);
    }

    /**
     * @notice Revokes the full amount of the delegation of the staker's stake to another staker.
     * @dev The operation will be reverted if the contract is paused.
     * @dev The operation will be reverted if the staker's stake is frozen.
     * @dev The operation will be reverted if the staker is blacklisted.
     * @dev Users should be able to revoke delegations to frozen or blacklisted stakers.
     * @param _delegatee Address of the delegatee
     */
    function revokeDelegation(address _delegatee) external {
        _onlyWhenOperational();
        _onlyWhenNotFrozen(msg.sender);
        _onlyWhenNotBlacklisted(msg.sender);

        _revokeDelegation(msg.sender, _delegatee);
    }

    /**
     * @notice Revokes all delegations of the staker's stake to other stakers.
     * @dev The operation will be reverted if the contract is paused.
     * @dev The operation will be reverted if the staker's stake is frozen.
     * @dev The operation will be reverted if the staker is blacklisted.
     */
    function revokeAllDelegations() external {
        _onlyWhenOperational();
        _onlyWhenNotFrozen(msg.sender);
        _onlyWhenNotBlacklisted(msg.sender);

        _revokeAllDelegations(msg.sender);
    }

    /**
     * @notice Adds a Frax contributor.
     * @dev Can only be called by the owner.
     * @param _contributor The address of the Frax contributor to add
     */
    function addFraxContributor(address _contributor) external {
        _onlyOwner();
        if (isFraxContributor[_contributor]) revert AlreadyFraxContributor();
        isFraxContributor[_contributor] = true;
        emit FraxContributorAdded(_contributor);
    }

    /**
     * @notice Removes a Frax contributor.
     * @dev Can only be called by the owner.
     * @param _contributor The address of the Frax contributor to remove
     */
    function removeFraxContributor(address _contributor) external {
        _onlyOwner();
        if (!isFraxContributor[_contributor]) revert NotFraxContributor();
        isFraxContributor[_contributor] = false;
        emit FraxContributorRemoved(_contributor);
    }

    /**
     * @notice Adds a Frax sentinel.
     * @dev Can only be called by the owner.
     * @param _sentinel The address of the Frax sentinel to add
     */
    function addFraxSentinel(address _sentinel) external {
        _onlyOwner();
        if (isFraxSentinel[_sentinel]) revert AlreadyFraxSentinel();
        isFraxSentinel[_sentinel] = true;
        emit FraxSentinelAdded(_sentinel);
    }

    /**
     * @notice Removes a Frax sentinel.
     * @dev Can only be called by the owner.
     * @param _sentinel The address of the Frax sentinel to remove
     */
    function removeFraxSentinel(address _sentinel) external {
        _onlyOwner();
        if (!isFraxSentinel[_sentinel]) revert NotFraxSentinel();
        isFraxSentinel[_sentinel] = false;
        emit FraxSentinelRemoved(_sentinel);
    }

    /**
     * @notice Updates the withdrawal cooldown duration.
     * @dev Can only be called by the owner.
     * @param _withdrawalCooldown The new withdrawal cooldown
     */
    function updateWithdrawalCooldown(uint256 _withdrawalCooldown) external {
        _onlyOwner();
        uint256 oldWithdrawalCooldown = withdrawalCooldown;
        withdrawalCooldown = _withdrawalCooldown;
        emit WithdrawalCooldownUpdated(oldWithdrawalCooldown, withdrawalCooldown);
    }

    /**
     * @notice Stops the operation of the smart contract.
     * @dev Can only be called by a Frax contributor.
     * @dev Can only be called if the contract is operational.
     */
    function stopOperation() external {
        _onlyFraxContributor();
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
     * @notice Proposes the slashing recipient update.
     * @dev Can only be called by the owner.
     * @dev The new slashing recipient cannot be the same as the old one.
     * @dev If the same address is passed, the operation will be reverted. This is to prevent passing a smilar spoofed
     *  address to the function.
     * @dev This starts the time delay and allows the slashing recipient to be updated after the delay has passed.
     * @param _slashingRecipient Address of the new slashing recipient
     */
    function proposeSlashingRecipientUpdate(address _slashingRecipient) external {
        _onlyOwner();

        address currentSlashingRecipient = SLASHING_RECIPIENT;
        if (currentSlashingRecipient == _slashingRecipient) revert AlreadySlashingRecipient();

        proposedSlashingRecipient = _slashingRecipient;
        proposedSlashingRecipientTimestamp = block.timestamp + slashingRecipientUpdateDelay;

        emit SlashingRecipientUpdateProposed(currentSlashingRecipient, proposedSlashingRecipient);
    }

    /**
     * @notice Accepts the slashing recipient update.
     * @dev Can only be called by the owner.
     * @dev The operation will be reverted if there is no proposed slashing recipient.
     * @dev The operation will be reverted if the proposed slashing recipient update is not available yet.
     */
    function acceptSlashingRecipientUpdate() external {
        _onlyOwner();

        if (proposedSlashingRecipientTimestamp == 0) revert NoProposedSlashingRecipient();
        if (block.timestamp < proposedSlashingRecipientTimestamp) revert SlashingRecipientUpdateNotAvailableYet();

        address oldSlashingRecipient = SLASHING_RECIPIENT;
        SLASHING_RECIPIENT = proposedSlashingRecipient;
        proposedSlashingRecipient = address(0);
        proposedSlashingRecipientTimestamp = 0;

        emit SlashingRecipientUpdated(oldSlashingRecipient, SLASHING_RECIPIENT);
    }

    /**
     * @notice Slashes the staker's stake by the specified amount.
     * @dev Can only be called by the Frax sentinel.
     * @dev The slashing operation will be reverted if the contract is paused.
     * @dev The user should be able to be slashed even if their stake is frozen.
     * @param _staker The address of the slashing recipient
     * @param _amount The amount of FRAX to slash
     */
    function slashStaker(address _staker, uint256 _amount) external {
        _onlyFraxSentinel();

        _slash(_staker, _amount);
    }

    /**
     * @notice Freezes the staker's stake.
     * @dev Can only be called by the Frax sentinel.
     * @dev The freezing operation will be reverted if the contract is paused.
     * @param _staker The address of the staker to freeze
     */
    function freezeStaker(address _staker) external {
        _onlyFraxSentinel();

        _freezeStaker(_staker);
    }

    /**
     * @notice Unfreezes the staker's stake.
     * @dev Can only be called by the Frax sentinel.
     * @dev The unfreezing operation will be reverted if the contract is paused.
     * @param _staker The address of the staker to unfreeze
     */
    function unfreezeStaker(address _staker) external {
        _onlyFraxSentinel();

        _unfreezeStaker(_staker);
    }

    /**
     * @notice Blacklists the staker.
     * @dev Can only be called by the Frax sentinel.
     * @param _staker The address of the staker to blacklist
     */
    function blacklistStaker(address _staker) external {
        _onlyFraxSentinel();

        _blacklistStaker(_staker);
    }

    /**
     * @notice Checks if an address is a Frax contributor.
     * @dev The operation will be reverted if the caller is not a Frax contributor.
     */
    function _onlyFraxContributor() internal view {
        if (!isFraxContributor[msg.sender]) revert NotFraxContributor();
    }

    /**
     * @notice Checks if an address is a Frax sentinel.
     * @dev The operation will be reverted if the caller is not a Frax sentinel.
     */
    function _onlyFraxSentinel() internal view {
        if (!isFraxSentinel[msg.sender]) revert NotFraxSentinel();
    }

    /**
     * @notice Checks if the contract is operational.
     * @dev The operation will be reverted if the contract is paused.
     */
    function _onlyWhenOperational() internal view {
        if (isPaused) revert ContractPaused();
    }

    /**
     * @notice Checks if the staker's stake is frozen.
     * @dev The operation will be reverted if the staker's stake is frozen.
     * @param _staker Address of the staker to check
     */
    function _onlyWhenNotFrozen(address _staker) internal view {
        if (isFrozenStaker[_staker]) revert FrozenStaker();
    }

    /**
     * @notice Checks if the staker is blacklisted.
     * @dev The operation will be reverted if the staker is blacklisted.
     * @param _staker Address of the staker to check
     */
    function _onlyWhenNotBlacklisted(address _staker) internal view {
        if (blacklist[_staker]) revert BlacklistedStaker();
    }

    /**
     * @notice Stakes FRAX for the caller.
     * @dev Since the amount to stake is the message value, we don't need to validate the user's balance.
     * @dev Attempting to stake zero FRAX will result in reverted execution.
     * @param _amount Amount of FRAX to stake
     * @param _staker Address of the staker
     */
    function _stake(uint256 _amount, address _staker) internal {
        if (_amount == 0) revert InvalidStakeAmount();

        Stake storage stake = stakes[_staker];
        if (stake.initiatedWithdrawal) revert WithdrawalInitiated();
        uint256 initialStake = stake.amountStaked;
        stake.amountStaked += _amount;

        emit StakeUpdated(_staker, initialStake, stake.amountStaked);
    }

    /**
     * @notice Initiates the withdrawal of the staker's stake.
     * @dev The operation will be reverted if the staker has no stake.
     * @dev The operation will be reverted if the staker has already initiated a withdrawal.
     * @param _staker Address of the staker
     */
    function _initiateWithdrawal(address _staker) internal {
        Stake storage stake = stakes[_staker];

        if (stake.amountStaked == 0) revert InvalidStakeAmount();
        if (stake.initiatedWithdrawal) revert WithdrawalInitiated();

        stake.initiatedWithdrawal = true;
        stake.unlockTime = block.timestamp + withdrawalCooldown;

        emit StakeWithdrawalInitiated(_staker, stake.amountStaked, stake.unlockTime);
    }

    /**
     * @notice Withdraws the staker's stake.
     * @dev The operation will be reverted if the staker has not initiated a withdrawal.
     * @dev The operation will be reverted if the staker's stake is not available to be withdrawn yet.
     * @param _staker Address of the staker
     */
    function _withdrawStake(address _staker) internal {
        Stake storage stake = stakes[_staker];

        if (!stake.initiatedWithdrawal) revert WithdrawalNotInitiated();
        if (block.timestamp < stake.unlockTime) revert WithdrawalNotAvailable();

        uint256 amount = stake.amountStaked;
        stake.amountStaked = 0;
        stake.initiatedWithdrawal = false;
        stake.unlockTime = 0;

        (bool success, ) = _staker.call{ value: amount }("");
        if (!success) revert TransferFailed();

        emit StakeUpdated(_staker, amount, 0);
    }

    /**
     * @notice Delegates a part of the staker's stake to another staker.
     * @dev The operation will be reverted if the staker wants to delegate more FRAX than available.
     * @dev The operation will be reverted if the staker has already delegated to the maximum number of delegatees.
     * @param _staker Address of the staker
     * @param _delegatee Address of the delegatee
     * @param _amount Amount of FRAX to delegate
     */
    function _delegate(address _staker, address _delegatee, uint256 _amount) internal {
        if (_staker == _delegatee) revert CannotDelegateToSelf();

        Stake storage stakerStake = stakes[_staker];

        if (_amount > stakerStake.amountStaked - stakerStake.amountDelegated) revert InvalidStakeAmount();

        bool alreadyStakersDelegatee;
        if (delegations[_staker][_delegatee] != 0) {
            alreadyStakersDelegatee = true;
        }

        if (!alreadyStakersDelegatee) {
            if (stakerStake.numberOfDelegations == 255) revert TooManyDelegations();
            stakerDelegatees[_staker][stakerStake.numberOfDelegations] = _delegatee;
            ++stakerStake.numberOfDelegations;
        }

        delegations[_staker][_delegatee] += _amount;
        stakerStake.amountDelegated += _amount;
        stakes[_delegatee].amountDelegatedToStaker += _amount;

        emit StakeDelegated(_staker, _delegatee, _amount);
    }

    /**
     * @notice Revokes the full amount of the delegation of the staker's stake to another staker.
     * @dev The operation will be reverted if the staker has not delegated any stake to the delegatee.
     * @dev This revokes the full amount of the delegated stake to the delegatee.
     * @param _staker Address of the staker
     * @param _delegatee Address of the delegatee
     */
    function _revokeDelegation(address _staker, address _delegatee) internal {
        Stake storage stakerStake = stakes[_staker];

        uint256 amount = delegations[_staker][_delegatee];
        if (amount == 0) revert InvalidStakeAmount();

        for (uint8 i; i < stakerStake.numberOfDelegations; ) {
            if (stakerDelegatees[_staker][i] == _delegatee) {
                // This shifts the last delegatee to the slot of the one we are removing
                stakerDelegatees[_staker][i] = stakerDelegatees[_staker][stakerStake.numberOfDelegations - 1];
                // This removes the entry that was shifted to the spot of the delegatee we are removing
                stakerDelegatees[_staker][stakerStake.numberOfDelegations - 1] = address(0);

                --stakerStake.numberOfDelegations;
                break;
            }

            unchecked {
                ++i;
            }
        }

        delegations[_staker][_delegatee] = 0;
        stakerStake.amountDelegated -= amount;
        stakes[_delegatee].amountDelegatedToStaker -= amount;

        emit StakeDelegationRevoked(_staker, _delegatee, amount);
    }

    /**
     * @notice Revokes all delegations of the staker's stake to other stakers.
     * @dev The operation will be reverted if the staker has not delegated any stake to any delegatee.
     * @dev This revokes the full amount of the delegated stake to all delegatees.
     * @dev This will also remove the staker from the delegatee's list of stakers.
     * @param _staker Address of the staker
     */
    function _revokeAllDelegations(address _staker) internal {
        Stake storage stake = stakes[_staker];
        uint256 totalAmountRevoked;

        for (uint8 i = stakes[_staker].numberOfDelegations; i > 0; ) {
            address delegatee = stakerDelegatees[_staker][i - 1];

            uint256 amount = delegations[_staker][delegatee];

            delegations[_staker][delegatee] = 0;
            stakes[delegatee].amountDelegatedToStaker -= amount;

            stakerDelegatees[_staker][i - 1] = address(0);

            totalAmountRevoked += amount;

            emit StakeDelegationRevoked(_staker, delegatee, amount);

            unchecked {
                --i;
            }
        }

        if (stake.amountDelegated != totalAmountRevoked) revert UnableToRevokeAllDelegations();
        stake.amountDelegated -= totalAmountRevoked;
        stake.numberOfDelegations = 0;
    }

    /**
     * @notice Slashes the staker's stake.
     * @dev If the staker's stake is less than the amount to be slashed, the entire stake will be slashed.
     * @param _staker Address of the staker to slash
     * @param _amount The amount of FRAX to slash
     */
    function _slash(address _staker, uint256 _amount) internal {
        Stake storage stake = stakes[_staker];

        _amount = stake.amountStaked < _amount ? stake.amountStaked : _amount;

        stake.amountStaked -= _amount;

        (bool success, ) = SLASHING_RECIPIENT.call{ value: _amount }("");
        if (!success) revert TransferFailed();

        emit Slashed(_staker, _amount);
    }

    /**
     * @notice Freezes the staker's stake.
     * @dev This is reversible and should be used when investigating a staker.
     * @dev The operation will be reverted if the staker's stake is already frozen.
     * @param _staker Address of the staker to freeze
     */
    function _freezeStaker(address _staker) internal {
        if (isFrozenStaker[_staker]) revert AlreadyFrozenStaker();
        if (stakes[_staker].amountStaked == 0) revert InvalidStakeAmount();

        isFrozenStaker[_staker] = true;

        emit StakerFrozen(_staker, stakes[_staker].amountStaked);
    }

    /**
     * @notice Unfreezes the staker's stake.
     * @dev The operation will be reverted if the staker's stake is not frozen.
     * @param _staker Address of the staker to unfreeze
     */
    function _unfreezeStaker(address _staker) internal {
        if (!isFrozenStaker[_staker]) revert NotFrozenStaker();

        isFrozenStaker[_staker] = false;

        emit StakerUnfrozen(_staker, stakes[_staker].amountStaked);
    }

    /**
     * @notice Blacklists the staker.
     * @dev This is irreversible and should be used when a staker is found to be malicious.
     * @dev If the staker should be slashed, slashing should be done before blacklisting.
     * @dev This forces the staker to withdraw their stake and prevents them from staking again.
     * @dev The operation will be reverted if the staker is already blacklisted.
     * @param _staker Address of the staker to blacklist
     */
    function _blacklistStaker(address _staker) internal {
        if (blacklist[_staker]) revert AlreadyBlacklistedStaker();

        if (isFrozenStaker[_staker]) {
            _unfreezeStaker(_staker);
        }

        blacklist[_staker] = true;

        _initiateWithdrawal(_staker);
        _revokeAllDelegations(_staker);

        emit StakerBlacklisted(_staker, stakes[_staker].amountStaked);
    }
}
