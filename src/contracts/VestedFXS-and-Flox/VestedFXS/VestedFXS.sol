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
 * ============================= VestedFXS ============================
 * ====================================================================
 * Solidity conversion of Frax's ETH Mainnet veFXS.vy
 * Frax Finance: https://github.com/FraxFinance
 */

/**
 *
 * Voting escrow to have time-weighted votes
 * Votes have a weight depending on time, so that users are committed
 * to the future of (whatever they are voting for).
 * The weight in this implementation is linear, and lock cannot be more than maxtime:
 * w ^
 * 1 +        /
 *   |      /
 *   |    /
 *   |  /
 *   |/
 * 0 +--------+------> time
 *       maxtime (4 years?)
 */
/* solhint-disable max-line-length, not-rely-on-time */
import { ReentrancyGuard } from "@openzeppelin-4/contracts/security/ReentrancyGuard.sol";
import { IERC20Metadata } from "@openzeppelin-4/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { ERC20Burnable } from "@openzeppelin-4/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { IveFXSEvents } from "./IveFXSEvents.sol";
import { IveFXSStructs } from "./IveFXSStructs.sol";
import { VestedFXSUtils } from "./VestedFXSUtils.sol";
import "forge-std/console2.sol";

/**
 * @title Vote Escrowed FXS (veFXS)
 * @author Frax Finance
 * @notice Votes have a weight depending on time, so that users are
 * committed to the future of (whatever they are voting for)
 * @dev Vote weight decays linearly over time. Lock time cannot be
 * more than `MAXTIME_INT128` (4 years).
 * @dev Original idea and credit:
 * Curve Finance's veCRV
 * https://resources.curve.fi/faq/vote-locking-boost
 * https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/VotingEscrow.vy
 * veFXS is basically a fork, with the key difference that 1 FXS locked for 1 second would be ~ 1 veFXS,
 * As opposed to ~ 0 veFXS (as it is with veCRV)
 * @dev Frax Reviewer(s) / Contributor(s)
 * Jan Turk: https://github.com/ThunderDeliverer
 * Travis Moore: https://github.com/FortisFortuna
 * Sam Kazemian: https://github.com/samkazemian
 * Carter Carlson: https://github.com/pegahcarter
 */
contract VestedFXS is ReentrancyGuard, IveFXSStructs, IveFXSEvents {
    // ==============================================================================
    // Constants
    // ==============================================================================

    // _depositFor codes
    // -------------------------------------------

    /// @notice _depositFor code for depositFor
    uint128 private constant DEPOSIT_FOR_TYPE = 0;

    /// @notice _depositFor code for createLock
    uint128 private constant CREATE_LOCK_TYPE = 1;

    /// @notice _depositFor code for increaseAmount
    uint128 private constant INCREASE_LOCK_AMOUNT = 2;

    /// @notice _depositFor code for increaseUnlockTime
    uint128 private constant INCREASE_UNLOCK_TIME = 3;

    // Other constants
    // -------------------------------------------

    /// @notice Minimum size you can createLock or increaseAmount
    /// @dev Meant to help prevent rounding issues
    uint256 public constant MIN_LOCK_AMOUNT = 1000 gwei; // 0.000001e18

    /// @notice Multiplier used in various math operations
    uint256 public constant MULTIPLIER_UINT256 = 10 ** 18;

    /// @notice One week, in uint256 seconds
    uint256 public constant WEEK_UINT256 = 7 * 86_400; // all future times are rounded by week

    /// @notice One week, in uint128 seconds
    uint128 public constant WEEK_UINT128 = 7 * 86_400; // all future times are rounded by week

    /// @notice Maximum lock time, in int128 seconds
    int128 public constant MAXTIME_INT128 = 4 * 365 * 86_400; // 4 years

    /// @notice Maximum lock time, in uint256 seconds
    uint256 public constant MAXTIME_UINT256 = 4 * 365 * 86_400; // 4 years

    /// @notice Vote weight multiplier, in int128
    int128 public constant VOTE_WEIGHT_MULTIPLIER_INT128 = 4 - 1; // 4x gives 300% boost at 4 years

    /// @notice Vote weight multiplier, in uint256
    uint256 public constant VOTE_WEIGHT_MULTIPLIER_UINT256 = 4 - 1; // 4x gives 300% boost at 4 years

    /// @notice The maximum active locks a user can create for themselves
    /// @dev If the user already has 8 locks (and some are created by Flox contributors), they can still create a new lock
    uint8 public constant MAX_USER_LOCKS = 8;

    /// @notice The maximum total number of active locks Flox contributors can create for a single user
    /// @dev If the user already has 8 locks (and some are created by the user), the Flox contributor can still create a new lock
    uint8 public constant MAX_CONTRIBUTOR_LOCKS = 8;

    // ==============================================================================
    // MUTABLE STATE VARIABLES
    // ==============================================================================

    /// @notice The VestedFXSUtils contract with extra helper functions
    VestedFXSUtils public veFxsUtils;

    /// @notice Whether key functions are paused
    bool public isPaused;

    /// @notice The address of the token being staked
    address public token;

    /// @notice The total FXS supply being locked. NOT the total veFXS. Use totalSupply() for that
    uint256 public supply;

    /// @notice Lock info for a given user and lock id. user -> ID -> LockedBalance
    mapping(address user => mapping(uint256 id => LockedBalance lockedInfo)) public locked;

    /// @notice Helper function to get a lock ID from a lock index. user -> index -> ID
    mapping(address user => mapping(uint128 index => uint256 id)) public indicesToIds;

    /// @notice Helper function to get a lock index from a lock ID. user -> ID -> LockIdInfo.
    /// @dev Be careful and check isInUse beforehand to avoid index 0 vs null. If in doubt, use getLockIndexById
    mapping(address user => mapping(uint256 id => LockIdIdxInfo info)) private idsToIndices;

    /// @notice The indicator of whether a lock was created by a Flox contributor (`true`) or the user (`false`)
    mapping(address user => mapping(uint256 id => bool createdByFloxContributor)) public isLockCreatedByFloxContributor;

    /// @notice The number of user's currently active locks created by the user
    mapping(address user => uint8 numberOfLocks) public numberOfUserCreatedLocks;

    /// @notice The number of user's currently active locks created by Flox contributors
    mapping(address user => uint8 numberOfLocks) public numberOfFloxContributorCreatedLocks;

    /// @notice The next lock ID to use for a given user. user -> next ID
    mapping(address user => uint256 nextId) public nextId;

    // TODO: Check numLocks = 0 wrong assertions and weird scenarios
    /// @notice The number of locks a user has
    mapping(address user => uint128 numLocks) public numLocks;

    /// @notice The current epoch you are in.
    uint256 public epoch;

    /// @notice The contract's Point information at a given epoch. epoch -> Point
    mapping(uint256 epoch => Point) public pointHistory;

    /// @notice A user's Point information at a given lock id and epoch. user -> ID -> epoch -> Point
    mapping(address user => mapping(uint256 id => mapping(uint256 epoch => Point point))) public userPointHistory;

    /// @notice A user's epoch for a given lock id. user address -> ID -> user's epoch
    mapping(address user => mapping(uint256 id => uint256 epoch)) public userPointEpoch;

    /// @notice Slope changes at a given time. time -> signed slope change
    mapping(uint256 time => int128 slopeChange) public slopeChanges;

    /// @notice If the emergency unlock is active
    bool public emergencyUnlockActive;

    // ERC20 related
    string public name;
    string public symbol;
    string public version;
    uint256 public decimals;

    /// @notice Admin of this contract
    address public admin;

    /// @notice Future admin of this contract, if applicable
    address public futureAdmin;

    /// @notice If a given address is a Flox Contributor. contributor => isContributor
    mapping(address contributor => bool isContributor) public floxContributors;

    /// @dev reserve extra storage for future upgrades
    uint256[50] private __gap;

    // ==============================================================================
    // CONSTRUCTOR
    // ==============================================================================

    constructor() {}

    /**
     * @notice Initialize contract
     * @dev Same values are set to proxy and implementation.
     * @param _admin Initial admin of the smart contract
     * @param _tokenAddr `FXS` token address
     * @param _name Token name
     * @param _symbol Token symbol
     * @param _version Contract version - required for Aragon compatibility
     */
    function initialize(
        address _admin,
        address _tokenAddr,
        string memory _name,
        string memory _symbol,
        string memory _version
        // bool _setZerothPointHistory
    ) public {
        // Safety checks - no validation on admin in case this is initialized without admin
        if (_tokenAddr == address(0) || token != address(0)) {
            revert InitializeFailed();
        }

        // Set the admin
        admin = _admin;

        // // (Optional) Initialize the 0th pointHistory
        // if (_setZerothPointHistory) {
        //     pointHistory[0].blk = block.number;
        //     pointHistory[0].ts = block.timestamp;
        //     pointHistory[0].fxsAmt = 0;
        // }

        // Initialize other variables
        name = _name;
        symbol = _symbol;
        version = _version;

        // Set up decimals
        uint256 _decimals = IERC20Metadata(_tokenAddr).decimals();
        if (_decimals > 255) revert DecimalsExceedMaximumValue();

        token = _tokenAddr;
        decimals = uint8(_decimals);
    }

    // ==============================================================================
    // PUBLIC/EXTERNAL VIEWS
    // ==============================================================================

    /**
     * The following ERC20/minime-compatible methods are not real balanceOf and supply!
     * They measure the weights for the purpose of voting, so they don't represent
     * real coins.
     * FRAX adds minimal 1-1 FXS/veFXS, as well as a voting multiplier
     */

    /**
     * @notice Get current voting power (veFXS) of `_addr`. Uses all locks.
     * @dev If `emergencyUnlock` is active, the FXS locked in all of the `_addr`'s locks is returned. If an external
     *  smart contract is using this function, make sure that it can handle this case.
     * @param _addr Address of the user
     * @return _balance Total voting power (veFXS) of the user
     */
    function balanceOf(address _addr) public view returns (uint256 _balance) {
        return balanceOfAllLocksAtTime(_addr, block.timestamp);
    }

    /**
     * @notice Same as balanceOfAllLocksAtBlock for backwards compatibility. Measures the total voting power (veFXS) of
     *  `_addr` at `_block`.
     * @dev If `emergencyUnlock` is active, the FXS locked in all of the `_addr`'s locks is returned. If an external
     *  smart contract is using this function, make sure that it can handle this case.
     * @param _addr Address of the user
     * @param _block Block number at which to measure voting power
     * @return _balance Total voting power (veFXS) of the user
     */
    function balanceOfAt(address _addr, uint256 _block) public view returns (uint256 _balance) {
        return balanceOfAllLocksAtBlock(_addr, _block);
    }

    /**
     * @notice Measure the total voting power (veFXS) of `_addr` at `_block`.
     * @dev If `emergencyUnlock` is active, the FXS locked in all of the `_addr`'s locks is returned. If an external
     *  smart contract is using this function, make sure that it can handle this case.
     * @param _addr Address of the user
     * @param _block Block number at which to measure voting power
     * @return _balance Total voting power (veFXS) of the user
     */
    function balanceOfAllLocksAtBlock(address _addr, uint256 _block) public view returns (uint256 _balance) {
        // Get the total number of locks
        uint128 _numLocks = numLocks[_addr];

        // Loop through all of the locks
        for (uint128 i = 0; i < _numLocks; ) {
            _balance += balanceOfOneLockAtBlock(_addr, i, _block);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Get voting power (veFXS) of `_addr` at a specific time.
     * @dev If `emergencyUnlock` is active, the FXS locked in all of the `_addr`'s locks is returned. If an external
     *  smart contract is using this function, make sure that it can handle this case.
     * @param _addr Address of the user
     * @param _timestamp Epoch time to return the voting power at
     * @return _balance Total voting power (veFXS) of the user
     */
    function balanceOfAllLocksAtTime(address _addr, uint256 _timestamp) public view returns (uint256 _balance) {
        // Get the total number of locks
        uint128 _numLocks = numLocks[_addr];

        // Loop through all of the locks
        for (uint128 i = 0; i < _numLocks; ) {
            _balance += balanceOfOneLockAtTime(_addr, i, _timestamp);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Measure voting power (veFXS) of `addr`'s specific lock at block height `_block`
     * @dev If `emergencyUnlock` is active, the FXS locked in the lock is returned. If an external smart contract is
     *  using this function, make sure that it can handle this case.
     * @param _addr User's wallet address
     * @param _lockIndex Index of the user's lock that is getting measured
     * @param _block Block to calculate the voting power at
     * @return _balance Total voting power (veFXS) of the user
     */
    function balanceOfOneLockAtBlock(
        address _addr,
        uint128 _lockIndex,
        uint256 _block
    ) public view returns (uint256 _balance) {
        if (emergencyUnlockActive) {
            return uint256(uint128(locked[_addr][indicesToIds[_addr][_lockIndex]].amount));
        }
        if (_block > block.number) revert InvalidBlockNumber();

        uint256 lockId = indicesToIds[_addr][_lockIndex];

        // Binary search
        uint256 _min = 0;
        uint256 _max = userPointEpoch[_addr][lockId];
        for (uint256 i; i < 128; ) {
            // Will be always enough for 128-bit numbers
            if (_min >= _max) {
                break;
            }
            uint256 _mid = (_min + _max + 1) / 2;
            if (userPointHistory[_addr][lockId][_mid].blk <= _block) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }

            unchecked {
                ++i;
            }
        }

        Point memory upoint = userPointHistory[_addr][lockId][_min];

        uint256 maxEpoch = epoch;
        uint256 _epoch = findBlockEpoch(_block, maxEpoch);
        Point memory point0 = pointHistory[_epoch];
        uint256 dBlock = 0;
        uint256 dT = 0;
        if (_epoch < maxEpoch) {
            Point memory point1 = pointHistory[_epoch + 1];
            dBlock = point1.blk - point0.blk;
            dT = point1.ts - point0.ts;
        } else {
            dBlock = block.number - point0.blk;
            dT = block.timestamp - point0.ts;
        }
        uint256 blockTime = point0.ts;
        if (dBlock != 0) {
            blockTime += (dT * (_block - point0.blk)) / dBlock;
        }

        upoint.bias -= upoint.slope * int128(int256(blockTime - upoint.ts));

        // Check bias
        if (upoint.bias < int256(upoint.fxsAmt)) _balance = upoint.fxsAmt;
        else _balance = uint256(uint128(upoint.bias));
    }

    /**
     * @notice Find the latest epoch at a past timestamp
     * @param _addr User wallet address
     * @param _lockId ID of the user's lock that is getting measured
     * @param _ts The timestamp to check at
     * @return _min The latest user's epoch assume you traveled back in time to the timestamp
     */
    function findUserTimestampEpoch(address _addr, uint256 _lockId, uint256 _ts) public view returns (uint256 _min) {
        // Get the most current user's epoch (not the contract epoch)
        uint256 _max = userPointEpoch[_addr][_lockId];

        // Find the latest epoch as of the time _ts
        for (uint256 i; i < 128; ) {
            if (_min >= _max) {
                break;
            }
            uint256 mid = (_min + _max + 1) / 2;
            if (userPointHistory[_addr][_lockId][mid].ts <= _ts) {
                _min = mid;
            } else {
                _max = mid - 1;
            }

            unchecked {
                ++i;
            }
        }
        return _min;
    }

    /**
     * @notice Get the voting power (veFXS) for `addr`'s specific lock at the specified time
     * @dev If `emergencyUnlock` is active, the FXS locked in the lock is returned. If an external smart contract is
     *  using this function, make sure that it can handle this case.
     * @param _addr User wallet address
     * @param _lockIndex Index of the user's lock that is getting measured
     * @param _timestamp Epoch time to return voting power at
     * @return _balance Total voting power (veFXS) of the user
     */
    function balanceOfOneLockAtTime(
        address _addr,
        uint128 _lockIndex,
        uint256 _timestamp
    ) public view returns (uint256 _balance) {
        if (emergencyUnlockActive) {
            return uint256(uint128(locked[_addr][indicesToIds[_addr][_lockIndex]].amount));
        }

        _timestamp = _timestamp == 0 ? block.timestamp : _timestamp; // Default to current timestamp if _timestamp is 0
        uint256 _lockId = indicesToIds[_addr][_lockIndex];
        // uint256 _epoch = userPointEpoch[_addr][_lockId];
        uint256 _epoch = findUserTimestampEpoch(_addr, _lockId, _timestamp);

        // if (_epoch == 0 || locked[_addr][_lockId].end == 0) {
        //     return 0;
        // } else {
        if (_epoch == 0) {
            return 0;
        } else {
            // Yearn Fix: https://etherscan.io/address/0x90c1f9220d90d3966fbee24045edd73e1d588ad5#code
            // Extra Finance: https://optimistic.etherscan.io/address/0xe0bec4f45aef64cec9dcb9010d4beffb13e91466#code
            // Point memory lastPoint = userPointHistory[_addr][_lockId][_epoch];
            Point memory lastPoint;
            // {
            //     uint256 _min = 0;
            //     uint256 _max = userPointEpoch[_addr][_lockId];
            //     for (uint256 i; i < 128; ) {
            //         // Will be always enough for 128-bit numbers
            //         if (_min >= _max) {
            //             break;
            //         }
            //         uint256 _mid = (_min + _max + 1) / 2;
            //         if (userPointHistory[_addr][_lockId][_mid].ts <= _timestamp) {
            //             _min = _mid;
            //         } else {
            //             _max = _mid - 1;
            //         }

            //         unchecked {
            //             ++i;
            //         }
            //     }
            //     lastPoint = userPointHistory[_addr][_lockId][_min];
            lastPoint = userPointHistory[_addr][_lockId][_epoch];
            // }

            lastPoint.bias -= lastPoint.slope * int128(uint128(_timestamp - lastPoint.ts));
            if (lastPoint.bias < 0) {
                lastPoint.bias = 0;
            }

            _balance = uint256(uint128(lastPoint.bias)); // Original from veCRV
            if (_balance < lastPoint.fxsAmt) {
                _balance = lastPoint.fxsAmt;
            }
        }
    }

    /**
     * @notice Get the total amount of FXS locked for a user
     * @param _addr User account address
     * @return _balanceOfLockedFxs The total amount of FXS locked for the user
     */
    function balanceOfLockedFxs(address _addr) public view returns (uint256 _balanceOfLockedFxs) {
        uint128 _numLocks = numLocks[_addr];

        for (uint128 i = 0; i < _numLocks; ) {
            _balanceOfLockedFxs += uint256(uint128(locked[_addr][indicesToIds[_addr][i]].amount));

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Binary search to estimate timestamp for block number
     * @param _block Block to find
     * @param _maxEpoch Don't go beyond this epoch
     * @return Approximate timestamp for block
     */
    function findBlockEpoch(uint256 _block, uint256 _maxEpoch) public view returns (uint256) {
        // Binary search
        uint256 _min = 0;
        uint256 _max = _maxEpoch;
        uint256 _mid;
        for (uint256 i; i < 128; ) {
            // Will be always enough for 128-bit numbers
            if (_min >= _max) {
                break;
            }
            _mid = (_min + _max + 1) / 2;
            if (pointHistory[_mid].blk <= _block) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }

            unchecked {
                ++i;
            }
        }
        return _min;
    }

    /**
     * @notice Get the earliest and latest timestamps createLock can use
     * @return _earliestLockEnd Earliest timestamp
     * @return _latestLockEnd Latest timestamp
     * @dev The truncation in these operations is desired
     */
    function getCreateLockTsBounds() external view returns (uint128 _earliestLockEnd, uint128 _latestLockEnd) {
        _earliestLockEnd = WEEK_UINT128 + ((uint128(block.timestamp) / WEEK_UINT128) * WEEK_UINT128); // Cannot be in the current epoch week
        // _latestLockEnd = (WEEK_UINT128 * (uint128(block.timestamp) + uint128(MAXTIME_UINT256))) / WEEK_UINT128;
        _latestLockEnd = ((uint128(block.timestamp) + uint128(MAXTIME_UINT256)) / WEEK_UINT128) * WEEK_UINT128;
    }

    /**
     * @notice Get the earliest and latest timestamps increaseUnlockTime can use
     * @dev If this is called in the first week after the lock is created and if the lock duration is for maximum time,
     *  the returned `_latestLockEnd` will be the same as the lock's end time. This will cause the extension of the lock
     *  to revert. If a smart contract is using this function, make sure that it can handle this case.
     * @return _earliestLockEnd Earliest timestamp
     * @return _latestLockEnd Latest timestamp
     * @dev The truncation in these operations is desired
     */
    function getIncreaseUnlockTimeTsBounds(
        address _user,
        uint256 _id
    ) external view returns (uint128 _earliestLockEnd, uint128 _latestLockEnd) {
        // Calculate the earliest end (current end + leftover time to get into next epoch week)
        _earliestLockEnd = WEEK_UINT128 + ((locked[_user][_id].end / WEEK_UINT128) * WEEK_UINT128); // Cannot be in the current epoch week

        // Calculate the latest end (same as getCreateLockTsBounds result)
        _latestLockEnd = (WEEK_UINT128 * (uint128(block.timestamp) + uint128(MAXTIME_UINT256))) / WEEK_UINT128;

        // Corner case near expiry
        if (_earliestLockEnd >= _latestLockEnd) _earliestLockEnd = _latestLockEnd;
    }

    /**
     * @return _lastPoint The most recent point for this specific lock index
     */
    function getLastGlobalPoint() external view returns (Point memory _lastPoint) {
        _lastPoint = pointHistory[epoch];
    }

    /**
     * @notice Get the user's Point for `_addr` at the specified epoch
     * @param _addr Address of the user wallet
     * @param _lockIndex Index of the user's lock that is getting measured
     * @param _uepoch The epoch of the user to get the point at
     * @return _lastPoint The most recent point for this specific lock index
     */
    function getUserPointAtEpoch(
        address _addr,
        uint128 _lockIndex,
        uint256 _uepoch
    ) external view returns (Point memory _lastPoint) {
        uint256 lockId = indicesToIds[_addr][_lockIndex];
        _lastPoint = userPointHistory[_addr][lockId][_uepoch];
    }

    /**
     * @notice Get the most recently recorded Point for `_addr`
     * @param _addr Address of the user wallet
     * @param _lockIndex Index of the user's lock that is getting measured
     * @return _lastPoint The most recent point for this specific lock index
     */
    function getLastUserPoint(address _addr, uint128 _lockIndex) external view returns (Point memory _lastPoint) {
        uint256 lockId = indicesToIds[_addr][_lockIndex];
        uint256 uepoch = userPointEpoch[_addr][lockId];
        _lastPoint = userPointHistory[_addr][lockId][uepoch];
    }

    /**
     * @notice Get the most recently recorded rate of voting power decrease for `_addr`
     * @param _addr Address of the user wallet
     * @param _lockIndex Index of the user's lock that is getting measured
     * @return Value of the slope
     */
    function getLastUserSlope(address _addr, uint128 _lockIndex) external view returns (int128) {
        uint256 lockId = indicesToIds[_addr][_lockIndex];
        uint256 uepoch = userPointEpoch[_addr][lockId];
        return userPointHistory[_addr][lockId][uepoch].slope;
    }

    /**
     * @notice Get locked amount and ending timestamp for a specific user and lock ID (not lock index). Same as locked()
     * @param _addr User address
     * @param _id User lock ID (not lock index)
     * @return _amount The amount locked
     * @return _end The timestamp when the lock expires/ends
     */
    function lockedById(address _addr, uint256 _id) public view returns (int128 _amount, uint128 _end) {
        LockedBalance memory _lockInfo = locked[_addr][_id];
        _amount = _lockInfo.amount;
        _end = _lockInfo.end;
    }

    /**
     * @notice Get locked amount and ending timestamp for a specific user and lock index (not lock ID)
     * @param _addr User address
     * @param _index User lock index (not lock ID)
     * @return _amount The amount locked
     * @return _end The timestamp when the lock expires/ends
     */
    function lockedByIndex(address _addr, uint128 _index) public view returns (int128 _amount, uint128 _end) {
        LockedBalance memory _lockInfo = locked[_addr][indicesToIds[_addr][_index]];
        _amount = _lockInfo.amount;
        _end = _lockInfo.end;
    }

    /**
     * @notice Same as lockedById but returns a LockedBalanceExtended struct. Will revert if the ID is not in use
     * @param _addr User address
     * @param _id User lock ID (not lock index)
     * @return _extendedLockInfo The LockedBalanceExtended
     */
    function lockedByIdExtended(
        address _addr,
        uint256 _id
    ) public view returns (LockedBalanceExtended memory _extendedLockInfo) {
        LockedBalance memory _lockInfo = locked[_addr][_id];
        _extendedLockInfo.id = _id;
        _extendedLockInfo.index = getLockIndexById(_addr, _id);
        _extendedLockInfo.amount = _lockInfo.amount;
        _extendedLockInfo.end = _lockInfo.end;
    }

    /**
     * @notice Get timestamp when `_addr`'s lock finishes
     * @dev If the emergency unlock is active, the current timestamp is returned. If an external smart contract is using
     *  this function, make sure that it can handle this case.
     * @param _addr User wallet
     * @param _index User lock index
     * @return Epoch time of the lock end
     */
    function lockedEnd(address _addr, uint128 _index) external view returns (uint256) {
        if (emergencyUnlockActive) {
            return block.timestamp;
        }

        uint256 lockId = indicesToIds[_addr][_index];
        return locked[_addr][lockId].end;
    }

    /**
     * @notice Get the lock index given a lock id. Reverts if the ID is not in use
     * @param _addr User address
     * @param _id User lock ID (not lock index)
     * @return _index The index of the lock
     */
    function getLockIndexById(address _addr, uint256 _id) public view returns (uint128 _index) {
        // Get the lock ID info
        LockIdIdxInfo memory _info = idsToIndices[_addr][_id];
        if (!_info.isInUse) revert LockIDNotInUse();

        // Set the index to return
        _index = _info.index;
    }

    /**
     * @notice Calculate total voting power at some point in the past
     * @dev If `emergencyUnlock` is active, the total FXS supply is returned. If an external smart contract is using
     *  this function, make sure that it can handle this case.
     * @param _point The point (bias/slope) to start search from
     * @param _t Time to calculate the total voting power at
     * @return Total voting power at that time
     */
    function supplyAt(Point memory _point, uint256 _t) public view returns (uint256) {
        if (emergencyUnlockActive) {
            return totalFXSSupply();
        }

        Point memory lastPoint = _point;
        uint256 tI = (lastPoint.ts / WEEK_UINT256) * WEEK_UINT256;

        if (lastPoint.ts > _t) revert InvalidTimestamp();

        for (uint256 i; i < 255; ) {
            tI += WEEK_UINT256;
            int128 dSlope = 0;
            if (tI > _t) {
                tI = _t;
            } else {
                dSlope = slopeChanges[tI];
            }
            lastPoint.bias -= lastPoint.slope * int128(uint128(tI - lastPoint.ts));
            if (tI == _t) {
                break;
            }
            lastPoint.slope += dSlope;
            lastPoint.ts = tI;

            unchecked {
                ++i;
            }
        }

        if (lastPoint.bias < 0) {
            lastPoint.bias = 0;
        }
        uint256 weightedSupply = uint256(uint128(lastPoint.bias));
        if (weightedSupply < lastPoint.fxsAmt) {
            weightedSupply = lastPoint.fxsAmt;
        }

        return weightedSupply;
    }

    /**
     * @notice Calculates FXS supply of veFXS contract.
     * @dev Adheres to the ERC20 `totalSupply` interface.
     * @return Total FXS supply
     */
    function totalFXSSupply() public view returns (uint256) {
        return IERC20Metadata(token).balanceOf(address(this));
    }

    /**
     * @notice Calculate total FXS at some point in the past
     * @param _block Block to calculate the total voting power at
     * @return Total FXS supply at `_block`
     */
    function totalFXSSupplyAt(uint256 _block) external view returns (uint256) {
        if (_block > block.number) revert InvalidBlockNumber();

        uint256 targetEpoch = findBlockEpoch(_block, epoch);

        Point memory point = pointHistory[targetEpoch];
        return point.fxsAmt;
    }

    /**
     * @notice Calculate total voting power at the current time
     * @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
     * @return Total voting power
     */
    function totalSupply() external view returns (uint256) {
        return totalSupply(block.timestamp);
    }

    /**
     * @notice Calculate total voting power
     * @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
     * @dev If `emergencyUnlock` is active, the total FXS supply is returned. If an external smart contract is using
     *  this function, make sure that it can handle this case.
     * @param _timestamp Time to calculate the total voting power at (default: block.timestamp)
     * @return Total voting power
     */
    function totalSupply(uint256 _timestamp) public view returns (uint256) {
        if (emergencyUnlockActive) {
            return totalFXSSupply();
        }

        _timestamp = _timestamp == 0 ? block.timestamp : _timestamp; // Default to current timestamp if t is 0

        uint256 _min = 0;
        uint256 _max = epoch;
        uint256 _mid;
        for (uint256 i; i < 128; ) {
            // Will be always enough for 128-bit numbers
            if (_min >= _max) {
                break;
            }
            _mid = (_min + _max + 1) / 2;
            if (pointHistory[_mid].ts <= _timestamp) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }

            unchecked {
                ++i;
            }
        }

        Point memory lastPoint = pointHistory[_min];
        return supplyAt(lastPoint, _timestamp);
    }

    /**
     * @notice Calculate total voting power at some point in the past
     * @dev If `emergencyUnlock` is active, the total FXS supply is returned. If an external smart contract is using
     *  this function, make sure that it can handle this case.
     * @param _block Block to calculate the total voting power at
     * @return Total voting power at `_block`
     */
    function totalSupplyAt(uint256 _block) external view returns (uint256) {
        if (_block > block.number) revert InvalidBlockNumber();

        uint256 targetEpoch = findBlockEpoch(_block, epoch);

        Point memory point = pointHistory[targetEpoch];
        uint256 dt = 0;
        if (targetEpoch < epoch) {
            Point memory pointNext = pointHistory[targetEpoch + 1];
            if (point.blk != pointNext.blk) {
                dt = ((_block - point.blk) * (pointNext.ts - point.ts)) / (pointNext.blk - point.blk);
            }
        } else {
            if (point.blk != block.number) {
                dt = ((_block - point.blk) * (block.timestamp - point.ts)) / (block.number - point.blk);
            }
        }
        // Now dt contains info on how far are we beyond point
        return supplyAt(point, point.ts + dt);
    }

    /**
     * @notice Get the timestamp for checkpoint `_idx` for `_addr`
     * @param _addr User wallet address
     * @param _lockIndex Index of the user's lock that is getting measured
     * @param _idx User epoch number
     * @return Timestamp of the checkpoint
     */
    function userPointHistoryTs(address _addr, uint128 _lockIndex, uint256 _idx) external view returns (uint256) {
        uint256 lockId = indicesToIds[_addr][_lockIndex];
        return userPointHistory[_addr][lockId][_idx].ts;
    }

    // ==============================================================================
    // INTERNAL FUNCTIONS
    // ==============================================================================

    /**
     * @notice Record global and per-user data to checkpoint
     * @param _addr User's wallet address. No user checkpoint if 0x0
     * @param _oldLocked Previous locked amount / end lock time for the user
     * @param _newLocked New locked amount / end lock time for the user
     * @param _lockIndex Index of a lock being modified
     */
    function _checkpoint(
        address _addr,
        LockedBalance memory _oldLocked,
        LockedBalance memory _newLocked,
        uint128 _lockIndex
    ) internal {
        Point memory uOld = Point({ bias: 0, slope: 0, ts: 0, blk: 0, fxsAmt: 0 });
        Point memory uNew = Point({ bias: 0, slope: 0, ts: 0, blk: 0, fxsAmt: 0 });
        int128 oldGlobalDslope;
        int128 newGlobalDslope;
        uint256 _epoch = epoch;

        if (_addr != address(0)) {
            // Calculate slopes and biases
            // Kept at zero when they have to

            if (_oldLocked.end > block.timestamp && _oldLocked.amount > 0) {
                uOld.slope = (_oldLocked.amount * VOTE_WEIGHT_MULTIPLIER_INT128) / MAXTIME_INT128;
                // @dev: Cannot overflow as _newLocked maximum cannot exceed 4 years.
                uOld.bias = _oldLocked.amount + uOld.slope * int128(uint128(_oldLocked.end - block.timestamp));
            }

            if (_newLocked.end > block.timestamp && _newLocked.amount > 0) {
                uNew.slope = (_newLocked.amount * VOTE_WEIGHT_MULTIPLIER_INT128) / MAXTIME_INT128;
                // @dev: Cannot overflow as _newLocked maximum cannot exceed 4 years.
                uNew.bias = _newLocked.amount + uNew.slope * int128(uint128(_newLocked.end - block.timestamp));
            }

            // Read values of scheduled changes in the slope
            // _oldLocked.end can be in the past and in the future
            // _newLocked.end can ONLY be in the FUTURE unless everything expired: than zeros
            oldGlobalDslope = slopeChanges[_oldLocked.end];
            if (_newLocked.end != 0) {
                if (_newLocked.end == _oldLocked.end) {
                    newGlobalDslope = oldGlobalDslope;
                } else {
                    newGlobalDslope = slopeChanges[_newLocked.end];
                }
            }
        }

        Point memory lastPoint = Point({ bias: 0, slope: 0, ts: block.timestamp, blk: block.number, fxsAmt: 0 });
        if (_epoch > 0) {
            lastPoint = pointHistory[_epoch];
        }
        uint128 lastCheckpoint = uint128(lastPoint.ts);

        // initialLastPoint is used for extrapolation to calculate block number
        // (approximately, for *At methods) and save them
        // as we cannot figure that out exactly from inside the contract
        Point memory initialLastPoint = Point({
            bias: lastPoint.bias,
            slope: lastPoint.slope,
            ts: lastPoint.ts,
            blk: lastPoint.blk,
            fxsAmt: lastPoint.fxsAmt
        });
        uint256 blockSlope = 0; // dblock/dt
        if (block.timestamp > lastPoint.ts) {
            blockSlope = (MULTIPLIER_UINT256 * (block.number - lastPoint.blk)) / (block.timestamp - lastCheckpoint);
        }
        // If the last point is already recorded in this block, slope=0
        // But that's ok b/c we know the block in such case

        // Go over weeks to fill history and calculate what the current point is
        lastPoint = _fillHistoryAndCalculateCurrentPoint(
            lastCheckpoint,
            lastPoint,
            initialLastPoint,
            blockSlope,
            _epoch
        );
        // Now pointHistory is filled until t=now

        if (_addr != address(0)) {
            // If the last point was in this block, the slope change has been applied already
            // But in such case we have 0 slope(s)
            lastPoint.slope += (uNew.slope - uOld.slope);
            lastPoint.bias += (uNew.bias - uOld.bias);

            if (_newLocked.amount > _oldLocked.amount) {
                lastPoint.fxsAmt += uint256(uint128(_newLocked.amount - _oldLocked.amount));
            }
            if (_newLocked.amount < _oldLocked.amount) {
                lastPoint.fxsAmt -= uint256(uint128(_oldLocked.amount - _newLocked.amount));

                // if (_newLocked.amount == 0 && !emergencyUnlockActive) {
                if (_newLocked.amount == 0 && _oldLocked.end <= block.timestamp) {
                    lastPoint.bias -= _oldLocked.amount;
                }
            }

            if (lastPoint.slope < 0) {
                lastPoint.slope = 0;
            }
            if (lastPoint.bias < 0) {
                lastPoint.bias = 0;
            }
        }

        // Record the changed point into history
        pointHistory[epoch] = lastPoint;

        if (_addr != address(0)) {
            // Schedule the slope changes (slope is going down)
            // We subtract new_user_slope from [_newLocked.end]
            // and add old_user_slope to [_oldLocked.end]
            if (_oldLocked.end > block.timestamp) {
                // old_dslope was <something> - uOld.slope, so we cancel that
                oldGlobalDslope += uOld.slope;
                if (_newLocked.end == _oldLocked.end) {
                    oldGlobalDslope -= uNew.slope; // It was a new deposit, not an extension
                }
                slopeChanges[_oldLocked.end] = oldGlobalDslope;
            }

            if (_newLocked.end > block.timestamp) {
                if (_newLocked.end > _oldLocked.end) {
                    newGlobalDslope -= uNew.slope; // old slope disappeared at this point
                    slopeChanges[_newLocked.end] = newGlobalDslope;
                } // The alternative is already recorded in the old_dslope
            }

            // Now handle every user
            _fillUserPointHistory(_addr, uNew, _lockIndex);
        }
    }

    /**
     * @notice Deposit `_value` tokens for `_addr` and add to the lock
     * @dev Anyone (even a smart contract) can deposit for someone else, but cannot extend their locktime and deposit for a brand new user
     * @dev WARNING: Since the `_value` is of `uint256` type and the `amount` in `LockedBalance` is of `int128` type,
     *  there is a risk of overflow. This does not impact veFXS as the maximum supply of FXS is 100M, but it could
     *  provide a risk for protocols forking this smart contract if their maximum supply is higher than maximum value of
     *  `int128`.
     * @param _addr User's wallet address
     * @param _value Amount to add to user's lock
     * @param _unlockTime Unix timestamp of when the lock expires
     * @param _lockedBalance The user's current locked balance
     * @param _depositType The type of deposit being made
     * @param _lockIdx The index of the user's lock that the deposit is being made to
     */
    function _depositFor(
        address _addr,
        uint256 _value,
        uint128 _unlockTime,
        LockedBalance memory _lockedBalance,
        uint128 _depositType,
        uint128 _lockIdx
    ) internal {
        // Revert if you are in an emergency
        if (emergencyUnlockActive) revert EmergencyUnlockActive();

        // Pull the tokens before modifying state
        require(IERC20Metadata(token).transferFrom(msg.sender, address(this), _value));

        LockedBalance memory oldLocked = _lockedBalance;
        uint256 supplyBefore = supply;

        LockedBalance memory newLocked = LockedBalance({ amount: oldLocked.amount, end: oldLocked.end });

        supply = supplyBefore + _value;
        // Adding to existing lock, or if a lock is expired - creating a new one
        // WARNING: If you are forking this smart contract, make sure that the downcast from uint256 to uint128, and to
        //  int128, is safe
        newLocked.amount += int128(uint128(_value));
        if (_unlockTime != 0) {
            newLocked.end = _unlockTime;
        }
        locked[_addr][indicesToIds[_addr][_lockIdx]] = newLocked;

        // Possibilities:
        // Both oldLocked.end could be current or expired (>/< block.timestamp)
        // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
        // _locked.end > block.timestamp (always)
        _checkpoint(_addr, oldLocked, newLocked, _lockIdx);

        emit Deposit(_addr, msg.sender, newLocked.end, _value, _depositType, block.timestamp);
        emit Supply(supplyBefore, supplyBefore + _value);
    }

    /**
     * @notice Go over weeks to fill history and calculate what the current point is
     * @param _lastCheckpoint Timestamp of the last checkpoint
     * @param _lastPoint Last point object
     * @param _initialLastPoint Initial last point object
     * @param _blockSlope Block slope
     * @param _epoch Epoch
     * @return The latest `Point` object
     */
    function _fillHistoryAndCalculateCurrentPoint(
        uint128 _lastCheckpoint,
        Point memory _lastPoint,
        Point memory _initialLastPoint,
        uint256 _blockSlope,
        uint256 _epoch
    ) private returns (Point memory) {
        uint128 tI = uint128((uint256(_lastCheckpoint) / WEEK_UINT256) * WEEK_UINT256);
        for (uint256 i; i < 255; ) {
            tI += WEEK_UINT128;
            int128 dSlope = 0;

            // Ensure that tI does not exceed the current block timestamp
            if (uint256(tI) > block.timestamp) {
                tI = uint128(block.timestamp);
            } else {
                dSlope = slopeChanges[tI];
            }

            _lastPoint.bias -= _lastPoint.slope * int128(tI - _lastCheckpoint);
            _lastPoint.slope += dSlope;

            // Ensure non-negativity of bias and slope
            if (_lastPoint.bias < 0) {
                _lastPoint.bias = 0;
            }
            if (_lastPoint.slope < 0) {
                _lastPoint.slope = 0;
            }

            _lastCheckpoint = tI;
            _lastPoint.ts = tI;

            _lastPoint.blk =
                _initialLastPoint.blk +
                (uint128(_blockSlope) * (tI - _initialLastPoint.ts)) /
                MULTIPLIER_UINT256;

            // TODO: does _epoch get incremented every single time checkpoint is called, or some other weird math?
            _epoch += 1;

            if (tI == uint128(block.timestamp)) {
                _lastPoint.blk = block.number;
                break;
            } else {
                // Store the point in history
                pointHistory[_epoch] = _lastPoint;
            }

            unchecked {
                ++i;
            }
        }

        epoch = _epoch;
        return _lastPoint;
    }

    /**
     * @notice Fill user point history
     * @param _addr User's wallet address
     * @param _point Latest user's point
     * @param _lockIndex Index of a lock being modified
     */
    function _fillUserPointHistory(address _addr, Point memory _point, uint128 _lockIndex) internal {
        uint256 lockId = indicesToIds[_addr][_lockIndex];
        uint256 userEpoch = userPointEpoch[_addr][lockId] + 1;

        userPointEpoch[_addr][lockId] = userEpoch;
        _point.ts = block.timestamp;
        _point.blk = block.number;
        _point.fxsAmt = uint256(uint128(locked[_addr][lockId].amount));
        userPointHistory[_addr][lockId][userEpoch] = _point;
    }

    /**
     * @notice Withdraw all tokens for `msg.sender`'s lock with the given `_lockIndex`
     * @dev Only possible if the lock has expired or if the emergency unlock is active
     * @param _staker The user address being withdrawn.
     * @param _recipient The recipient of the withdrawn tokens.
     * @param _lockIndex Index of the user's lock that is getting withdrawn
     * @return _value How much FXS was withdrawn
     */
    function _withdraw(
        address _staker,
        address _recipient,
        uint128 _lockIndex
    ) internal nonReentrant returns (uint256 _value) {
        // Revert if it would be an array out-of-bounds
        if (_lockIndex >= numLocks[_staker]) revert InvalidLockIndex();

        // Revert if paused
        if (isPaused) revert OperationIsPaused();

        // Get old lock information
        uint256 lockId = indicesToIds[_staker][_lockIndex];
        LockedBalance memory oldLocked = locked[_staker][lockId];

        // Revert if the lock is not expired yet, unless you are in an emergency unlock
        if ((uint128(block.timestamp) < oldLocked.end) && !emergencyUnlockActive) {
            revert LockDidNotExpire();
        }

        // Instantiate new lock info
        _value = uint256(uint128(oldLocked.amount));
        LockedBalance memory newLocked = LockedBalance({ amount: 0, end: 0 });

        // oldLocked can have either expired <= timestamp or zero end
        // newLocked has only 0 end
        // Both can have >= 0 amount
        _checkpoint(_staker, oldLocked, newLocked, _lockIndex);

        /**
         * This effectively moves the last lock to the place of the one being withdrawn. Doing so allows for keeping all
         * of the active indices without the gaps and allows for easier tracking of locks and the data attached to them.
         * The shift is done by moving the ID of the last lock and the accompanying userPointHistory and userPointEpoch
         * to the index of the lock being withdrawn.
         */

        // Example (indicesToIds): [4, 2, 1, 10, 5]

        // Withdraw lock ID 2 at index 1
        // lockIndex = 1
        // lastLockId = 5, at index 4
        // -->>
        // indicesToIds becomes: [4, 5, 1, 10]
        // idsToIndices for ID 5 updated to index 1
        // idsToIndices for ID 2 deleted

        // Update indicesToIds
        uint256 lastLockId = indicesToIds[_staker][numLocks[_staker] - 1];
        indicesToIds[_staker][_lockIndex] = lastLockId;
        delete indicesToIds[_staker][numLocks[_staker] - 1];

        // Update idsToIndices
        idsToIndices[_staker][lastLockId].index = _lockIndex;
        idsToIndices[_staker][lastLockId].isInUse = true;
        delete idsToIndices[_staker][lockId]; // If lastLockId = lockId, like in the case of numLocks = 1, then isInUse will become false here too

        // Update numLocks
        numLocks[_staker] -= 1;

        // Update lock creator tracking
        if (!isLockCreatedByFloxContributor[_staker][lockId]) {
            // NOTE: Negation is used, so that if the user is also Flox contributor, the behaviour of lock creation tracking is inverse of the one in the `createLock`
            numberOfUserCreatedLocks[_staker] -= 1;
        } else {
            numberOfFloxContributorCreatedLocks[_staker] -= 1;
        }

        uint256 supplyBefore = supply;
        supply = supplyBefore - _value;

        require(IERC20Metadata(token).transfer(_recipient, _value), "Transfer failed");

        // Global checkpoint if the emergency unlock is active
        if (emergencyUnlockActive) {
            _checkpoint(address(0), LockedBalance(0, 0), LockedBalance(0, 0), 2 ** 128 - 1);
        }

        emit Withdraw(_staker, _recipient, _value, block.timestamp);
        emit Supply(supplyBefore, supply);
    }

    // ==============================================================================
    // PUBLIC/EXTERNAL MUTABLE FUNCTIONS
    // ==============================================================================

    /**
     * @notice Record global data to checkpoint
     */
    function checkpoint() external {
        // Revert if the contract is paused
        if (isPaused) revert OperationIsPaused();

        // Revert if you are in an emergency
        if (emergencyUnlockActive) revert EmergencyUnlockActive();

        // Do the checkpoint
        _checkpoint(address(0), LockedBalance(0, 0), LockedBalance(0, 0), 2 ** 128 - 1);
    }

    /**
     * @notice Deposit `_value` tokens for `msg.sender` and lock until `_unlockTime`
     * @dev Users should only be allowed to create locks for themselves, the only exemption being Flow contributors that
     *  can create locks for other users.
     * @dev Flox contributors can only create 8 locks for themselves. Even if they are Flox contributors, they cannot
     *  create contributor locks for themselves.
     * @param _addr Address of the user for which the lock is being created
     * @param _value Amount to deposit
     * @param _unlockTime Epoch time when tokens unlock, rounded down to whole weeks
     * @return _index Index of the user's lock that was created
     * @return _newLockId ID of the user's lock that was created
     */
    function createLock(
        address _addr,
        uint256 _value,
        uint128 _unlockTime
    ) external nonReentrant returns (uint128 _index, uint256 _newLockId) {
        if (isPaused) revert OperationIsPaused();
        if (_value < MIN_LOCK_AMOUNT) revert MinLockAmount();
        if (msg.sender != _addr && !floxContributors[msg.sender]) revert NotLockingForSelfOrFloxContributor();
        if (msg.sender == _addr && numberOfUserCreatedLocks[_addr] >= MAX_USER_LOCKS) revert MaximumUserLocksReached();
        if (
            floxContributors[msg.sender] &&
            msg.sender != _addr &&
            numberOfFloxContributorCreatedLocks[_addr] >= MAX_CONTRIBUTOR_LOCKS
        ) {
            revert MaximumFloxContributorLocksReached();
        }

        nextId[_addr] += 1; // This is done so that the lock with ID 0 is always empty. It allows for checking if a lock exists by checking if the ID is 0
        _newLockId = nextId[_addr];

        uint128 unlockTime = (_unlockTime / WEEK_UINT128) * WEEK_UINT128; // Locktime is rounded down to weeks
        LockedBalance storage _locked = locked[_addr][_newLockId];

        if (uint256(unlockTime) <= block.timestamp) revert MustBeInAFutureEpochWeek();
        if (uint256(unlockTime) > block.timestamp + MAXTIME_UINT256) {
            revert LockCanOnlyBeUpToFourYears();
        }

        // Using numLocks[_addr] (original)
        {
            // Update indicesToIds
            indicesToIds[_addr][numLocks[_addr]] = _newLockId;

            // Update idsToIndices
            idsToIndices[_addr][_newLockId].id = _newLockId;
            idsToIndices[_addr][_newLockId].index = numLocks[_addr];
            idsToIndices[_addr][_newLockId].isInUse = true;
        }

        numLocks[_addr] += 1;

        // Update the information about lock creator
        if (msg.sender == _addr) {
            // NOTE: If the user is also Flox contributor, the lock will be counted as user's lock
            numberOfUserCreatedLocks[_addr] += 1;
        } else {
            numberOfFloxContributorCreatedLocks[_addr] += 1;
            isLockCreatedByFloxContributor[_addr][_newLockId] = true;
        }

        _depositFor(_addr, _value, unlockTime, _locked, CREATE_LOCK_TYPE, numLocks[_addr] - 1);

        return (numLocks[_addr] - 1, _newLockId);
    }

    /**
     * @notice Deposit `_value` tokens for `_addr` and add to the lock
     * @dev Anyone (even a smart contract) can deposit for someone else, but
     * cannot extend their locktime and deposit for a brand new user
     * @param _addr User's wallet address
     * @param _value Amount to add to user's lock
     * @param _lockIndex Index of the user's lock that the deposit is being made to
     */
    function depositFor(address _addr, uint256 _value, uint128 _lockIndex) external nonReentrant {
        if (isPaused) revert OperationIsPaused();
        if (_value < MIN_LOCK_AMOUNT) revert MinLockAmount();
        uint256 lockId = indicesToIds[_addr][_lockIndex];
        LockedBalance storage _locked = locked[_addr][lockId];

        if (_locked.amount <= 0) revert NoExistingLockFound();
        if (_locked.end <= block.timestamp) revert LockExpired(); // Withdraw instead

        _depositFor(_addr, _value, 0, locked[_addr][lockId], DEPOSIT_FOR_TYPE, _lockIndex);
    }

    /**
     * @notice Deposit `_value` additional tokens for `msg.sender`
     *         without modifying the unlock time
     * @param _value Amount of tokens to deposit and add to the lock
     * @param _lockIndex Index of the user's lock that getting the increased amount
     */
    function increaseAmount(uint256 _value, uint128 _lockIndex) external nonReentrant {
        if (isPaused) revert OperationIsPaused();
        if (_value < MIN_LOCK_AMOUNT) revert MinLockAmount();
        uint256 lockId = indicesToIds[msg.sender][_lockIndex];
        LockedBalance storage _locked = locked[msg.sender][lockId];

        if (_locked.amount <= 0) revert NoExistingLockFound();
        if (_locked.end <= uint128(block.timestamp)) revert LockExpired(); // Withdraw instead

        _depositFor(msg.sender, _value, 0, _locked, INCREASE_LOCK_AMOUNT, _lockIndex);
    }

    /**
     * @notice Extend the unlock time for `msg.sender` to `_unlockTime`
     * @param _unlockTime New epoch time for unlocking
     * @param _lockIndex Index of the user's lock that is getting the increased unlock time
     */
    function increaseUnlockTime(uint128 _unlockTime, uint128 _lockIndex) external nonReentrant {
        if (isPaused) revert OperationIsPaused();
        uint256 lockId = indicesToIds[msg.sender][_lockIndex];
        LockedBalance storage _locked = locked[msg.sender][lockId];
        uint128 unlockTime = (_unlockTime / WEEK_UINT128) * WEEK_UINT128; // Locktime is rounded down to weeks

        if (uint256(_locked.end) <= block.timestamp) revert LockExpired();
        if (_locked.amount <= 0) revert NoExistingLockFound(); // TODO: This might be unreachable because of the validation above
        if (unlockTime <= _locked.end) revert MustBeInAFutureEpochWeek();
        if (uint256(unlockTime) > block.timestamp + MAXTIME_UINT256) {
            revert LockCanOnlyBeUpToFourYears();
        }

        _depositFor(msg.sender, 0, unlockTime, _locked, INCREASE_UNLOCK_TIME, _lockIndex);
    }

    /**
     * @notice Withdraw all tokens for `msg.sender`'s lock with the given `_lockIndex`
     * @dev Only possible if the lock has expired or if the emergency unlock is active
     * @param _lockIndex Index of the user's lock that is getting withdrawn
     * @return _value How much FXS was withdrawn
     */
    function withdraw(uint128 _lockIndex) external returns (uint256 _value) {
        _value = _withdraw(msg.sender, msg.sender, _lockIndex);
    }

    // ==============================================================================
    // ADMIN / PERMISSIONED ACTIONS
    // ==============================================================================

    /**
     * @notice Apply ownership transfer. Only callable by the future admin. Do commitTransferOwnership first
     */
    function acceptTransferOwnership() external {
        if (msg.sender != futureAdmin) revert FutureAdminOnly();
        address _admin = futureAdmin;
        if (_admin == address(0)) revert AdminNotSet(); // This is now unreachable, but I don't mind leaving it for the extremely remote chance that someone figures out a way to execute calls from 0x0
        admin = _admin;
        futureAdmin = address(0);
        emit ApplyOwnership(_admin);
    }

    /**
     * @notice Transfer ownership of VotingEscrow contract to `addr`
     * @param _addr Address to have ownership transferred to
     */
    function commitTransferOwnership(address _addr) external {
        if (msg.sender != admin) revert AdminOnly();
        futureAdmin = _addr;
        emit CommitOwnership(_addr);
    }

    /**
     * @notice Used to recover non-FXS ERC20 tokens
     * @param _tokenAddr Address of the ERC20 token to recover
     * @param _amount Amount of tokens to recover
     */
    function recoverIERC20(address _tokenAddr, uint256 _amount) external {
        if (msg.sender != admin) revert AdminOnly();
        if (_tokenAddr == token) revert UnableToRecoverFXS(); // Use `activateEmergencyUnlock` instead and have users pull theirs out individually
        require(IERC20Metadata(_tokenAddr).transfer(admin, _amount));
    }

    /**
     * @notice Set the address of a Flox contributor
     * @param _floxContributor Address of a Flox contributor
     * @param _isFloxContributor Boolean indicating if the address is a Flox contributor or not
     */
    function setFloxContributor(address _floxContributor, bool _isFloxContributor) external {
        if (msg.sender != admin) revert AdminOnly();
        floxContributors[_floxContributor] = _isFloxContributor;

        emit FloxContributorUpdate(_floxContributor, _isFloxContributor);
    }

    /**
     * @notice Set the address of a VestedFXSUtils contract
     * @param _veFxsUtilsAddr Address of the VestedFXSUtils contract
     */
    function setVeFXSUtils(address _veFxsUtilsAddr) external {
        if (msg.sender != admin) revert AdminOnly();

        // Set the utils contract
        veFxsUtils = VestedFXSUtils(_veFxsUtilsAddr);

        emit VeFxsUtilsContractUpdated(_veFxsUtilsAddr);
    }

    /**
     * @notice Pause/Unpause critical functions
     */
    function toggleContractPause() external {
        if (msg.sender != admin) revert AdminOnly();
        isPaused = !isPaused;
        emit ContractPause(isPaused);
    }

    /**
     * @notice Used to allow early withdrawals of veFXS back into FXS, in case of an emergency. Only users themselves can pull out the FXS, not the admin. Once toggled, cannot be undone as slope/bias math will be permanently off going forward.
     */
    function activateEmergencyUnlock() external {
        if (msg.sender != admin) revert AdminOnly();
        if (emergencyUnlockActive) revert EmergencyUnlockActive();
        emergencyUnlockActive = true;
        emit EmergencyUnlockActivated();
    }

    // ==============================================================================
    // Errors
    // ==============================================================================

    /// @notice If the admin was never set
    error AdminNotSet();

    /// @notice Only the admin can call this function
    error AdminOnly();

    /// @notice You cannot merge a lock with itself
    error CannotMergeLockWithItself();

    /// @notice Your veToken cannot have more than 255 decimals
    error DecimalsExceedMaximumValue();

    /// @notice If you are in an emergency unlock
    error EmergencyUnlockActive();

    /// @notice Only the future admin can call this function
    error FutureAdminOnly();

    /// @notice Cannot initialize twice
    error InitializeFailed();

    /// @notice When you are trying to balanceOfAt for a future block
    error InvalidBlockNumber();

    /// @notice When the lock index is invalid
    error InvalidLockIndex();

    /// @notice When the timestamp is invalid (attempting to backwards extrapolate supplyAt)
    error InvalidTimestamp();

    /// @notice When you are trying to lock for more than 4 years. See getCreateLockTsBounds()
    error LockCanOnlyBeUpToFourYears();

    /// @notice When you are trying to withdraw before the lock expires
    error LockDidNotExpire();

    /// @notice If you are trying to extend or add to an already expired lock. Withdraw that lock and create a new one instead
    error LockExpired();

    /// @notice When you call getLockIdByIndex when the ID supplied is not in use
    error LockIDNotInUse();

    /// @notice When the operation would cause too many locks to be produced by the Flox contributors
    error MaximumFloxContributorLocksReached();

    /// @notice When the operation would cause too many locks to be produced by the user
    error MaximumUserLocksReached();

    /// @notice When you are not locking enough
    error MinLockAmount();

    /// @notice The new lock end timestamp needs to at least be in the next epoch week. See getCreateLockTsBounds()
    error MustBeInAFutureEpochWeek();

    /// @notice No existing lock found when you are trying to depositFor or increaseAmount
    error NoExistingLockFound();

    /// @notice You can only create a lock for yourself, unless you are a Flox Contributor
    error NotLockingForSelfOrFloxContributor();

    /// @notice When the function is paused
    error OperationIsPaused();

    /// @notice Admin is specifically not allowed to recover FXS. Users must pull it out themselves after activateEmergencyUnlock is called
    error UnableToRecoverFXS();
}
