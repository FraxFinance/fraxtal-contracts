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
// ========================= VeFXSAggregator ==========================
// ====================================================================
// Looks at various sources of veFXS for a given address. Also gives totalSupply
// Includes:
// 1) L1veFXS: Lives on Fraxtal. Users can prove their Ethereum Mainnet vefxs.vy balance and end time so it is visible on Fraxtal
// 2) VestedFXS: Fraxtal-native veFXS. Basically the same as Mainnet vefxs.vy but lives on Fraxtal
// 3) FPISLocker: Locked FPIS on Fraxtal that eventually will be converted to FXS per https://snapshot.org/#/frax.eth/proposal/0x9ec68015d6f6fd185f600a255e494f4ff926bbdd9b268f4bd712983a6e68fb5a
// 4+) Future capability to add even more sources of veFXS

// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna

// Reviewer(s) / Contributor(s)
// Jan Turk: https://github.com/ThunderDeliverer
// Dennis: https://github.com/denett
// Sam Kazemian: https://github.com/samkazemian

// Originally inspired by Synthetix.io, but heavily modified by the Frax team (veFXS portion)
// https://github.com/Synthetixio/synthetix/blob/develop/contracts/StakingRewards.sol

import { L1VeFXSTotalSupplyOracle } from "./L1VeFXSTotalSupplyOracle.sol";
import { IFPISLocker } from "../interfaces/IFPISLocker.sol";
import { IL1VeFXS } from "../interfaces/IL1VeFXS.sol";
import { IVestedFXS } from "../interfaces/IVestedFXS.sol";
import { IVestedFXSUtils } from "../interfaces/IVestedFXSUtils.sol";
import { FPISLockerUtils } from "../FPISLocker/FPISLockerUtils.sol";
import { IlFPISStructs } from "../FPISLocker/IlFPISStructs.sol";
import { IveFXSStructs } from "./IveFXSStructs.sol";
import { TransferHelper } from "../Flox/TransferHelper.sol";
import "@openzeppelin-4/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin-4/contracts/token/ERC20/utils/SafeERC20.sol";
import { OwnedV2AutoMsgSender } from "./OwnedV2AutoMsgSender.sol";

// import "forge-std/console2.sol";

contract VeFXSAggregator is OwnedV2AutoMsgSender, IveFXSStructs {
    using SafeERC20 for ERC20;

    // ==============================================================================
    // STATE VARIABLES
    // ==============================================================================

    // Instances
    // -------------------------
    /// @notice The Fraxtal veFXS contract
    IVestedFXS public veFXS;

    /// @notice The FPIS Locker contract
    IFPISLocker public fpisLocker;

    /// @notice The IL1VeFXS contract (snapshot of Ethereum Mainnet veFXS.vy)
    IL1VeFXS public l1veFXS;

    /// @notice The Fraxtal veFXS veFXSUtils contract
    IVestedFXSUtils public veFXSUtils;

    /// @notice The Fraxtal FPIS Locker FPISLockerUtils contract
    FPISLockerUtils public lFpisUtils;

    /// @notice Oracle on Fraxtal that reports Mainnet veFXS totalSupply.
    L1VeFXSTotalSupplyOracle public l1VeFXSTotalSupplyOracle;

    // Addresses
    // -------------------------
    /// @notice Address of the timelock
    address public timelockAddress;

    /// @notice Array of additional / future veFXS-like contracts
    address[] public addlVeContractsArr;

    /// @notice Whether an address is an additional / future veFXS-like contract
    mapping(address => bool) public addlVeContracts;

    // Misc
    // -------------------------

    /// @notice If the contract was initialized
    bool wasInitialized;

    // /// @dev reserve extra storage for future upgrades
    // uint256[50] private __gap;

    // ==============================================================================
    // STRUCTS
    // ==============================================================================

    /// @notice A more detailed breakdown of the veFXS supply
    /// @param vestedFXSTotal Fraxtal-native VestedFXS totalSupply
    /// @param fpisLockerTotal FPISLocker's totalSupply
    /// @param l1veFXSTotal Sum of L1veFXS as reported by the L1VeFXSTotalSupplyOracle
    /// @param otherSourcesTotal Sum of the totalSupply's of other veFXS sources
    /// @param grandTotal Grand totalSupply of all veFXS sources
    struct DetailedTotalSupplyInfo {
        uint256 vestedFXSTotal;
        uint256 fpisLockerTotal;
        uint256 l1veFXSTotal;
        uint256 otherSourcesTotal;
        uint256 grandTotal;
    }

    // ==============================================================================
    // MODIFIERS
    // ==============================================================================

    /// @notice A modifier that only allows the contract owner or the timelock to call
    modifier onlyByOwnGov() {
        if (msg.sender != owner && msg.sender != timelockAddress) revert NotOwnerOrTimelock();
        _;
    }

    // ==============================================================================
    // CONSTRUCTOR
    // ==============================================================================

    constructor() {
        // Set the contract as initialized
        // wasInitialized = true;
    }

    /**
     * @notice Initialize contract
     * @param _owner The owner of this contract
     * @param _timelockAddress Address of the timelock
     * @param _veAddresses The addresses: 0: veFXS, 1: veFXSUtils, 2: FPIS Locker, 3: FPISLockerUtils, 4: L1VeFXS, 5: L1VeFXSTotalSupplyOracle
     */
    function initialize(address _owner, address _timelockAddress, address[6] memory _veAddresses) public {
        // Safety checks - no validation on admin in case this is initialized without admin
        if (wasInitialized) revert InitializeFailed();

        // Set owner for OwnedV2
        owner = _owner;

        // Set misc addresses
        timelockAddress = _timelockAddress;

        // Set the Fraxtal VestedFXS
        veFXS = IVestedFXS(_veAddresses[0]);
        veFXSUtils = IVestedFXSUtils(_veAddresses[1]);

        // (Optional) Set the FPISLocker
        if ((_veAddresses[2] != address(0)) && (_veAddresses[3] != address(0))) {
            fpisLocker = IFPISLocker(_veAddresses[2]);
            lFpisUtils = FPISLockerUtils(_veAddresses[3]);
        }

        // (Optional) Set the L1VeFXS andL1VeFXSTotalSupplyOracle
        if ((_veAddresses[4] != address(0)) && (_veAddresses[5] != address(0))) {
            l1veFXS = IL1VeFXS(_veAddresses[4]);
            l1VeFXSTotalSupplyOracle = L1VeFXSTotalSupplyOracle(_veAddresses[5]);
        }

        // Set the contract as initialized
        wasInitialized = true;
    }

    // ==============================================================================
    // VIEWS
    // ==============================================================================

    /// @notice Same as ttlCombinedVeFXS. For backwards-compatibility
    /// @param _addr The address to check
    /// @return _balance The veFXS balance of the _addr
    function balanceOf(address _addr) public view returns (uint256 _balance) {
        return ttlCombinedVeFXS(_addr);
    }

    /// @notice Returns the decimals
    function decimals() public view returns (uint256) {
        return 18;
    }

    /// @notice Returns the name
    function name() public view returns (string memory) {
        return "Vested FRAX";
    }

    /// @notice Returns the symbol
    function symbol() public view returns (string memory) {
        return "veFRAX";
    }

    /// @notice Total veFXS of a user from multiple different sources, such as the FPIS Locker, L1VeFXS, and Fraxtal veFXS
    /// @param _user The user to check
    /// @return _currBal The veFXS balance
    function ttlCombinedVeFXS(address _user) public view returns (uint256 _currBal) {
        // Look at the OG 3 sources first
        // ===========================
        // VestedFXS on Fraxtal
        _currBal = veFXS.balanceOf(_user);

        // (Optional) FPIS Locker on Fraxtal
        if (address(fpisLocker) != address(0)) _currBal += fpisLocker.balanceOf(_user);

        // (Optional) L1VeFXS: snapshot of Ethereum Mainnet veFXS. Lives on Fraxtal
        if ((address(l1veFXS) != address(0)) && (address(l1VeFXSTotalSupplyOracle) != address(0))) {
            _currBal += l1veFXS.balanceOf(_user);
        }

        // (Optional) Look at any extra veFXS sources
        for (uint256 i; i < addlVeContractsArr.length; ) {
            address _veAddr = addlVeContractsArr[i];
            if (_veAddr != address(0)) {
                _currBal += IVestedFXS(_veAddr).balanceOf(_user);
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Detailed veFXS totalSupply from multiple different sources, such as the FPIS Locker, L1VeFXS, and Fraxtal veFXS. Non-checkpointed L1VeFXS is excluded
    /// @return _supplyInfo Detailed breakdown of veFXS from different sources
    function ttlCombinedVeFXSTotalSupplyDetailed() public view returns (DetailedTotalSupplyInfo memory _supplyInfo) {
        // Look at the OG 3 sources first
        // ===========================
        // VestedFXS on Fraxtal
        _supplyInfo.vestedFXSTotal = veFXS.totalSupply();
        _supplyInfo.grandTotal = _supplyInfo.vestedFXSTotal;
        // console2.log("{agg} veFXS.totalSupply(): %s", _supplyInfo.vestedFXSTotal);

        // (Optional) FPIS Locker on Fraxtal
        if (address(fpisLocker) != address(0)) {
            _supplyInfo.fpisLockerTotal = fpisLocker.totalSupply();
            _supplyInfo.grandTotal += _supplyInfo.fpisLockerTotal;
            // console2.log("{agg} fpisLocker.totalSupply(): %s", _supplyInfo.fpisLockerTotal);
        }

        // (Optional) L1VeFXS: snapshot of Ethereum Mainnet veFXS. Lives on Fraxtal
        if ((address(l1veFXS) != address(0)) && (address(l1VeFXSTotalSupplyOracle) != address(0))) {
            _supplyInfo.l1veFXSTotal = l1VeFXSTotalSupplyOracle.totalSupply();
            _supplyInfo.grandTotal += _supplyInfo.l1veFXSTotal;
            // console2.log("{agg} l1VeFXSTotalSupplyOracle.totalSupply(): %s", _supplyInfo.l1veFXSTotal);
        }

        // (Optional) Look at any extra veFXS sources
        for (uint256 i; i < addlVeContractsArr.length; ) {
            address _veAddr = addlVeContractsArr[i];
            if (_veAddr != address(0)) {
                uint256 _thisSupply = IVestedFXS(_veAddr).totalSupply();
                _supplyInfo.otherSourcesTotal += _thisSupply;
                _supplyInfo.grandTotal += _thisSupply;
                // console2.log("{agg} addlVeContractsArr[%s].totalSupply(): %s", i, _thisSupply);
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Total veFXS totalSupply from multiple different sources, such as the FPIS Locker, L1VeFXS, and Fraxtal veFXS. Non-checkpointed L1VeFXS is excluded
    /// @return _totalSupply The veFXS totalSupply from all sources
    /// @dev Summarized version of ttlCombinedVeFXSTotalSupplyDetailed
    function ttlCombinedVeFXSTotalSupply() public view returns (uint256 _totalSupply) {
        DetailedTotalSupplyInfo memory _supplyInfo = ttlCombinedVeFXSTotalSupplyDetailed();
        _totalSupply = _supplyInfo.grandTotal;
    }

    /// @notice Array of all extra veFXS-like contracts
    /// @return _addresses The addresses
    function allAddlVeContractsAddresses() external view returns (address[] memory _addresses) {
        return addlVeContractsArr;
    }

    /// @notice Length of the array of all extra veFXS-like contracts
    /// @return _length The length
    function allAddlVeContractsLength() external view returns (uint256 _length) {
        return addlVeContractsArr.length;
    }

    /// @notice Get all the active locks for a user
    /// @param _account The account to get the locks for
    /// @param _estimateCrudeVeFXS False to save gas. True to add the lock's estimated veFXS
    /// @return _currActiveLocks Array of LockedBalanceExtendedV2 structs (all active locks)
    function getAllCurrActiveLocks(
        address _account,
        bool _estimateCrudeVeFXS
    ) public view returns (LockedBalanceExtendedV2[] memory _currActiveLocks) {
        // Prepare to allocate the return array. Not all of the locks will be active.

        // OG 3 veFXS contracts
        // ===================================
        // Fraxtal VestedFXS
        uint256 _maxArrSize = veFXS.numLocks(_account);

        // (Optional) FPIS Locker
        if (address(fpisLocker) != address(0)) _maxArrSize += fpisLocker.numLocks(_account);

        // (Optional) L1VeFXS
        if ((address(l1veFXS) != address(0)) && (address(l1VeFXSTotalSupplyOracle) != address(0))) {
            _maxArrSize += 1; // Legacy veFXS on Mainnet only has one lock
        }

        // (Optional) Get the total number of locks in the additional veFXS contracts
        for (uint256 i = 0; i < addlVeContractsArr.length; ) {
            address _veAddr = addlVeContractsArr[i];
            if (_veAddr != address(0)) {
                // Get the total number of locks
                _maxArrSize += IVestedFXS(_veAddr).numLocks(_account);
            }

            unchecked {
                ++i;
            }
        }

        // Allocate a temporary dynamic array
        uint256 _activeLockIdx = 0;
        LockedBalanceExtendedV2[] memory _tmpActiveLocks = new LockedBalanceExtendedV2[](_maxArrSize);

        // Go through the OG 3 sources first

        // Fraxtal veFXS
        // -------------------------
        {
            // Get the LockedBalanceExtendeds
            LockedBalanceExtended[] memory _fxtlVeFXSLockedBalExtds = (veFXSUtils.getDetailedUserLockInfo(_account))
                .activeLocks;

            // Loop though the Fraxtal veFXS locks and add them to the combined array
            for (uint256 i; i < _fxtlVeFXSLockedBalExtds.length; ) {
                // Save tmp variable to memory
                IveFXSStructs.LockedBalanceExtended memory _vestedFXSLockInfo = _fxtlVeFXSLockedBalExtds[i];

                // (Optional) Estimate the lock's veFXS based on amount, end, and block.timestamp
                uint256 _estimatedVeFXS;
                if (_estimateCrudeVeFXS) {
                    _estimatedVeFXS = veFXSUtils.getCrudeExpectedVeFXSOneLock(
                        _vestedFXSLockInfo.amount,
                        _vestedFXSLockInfo.end - uint128(block.timestamp)
                    );
                }

                // Add to the temp array
                _tmpActiveLocks[_activeLockIdx] = LockedBalanceExtendedV2({
                    id: _vestedFXSLockInfo.id,
                    index: _vestedFXSLockInfo.index,
                    amount: _vestedFXSLockInfo.amount,
                    end: _vestedFXSLockInfo.end,
                    location: address(veFXS),
                    estimatedCurrLockVeFXS: _estimatedVeFXS
                });

                // Increase the active lock index
                ++_activeLockIdx;

                unchecked {
                    ++i;
                }
            }
        }

        // (Optional) FPIS Locker
        // -------------------------
        if (address(fpisLocker) != address(0)) {
            // Get the LockedBalanceExtendeds
            IlFPISStructs.LockedBalanceExtended[] memory _fpisLockerLockedBalExtds = (
                lFpisUtils.getDetailedUserLockInfo(_account)
            ).activeLocks;

            // Loop though the FPIS Locker locks and add them to the combined array
            for (uint256 i; i < _fpisLockerLockedBalExtds.length; ) {
                // Save tmp variable to memory
                IlFPISStructs.LockedBalanceExtended memory _fpisLockInfo = _fpisLockerLockedBalExtds[i];

                // (Optional) Estimate the lock's veFXS based on amount, end, and block.timestamp
                uint256 _estimatedVeFXS;
                if (_estimateCrudeVeFXS) {
                    _estimatedVeFXS = lFpisUtils.getCrudeExpectedLFPISOneLock(
                        _fpisLockInfo.amount,
                        _fpisLockInfo.end - uint128(block.timestamp)
                    );
                }

                // Need to save as LockedBalanceExtendedV2
                _tmpActiveLocks[_activeLockIdx] = LockedBalanceExtendedV2({
                    id: _fpisLockInfo.id,
                    index: _fpisLockInfo.index,
                    amount: _fpisLockInfo.amount,
                    end: _fpisLockInfo.end,
                    location: address(fpisLocker),
                    estimatedCurrLockVeFXS: _estimatedVeFXS
                });

                // Increase the active lock index
                ++_activeLockIdx;

                unchecked {
                    ++i;
                }
            }
        }

        // (Optional) L1VeFXS
        // -------------------------
        if ((address(l1veFXS) != address(0)) && (address(l1VeFXSTotalSupplyOracle) != address(0))) {
            // Get the LockedBalance
            IL1VeFXS.LockedBalance memory _l1LockedBalance = l1veFXS.locked(_account);

            // Convert to LockedBalanceExtendedV2 and push into _currCombinedLockBalExtds if it is active. There is only one lock too
            if (_l1LockedBalance.end > block.timestamp) {
                // (Optional) Estimate the lock's veFXS based on amount, end, and block.timestamp
                uint256 _estimatedVeFXS;
                if (_estimateCrudeVeFXS) {
                    _estimatedVeFXS = l1veFXS.balanceOf(_account);
                }

                // Add to the temp array
                _tmpActiveLocks[_activeLockIdx] = LockedBalanceExtendedV2({
                    id: 0,
                    index: 0,
                    amount: int128(_l1LockedBalance.amount),
                    end: _l1LockedBalance.end,
                    location: address(l1veFXS),
                    estimatedCurrLockVeFXS: _estimatedVeFXS
                });

                // Increase the active lock index
                ++_activeLockIdx;
            }
        }

        // (Optional) Look in the extra veFXS sources next. They should all be IVestedFXS ABI compliant
        for (uint256 i; i < addlVeContractsArr.length; ) {
            address _veAddr = addlVeContractsArr[i];
            if (_veAddr != address(0)) {
                // Get the active locks
                LockedBalanceExtended[] memory _addlVeFXSLockedBalExtds = (
                    IVestedFXSUtils(IVestedFXS(_veAddr).veFxsUtils()).getDetailedUserLockInfo(_account)
                ).activeLocks;

                // Loop though the active locks and add them to the combined array
                for (uint256 j; j < _addlVeFXSLockedBalExtds.length; ) {
                    // Save tmp variable to memory
                    IveFXSStructs.LockedBalanceExtended memory _addVeFXSLockInfo = _addlVeFXSLockedBalExtds[j];

                    // (Optional) Estimate the lock's veFXS based on amount, end, and block.timestamp
                    uint256 _estimatedVeFXS;
                    if (_estimateCrudeVeFXS) {
                        _estimatedVeFXS = IVestedFXSUtils(IVestedFXS(_veAddr).veFxsUtils())
                            .getCrudeExpectedVeFXSOneLock(
                                _addVeFXSLockInfo.amount,
                                _addVeFXSLockInfo.end - uint128(block.timestamp)
                            );
                    }

                    // Add to the temporary array
                    _tmpActiveLocks[_activeLockIdx] = LockedBalanceExtendedV2({
                        id: _addVeFXSLockInfo.id,
                        index: _addVeFXSLockInfo.index,
                        amount: _addVeFXSLockInfo.amount,
                        end: _addVeFXSLockInfo.end,
                        location: _veAddr,
                        estimatedCurrLockVeFXS: _estimatedVeFXS
                    });

                    // Increase the active lock index
                    ++_activeLockIdx;

                    unchecked {
                        ++j;
                    }
                }
            }

            unchecked {
                ++i;
            }
        }

        // Allocate the return array with only the number of active locks
        _currActiveLocks = new LockedBalanceExtendedV2[](_activeLockIdx);

        // Fill the return array
        for (uint256 i; i < _currActiveLocks.length; ) {
            _currActiveLocks[i] = _tmpActiveLocks[i];

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Get all the expired locks for a user
    /// @param _account The account to get the locks for
    /// @return _expiredLocks Array of LockedBalanceExtendedV2 structs (all expired locks)
    /// @dev Technically could combine with getAllCurrActiveLocks to save gas, but getAllExpiredLocks is mainly intended for a UI
    function getAllExpiredLocks(address _account) public view returns (LockedBalanceExtendedV2[] memory _expiredLocks) {
        // Prepare to allocate the return array. Not all of the locks will be expired.

        // OG 3 veFXS contracts
        // ===================================
        // Fraxtal VestedFXS
        uint256 _maxArrSize = veFXS.numLocks(_account);

        // (Optional) FPIS Locker
        if (address(fpisLocker) != address(0)) _maxArrSize += fpisLocker.numLocks(_account);

        // (Optional) L1VeFXS
        if ((address(l1veFXS) != address(0)) && (address(l1VeFXSTotalSupplyOracle) != address(0))) {
            _maxArrSize += 1; // Legacy veFXS on Mainnet only has one lock
        }

        // (Optional) Get the total number of locks in the additional veFXS contracts
        for (uint256 i = 0; i < addlVeContractsArr.length; ) {
            address _veAddr = addlVeContractsArr[i];
            if (_veAddr != address(0)) {
                // Get the total number of locks
                _maxArrSize += IVestedFXS(_veAddr).numLocks(_account);
            }

            unchecked {
                ++i;
            }
        }

        // Allocate a temporary dynamic array
        uint256 _expiredLockIdx = 0;
        LockedBalanceExtendedV2[] memory _tmpExpiredLocks = new LockedBalanceExtendedV2[](_maxArrSize);

        // Go through the OG 3 sources first

        // Fraxtal veFXS
        // -------------------------
        {
            // Get the LockedBalanceExtendeds
            LockedBalanceExtended[] memory _fxtlVeFXSLockedBalExtds = (veFXSUtils.getDetailedUserLockInfo(_account))
                .expiredLocks;

            // Loop though the Fraxtal veFXS locks and add them to the combined array
            for (uint256 i; i < _fxtlVeFXSLockedBalExtds.length; ) {
                // Save tmp variable to memory
                IveFXSStructs.LockedBalanceExtended memory _vestedFXSLockInfo = _fxtlVeFXSLockedBalExtds[i];

                // Add to the temp array
                _tmpExpiredLocks[_expiredLockIdx] = LockedBalanceExtendedV2({
                    id: _vestedFXSLockInfo.id,
                    index: _vestedFXSLockInfo.index,
                    amount: _vestedFXSLockInfo.amount,
                    end: _vestedFXSLockInfo.end,
                    location: address(veFXS),
                    estimatedCurrLockVeFXS: 0
                });

                // Increase the expired lock index
                ++_expiredLockIdx;

                unchecked {
                    ++i;
                }
            }
        }

        // (Optional) FPIS Locker
        // -------------------------
        if (address(fpisLocker) != address(0)) {
            // Get the LockedBalanceExtendeds
            IlFPISStructs.LockedBalanceExtended[] memory _fpisLockerLockedBalExtds = (
                lFpisUtils.getDetailedUserLockInfo(_account)
            ).expiredLocks;

            // Loop though the FPIS Locker locks and add them to the combined array
            for (uint256 i; i < _fpisLockerLockedBalExtds.length; ) {
                // Save tmp variable to memory
                IlFPISStructs.LockedBalanceExtended memory _fpisLockInfo = _fpisLockerLockedBalExtds[i];

                // Need to save as LockedBalanceExtendedV2
                _tmpExpiredLocks[_expiredLockIdx] = LockedBalanceExtendedV2({
                    id: _fpisLockInfo.id,
                    index: _fpisLockInfo.index,
                    amount: _fpisLockInfo.amount,
                    end: _fpisLockInfo.end,
                    location: address(fpisLocker),
                    estimatedCurrLockVeFXS: 0
                });

                // Increase the expired lock index
                ++_expiredLockIdx;

                unchecked {
                    ++i;
                }
            }
        }

        // (Optional) L1VeFXS
        // -------------------------
        if ((address(l1veFXS) != address(0)) && (address(l1VeFXSTotalSupplyOracle) != address(0))) {
            // Get the LockedBalance
            IL1VeFXS.LockedBalance memory _l1LockedBalance = l1veFXS.locked(_account);

            // Convert to LockedBalanceExtendedV2 and push into _currCombinedLockBalExtds if it is expired. There is only one lock too
            if (_l1LockedBalance.end <= block.timestamp) {
                // Add to the temp array
                _tmpExpiredLocks[_expiredLockIdx] = LockedBalanceExtendedV2({
                    id: 0,
                    index: 0,
                    amount: int128(_l1LockedBalance.amount),
                    end: _l1LockedBalance.end,
                    location: address(l1veFXS),
                    estimatedCurrLockVeFXS: 0
                });

                // Increase the expired lock index
                ++_expiredLockIdx;
            }
        }

        // (Optional) Look in the extra veFXS sources next. They should all be IVestedFXS ABI compliant
        for (uint256 i; i < addlVeContractsArr.length; ) {
            address _veAddr = addlVeContractsArr[i];
            if (_veAddr != address(0)) {
                // Get the expired locks
                LockedBalanceExtended[] memory _addlVeFXSLockedBalExtds = (
                    IVestedFXSUtils(IVestedFXS(_veAddr).veFxsUtils()).getDetailedUserLockInfo(_account)
                ).expiredLocks;

                // Loop though the expired locks and add them to the combined array
                for (uint256 j; j < _addlVeFXSLockedBalExtds.length; ) {
                    // Save tmp variable to memory
                    IveFXSStructs.LockedBalanceExtended memory _addVeFXSLockInfo = _addlVeFXSLockedBalExtds[j];

                    // Add to the temporary array
                    _tmpExpiredLocks[_expiredLockIdx] = LockedBalanceExtendedV2({
                        id: _addVeFXSLockInfo.id,
                        index: _addVeFXSLockInfo.index,
                        amount: _addVeFXSLockInfo.amount,
                        end: _addVeFXSLockInfo.end,
                        location: _veAddr,
                        estimatedCurrLockVeFXS: 0
                    });

                    // Increase the expired lock index
                    ++_expiredLockIdx;

                    unchecked {
                        ++j;
                    }
                }
            }

            unchecked {
                ++i;
            }
        }

        // Allocate the return array with only the number of expired locks
        _expiredLocks = new LockedBalanceExtendedV2[](_expiredLockIdx);

        // Fill the return array
        for (uint256 i; i < _expiredLocks.length; ) {
            _expiredLocks[i] = _tmpExpiredLocks[i];

            unchecked {
                ++i;
            }
        }
    }

    // ==============================================================================
    // MUTATIVE FUNCTIONS
    // ==============================================================================

    // None...

    // ==============================================================================
    // RESTRICTED FUNCTIONS
    // ==============================================================================

    /// @notice Adds an additional veFXS-like contract
    /// @param _addr The contract to added
    function addAddlVeFXSContract(address _addr) public onlyByOwnGov {
        require(_addr != address(0), "Zero address detected");

        // Check the ABI here to make sure it is veFXS-like
        // None of these should revert
        IVestedFXS(_addr).totalSupply();
        IVestedFXS(_addr).balanceOf(address(0));
        IVestedFXS(_addr).numLocks(address(0));
        IVestedFXSUtils(IVestedFXS(_addr).veFxsUtils()).getDetailedUserLockInfo(address(0));
        IVestedFXSUtils(IVestedFXS(_addr).veFxsUtils()).getCrudeExpectedVeFXSOneLock(1e18, 604_800);

        require(addlVeContracts[_addr] == false, "Address already exists");
        addlVeContracts[_addr] = true;
        addlVeContractsArr.push(_addr);

        emit AddlVeFXSContractAdded(_addr);
    }

    /// @notice Removes a veFXS-like contract. Will need to mass checkpoint on the yield distributor or other sources to reflect new stored total veFXS
    /// @param _addr The contract to remove
    function removeAddlVeFXSContract(address _addr) public onlyByOwnGov {
        require(_addr != address(0), "Zero address detected");
        require(addlVeContracts[_addr] == true, "Address nonexistent");

        // Delete from the mapping
        delete addlVeContracts[_addr];

        // 'Delete' from the array by setting the address to 0x0
        for (uint256 i = 0; i < addlVeContractsArr.length; i++) {
            if (addlVeContractsArr[i] == _addr) {
                addlVeContractsArr[i] = address(0); // This will leave a null in the array and keep the indices the same
                break;
            }
        }

        emit AddlVeFXSContractRemoved(_addr);
    }

    /// @notice Added to support recovering LP Yield and other mistaken tokens from other systems to be distributed to holders
    /// @param _tokenAddress The token to recover
    /// @param _tokenAmount The amount to recover
    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyByOwnGov {
        // Only the owner address can ever receive the recovery withdrawal
        TransferHelper.safeTransfer(_tokenAddress, owner, _tokenAmount);
        emit RecoveredERC20(_tokenAddress, _tokenAmount);
    }

    /// @notice Set the original 3 veFXS-like contracts on Fraxtal
    /// @param _veAddresses The addresses: 0: veFXS, 1: veFXSUtils, 2: FPIS Locker, 3: FPISLockerUtils, 4: L1VeFXS, 5: L1VeFXSTotalSupplyOracle
    function setAddresses(address[6] calldata _veAddresses) external onlyByOwnGov {
        // Future upgrade: remove this once full support is added and tested
        require(_veAddresses[0] != address(0), "veFXS must not be 0x0");
        require(_veAddresses[1] != address(0), "veFXSUtils must not be 0x0");
        require(_veAddresses[2] != address(0), "FPISLocker must not be 0x0");
        require(_veAddresses[3] != address(0), "FPISLockerUtils must not be 0x0");
        require(_veAddresses[4] != address(0), "L1VeFXS must not be 0x0");
        require(_veAddresses[5] != address(0), "L1VeFXSTotalSupplyOracle must not be 0x0");

        // Set veFXS-like addresses
        veFXS = IVestedFXS(_veAddresses[0]);
        veFXSUtils = IVestedFXSUtils(_veAddresses[1]);

        // FPIS Locker
        if ((_veAddresses[2] != address(0)) && _veAddresses[3] != address(0)) {
            fpisLocker = IFPISLocker(_veAddresses[2]);
            lFpisUtils = FPISLockerUtils(_veAddresses[3]);
        }

        // L1VeFXS and L1VeFXSTotalSupplyOracle
        if ((_veAddresses[4] != address(0)) && (_veAddresses[5] != address(0))) {
            l1veFXS = IL1VeFXS(_veAddresses[4]);
            l1VeFXSTotalSupplyOracle = L1VeFXSTotalSupplyOracle(_veAddresses[5]);
        }
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

    /// @notice When an additional veFXS contract is added
    /// @param addr The contract that was added
    event AddlVeFXSContractAdded(address addr);

    /// @notice When an additional veFXS contract is removed
    /// @param addr The contract that was removed
    event AddlVeFXSContractRemoved(address addr);

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
    /// @param user Address collecting the yield
    /// @param yield The amount of tokens collected
    /// @param tokenAddress The address collecting the rewards
    event YieldCollected(address indexed user, uint256 yield, address tokenAddress);

    /// @notice When the yield duration is updated
    /// @param newDuration The new duration
    event YieldDurationUpdated(uint256 newDuration);

    // ==============================================================================
    // ERRORS
    // ==============================================================================

    /// @notice Cannot initialize twice
    error InitializeFailed();

    /// @notice If you are trying to call a function not as the owner or timelock
    error NotOwnerOrTimelock();
}
