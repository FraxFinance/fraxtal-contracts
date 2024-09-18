// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IsFrax {
    /// @notice Information about the current rewards cycle
    struct RewardsCycleData {
        uint40 cycleEnd; // Timestamp of the end of the current rewards cycle
        uint40 lastSync; // Timestamp of the last time the rewards cycle was synced
        uint216 rewardCycleAmount; // Amount of rewards to be distributed in the current cycle
    }

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PRECISION() external view returns (uint256);

    function REWARDS_CYCLE_LENGTH() external view returns (uint256);

    function UNDERLYING_PRECISION() external view returns (uint256);

    function acceptTransferTimelock() external;

    function allowance(address, address) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function asset() external view returns (address);

    function balanceOf(address) external view returns (uint256);

    function calculateRewardsToDistribute(
        RewardsCycleData memory _rewardsCycleData,
        uint256 _deltaTime
    ) external view returns (uint256 _rewardToDistribute);

    function convertToAssets(uint256 shares) external view returns (uint256);

    function convertToShares(uint256 assets) external view returns (uint256);

    function decimals() external view returns (uint8);

    function deposit(uint256 _assets, address _receiver) external returns (uint256 _shares);

    function depositWithSignature(
        uint256 _assets,
        address _receiver,
        uint256 _deadline,
        bool _approveMax,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external returns (uint256 _shares);

    function lastRewardsDistribution() external view returns (uint256);

    function maxDeposit(address) external view returns (uint256);

    function maxDistributionPerSecondPerAsset() external view returns (uint256);

    function maxMint(address) external view returns (uint256);

    function maxRedeem(address owner) external view returns (uint256);

    function maxWithdraw(address owner) external view returns (uint256);

    function mint(uint256 _shares, address _receiver) external returns (uint256 _assets);

    function name() external view returns (string memory);

    function nonces(address) external view returns (uint256);

    function pendingTimelockAddress() external view returns (address);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function previewDeposit(uint256 assets) external view returns (uint256);

    function previewDistributeRewards() external view returns (uint256 _rewardToDistribute);

    function previewMint(uint256 shares) external view returns (uint256);

    function previewRedeem(uint256 shares) external view returns (uint256);

    function previewSyncRewards() external view returns (RewardsCycleData memory _newRewardsCycleData);

    function previewWithdraw(uint256 assets) external view returns (uint256);

    function pricePerShare() external view returns (uint256 _pricePerShare);

    function redeem(uint256 _shares, address _receiver, address _owner) external returns (uint256 _assets);

    function renounceTimelock() external;

    function rewardsCycleData() external view returns (uint40 cycleEnd, uint40 lastSync, uint216 rewardCycleAmount);

    function setMaxDistributionPerSecondPerAsset(uint256 _maxDistributionPerSecondPerAsset) external;

    function storedTotalAssets() external view returns (uint256);

    function symbol() external view returns (string memory);

    function syncRewardsAndDistribution() external;

    function timelockAddress() external view returns (address);

    function totalAssets() external view returns (uint256 _totalAssets);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function transferTimelock(address _newTimelock) external;

    function withdraw(uint256 _assets, address _receiver, address _owner) external returns (uint256 _shares);
}
