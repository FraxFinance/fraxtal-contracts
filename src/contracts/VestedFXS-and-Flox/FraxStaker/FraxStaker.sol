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
     * @dev If the staker delegates their stake, this will increase the delegated stake instead of creating a separate
     *  stake for them.
     */
    function stakeFrax() external payable {
        _onlyWhenOperational();
        _onlyWhenNotFrozen(msg.sender);
        _onlyWhenNotBlacklisted(msg.sender);

        _stake(msg.value, msg.sender);

        Stake memory stake = stakes[msg.sender];
        if (stake.delegatee != address(0)) {
            _onlyWhenNotFrozen(stake.delegatee);
            _onlyWhenNotBlacklisted(stake.delegatee);

            _delegate(msg.sender, stake.delegatee, msg.value);
        }
    }

    /**
     * @notice Stakes FRAX for the caller.
     * @dev The operation will be reverted if the contract is paused.
     * @dev The operation will be reverted if the staker's stake is frozen.
     * @dev The operation will be reverted if the delegatee's stake is frozen.
     * @dev The operation will be reverted if the staker is blacklisted.
     * @dev The operation will be reverted if the delegatee is blacklisted.
     * @dev The amount of FRAX to stake is the value sent with the transaction.
     * @dev This overloaded function allows the staker to delegate their stake to antoher staker.
     * @dev If another delegation exists for the staker, this function will revert.
     * @param _delegatee Address of the delegatee
     */
    function stakeFrax(address _delegatee) external payable {
        _onlyWhenOperational();
        _onlyWhenNotFrozen(msg.sender);
        _onlyWhenNotFrozen(_delegatee);
        _onlyWhenNotBlacklisted(msg.sender);
        _onlyWhenNotBlacklisted(_delegatee);

        // Make sure that the staker doesn't have a non-delegated stake
        if (stakes[msg.sender].amountStaked != stakes[msg.sender].amountDelegated) {
            revert NonDelegatedStakeAlreadyExists();
        }

        _stake(msg.value, msg.sender);
        _delegate(msg.sender, _delegatee, msg.value);
    }

    /**
     * @notice Initiates the withdrawal of the staker's stake.
     * @dev The operation will be reverted if the contract is paused.
     * @dev The operation will be reverted if the staker's stake is frozen.
     * @dev The operation will be reverted if the staker is blacklisted.
     */
    function initiateWithdrawal() external {
        _onlyWhenOperational();
        _onlyWhenNotFrozen(msg.sender);
        _onlyWhenNotBlacklisted(msg.sender);

        _initiateWithdrawal(msg.sender);
    }

    /**
     * @notice Withdraws the staker's stake.
     * @dev The operation will be reverted if the contract is paused.
     * @dev The operation will be reverted if the staker's stake is frozen.
     * @dev This operation will revoke all delegations of the staker's stake. This is only done in this stepto ensure
     *  the delegations can't be instantly revoked.
     * @dev Blacklisted stakers can withdraw their remaining stake.
     */
    function withdrawStake() external {
        _onlyWhenOperational();
        _onlyWhenNotFrozen(msg.sender);

        _revokeDelegation(msg.sender);
        _withdrawStake(msg.sender);
    }

    /**
     * @notice Allows Frax contibutor to force the withdrawal of staker's stake.
     * @dev This can only be called by a Frax contributor and is used to prevent the abiltiy to instantly withdraw
     *  delegated stakes.
     * @dev The operation will be reverted if the staker's stake is frozen.
     * @dev This revokes the full amount of the delegated stake.
     * @param _staker Address of the staker to force withdraw
     */
    function forceStakeWithdrawal(address _staker) external {
        _onlyFraxContributor();
        _onlyWhenNotFrozen(_staker);

        _revokeDelegation(_staker);
        _withdrawStake(_staker);
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

        if (stake.delegatee != address(0)) {
            emit DelegationRevocationInitiated(_staker, stake.delegatee, stake.amountStaked, stake.unlockTime);
        }
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
     * @dev The operation will be reverted if the staker has already delegated to amother delegatee.
     * @param _staker Address of the staker
     * @param _delegatee Address of the delegatee
     * @param _amount Amount of FRAX to delegate
     */
    function _delegate(address _staker, address _delegatee, uint256 _amount) internal {
        if (_staker == _delegatee) revert CannotDelegateToSelf();

        Stake storage stakerStake = stakes[_staker];

        if (_amount > stakerStake.amountStaked - stakerStake.amountDelegated) revert InvalidStakeAmount();

        if (stakerStake.delegatee != address(0) && stakerStake.delegatee != _delegatee)
            revert AlreadyDelegatedToAnotherDelegatee();

        stakerStake.amountDelegated += _amount;
        stakerStake.delegatee = _delegatee;
        stakes[_delegatee].amountDelegatedToStaker += _amount;

        emit StakeDelegated(_staker, _delegatee, _amount);
    }

    /**
     * @notice Revokes staker's delegation.
     * @dev The operation will be reverted if the staker has not delegated their stake to anyone.
     * @dev This revokes the full amount of the delegated stake.
     * @param _staker Address of the staker
     */
    function _revokeDelegation(address _staker) internal {
        Stake storage stake = stakes[_staker];

        address delegatee = stake.delegatee;

        uint256 amount = stake.amountDelegated;

        if (amount > 0) {
            stake.amountDelegated = 0;
            stakes[delegatee].amountDelegatedToStaker -= amount;

            stake.delegatee = address(0);

            emit StakeDelegationRevoked(_staker, delegatee, amount);
        }
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

        if (stake.delegatee != address(0)) {
            stakes[stake.delegatee].amountDelegatedToStaker -= _amount;
            stake.amountDelegated -= _amount;
        }

        (bool success, ) = SLASHING_RECIPIENT.call{ value: _amount }("");
        if (!success) revert TransferFailed();

        emit Slashed(_staker, _amount);
    }

    /**
     * @notice Freezes the staker's stake.
     * @dev This is reversible and should be used when investigating a staker.
     * @dev The operation will be reverted if the staker's stake is already frozen.
     * @dev IF the staker delegated their stake, freezing their stake will temporarily remove the delegated stake.
     * @param _staker Address of the staker to freeze
     */
    function _freezeStaker(address _staker) internal {
        if (isFrozenStaker[_staker]) revert AlreadyFrozenStaker();
        if (stakes[_staker].amountStaked == 0) revert InvalidStakeAmount();

        isFrozenStaker[_staker] = true;

        if (stakes[_staker].delegatee != address(0)) {
            stakes[stakes[_staker].delegatee].amountDelegatedToStaker -= stakes[_staker].amountStaked;
        }

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

        if (stakes[_staker].delegatee != address(0)) {
            stakes[stakes[_staker].delegatee].amountDelegatedToStaker += stakes[_staker].amountStaked;
        }

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
        _revokeDelegation(_staker);

        emit StakerBlacklisted(_staker, stakes[_staker].amountStaked);
    }
}
