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
 * ========================= IVestedFXSUtils ==========================
 * ====================================================================
 * Interface for helper and utility functions for VestedFXS
 * Frax Finance: https://github.com/FraxFinance
 */
import { IveFXSStructs } from "../VestedFXS/IveFXSStructs.sol";

interface IVestedFXSUtils is IveFXSStructs {
    function getDetailedUserLockInfo(address user) external view returns (DetailedUserLockInfo memory);

    function getDetailedUserLockInfoBulk(address[] memory users) external view returns (DetailedUserLockInfo[] memory);

    function getLongestLock(address user) external view returns (LockedBalance memory, uint128);

    function getLongestLockBulk(address[] memory users) external view returns (LongestLock[] memory);

    function getCrudeExpectedVeFXSOneLock(int128 _fxsAmount, uint128 _lockSecsU128) external view returns (uint256);

    function getCrudeExpectedVeFXSMultiLock(
        int128[] memory _fxsAmounts,
        uint128[] memory _lockSecsU128
    ) external view returns (uint256);

    function getCrudeExpectedVeFXSUser(address _user) external view returns (uint256);
}
