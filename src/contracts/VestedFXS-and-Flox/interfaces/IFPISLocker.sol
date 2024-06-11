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
 * ============================ IFPISLocker ============================
 * ====================================================================
 * Frax Finance: https://github.com/FraxFinance
 */
import "src/contracts/VestedFXS-and-Flox/FPISLocker/IlFPISStructs.sol";

interface IFPISLocker is IlFPISStructs {
    function MAXTIME_INT128() external view returns (int128);

    function MAXTIME_UINT256() external view returns (uint256);

    function MAX_CONTRIBUTOR_LOCKS() external view returns (uint8);

    function MAX_USER_LOCKS() external view returns (uint8);

    function MULTIPLIER_UINT256() external view returns (uint256);

    function VOTE_WEIGHT_MULTIPLIER_INT128() external view returns (int128);

    function VOTE_WEIGHT_MULTIPLIER_UINT256() external view returns (uint256);

    function VOTE_END_POWER_BASIS_POINTS_INT128() external view returns (int128);

    function VOTE_END_POWER_BASIS_POINTS_UINT256() external view returns (uint256);

    function MAX_BASIS_POINTS_INT128() external view returns (int128);

    function MAX_BASIS_POINTS_UINT256() external view returns (uint256);

    function FXS_CONVERSION_START_TIMESTAMP() external view returns (uint256);

    function WEEK_UINT128() external view returns (uint128);

    function WEEK_UINT256() external view returns (uint256);

    function acceptTransferOwnership() external;

    function admin() external view returns (address);

    function balanceOf(address _addr) external view returns (uint256 _balance);

    function balanceOfAllLocksAtBlock(address _addr, uint256 _block) external view returns (uint256 _balance);

    function balanceOfAllLocksAtTime(address _addr, uint256 _timestamp) external view returns (uint256 _balance);

    function balanceOfAt(address _addr, uint256 _block) external view returns (uint256 _balance);

    function balanceOfOneLockAtBlock(
        address _addr,
        uint128 _lockIndex,
        uint256 _block
    ) external view returns (uint256 _balance);

    function balanceOfOneLockAtTime(
        address _addr,
        uint128 _lockIndex,
        uint256 _timestamp
    ) external view returns (uint256 _balance);

    function checkpoint() external;

    function commitTransferOwnership(address _addr) external;

    function createLock(address _addr, uint256 _value, uint128 _unlockTime) external returns (uint128);

    function decimals() external view returns (uint256);

    function depositFor(address _addr, uint256 _value, uint128 _lockIndex) external;

    function emergencyUnlockActive() external view returns (bool);

    function epoch() external view returns (uint256);

    function findBlockEpoch(uint256 _block, uint256 _maxEpoch) external view returns (uint256);

    function floxContributors(address) external view returns (bool);

    function futureAdmin() external view returns (address);

    function getLastUserSlope(address _addr, uint128 _lockIndex) external view returns (int128);

    function increaseAmount(uint256 _value, uint128 _lockIndex) external;

    function increaseUnlockTime(uint128 _unlockTime, uint128 _lockIndex) external;

    function indicesToIds(address, uint128) external view returns (uint256);

    function isPaused() external view returns (bool);

    function locked(address, uint256) external view returns (int128 amount, uint128 end);

    function lockedById(address _addr, uint256 _id) external view returns (LockedBalance memory _lockInfo);

    function lockedByIndex(address _addr, uint128 _index) external view returns (LockedBalance memory _lockInfo);

    function lockedEnd(address _addr, uint128 _index) external view returns (uint256);

    function name() external view returns (string memory);

    function nextId(address) external view returns (uint256);

    function numLocks(address) external view returns (uint128);

    function pointHistory(
        uint256
    ) external view returns (int128 bias, int128 slope, uint256 ts, uint256 blk, uint256 fpisAmt);

    function recoverIERC20(address _tokenAddr, uint256 _amount) external;

    function setFloxContributor(address _floxContributor, bool _isFloxContributor) external;

    function setLVPIDUtils(address _lFpisUtilsAddr) external;

    function slopeChanges(uint256) external view returns (int128);

    function supply() external view returns (uint256);

    function supplyAt(Point memory _point, uint256 _t) external view returns (uint256);

    function symbol() external view returns (string memory);

    function toggleContractPause() external;

    function activateEmergencyUnlock() external;

    function fpis() external view returns (address);

    function totalFPISSupply() external view returns (uint256);

    function totalFPISSupplyAt(uint256 _block) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalSupply(uint256 _timestamp) external view returns (uint256);

    function totalSupplyAt(uint256 _block) external view returns (uint256);

    function userPointEpoch(address, uint256) external view returns (uint256);

    function userPointHistory(
        address,
        uint256,
        uint256
    ) external view returns (int128 bias, int128 slope, uint256 ts, uint256 blk, uint256 fpisAmt);

    function userPointHistoryTs(address _addr, uint128 _lockIndex, uint256 _idx) external view returns (uint256);

    function lFpisUtils() external view returns (address);

    function version() external view returns (string memory);

    function withdraw(uint128 _lockIndex) external;
}
