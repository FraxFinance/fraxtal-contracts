interface IFraxtalFarm {
    /// @notice Information about a particular locked stake
    /// @param kek_id A unique ID for the stake
    /// @param start_timestamp When the stake was locked
    /// @param liquidity How much LP the stake has
    /// @param ending_timestamp When the stake should be unlocked
    /// @param lock_multiplier Initial weight multiplier from the lock time component.
    struct LockedStake {
        bytes32 kek_id;
        uint256 start_timestamp;
        uint256 liquidity;
        uint256 ending_timestamp;
        uint256 lock_multiplier; // 6 decimals of precision. 1x = 1000000
    }

    function acceptOwnership() external;

    function addMigrator(address migrator_address) external;

    function calcCurCombinedWeight(
        address account
    ) external view returns (uint256 old_combined_weight, uint256 new_vefxs_multiplier, uint256 new_combined_weight);

    function calcCurrLockMultiplier(
        address account,
        uint256 stake_idx
    ) external view returns (uint256 midpoint_lock_multiplier);

    function combinedWeightOf(address account) external view returns (uint256);

    function controllerAddress() external view returns (address);

    function earned(address account) external view returns (uint256[] memory _rtnEarned);

    function farm_type() external view returns (string memory);

    function fraxAddress() external view returns (address);

    function fraxPerLPToken() external view returns (uint256);

    function getReward() external returns (uint256[] memory);

    function getRewardForDuration() external view returns (uint256[] memory _rtnRewardForDuration);

    function initializeDefault() external;

    function initiateWithdrawalOnlyShutdown() external;

    function isInitialized() external view returns (bool);

    function lastRewardPull() external view returns (uint256);

    function lastUpdateTime() external view returns (uint256);

    function lockAdditional(bytes32 kek_id, uint256 addl_liq) external;

    function lockLonger(bytes32 kek_id, uint256 new_ending_ts) external;

    function lockMultiplier(uint256 secs) external view returns (uint256);

    function lock_max_multiplier() external view returns (uint256);

    function lock_time_for_max_multiplier() external view returns (uint256);

    function lock_time_min() external view returns (uint256);

    function lockedLiquidityOf(address account) external view returns (uint256);

    function lockedStakes(
        address,
        uint256
    )
        external
        view
        returns (
            bytes32 kek_id,
            uint256 start_timestamp,
            uint256 liquidity,
            uint256 ending_timestamp,
            uint256 lock_multiplier
        );

    function lockedStakesOf(address account) external view returns (LockedStake[] memory);

    function migrationsOn() external view returns (bool);

    function migrator_stakeLocked_for(
        address staker_address,
        uint256 amount,
        uint256 secs,
        uint256 start_timestamp
    ) external;

    function migrator_withdraw_locked(address staker_address, bytes32 kek_id) external;

    function minVeFXSForMaxBoost(address account) external view returns (uint256);

    function nominateNewOwner(address _owner) external;

    function nominatedOwner() external view returns (address);

    function owner() external view returns (address);

    function periodFinish() external view returns (uint256);

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external;

    function removeMigrator(address migrator_address) external;

    function rewardPerToken() external view returns (uint256[] memory _rtnRewardsPerTokenStored);

    function rewardRates(uint256) external view returns (uint256);

    function rewardTokenAddrToIdx(address) external view returns (uint256);

    function rewardTokens(uint256) external view returns (address);

    function rewarder() external view returns (address);

    function rewardsCollectionPaused() external view returns (bool);

    function rewardsDuration() external view returns (uint256);

    function setController(address _controllerAddress) external;

    function setLockedStakeTimeForMinAndMaxMultiplier(
        uint256 _lock_time_for_max_multiplier,
        uint256 _lock_time_min
    ) external;

    function setMultipliers(
        uint256 _lock_max_multiplier,
        uint256 _vefxs_max_multiplier,
        uint256 _vefxs_per_frax_for_max_boost
    ) external;

    function setTimelock(address _new_timelock) external;

    function setVeFXS(address _vefxs_address) external;

    function stakeLocked(uint256 liquidity, uint256 secs) external;

    function stakerAllowMigrator(address migrator_address) external;

    function stakerDisallowMigrator(address migrator_address) external;

    function staker_allowed_migrators(address, address) external view returns (bool);

    function stakesUnlocked() external view returns (bool);

    function stakingPaused() external view returns (bool);

    function stakingToken() external view returns (address);

    function sync() external;

    function timelockAddress() external view returns (address);

    function toggleMigrations() external;

    function toggleRewardsCollection() external;

    function toggleStaking() external;

    function toggleWithdrawals() external;

    function totalCombinedWeight() external view returns (uint256);

    function totalLiquidityLocked() external view returns (uint256);

    function ttlRewsOwed(uint256) external view returns (uint256);

    function ttlRewsPaid(uint256) external view returns (uint256);

    function unlockStakes() external;

    function userStakedFrax(address account) external view returns (uint256);

    function valid_migrators(address) external view returns (bool);

    function veFXS() external view returns (address);

    function veFXSMultiplier(address account) external view returns (uint256);

    function vefxs_max_multiplier() external view returns (uint256);

    function vefxs_per_frax_for_max_boost() external view returns (uint256);

    function version() external view returns (string memory);

    function withdrawLocked(bytes32 kek_id, bool claim_rewards_deprecated) external;

    function withdrawalOnlyShutdown() external view returns (bool);

    function withdrawalsPaused() external view returns (bool);
}
