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
 * ========================= lFPISEvents ==============================
 * ====================================================================
 * Events for FPISLockere (lFPIS)
 * Frax Finance: https://github.com/FraxFinance
 */
interface IlFPISEvents {
    // ==============================================================================
    // Events
    // ==============================================================================
    /// @notice When the new prospective admin accepts being the admin.
    /// @param admin The address of the new admin
    event ApplyOwnership(address admin);

    /// @notice When a new admin is proposed by the existing admin. The prospective new admin will still have to accept via acceptTransferOwnership
    /// @param admin The prospective new admin
    event CommitOwnership(address admin);

    /// @notice When key functions are paused or unpaused
    /// @param isPaused The pause status that was set
    event ContractPause(bool isPaused);

    /// @notice When a lock is convertev to veFXS
    /// @param staker The address of the staker
    /// @param fpisAmount The amount of FPIS locked in the lock that was migrated
    /// @param fxsAmount The amount of FXS deposited to the new lock
    /// @param lFpisLockIndex The index of the lock in the lFPIS contract
    /// @param veFxsLockIndex The index of the lock in the veFXS contract
    event ConvertLockToVeFxs(
        address indexed staker,
        uint256 fpisAmount,
        uint256 fxsAmount,
        uint128 lFpisLockIndex,
        uint128 veFxsLockIndex
    );

    /// @notice When a deposit of FPIS has occured
    /// @param staker The address where the deposit is credited to
    /// @param payor The address actually paying for the deposit
    /// @param endingTimestamp The ending timestamp of the lock
    /// @param value The amount of FPIS to add
    /// @param depositType The type of the traction. DEPOSIT_FOR_TYPE = 0, CREATE_LOCK_TYPE = 1, INCREASE_LOCK_AMOUNT = 2, INCREASE_UNLOCK_TIME = 3;
    /// @param txTimestamp The timestamp that the deposit occured
    event Deposit(
        address indexed staker,
        address indexed payor,
        uint256 indexed endingTimestamp,
        uint256 value,
        uint128 depositType,
        uint256 txTimestamp
    );

    /// @notice When the emergency unlock is activated
    event EmergencyUnlockActivated();

    /// @notice When an address is set, or unset, as a Flox Contributor
    /// @param contributor The address
    /// @param isContributor If the address is or is not a Flox Contributor
    event FloxContributorUpdate(address indexed contributor, bool isContributor);

    /// @notice When the FPIS supply changes
    /// @param prevSupply The previous FPIS
    /// @param supply The new FPIS
    event Supply(uint256 prevSupply, uint256 supply);

    /// @notice When the address of a FPISLockerUtils contract is changed
    /// @param lFpisUtilsAddr Address of the FPISLockerUtils contract
    event LFpisUtilsContractUpdated(address lFpisUtilsAddr);

    /// @notice When FPIS is withdrawn
    /// @param staker The address of the staker that is withdrawing
    /// @param recipient The recipient of the withdrawn tokens
    /// @param value The amount of FPIS withdrawn
    /// @param ts The timestamp of the withdrawal
    event Withdraw(address indexed staker, address indexed recipient, uint256 value, uint256 ts);

    /// @notice When lFPIS is withdrawn as FXS
    /// @param staker The address of the staker that is withdrawing
    /// @param recipient The recipient of the withdrawn tokens
    /// @param fpisValue The amount of FPIS that was deposited in the lock
    /// @param fxsValue The amount of FXS that was withdrawn
    event WithdrawAsFxs(address indexed staker, address indexed recipient, uint256 fpisValue, uint256 fxsValue);
}
