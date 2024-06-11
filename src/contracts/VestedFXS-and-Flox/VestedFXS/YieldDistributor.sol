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
// =========================YieldDistributor===========================
// ====================================================================
// Distributes Frax protocol yield based on the claimer's veFXS balance
// Yield will now not accrue for unlocked veFXS

// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)

// Jan Turk: https://github.com/ThunderDeliverer
// Travis Moore: https://github.com/FortisFortuna

// Reviewer(s) / Contributor(s)
// Sam Kazemian: https://github.com/samkazemian

// Originally inspired by Synthetix.io, but heavily modified by the Frax team (veFXS portion)
// https://github.com/Synthetixio/synthetix/blob/develop/contracts/StakingRewards.sol

import { VeFXSAggregator } from "./VeFXSAggregator.sol";
import { IveFXSStructs } from "./IveFXSStructs.sol";
import { TransferHelper } from "../Flox/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { OwnedV2AutoMsgSender } from "./OwnedV2AutoMsgSender.sol";

// import "forge-std/console2.sol";

contract YieldDistributor is OwnedV2AutoMsgSender, ReentrancyGuard, IveFXSStructs {
    using SafeERC20 for ERC20;

    // ==============================================================================
    // STATE VARIABLES
    // ==============================================================================

    // Instances
    // -------------------------
    /// @notice Aggregator contract that sums a user's veFXS from multiple sources
    VeFXSAggregator public veFXSAggregator;

    /// @notice ERC20 instance of the token being emitted
    ERC20 public emittedToken;

    // Addresses
    // -------------------------
    /// @notice Address of the token being emitted
    address public emittedTokenAddress;

    /// @notice Address of the timelock
    address public timelockAddress;

    // Yield and period related
    // -------------------------
    /// @notice Timestamp when the reward period ends
    uint256 public periodFinish;

    /// @notice Timestamp when the contract was last synced or had rewards deposited
    uint256 public lastUpdateTime;

    /// @notice Emission rate of tokens, in tokens per second
    uint256 public yieldRate;

    /// @notice Duration of the period, in seconds
    uint256 public yieldDuration; // 7 * 86400  (7 days)

    /// @notice Mapping of addresses that are allowed to deposit reward tokens
    mapping(address => bool) public rewardNotifiers;

    // Yield tracking
    // -------------------------
    /// @notice Accumulator for tracking contract-wide rewards paid
    uint256 public yieldPerVeFXSStored;

    /// @notice Accumulator for tracking user-specific rewards paid
    mapping(address => uint256) public userYieldPerTokenPaid;

    /// @notice Last stored version of earned(). Set to 0 on yield claim and to earned() on a checkpoint.
    mapping(address => uint256) public yields;

    // veFXS tracking
    // -------------------------
    /// @notice Total amount of veFXS that was checkpointed and is earning
    uint256 public totalVeFXSParticipating;

    /// @notice Stored version of the total veFXS supply
    uint256 public totalComboVeFXSSupplyStored;

    /// @notice If the user was initialized or not
    mapping(address => bool) public userIsInitialized;

    /// @notice Last stored veFXS balance for the user
    mapping(address => uint256) public userVeFXSCheckpointed;

    /// @notice The stored shortest endpoint of any of the user's veFXS positions. You will need to re-checkpoint after any lock expires if you want to keep earning.
    mapping(address => uint256) public userVeFXSEndpointCheckpointed;

    /// @notice Last time the user claimed their yield
    mapping(address => uint256) private lastRewardClaimTime; // staker addr -> timestamp

    // Greylists
    // -------------------------
    /// @notice A graylist for questionable users
    mapping(address => bool) public greylist;

    // Constants
    // -------------------------
    /// @notice Constant for price precision
    uint256 private constant PRICE_PRECISION = 1e6;

    // Admin related
    // -------------------------

    /// @notice For Convex, StakeDAO, etc whose contract addresses cannot claim for themselves. Admin set on a case-by-case basis
    mapping(address staker => address claimer) public thirdPartyClaimers;

    /// @notice A graylist for questionable users
    bool public yieldCollectionPaused = false; // For emergencies

    // Misc
    // -------------------------
    /// @notice If the contract was initialized
    bool wasInitialized;

    // Gap
    // -------------------------

    /// @dev reserve extra storage for future upgrades
    uint256[50] private __gap;

    // ==============================================================================
    // MODIFIERS
    // ==============================================================================

    /// @notice A modifier that only allows the contract owner or the timelock to call
    modifier onlyByOwnGov() {
        if (msg.sender != owner && msg.sender != timelockAddress) revert NotOwnerOrTimelock();
        _;
    }

    /// @notice Make sure yield collection is not paused
    modifier notYieldCollectionPaused() {
        if (yieldCollectionPaused) revert YieldCollectionPaused();
        _;
    }

    /// @notice Checkpoint the user
    modifier checkpointUser(address account) {
        _checkpointUser(account, true);
        _;
    }

    // ==============================================================================
    // CONSTRUCTOR
    // ==============================================================================

    constructor() {
        // Set the contract as initialized
        wasInitialized = true;
    }

    /// @notice Initialize contract
    /// @param _owner The owner of this contract
    /// @param _timelockAddress Address of the timelock
    /// @param _emittedToken Address of the token being emitted as yield
    /// @param _veFXSAggregator Address of the veFXS aggregator
    function initialize(
        address _owner,
        address _timelockAddress,
        address _emittedToken,
        address _veFXSAggregator
    ) public {
        // Safety checks - no validation on admin in case this is initialized without admin
        if (wasInitialized || _emittedToken == address(0) || emittedTokenAddress != address(0)) {
            revert InitializeFailed();
        }

        // Set owner for OwnedV2
        owner = _owner;

        // Set misc addresses
        emittedTokenAddress = _emittedToken;
        emittedToken = ERC20(_emittedToken);
        timelockAddress = _timelockAddress;

        // Set the veFXS Aggregator
        veFXSAggregator = VeFXSAggregator(_veFXSAggregator);

        // Initialize other variables
        lastUpdateTime = block.timestamp;
        rewardNotifiers[_owner] = true;
        yieldDuration = 604_800;

        // Set the contract as initialized
        wasInitialized = true;
    }

    // ==============================================================================
    // VIEWS
    // ==============================================================================

    /// @notice Fraction of the total Fraxtal-visible veFXS collecting yield
    /// @return _fraction The Fraction
    function fractionParticipating() external view returns (uint256 _fraction) {
        if (totalComboVeFXSSupplyStored == 0) return 0;
        else return (totalVeFXSParticipating * PRICE_PRECISION) / totalComboVeFXSSupplyStored;
    }

    /// @notice Eligible veFXS for a given user. Only positions with locked veFXS can accrue yield, not expired positions
    /// @param _user The user to check
    /// @return _eligibleVefxsBal Eligible veFXS
    /// @return _storedEndingTimestamp The stored ending timestamp
    function eligibleCurrentVeFXS(
        address _user
    ) public view returns (uint256 _eligibleVefxsBal, uint256 _storedEndingTimestamp) {
        // Get the total combined veFXS from all sources
        uint256 _currVefxsBal = veFXSAggregator.ttlCombinedVeFXS(_user);

        // Stored is used to prevent abuse
        _storedEndingTimestamp = userVeFXSEndpointCheckpointed[_user];

        // Only unexpired veFXS should be eligible
        if (block.timestamp >= _storedEndingTimestamp) {
            _eligibleVefxsBal = 0;
        } else {
            _eligibleVefxsBal = _currVefxsBal;
        }
    }

    /// @notice Last time the yield was accruing
    /// @return _ts The timestamp
    function lastTimeYieldApplicable() public view returns (uint256 _ts) {
        return (block.timestamp < periodFinish ? block.timestamp : periodFinish);
    }

    /// @notice Amount of yield per veFXS
    /// @return _yield The amount of yield
    function yieldPerVeFXS() public view returns (uint256 _yield) {
        if (totalComboVeFXSSupplyStored == 0) {
            return yieldPerVeFXSStored;
        } else {
            return (yieldPerVeFXSStored +
                (((lastTimeYieldApplicable() - lastUpdateTime) * yieldRate * 1e18) / totalComboVeFXSSupplyStored));
        }
    }

    /// @notice Amount of tokens claimaible as yield
    /// @param _account The user to check
    /// @return _earned The amount of yield
    function earned(address _account) public view returns (uint256 _earned) {
        // Uninitialized users should not earn anything yet
        // console2.log("userIsInitialized[_account]: ", userIsInitialized[_account]);
        if (!userIsInitialized[_account]) return 0;

        // Get eligible veFXS balances
        (uint256 eligibleCurrentVefxs, uint256 endingTimestamp) = eligibleCurrentVeFXS(_account);

        // If your veFXS is unlocked
        uint256 eligibleTimeFraction = PRICE_PRECISION;
        // console2.log("eligibleTimeFraction: ", eligibleTimeFraction);
        if (eligibleCurrentVefxs == 0) {
            // console2.log("block.timestamp: ", block.timestamp);
            // console2.log("lastRewardClaimTime[_account]: ", lastRewardClaimTime[_account]);
            // console2.log("endingTimestamp: ", endingTimestamp);

            // And you already claimed after expiration
            if (lastRewardClaimTime[_account] >= endingTimestamp) {
                // You get NOTHING. You LOSE. Good DAY ser!
                return 0;
            }
            // You haven't claimed yet
            else {
                // See what fraction of the time since you last claimed that you were eligible for earning
                // console2.log("calculating eligibleTimeFraction");
                uint256 eligibleTime = endingTimestamp - lastRewardClaimTime[_account];
                // console2.log("eligibleTime: ", eligibleTime);
                uint256 totalTime = block.timestamp - lastRewardClaimTime[_account];
                // console2.log("totalTime: ", totalTime);
                eligibleTimeFraction = (PRICE_PRECISION * eligibleTime) / totalTime;
                // console2.log("eligibleTimeFraction: ", eligibleTimeFraction);
            }
        }

        // If the amount of veFXS increased, only pay off based on the old balance
        // Otherwise, take the midpoint
        uint256 vefxsBalanceToUse;
        uint256 oldVefxsBalance = userVeFXSCheckpointed[_account];
        // console2.log("vefxsBalanceToUse: ", vefxsBalanceToUse);
        // console2.log("oldVefxsBalance: ", oldVefxsBalance);

        if (eligibleCurrentVefxs > oldVefxsBalance) {
            // VeFXS increased so use old amount
            vefxsBalanceToUse = oldVefxsBalance;
            // console2.log("VeFXS increased so use old amount: ", vefxsBalanceToUse);
        } else {
            // VeFXS decreased so use midpoint (average)
            vefxsBalanceToUse = (eligibleCurrentVefxs + oldVefxsBalance) / 2;
            // console2.log("VeFXS decreased so use midpoint (average): ", vefxsBalanceToUse);

            // Print old earnings if there was no midpointing (debug only)
            // uint256 _oldVeFXSEarnings = ((oldVefxsBalance *
            //     (yieldPerVeFXS() - userYieldPerTokenPaid[_account]) *
            //     eligibleTimeFraction) /
            //     (1e18 * PRICE_PRECISION) +
            //     yields[_account]);
            // console2.log("Old earnings would have been: ", _oldVeFXSEarnings);
        }

        // Calculate earnings
        return ((vefxsBalanceToUse * (yieldPerVeFXS() - userYieldPerTokenPaid[_account]) * eligibleTimeFraction) /
            (1e18 * PRICE_PRECISION) +
            yields[_account]);
    }

    /// @notice Total amount of yield for the duration (normally a week)
    /// @return _yield The amount of yield
    function getYieldForDuration() external view returns (uint256 _yield) {
        return (yieldRate * yieldDuration);
    }

    // ==============================================================================
    // MUTATIVE FUNCTIONS
    // ==============================================================================

    /// @notice Checkpoint a user's earnings
    /// @param _account The user to checkpoint
    /// @param _syncToo Should normally be true. Can be false only for bulkCheckpointOtherUsers to save gas since it calls sync() once beforehand
    /// @dev If you want to keep earning, you need to make sure you checkpoint after ANY lock expires
    function _checkpointUser(address _account, bool _syncToo) internal {
        // Need to retro-adjust some things if the period hasn't been renewed, then start a new one

        // Should always sync unless you are bulkCheckpointOtherUsers, which can be called once beforehand to save gas
        if (_syncToo) sync();

        // Calculate the earnings first
        _syncEarned(_account);

        // Get the old and the new veFXS balances
        uint256 _oldVefxsBalance = userVeFXSCheckpointed[_account];

        // Get the total combined veFXS from all sources
        uint256 _newVefxsBalance = veFXSAggregator.ttlCombinedVeFXS(_account);

        // Update the user's stored veFXS balance
        userVeFXSCheckpointed[_account] = _newVefxsBalance;

        // Collect all active locks
        LockedBalanceExtendedV2[] memory _currCombinedLockBalExtds = veFXSAggregator.getAllCurrActiveLocks(
            _account,
            false
        );

        // Update the user's stored ending timestamp
        // TODO: Check this math as well as corner cases
        // TODO: Is there a better way to do this? This might be ok for now since gas is low on Fraxtal, but in the future,
        // I imagine there is a more elegant solution
        // ----------------------
        uint128 _shortestActiveLockEnd;

        // In case there are no active locks anywhere
        if (_currCombinedLockBalExtds.length > 0) {
            // console2.log("_checkpointUser > 0 active locks");
            _shortestActiveLockEnd = _currCombinedLockBalExtds[0].end;
        }

        // Find the timestamp of the lock closest to expiry
        if (_currCombinedLockBalExtds.length > 1) {
            // console2.log("_checkpointUser > 1 active locks");
            for (uint256 i; i < _currCombinedLockBalExtds.length; ) {
                // console2.log("_currCombinedLockBalExtds[i].end: ", _currCombinedLockBalExtds[i].end);
                if (_currCombinedLockBalExtds[i].end < _shortestActiveLockEnd) {
                    _shortestActiveLockEnd = _currCombinedLockBalExtds[i].end;
                }

                unchecked {
                    ++i;
                }
            }
        }
        // console2.log("userVeFXSEndpointCheckpointed result: ", _shortestActiveLockEnd);
        userVeFXSEndpointCheckpointed[_account] = _shortestActiveLockEnd;

        // Update the total amount participating
        if (_newVefxsBalance >= _oldVefxsBalance) {
            uint256 weightDiff = _newVefxsBalance - _oldVefxsBalance;
            totalVeFXSParticipating = totalVeFXSParticipating + weightDiff;
        } else {
            uint256 weightDiff = _oldVefxsBalance - _newVefxsBalance;
            totalVeFXSParticipating = totalVeFXSParticipating - weightDiff;
        }

        // Mark the user as initialized
        if (!userIsInitialized[_account]) {
            userIsInitialized[_account] = true;
            lastRewardClaimTime[_account] = block.timestamp;
        }
    }

    /// @notice Sync a user's earnings
    /// @param _account The user to sync
    function _syncEarned(address _account) internal {
        if (_account != address(0)) {
            uint256 earned0 = earned(_account);
            yields[_account] = earned0;
            userYieldPerTokenPaid[_account] = yieldPerVeFXSStored;
        }
    }

    /// @notice Anyone can checkpoint another user
    /// @param _account The user to sync
    function checkpointOtherUser(address _account) external {
        _checkpointUser(_account, true);
    }

    /// @notice Anyone can checkpoint other users
    /// @param _accounts The users to sync
    function bulkCheckpointOtherUsers(address[] memory _accounts) external {
        // Loop through the addresses
        for (uint256 i = 0; i < _accounts.length; ) {
            // Sync once to save gas
            sync();

            // Can skip syncing here since you did it above
            _checkpointUser(_accounts[i], false);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Checkpoint yourself
    function checkpoint() external {
        _checkpointUser(msg.sender, true);
    }

    /// @notice Retrieve yield for a specific address and send it to the designed recipient
    /// @param _staker The address whose rewards to collect
    /// @param _recipient Recipient of the rewards
    /// @return _yield0 The amount collected
    function _getYield(
        address _staker,
        address _recipient
    ) internal nonReentrant notYieldCollectionPaused checkpointUser(_staker) returns (uint256 _yield0) {
        if (greylist[_staker]) revert AddressGreylisted();

        _yield0 = yields[_staker];
        if (_yield0 > 0) {
            yields[_staker] = 0;
            TransferHelper.safeTransfer(emittedTokenAddress, _recipient, _yield0);
            emit YieldCollected(_staker, _recipient, _yield0, emittedTokenAddress);
        }

        lastRewardClaimTime[_staker] = block.timestamp;
    }

    /// @notice Retrieve own yield
    /// @return _yield0 The amount collected
    function getYield() external returns (uint256 _yield0) {
        // Sender collects rewards for himself
        _yield0 = _getYield(msg.sender, msg.sender);
    }

    /// @notice Retrieve another address's yield. Only for specific cases (e.g. Convex, etc) where the mainnet contract cannot claim for itself
    /// @param _staker Address whose rewards to collect
    /// @return _yield0 The amount collected
    /// @dev Only specific addresses allowed by the admin can do this, and only 1:1 (i.e. the third party can only collect one specified address's rewards)
    function getYieldThirdParty(address _staker) external returns (uint256 _yield0) {
        // Make sure the sender is authorized for this _staker
        if (thirdPartyClaimers[_staker] != msg.sender) revert SenderNotAuthorizedClaimer();

        // Sender collects _staker's rewards and sends to himself
        _yield0 = _getYield(_staker, msg.sender);
    }

    /// @notice Sync contract-wide variables
    function sync() public {
        // Update the yieldPerVeFXSStored
        // console2.log("Update the yieldPerVeFXSStored");
        yieldPerVeFXSStored = yieldPerVeFXS();

        // Update the total veFXS supply
        // console2.log("Update the totalComboVeFXSSupplyStored");
        totalComboVeFXSSupplyStored = veFXSAggregator.ttlCombinedVeFXSTotalSupply();

        // Update the last update time
        // console2.log("Update the lastUpdateTime");
        lastUpdateTime = lastTimeYieldApplicable();

        // console2.log("Sync completed");
    }

    /// @notice Deposit rewards. Only callable by privileged users
    /// @param _amount The amount to deposit
    function notifyRewardAmount(uint256 _amount) external {
        // Only whitelisted addresses can notify rewards
        if (!rewardNotifiers[msg.sender]) revert SenderNotRewarder();

        // Handle the transfer of emission tokens via `transferFrom` to reduce the number
        // of transactions required and ensure correctness of the emission amount
        emittedToken.safeTransferFrom(msg.sender, address(this), _amount);

        // Update some values beforehand
        sync();

        // Update the new yieldRate
        if (block.timestamp >= periodFinish) {
            yieldRate = _amount / yieldDuration;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * yieldRate;
            yieldRate = (_amount + leftover) / yieldDuration;
        }

        // Update duration-related info
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + yieldDuration;

        // Update some values afterwards
        totalComboVeFXSSupplyStored = veFXSAggregator.ttlCombinedVeFXSTotalSupply();

        emit RewardAdded(_amount, yieldRate);
    }

    // ==============================================================================
    // RESTRICTED FUNCTIONS
    // ==============================================================================

    /// @notice Added to support recovering LP Yield and other mistaken tokens from other systems to be distributed to holders
    /// @param _tokenAddress The token to recover
    /// @param _tokenAmount The amount to recover
    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyByOwnGov {
        // Only the owner address can ever receive the recovery withdrawal
        TransferHelper.safeTransfer(_tokenAddress, owner, _tokenAmount);
        emit RecoveredERC20(_tokenAddress, _tokenAmount);
    }

    /// @notice Set the duration of the yield
    /// @param _yieldDuration New duration in seconds
    function setYieldDuration(uint256 _yieldDuration) external onlyByOwnGov {
        if (periodFinish != 0 && block.timestamp <= periodFinish) {
            revert YieldPeriodMustCompleteBeforeChangingToNewPeriod();
        }
        yieldDuration = _yieldDuration;
        emit YieldDurationUpdated(yieldDuration);
    }

    /// @notice Greylist an address that is misbehaving
    /// @dev This is a toggle, so it can re-enable to user as well
    /// @param _address The address to greylist
    function greylistAddress(address _address) external onlyByOwnGov {
        greylist[_address] = !(greylist[_address]);
    }

    /// @notice Toggle an address as being able to be a reward notifier
    /// @param _notifierAddr The address to toggle
    function toggleRewardNotifier(address _notifierAddr) external onlyByOwnGov {
        rewardNotifiers[_notifierAddr] = !rewardNotifiers[_notifierAddr];
    }

    /// @notice Set the veFXS Aggregator contract
    /// @param _veFXSAggregator The new address of the veFXS Aggregator
    function setVeFXSAggregator(address _veFXSAggregator) external onlyByOwnGov {
        veFXSAggregator = VeFXSAggregator(_veFXSAggregator);
    }

    /// @notice Pause / unpause yield collecting
    /// @param _yieldCollectionPaused The new status
    function setPauses(bool _yieldCollectionPaused) external onlyByOwnGov {
        yieldCollectionPaused = _yieldCollectionPaused;
    }

    /// @notice Used for manual reward rates. Only valid until the next notifyRewardAmount() or setYieldRate()
    /// @param _newRate The new rate
    /// @param _syncToo Whether to sync or not
    function setYieldRate(uint256 _newRate, bool _syncToo) external onlyByOwnGov {
        yieldRate = _newRate;

        if (_syncToo) {
            sync();
        }
    }

    /// @notice Allow a 3rd party address to claim the rewards of a specific staker
    /// @param _staker The address of the staker
    /// @param _claimer The address of the claimer
    /// @dev For Convex, StakeDAO, etc whose contract addresses cannot claim for themselves. Admin set on a case-by-case basis
    function setThirdPartyClaimer(address _staker, address _claimer) external onlyByOwnGov {
        thirdPartyClaimers[_staker] = _claimer;
    }

    /// @notice Set the timelock address
    /// @param _newTimelock The address of the timelock
    function setTimelock(address _newTimelock) external onlyByOwnGov {
        timelockAddress = _newTimelock;

        emit TimelockChanged(_newTimelock);
    }

    // ==============================================================================
    // EVENTS
    // ==============================================================================

    /// @notice When the contract is initialized
    event DefaultInitialization();

    /// @notice When ERC20 tokens were recovered
    /// @param token Token address
    /// @param amount Amount of tokens collected
    event RecoveredERC20(address token, uint256 amount);

    /// @notice When a reward is deposited
    /// @param reward Amount of tokens deposited
    /// @param yieldRate The resultant yield/emission rate
    event RewardAdded(uint256 reward, uint256 yieldRate);

    /// @notice Emitted when the timelock address changes
    /// @param timelock_address Address of the removed timelock
    event TimelockChanged(address timelock_address);

    /// @notice When yield is collected
    /// @param staker Address whose rewards to collect
    /// @param recipient Address where the yield is ultimately sent
    /// @param yield The amount of tokens collected
    /// @param tokenAddress The address collecting the rewards
    event YieldCollected(address indexed staker, address indexed recipient, uint256 yield, address tokenAddress);

    /// @notice When the yield duration is updated
    /// @param newDuration The new duration
    event YieldDurationUpdated(uint256 newDuration);

    // ==============================================================================
    // ERRORS
    // ==============================================================================

    /// @notice If the address was greylisted
    error AddressGreylisted();

    /// @notice Cannot initialize twice
    error InitializeFailed();

    /// @notice If you are trying to call a function not as the owner or timelock
    error NotOwnerOrTimelock();

    /// @notice If the sender is not an authorized thirdPartyClaimers for the specified staker address
    error SenderNotAuthorizedClaimer();

    /// @notice If the sender is not a rewarder
    error SenderNotRewarder();

    /// @notice If yield collection is paused
    error YieldCollectionPaused();

    /// @notice If you are trying to change a yield period before it ends
    error YieldPeriodMustCompleteBeforeChangingToNewPeriod();

    /* ====================================== A NIFFLER ================================================ */
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0OxdOKKOOkxxxxxxk0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0dl:,',cc:;;;;;;;;,'';cx0XWMMMMMMMMMMMMMMMMMMMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkl:;::::::::::;;;;:::::;;,;cox0NWMMMMMMMMMMMMMMMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXxc;;:;;;;;;;,;,,,,,,,,,;,,,,,,,,;cdOXMMMMMMMMMMMMMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOc;;;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'.;d0NMMMMMMMMMMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd;;:;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'',l0WMMMMMMMMMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo;;;,,,,,,,,,,,,,,,,,,,,,,''''''',,,,,,,,,,ckNMMMMMMMMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd;;,,,,,,,,,,,,,,,,,,,,,,,'''''...'',,,,,,,,,,l0WMMMMMMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'''''',,,,,,,'.'xNMMMMMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'.'kWMMMMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0:',,,,,,,,,,,,,,,;;;,,,,,,,,,,,,,,,,,,,,,,,,,,,,''lKMMMMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO;',,;;,,,,,,,;:cc:;:c;,,,,,,,,,,,,,,,,,,,,,,,,,,,,'c0WMMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk,';lkkxoc;,,,cxl,...cl,,,,,,,,,,,,,,,,,,,,,,,,,,,,'':OWMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx;cx00000OkdooxOd;',;ll,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'.;OWMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKOxdxO00000000000000Oxxxd:,,''',,,,,,,,,,,,,,,,,,,,,,,,'..,OWMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMWKkkOO00OOkxxxO00000000000000000Okddd:.....'''''',,,,,,,,,,,,,,,,,,,'..oNMMMMMMM
    // MMMMMMMMMMMMMMMMMMMM0ookkxxxdxk00000000000000000Okkkxxdl;............',,,,,,,,,,,,,,,,,,'..;OMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMKdoxOOOO000000000000000Okkxdollc:;'.....''..''....',,,,,,,,,,,,,,,,,,'..;KMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMNOxddodddxxxxxxxxddoll:,,,,,'''''''.'',,''',,'','',,,,,,,,,,,,,,,,,,,'..dNMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMNXK0OOOkkkkkkkOkdc;'.',,,,,,''''',,,,,,,,,,,,,,,,,,,,,',,,,,,,,,,,,.,xNMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKko:;:lodxxxxxdolc;,,,,,,,,,,,,,,,,,,,'''',,,,,,,,,,,,''dWMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkddl:lxO000000000000Odc;,,,,,,,,,,,,,,'.',,,,,,,,,,,,,,,,.:KMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0odO0kooxO00000000000000Oxl:::::::;;;::,.',,,,,,,,,,,,,,,,,',kMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXdlk0kdodO000000000000000kxdxOOOOOkkkkOkxc,',,,,,,,,,,,,,,,,'.dWMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMWNKkdoccol:loc:;:lllllllooddxkOOOdllok0OO0000000Od;',,,,,,,,,,,,,,,,'.lNMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMKl:c::c:;,,','',,,,,,,,,,,,,,,;:cllcc::::::clodxxdc,',,,'''..'',,,,,,'.cXMMMM
    // MMMMMMMMMMMMMMMMMMMMMMXo:clc:;,,,,,,,,,,,,,,,,,,,,,,,,,,,,;;,''''''''''''..........',,,,,,,,..cXMMMM
    // MMMMMMMMMMMMMMMMMMMMMMOlol,'',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,''''''''....''''''',,,,,,,,,,,,,..lNMMMM
    // MMMMMMMMMMMMMMMMMMMMMMk:;,,,,,,,,,,,,,,,,,,,,,,,:,',,,,,,,''..............'',,,,,,,,,,,,,,,,..dWMMMM
    // MMMMWWWMWWMMMMMMMMMMMXl'',,,,,,,,,,,,,,,,;:;:olcdocl:'''.....'',,,,,,''',''..',,,,,,,,,,,,,'.;0MMMMM
    // MMMMXdlxllkXWMNXWMMMNo..,,,,,,,,,,,,,,,,,:oxoxkxkOOOl'....'',,,,,,,,,,,,,,,,'.'',,,,,,,,,,'..oWMMMMM
    // MMMMWk,...';ldc,lxk0k;.',,,,,,,,,,,,,,,,,;ckOOO00000l..'',,,,,,,,,,,,,,,,,,,,,'',,,,,,,,,,..'kMMMMMM
    // MMMMMNl..,,,,'''''',,'....'',,,,,,,,,,,,cook0000000Oc..',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'..;0MMMMMM
    // MMMMMMO...',,,,,,,,,,,'.'''..''',,,,,,,,lkkO000000Ox;.',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,...lNMMMMMM
    // MMMMMMNl....'',,,,,,,,,,,,,,''''..',,,,;dkO00000xlc:,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'..'kMMMMMMM
    // MMMMMMMk'....',,,,,,,,,,,,,,,,,''..'',,:xkO000Oxc,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'...cXMMMMMMM
    // MMMMMMMX:....'',,,,,,,,,,,,,,,,,,''..''cxkO0Oxl:,,,,,,,,,,,,,,,,,,,,,,',,,,,,,,,,,,,,,'..,o0MMMMMMMM
    // MMMMMMMM0,.....'',,,,,,,,,,,,,,,,,,,'.':xkOOd;'',,,,,,,,,,,,,,,,,,,,'''',,,,,,,,,,,,,'..'kWMMMMMMMMM
    // MMMMMMMMW0;......'',,,,,,,,,,,,,,,,,,'';dkkd:,,,,,,,,,,,,,,,,,,,,,,'''',,,,,,,,,,,,,'..'xWMMMMMMMMMM
    // MMMMMMMMMMKl.......'',,,,,,,,,,,,,,,,,,,cdl;,,,,,,,,,,,,,,,,,,,,'''''',,,,,,,,,,,,,'..'xNMMMMMMMMMMM
    // MMMMMMMMMMMNx,.......''',,,,,,,,,,,,,,,',;,',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,''...;OWMMMMMMMMMMMM
    // MMMMMMMMMMMMNk;..........'',,,,,,,,,,,,,'..',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'....'oXMMMMMMMMMMMMMM
    // MMMMMMMMMMMMMWXx;.......'',,,,,,,,,,,,,,'..',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'....'l0WMMMMMMMMMMMMMMM
    // MMMMMMMMMMMMMMMMN0o;......''''''''',,,,,,''',,,,,,,,,,,,,,,,,,,,,''',,,,,''....'l0WMMMMMMMMMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMNk:..............'''''','',,,,,,,,,,,,,,,,'''...''''...':ccdKWMMMMMMMMMMMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMN0dc;'..................''''''''''''''..........';cokKNNNMMMMMMMMMMMMMMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMNX0Okxddoolc::;,'............''','...',:loxOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXK0OOOkkkkkOOO0KKK000KXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
}
