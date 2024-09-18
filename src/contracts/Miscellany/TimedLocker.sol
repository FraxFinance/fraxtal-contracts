// SPDX-License-Identifier: MIT
// @version 0.2.8
pragma solidity >=0.8.0;

/**
 * ====================================================================
 * |     ______                   _______                             |
 * |    / _____________ __  __   / ____(_____  ____ _____  ________   |
 * |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
 * |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
 * | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
 * |                                                                  |
 * ====================================================================
 * =========================== TimedLocker ============================
 * ====================================================================
 * Fixed-rate FXS rewards for locking tokens.
 * Total amount of staking token lockable is capped
 * Locked positions are transferable as vault tokens
 * After a set ending timestamp, all positions are unlockable
 * Frax Finance: https://github.com/FraxFinance
 */
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { OwnedV2 } from "./OwnedV2.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { TransferHelper } from "src/contracts/VestedFXS-and-Flox/Flox/TransferHelper.sol";

// import "forge-std/console2.sol";

contract TimedLocker is ERC20, OwnedV2, ReentrancyGuard {
    /* ========== STATE VARIABLES ========== */

    // Core variables
    // ----------------------------------------
    /// @notice When the locker was deployed
    uint256 public immutable deployTimestamp;

    /// @notice When the locker ends
    uint256 public immutable endingTimestamp;

    /// @notice Maximum amount of staking token that can be staked
    /// @dev Can be increased only if more reward tokens are simultaneously provided, to keep the new rewardPerSecondPerToken >= old rewardPerSecondPerToken
    uint256 public cap;

    /// @notice The token being staked
    ERC20 public stakingToken;

    // Global reward-related
    // ----------------------------------------

    /// @notice Helper to see if a token is a reward token on this locker
    mapping(address => bool) public isRewardToken;

    /// @notice The last time rewards were sent in
    uint256 public lastRewardPull;

    /// @notice The last time this contract was updated
    uint256 public lastUpdateTime;

    /// @notice The time the rewards period should finish. Should be endingTimestamp
    uint256 public immutable periodFinish;

    /// @notice The duration of the reward period. Should be endingTimestamp - deploy block.timestamp
    uint256 public immutable rewardsDuration;

    /// @notice Mapping of addresses that are allowed to deposit reward tokens
    mapping(address => bool) public rewardNotifiers;

    /// @notice Accumulator for rewardsPerToken
    // https://www.paradigm.xyz/2021/05/liquidity-mining-on-uniswap-v3
    uint256[] public rewardsPerTokenStored;

    /// @notice The reward tokens per second
    uint256[] public rewardRates;

    /// @notice Helper to get the reward token index, given the address of the token
    mapping(address => uint256) public rewardTokenAddrToIdx;

    /// @notice Array of all the reward tokens
    address[] public rewardTokens;

    // User reward-related
    // ----------------------------------------

    /// @notice The last time a farmer claimed their rewards
    mapping(address => uint256) public lastRewardClaimTime; // staker addr -> timestamp

    /// @notice Used for tracking stored/collectible rewards. earned()
    mapping(address => mapping(uint256 => uint256)) public rewards; // staker addr -> token id -> reward amount

    /// @notice Accumulator for userRewardsPerTokenPaid
    mapping(address => mapping(uint256 => uint256)) public userRewardsPerTokenPaid; // staker addr -> token id -> paid amount

    // Emergency variables
    // ----------------------------------------
    /// @notice If external syncEarned calls via bulkSyncEarnedUsers are allowed
    bool public externalSyncEarningPaused;

    /// @notice If reward collections are paused
    bool public rewardsCollectionPaused;

    /// @notice If staking is paused
    bool public stakingPaused;

    /// @notice Release locked stakes in case of system migration or emergency
    bool public stakesUnlocked;

    // For emergencies if a token is overemitted or something else. Only callable once.
    // Bypasses certain logic, which will cause reward calculations to be off
    // But the goal is for the users to recover LP, and they couldn't claim the erroneous rewards anyways.
    // Reward reimbursement claims would be handled with pre-issue earned() snapshots and a claim contract, or similar.
    bool public withdrawalOnlyShutdown;

    /// @notice If withdrawals are paused
    bool public withdrawalsPaused;

    /* ========== CONSTRUCTOR ========== */

    /// @notice Constructor
    /// @param _owner The owner of the locker
    /// @param _rewardTokens Array of reward tokens
    /// @param _name Name for the vault token
    /// @param _symbol Symbol for the vault token
    /// @param _stakingToken The token being staked
    /// @param _endingTimestamp Timestamp when all locks become unlocked
    /// @param _cap Maximum amount of staking tokens allowed to be locked
    /// @param _extraNotifier Additional reward notifier to add when constructing. Can add more / remove later
    constructor(
        address _owner,
        address[] memory _rewardTokens,
        address _stakingToken,
        string memory _name,
        string memory _symbol,
        uint256 _endingTimestamp,
        uint256 _cap,
        address _extraNotifier
    ) ERC20(_name, _symbol) OwnedV2(_owner) {
        // Set state variables
        stakingToken = ERC20(_stakingToken);
        rewardTokens = _rewardTokens;
        endingTimestamp = _endingTimestamp;
        cap = _cap;

        // Loop through the reward tokens
        for (uint256 i = 0; i < _rewardTokens.length; i++) {
            // For fast token address -> token ID lookups later
            rewardTokenAddrToIdx[_rewardTokens[i]] = i;

            // Add to the mapping
            isRewardToken[_rewardTokens[i]] = true;

            // Initialize the stored rewards
            rewardsPerTokenStored.push(0);

            // Initialize the reward rates
            rewardRates.push(0);
        }

        // Set the owner as an allowed reward notifier
        rewardNotifiers[_owner] = true;

        // Add the additional reward notifier, if present
        if (_extraNotifier != address(0)) rewardNotifiers[_extraNotifier] = true;

        // Other booleans
        stakesUnlocked = false;

        // For initialization
        deployTimestamp = block.timestamp;
        lastUpdateTime = block.timestamp;
        rewardsDuration = _endingTimestamp - block.timestamp;
        periodFinish = _endingTimestamp;
    }

    /* ========== MODIFIERS ========== */

    /// @notice Staking should not be paused
    modifier notStakingPaused() {
        require(!stakingPaused, "Staking paused");
        _;
    }

    /// @notice Update rewards and balances
    modifier updateRewards(address account) {
        _updateRewards(account);
        _;
    }

    /* ========== VIEWS ========== */

    /// @notice Remaining amount of stakingToken you can lock before hitting the cap
    /// @return _amount The amount
    function availableToLock() public view returns (uint256 _amount) {
        _amount = (cap - totalSupply());
    }

    /// @notice The last time rewards were applicable. Should be the lesser of the current timestamp, or the end of the last period
    /// @return uint256 The last timestamp where rewards were applicable
    function lastTimeRewardApplicable() internal view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    /// @notice Minimum amount of additional reward tokens needed so rewardPerSecondPerToken remains the same after a cap increase
    /// @param _newCap The new cap you want to increase to
    /// @return _minRewRates Minimum rewardRate needed after the cap is raised
    /// @return _minAddlTkns Minimum amount of additional reward tokens needed
    function minAddlRewTknsForCapIncrease(
        uint256 _newCap
    ) public view returns (uint256[] memory _minRewRates, uint256[] memory _minAddlTkns) {
        // Cap can only increase
        if (_newCap < cap) revert CapCanOnlyIncrease();

        // Initialize return arrays
        _minRewRates = new uint256[](rewardTokens.length);
        _minAddlTkns = new uint256[](rewardTokens.length);

        // See how much time is left
        uint256 _timeLeft = endingTimestamp - block.timestamp;

        // Loop through the reward tokens
        for (uint256 i = 0; i < rewardTokens.length; ) {
            // Solve for the new reward rate, assuming (Rate / Tokens) is constant
            // Round up by 1 wei
            _minRewRates[i] = ((rewardRates[i] * _newCap) + 1) / cap;

            // Calculate the additional tokens needed
            _minAddlTkns[i] = _timeLeft * (_minRewRates[i] - rewardRates[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice The calculated rewardPerTokenStored accumulator
    /// @return _rtnRewardsPerTokenStored Array of rewardsPerTokenStored
    function rewardPerToken() public view returns (uint256[] memory _rtnRewardsPerTokenStored) {
        // Prepare the return variable
        _rtnRewardsPerTokenStored = new uint256[](rewardTokens.length);

        // Calculate
        if (totalSupply() == 0) {
            // Return 0 if there are no vault tokens
            _rtnRewardsPerTokenStored = rewardsPerTokenStored;
        } else {
            // Loop through the reward tokens
            for (uint256 i = 0; i < rewardTokens.length; ) {
                _rtnRewardsPerTokenStored[i] =
                    rewardsPerTokenStored[i] +
                    (((lastTimeRewardApplicable() - lastUpdateTime) * rewardRates[i] * 1e18) / totalSupply());
                unchecked {
                    ++i;
                }
            }
        }
    }

    /// @notice The currently earned rewards for a user
    /// @param _account The staker's address
    /// @return _rtnEarned Array of the amounts of reward tokens the staker can currently collect
    function earned(address _account) public view returns (uint256[] memory _rtnEarned) {
        // Prepare the return variable
        _rtnEarned = new uint256[](rewardTokens.length);

        // Get the reward rate per token
        uint256[] memory _rtnRewardsPerToken = rewardPerToken();

        // Loop through the reward tokens
        for (uint256 i = 0; i < rewardTokens.length; ) {
            _rtnEarned[i] =
                rewards[_account][i] +
                ((balanceOf(_account) * ((_rtnRewardsPerToken[i] - userRewardsPerTokenPaid[_account][i]))) / 1e18);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Amount of rewards remaining
    /// @return _rtnRewardsRemaining Array of the amounts of the reward tokens
    function getRewardsRemaining() external view returns (uint256[] memory _rtnRewardsRemaining) {
        // Prepare the return variable
        _rtnRewardsRemaining = new uint256[](rewardTokens.length);

        // Return 0 if the locker has already ended
        if (endingTimestamp <= block.timestamp) return _rtnRewardsRemaining;

        // See how much time is left
        uint256 _timeLeft = endingTimestamp - block.timestamp;

        // Calculate the duration rewards
        for (uint256 i = 0; i < rewardTokens.length; ) {
            _rtnRewardsRemaining[i] = rewardRates[i] * _timeLeft;

            unchecked {
                ++i;
            }
        }
    }

    /* ========== ERC20 OVERRIDES ========== */

    /// @notice Override the _update logic to claim/sync earnings before transferring.
    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 value) internal override {
        // TODO for auditors: Make sure this is not manipulatable
        // If you aren't minting, sync rewards first so the owner doesn't lose them after transferring
        // Also so the recipient doesn't get free rewards
        // withdrawalOnlyShutdown sacrifices rewards buts lets the token move, for emergencies only.
        if (!withdrawalOnlyShutdown && (from != address(0))) {
            sync();
            _syncEarnedInner(from);
            _syncEarnedInner(to);
        }
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @notice Sync earnings for many users. Convenience function
    /// @param _users The account to sync
    /// @dev _beforeTokenTransfer essentially does this
    function bulkSyncEarnedUsers(address[] memory _users) external {
        // Check for withdrawal-only shutdown as well as the pause
        if (withdrawalOnlyShutdown || externalSyncEarningPaused) revert ExternalSyncEarningPaused();

        // Sync normally first
        sync();

        // Loop through the users and sync them. Skip global sync() to save gas
        for (uint256 i = 0; i < _users.length; ) {
            _syncEarnedInner(_users[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Sync contract-wide variables
    function sync() public {
        // Update rewardsPerTokenStored
        rewardsPerTokenStored = rewardPerToken();

        // Update the last update time
        lastUpdateTime = lastTimeRewardApplicable();
    }

    /// @notice Update the reward and balance state for a staker
    /// @param account The address of the user
    function _updateRewards(address account) internal {
        if (account != address(0)) {
            // Calculate the earnings first
            // Skip if we are in emergency shutdown
            if (!withdrawalOnlyShutdown) _syncEarned(account);
        }
    }

    /// @notice [MUST be proceeded by global sync()] Sync earnings for a specific staker. Skips the global sync() to save gas (mainly for bulkSyncEarnedUsers())
    /// @param _account The account to sync
    function _syncEarnedInner(address _account) internal {
        if (_account != address(0)) {
            // Calculate the earnings
            uint256[] memory _earneds = earned(_account);

            // Update the stake
            for (uint256 i = 0; i < rewardTokens.length; ) {
                rewards[_account][i] = _earneds[i];
                userRewardsPerTokenPaid[_account][i] = rewardsPerTokenStored[i];

                unchecked {
                    ++i;
                }
            }
        }
    }

    /// @notice Sync earnings for a specific staker
    /// @param _account The account to sync
    function _syncEarned(address _account) internal {
        // Update rewardsPerTokenStored and last update time
        sync();

        // Sync the account's earnings
        _syncEarnedInner(_account);
    }

    /// @notice Stake stakingToken for vault tokens
    /// @param _amount The amount of stakingToken
    function stake(uint256 _amount) public nonReentrant updateRewards(msg.sender) {
        // Do checks
        if (block.timestamp >= endingTimestamp) revert LockerHasEnded();
        if (stakingPaused) revert StakingPaused();
        if (stakesUnlocked) revert StakesAreUnlocked();
        if (withdrawalOnlyShutdown) revert OnlyWithdrawalsAllowed();
        if (_amount == 0) revert MustBeNonZero();
        if ((totalSupply() + _amount) > cap) revert Capped();

        // Pull the staking tokens from the msg.sender
        TransferHelper.safeTransferFrom(address(stakingToken), msg.sender, address(this), _amount);

        // Mint an equal amount of vault tokens to the staker
        _mint(msg.sender, _amount);

        // Update rewards
        _updateRewards(msg.sender);

        emit Stake(msg.sender, _amount, msg.sender);
    }

    /// @notice Withdraw stakingToken from vault tokens.
    /// @param _vaultTknAmount Amount of vault tokens to use
    /// @param _collectRewards Whether to also collect rewards
    function withdraw(
        uint256 _vaultTknAmount,
        bool _collectRewards
    ) public nonReentrant returns (uint256[] memory _rtnRewards) {
        if ((block.timestamp < endingTimestamp) && !(stakesUnlocked || withdrawalOnlyShutdown)) {
            revert LockerStillActive();
        }
        if (withdrawalsPaused) revert WithdrawalsPaused();

        // Burn the vault token from the sender
        _burn(msg.sender, _vaultTknAmount);

        // Give the stakingToken to the msg.sender
        // Should throw if insufficient balance
        TransferHelper.safeTransfer(address(stakingToken), msg.sender, _vaultTknAmount);

        // Collect rewards
        _rtnRewards = new uint256[](rewardTokens.length);
        if (_collectRewards) _rtnRewards = getReward(msg.sender);

        emit Withdrawal(msg.sender, _vaultTknAmount);
    }

    /// @notice Collect rewards
    /// @param _destinationAddress Destination address for the rewards
    /// @return _rtnRewards The amounts of collected reward tokens
    function getReward(
        address _destinationAddress
    ) public updateRewards(msg.sender) returns (uint256[] memory _rtnRewards) {
        // Make sure you are not in shutdown
        if (withdrawalOnlyShutdown) revert OnlyWithdrawalsAllowed();

        // Make sure reward collections are not paused
        if (rewardsCollectionPaused) revert RewardCollectionIsPaused();

        // Prepare the return variable
        _rtnRewards = new uint256[](rewardTokens.length);

        // Loop through the rewards
        for (uint256 i = 0; i < rewardTokens.length; ) {
            _rtnRewards[i] = rewards[msg.sender][i];

            // Do reward accounting
            if (_rtnRewards[i] > 0) {
                rewards[msg.sender][i] = 0;
                TransferHelper.safeTransfer(rewardTokens[i], _destinationAddress, _rtnRewards[i]);

                emit RewardPaid(msg.sender, _rtnRewards[i], rewardTokens[i], _destinationAddress);
            }

            unchecked {
                ++i;
            }
        }

        // Update the last reward claim time
        lastRewardClaimTime[msg.sender] = block.timestamp;
    }

    /// @notice Supply rewards. Only callable by whitelisted addresses.
    /// @param _amounts Amount of each reward token to add
    function notifyRewardAmounts(uint256[] memory _amounts) public {
        // Only the owner and the whitelisted addresses can notify rewards
        if (!((owner == msg.sender) || rewardNotifiers[msg.sender])) revert SenderNotOwnerOrRewarder();

        // Make sure the locker has not ended
        if (block.timestamp >= endingTimestamp) revert LockerHasEnded();

        // Pull in the reward tokens from the sender
        for (uint256 i = 0; i < rewardTokens.length; ) {
            // Handle the transfer of emission tokens via `transferFrom` to reduce the number
            // of transactions required and ensure correctness of the emission amount
            TransferHelper.safeTransferFrom(rewardTokens[i], msg.sender, address(this), _amounts[i]);

            unchecked {
                ++i;
            }
        }

        // Update rewardsPerTokenStored and last update time
        sync();

        // Calculate the reward rate
        for (uint256 i = 0; i < rewardTokens.length; ) {
            // Account for unemitted tokens
            uint256 remainingTime = periodFinish - block.timestamp;
            uint256 leftoverRwd = remainingTime * rewardRates[i];

            // Replace rewardsDuration with remainingTime here since we only have one big period
            // rewardRates[i] = (_amounts[i] + leftoverRwd) / rewardsDuration;
            rewardRates[i] = (_amounts[i] + leftoverRwd) / remainingTime;

            emit RewardAdded(rewardTokens[i], _amounts[i], rewardRates[i]);

            unchecked {
                ++i;
            }
        }

        // Update rewardsPerTokenStored and last update time (again)
        sync();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /// @notice Only settable to true
    function initiateWithdrawalOnlyShutdown() external onlyOwner {
        withdrawalOnlyShutdown = true;
    }

    /// @notice Increase the staking token cap. Can be increased only if more reward tokens are simultaneously provided, to keep the new rewardPerSecondPerToken >= old rewardPerSecondPerToken.
    /// @param _newCap The address of the token
    /// @param _addlRewTknAmounts The amount(s) of reward tokens being supplied as part of this cap increase.
    function increaseCapWithRewards(uint256 _newCap, uint256[] memory _addlRewTknAmounts) external onlyOwner {
        // Cap can only increase
        if (_newCap < cap) revert CapCanOnlyIncrease();

        // Sync first
        sync();

        // Fetch the calculated new rewardRates as well as the amount of additional tokens needed
        (uint256[] memory _minRewRates, uint256[] memory _minAddlTkns) = minAddlRewTknsForCapIncrease(_newCap);

        // Make sure enough reward tokens were supplied
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            if (_addlRewTknAmounts[i] < _minAddlTkns[i]) revert NotEnoughAddlRewTkns();
        }

        // Increase the cap
        cap = _newCap;

        // Add in the new rewards
        notifyRewardAmounts(_addlRewTknAmounts);

        // Compare the new rewardRate with the calculated minimum
        // New must be >= old
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            if (rewardRates[i] < _minRewRates[i]) {
                revert NotEnoughAddlRewTkns();
            }
        }
    }

    /// @notice Added to support recovering LP Rewards and other mistaken tokens from other systems to be distributed to holders
    /// @param _tokenAddress The address of the token
    /// @param _tokenAmount The amount of the token
    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        // Only the owner address can ever receive the recovery withdrawal
        TransferHelper.safeTransfer(_tokenAddress, owner, _tokenAmount);

        emit Recovered(_tokenAddress, _tokenAmount);
    }

    /// @notice Toggle the ability to syncEarned externally via bulkSyncEarnedUsers
    function toggleExternalSyncEarning() external onlyOwner {
        externalSyncEarningPaused = !externalSyncEarningPaused;
    }

    /// @notice Toggle the ability to stake
    function toggleStaking() external onlyOwner {
        stakingPaused = !stakingPaused;
    }

    /// @notice Toggle the ability to collect rewards
    function toggleRewardsCollection() external onlyOwner {
        rewardsCollectionPaused = !rewardsCollectionPaused;
    }

    /// @notice Toggle an address as being able to be a reward notifier
    /// @param _notifierAddr The address to toggle
    function toggleRewardNotifier(address _notifierAddr) external onlyOwner {
        rewardNotifiers[_notifierAddr] = !rewardNotifiers[_notifierAddr];
    }

    /// @notice Toggle the ability to withdraw
    function toggleWithdrawals() external onlyOwner {
        withdrawalsPaused = !withdrawalsPaused;
    }

    /// @notice Unlock all stakes, in the case of an emergency
    function unlockStakes() external onlyOwner {
        stakesUnlocked = !stakesUnlocked;
    }

    /* ========== ERRORS ========== */

    /// @notice When you are trying to lower the cap, which is not allowed
    error CapCanOnlyIncrease();

    /// @notice When you are trying to lock more tokens than are allowed
    error Capped();

    /// @notice If syncEarned should only be callable indirectly through methods or internally. Also occurs if in a withdrawal-only shutdown
    error ExternalSyncEarningPaused();

    /// @notice If the locker ending timestamp has passed
    error LockerHasEnded();

    /// @notice If the locker ending timestamp has not yet passed
    error LockerStillActive();

    /// @notice If an input value must be non-zero
    error MustBeNonZero();

    /// @notice If only withdrawals are allowed
    error OnlyWithdrawalsAllowed();

    /// @notice If reward collections are paused
    error RewardCollectionIsPaused();

    /// @notice When the cap is increased, the rewardPerSecondPerToken must either increase or stay the same
    error NotEnoughAddlRewTkns();

    /// @notice If the sender is not the owner or a rewarder
    error SenderNotOwnerOrRewarder();

    /// @notice If staking has been paused
    error StakingPaused();

    /// @notice If you are trying to stake after stakes have been unlock
    error StakesAreUnlocked();

    /// @notice If you didn't acknowledge the notifyRewardAmounts sync warning
    error MustSyncAllUsersBeforeNotifying();

    /// @notice If withdrawals have been paused
    error WithdrawalsPaused();

    /* ========== EVENTS ========== */

    /// @notice When LP tokens are locked
    /// @param user The staker
    /// @param amount Amount of LP staked
    /// @param source_address The origin address of the LP tokens. Usually the same as the user unless there is a migration in progress
    event Stake(address indexed user, uint256 amount, address source_address);

    /// @notice When LP tokens are withdrawn
    /// @param user The staker
    /// @param amount Amount of LP withdrawn
    event Withdrawal(address indexed user, uint256 amount);

    /// @notice When tokens are recovered, in the case of an emergency
    /// @param token Address of the token
    /// @param amount Amount of the recovered tokens
    event Recovered(address token, uint256 amount);

    /// @notice When a reward is deposited
    /// @param reward_address The address of the reward token
    /// @param reward Amount of tokens deposited
    /// @param yieldRate The resultant yield/emission rate
    event RewardAdded(address indexed reward_address, uint256 reward, uint256 yieldRate);

    /// @notice When a staker collects rewards
    /// @param user The staker
    /// @param reward Amount of reward tokens
    /// @param token_address Address of the reward token
    /// @param destination_address Destination address of the reward tokens
    event RewardPaid(address indexed user, uint256 reward, address token_address, address destination_address);
}
