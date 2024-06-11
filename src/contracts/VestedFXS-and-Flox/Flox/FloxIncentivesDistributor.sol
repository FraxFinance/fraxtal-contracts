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
 * =============================== veFXS ==============================
 * ====================================================================
 * Frax Finance: https://github.com/FraxFinance
 */
import "./IFloxEvents.sol";
import "./IFloxStructs.sol";
import "../interfaces/IVestedFXS.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/console2.sol";

/**
 * @title FloxIncentivesDistributor
 * @author Frax Finance
 * @notice A smart contract used to distribute the Flox blockspace incentives.
 */
contract FloxIncentivesDistributor is IFloxEvents, IFloxStructs {
    IVestedFXS public veFXS;
    IERC20 public fxs;

    uint128 public constant MAXTIME_UINT128 = 4 * 365 * 86_400; // 4 years
    uint128 public newLockDuration;

    uint128 public nextBlock;
    uint256 public incentivesEpoch;

    address public admin;
    address public futureAdmin;

    mapping(address => bool) public isContributor; // contributor => isContributor
    mapping(uint256 => IncentivesStats) public incentivesStats; // epoch => stats

    /**
     * @notice Intialize the FloxIncentivesDistributor
     * @dev The caller of this function will become the initial admin.
     * @dev Upon initialization, the approval for spending the FXS tokens by the veFXS smart contract is set to the
     *  maximum value.
     * @param _veFXS The address of the veFXS contract
     * @param _fxs The address of the FXS contract
     */
    constructor(address _veFXS, address _fxs) {
        admin = msg.sender;
        veFXS = IVestedFXS(_veFXS);
        fxs = IERC20(_fxs);

        fxs.approve(_veFXS, type(uint256).max);

        newLockDuration = MAXTIME_UINT128;
        emit NewLockDurationUpdated(newLockDuration);
    }

    /**
     * @notice Propose a new admin.
     * @dev Will revert if the caller is not the current admin.
     * @param _admin Address of the new admin
     */
    function proposeNewAdmin(address _admin) external {
        if (msg.sender != admin) revert NotAdmin();
        if (_admin == address(0)) revert CannotAppointZeroAddress();

        futureAdmin = _admin;

        emit FutureAdminProposed(admin, futureAdmin);
    }

    /**
     * @notice Accept the admin role.
     * @dev Will revert if the caller is not the future admin
     */
    function acceptAdmin() external {
        if (msg.sender != futureAdmin) revert NotFutureAdmin();

        address oldAdmin = admin;
        admin = futureAdmin;
        futureAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
    }

    /**
     * @notice Add a contributor.
     * @dev Can only be called by the admin.
     * @param _contributor The address of the contributor to add
     */
    function addContributor(address _contributor) external {
        if (msg.sender != admin) revert NotAdmin();
        if (isContributor[_contributor]) revert ContributorAlreadyAdded();
        if (_contributor == address(0)) revert CannotAppointZeroAddress();

        isContributor[_contributor] = true;

        emit ContributorAdded(_contributor);
    }

    /**
     * @notice Remove a contributor.
     * @dev Can only be called by the admin.
     * @param _contributor The address of the contributor to remove
     */
    function removeContributor(address _contributor) external {
        if (msg.sender != admin) revert NotAdmin();
        if (!isContributor[_contributor]) revert ContributorAlreadyRemoved();

        isContributor[_contributor] = false;

        emit ContributorRemoved(_contributor);
    }

    /**
     * @notice Set the new duration of locks created through this smart contract.
     * @dev Can only be called by the admin.
     * @param _newLockDuration The new lock duration
     */
    function setNewLockDuration(uint128 _newLockDuration) external {
        if (msg.sender != admin) revert NotAdmin();
        if (_newLockDuration > MAXTIME_UINT128) revert AttemptingToSetTooBigLockTime();

        newLockDuration = _newLockDuration;

        emit NewLockDurationUpdated(_newLockDuration);
    }

    /**
     * @notice Allocate incentives to existing locks.
     * @dev Can only be called by a contributor.
     * @dev The `IncentivesInput` struct consists of:
     *  [
     *    recipient: address of the recipient,
     *    lockIndex: index of the lock to deposit to,
     *    amount: amount of FXS to deposit
     *  ]
     * @param input An array of IncentivesInput structs
     */
    function allocateIncentivesToExistingLocks(IncentivesInput[] memory input) external {
        if (!isContributor[msg.sender]) revert NotAFloxContributor();

        uint256 incentivesDistributed;
        uint256 recipients;

        for (uint256 i; i < input.length; ) {
            veFXS.depositFor(input[i].recipient, input[i].amount, input[i].lockIndex);

            emit IncentiveAllocated(input[i].recipient, input[i].amount, input[i].lockIndex);

            unchecked {
                incentivesDistributed += input[i].amount; // This is safe because the total amount of incentives distributed will never
                ++recipients; // overflow due to gas constraints of the call (there is no way that a single allocation
                ++i; // contains more than 2^256 - 1 FXS or recipients)
            }
        }

        incentivesStats[incentivesEpoch].totalIncentvesDistributed += incentivesDistributed;
        incentivesStats[incentivesEpoch].totalRecipients += recipients;
    }

    /**
     * @notice Allocate incentives to new locks.
     * @dev Can only be called by a contributor.
     * @dev The `IncentivesInput` struct consists of:
     *  [
     *    recipient: address of the recipient,
     *    lockIndex: index of the lock to deposit to,
     *    amount: amount of FXS to deposit
     *  ]
     * @dev The lock index will be ignored and a new lock will be created.
     * @param input An array of IncentivesInput structs
     */
    function allocateIncentivesToNewLocks(IncentivesInput[] memory input) external {
        if (!isContributor[msg.sender]) revert NotAFloxContributor();

        uint256 incentivesDistributed;
        uint256 recipients;
        uint128 createdLock;

        uint128 currentLockTime = uint128(block.timestamp) + newLockDuration;

        for (uint256 i; i < input.length; ) {
            (createdLock, ) = veFXS.createLock(input[i].recipient, input[i].amount, currentLockTime);

            emit IncentiveAllocated(input[i].recipient, input[i].amount, createdLock);

            unchecked {
                incentivesDistributed += input[i].amount; // This is safe because the total amount of incentives distributed will never
                ++recipients; // overflow due to gas constraints of the call (there is no way that a single allocation
                ++i; // contains more than 2^256 - 1 FXS or recipients)
            }
        }

        incentivesStats[incentivesEpoch].totalIncentvesDistributed += incentivesDistributed;
        incentivesStats[incentivesEpoch].totalRecipients += recipients;
    }

    /**
     * @notice Provide the stats for an epoch.
     * @dev Can only be called by a contributor.
     * @dev Once the stats for an epoch are provided, the epoch is sealed and all of the allocations will be tracked in
     *  the following epoch.
     * @param _startBlock The start block of the epoch
     * @param _endBlock The stop block of the epoch
     * @param _proof The Keccak256 hash of the full incentives allocation struct
     */
    function provideEpochStats(uint128 _startBlock, uint128 _endBlock, bytes32 _proof) external {
        if (!isContributor[msg.sender]) revert NotAFloxContributor();
        if (_startBlock != nextBlock) revert IncentivesEpochStartBlockMismatch(_startBlock, nextBlock);
        if (_startBlock >= _endBlock) revert EndBlockBeforeStartBlock();

        incentivesStats[incentivesEpoch].startBlock = _startBlock;
        incentivesStats[incentivesEpoch].endBlock = _endBlock;
        incentivesStats[incentivesEpoch].incentivesAllocationStructProof = _proof;

        IncentivesStats memory stats = incentivesStats[incentivesEpoch];

        nextBlock = _endBlock + 1;

        unchecked {
            ++incentivesEpoch;
        }

        emit IncentiveStatsUpdate(
            incentivesEpoch - 1,
            stats.startBlock,
            stats.endBlock,
            stats.totalIncentvesDistributed,
            stats.totalRecipients,
            stats.incentivesAllocationStructProof
        );
    }

    // ==============================================================================
    // Errors
    // ==============================================================================

    error AttemptingToSetTooBigLockTime();
    error CannotAppointZeroAddress();
    error ContributorAlreadyAdded();
    error ContributorAlreadyRemoved();
    error EndBlockBeforeStartBlock();
    error IncentivesEpochStartBlockMismatch(uint128 attemptedStartBlock, uint128 requiredStartBlock);
    error NotAdmin();
    error NotAFloxContributor();
    error NotFutureAdmin();
}
