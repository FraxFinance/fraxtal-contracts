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
// ======================== Flox Converter ============================
// ====================================================================

import { OwnedUpgradeable } from "./OwnedUpgradeable.sol";
import { FloxConverterStructs } from "./interfaces/FloxConverterStructs.sol";
import { FloxCapacitor } from "./FloxCapacitor.sol";
import { FxtlPoints } from "./FxtlPoints.sol";

import { console } from "forge-std/console.sol";

/**
 * @title FloxConverter
 * @author Frax Finance
 * @notice A smart contract that allows users to "convert" their FXTL points to FRAX. FXTL is not actually burned from the user, but redemptions are tracked to keep a "virtual" balance (see totalEligibleFxtlPointsByUser()).
 * @dev Used to virtually "convert" a percentage of user's FXTL points to FRAX. We have a set yearly (and subsequently weekly) emission amount
 *   and the users get a share of it based on their balances as well as boost determined by their FloxCapacitor balance.
 * @dev We should be able to populate the epoch data using the flox stake units calculated from 2% of user's unclaimed FXTL point balance and their FloxCapacitor balance.
 * @dev Once all the data is populated the FRAX should be distributed (by a trusted entity / bot) to the users using bulk actions.
 * @dev The users themselves do not interact (write) with this FloxConverter contract
 * @dev We need to keep track of the amount of points the user has already used to redeem their FRAX,
 *  because the FXTL smart contract will be used to aggregate the points through perpetuity and we won't be physically burning / removing user's redeemed points from their FXTL ERC20 balance.
 * @dev The Flox Converter uses Flox Capacitor to boost the user's stake when claiming the FRAX token.
 */
contract FloxConverter is OwnedUpgradeable, FloxConverterStructs {
    /// @notice Instantiation of the Flox Capacitor smart contract.
    FloxCapacitor public FLOX_CAPACITOR;

    /// @notice Instantiation of the FXTL points smart contract.
    FxtlPoints public FXTL_POINTS;

    /// @notice The maximum amount of basis points used in calculations to increase precision (equals 100%).
    uint256 public constant MAX_BASIS_POINTS = 1e5;

    /**
     * @notice Used to track the Flox contributors.
     * @dev contributor Address of the Flox contributor.
     * @dev isContributor True if the address is a Flox contributor.
     */
    mapping(address contributor => bool isContributor) public isFloxContributor;
    /**
     * @notice Used to track the redemption epochs.
     * @dev epochNumber The number of the epoch.
     * @dev epoch The struct that contains the information of the epoch.
     */
    mapping(uint256 epochNumber => RedemptionEpoch epoch) public redemptionEpochs;
    /**
     * @notice Used to track the user data in the redemption epochs.
     * @dev epochNumber The number of the redemption epoch.
     * @dev user The address of the user.
     * @dev userData The struct that contains the information of the user in the epoch.
     */
    mapping(uint256 epochNumber => mapping(address user => RedemptionEpochUserData userData))
        public redemptionEpochUserData;
    /**
     * @notice Used to track the total amonut og Flox stake units per redemption epoch.
     * @dev epochNumber The number of the redemption epoch.
     * @dev totalFloxStakeUnits The total amount of Flox stake units in the redemption epoch.
     */
    mapping(uint256 epochNumber => uint256 totalFloxStakeUnits) public totalFloxStakeUnitsPerRedemptionEpoch;
    /**
     * @notice Used to track the total user data in the Flox Converter.
     * @dev user The address of the user.
     * @dev userData The struct that contains the information of the user in the Flox Converter.
     */
    mapping(address user => UserData userData) public userStats;

    /// @notice Version of the FloxConverter smart contract.
    string public version;

    /// @notice Variable to track if the contract is paused.
    bool public isPaused;

    /// @notice Used to make sure the contract is initialized only once.
    bool private _initialized;

    /// @notice Used to prevent reentrancy attacks.
    bool private executing;

    /// @notice Used to track the number of allocated weekly distribution epochs.
    uint256 public latestAllocatedDistributionEpoch;

    /// @notice Used to track the total amount of FXTL points redeemed for FRAX.
    uint256 public totalFxtlPointsRedeemed;

    /// @notice Amount of FRAX to distribute in a year.
    uint256 public yearlyFraxDistribution;

    /// @notice Percentage of FXTL points to redeem per redemption epoch.
    uint256 public basisPointsToRedeemPerEpoch;

    /// @notice Amount of FXTL points per FRAX staked in order to get the maximum Flox stake boost.
    uint256 public fxtlPointsPerOneFrax;

    /// @notice Maximum Flox Stake Units boost.
    uint256 public maxFloxStakeUnitsBoost;

    /// @dev reserve extra storage for future upgrades
    uint256[50] private __gap;

    /**
     * @notice Used to initialize the smart contract.
     * @dev The initial owner is set as the deployer of the smart contract.
     * @param _owner Address of the owner of the smart contract
     * @param _floxCapacitor Address of the Flox Capacitor smart contract
     * @param _version Version of the FloxCAP smart contract
     */
    function initialize(address _owner, address _floxCapacitor, address _fxtlPoints, string memory _version) public {
        if (_initialized) revert AlreadyInitialized();

        _initialized = true;
        FLOX_CAPACITOR = FloxCapacitor(_floxCapacitor);
        FXTL_POINTS = FxtlPoints(_fxtlPoints);
        version = _version;

        basisPointsToRedeemPerEpoch = 2000; // 2% of the FXTL points
        fxtlPointsPerOneFrax = 1000; // 1000 FXTL points per 1 FRAX staked to get the maximum Flox stake boost
        maxFloxStakeUnitsBoost = 2; // By reaching the maximum Flox Stake Units boost, the user can double their Flox stake units in the epoch

        __Owned_init(_owner);
    }

    /* ====================== VIEW FUNCTIONS ====================== */

    /**
     * @notice Returns the amount of FRAX available for distribution in the contract.
     * @return The amount of FRAX available for distribution
     */
    function remainingFraxAvailable() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Returns the amount of FRAX available to be distributed weekly.
     * @dev The amount of FRAX available for distribution is calculated based on the yearly distribution and
     *  recalculated using daily precision.
     * @return _availableFrax The amount of FRAX available for distribution weekly
     */
    function weeklyAvailableFrax() public view returns (uint256 _availableFrax) {
        return ((yearlyFraxDistribution * MAX_BASIS_POINTS * 7 days) / 365 days) / MAX_BASIS_POINTS;
    }

    /**
     * @notice User's FXTL points eligible for current AND future conversions. FXTL ERC20 balance - total redeemed.
     * @param _user The address of the user
     * @return _ttlFxtlPoints The total amount of FXTL points eligible to be redeemed in current AND future redemption epochs
     */
    function totalEligibleFxtlPointsByUser(address _user) public view returns (uint256 _ttlFxtlPoints) {
        _ttlFxtlPoints = FXTL_POINTS.balanceOf(_user);
        _ttlFxtlPoints -= userStats[_user].totalFxtlPointsRedeemed;
    }

    /**
     * @notice Returns the amount of FXTL points eligible to be redeemed in the current redemption epoch only.
     * @param _user The address of the user
     * @return _epochFxtlPoints The amount of FXTL points eligible to be redeemed in the current redemption epoch only
     */
    function getCurrentUserRedemptionEpochFxtlPoints(address _user) public view returns (uint256 _epochFxtlPoints) {
        _epochFxtlPoints = totalEligibleFxtlPointsByUser(_user);
        _epochFxtlPoints = (_epochFxtlPoints * basisPointsToRedeemPerEpoch) / MAX_BASIS_POINTS;
    }

    /**
     * @notice Returns the amount of FXTL points eligible to be redeemed in the current redemption epoch for multiple
     *  users at the same time.
     * @param _users An array of user addresses
     * @return _userFxtlPointsThisEpoch The amount of FXTL points eligible to be redeemed in the current redemption epoch
     */
    function bulkGetCurrentUserRedemptionEpochFxtlPoints(
        address[] memory _users
    ) public view returns (uint256[] memory _userFxtlPointsThisEpoch) {
        _userFxtlPointsThisEpoch = new uint256[](_users.length);

        for (uint256 i; i < _users.length; ) {
            _userFxtlPointsThisEpoch[i] = getCurrentUserRedemptionEpochFxtlPoints(_users[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Returns the amount of Flox stake units for a given user.
     * @dev The Flox stake units are calculated based on the FXTL points and the Flox Capacitor balance.
     * @param _user The address of the user
     * @return _floxStakeUnits The amount of Flox stake units for the user
     */
    function calculateFloxStakeUnits(address _user) public view returns (uint256 _floxStakeUnits) {
        uint256 usrFxtlPtsThisEpoch = getCurrentUserRedemptionEpochFxtlPoints(_user);
        if (usrFxtlPtsThisEpoch == 0) return 0;

        uint256 floxCapBalance = FLOX_CAPACITOR.balanceOf(_user);

        // We need to scale up FXTL points to the amount of FRAX decimals
        uint256 maxBoostRequiredBalance = (usrFxtlPtsThisEpoch * 1e18) / fxtlPointsPerOneFrax;

        // Get the boost in basis points
        uint256 floxCapBoostBPs;
        if (floxCapBalance >= maxBoostRequiredBalance) {
            floxCapBoostBPs = maxFloxStakeUnitsBoost * MAX_BASIS_POINTS;
        } else {
            floxCapBoostBPs =
                MAX_BASIS_POINTS +
                (floxCapBalance * (maxFloxStakeUnitsBoost - 1) * MAX_BASIS_POINTS) /
                maxBoostRequiredBalance;
        }

        // Return the multiplied epoch points
        return ((usrFxtlPtsThisEpoch * floxCapBoostBPs) / MAX_BASIS_POINTS);
    }

    /**
     * @notice Returns the amount of Flox stake units for multiple users at the same time.
     * @dev The Flox stake units are calculated based on the FXTL points and the Flox Capacitor balance.
     * @param _users An array of user addresses
     * @return _floxStakeUnits An array of Flox stake units for each user
     */
    function bulkCalculateFloxStakeUnits(
        address[] memory _users
    ) public view returns (uint256[] memory _floxStakeUnits) {
        _floxStakeUnits = new uint256[](_users.length);

        for (uint256 i; i < _users.length; ) {
            _floxStakeUnits[i] = calculateFloxStakeUnits(_users[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Returns the amount of FRAX eligible to be redeemed in the current redemption epoch for given Flox stake
     *  units.
     * @param _floxStakeUnits Amount of Flox stake units to calculate the FRAX allocation for
     * @param _redemptionEpoch The redemption epoch to calculate the FRAX allocation for
     * @return _redeemableFrax The amount of FRAX allocated to the user based on their Flox stake units
     */
    function getFraxAllocationFromFloxStakeUnits(
        uint256 _floxStakeUnits,
        uint256 _redemptionEpoch
    ) public view returns (uint256 _redeemableFrax) {
        _redemptionEpoch = _redemptionEpoch == 0 ? latestAllocatedDistributionEpoch + 1 : _redemptionEpoch;

        if (!redemptionEpochs[_redemptionEpoch].initiated) revert UninitiatedRedemptionEpoch();

        uint256 redemptionEpochAvailableFrax = weeklyAvailableFrax();
        uint256 totalFloxStakeUnits = redemptionEpochs[_redemptionEpoch].totalFloxStakeUnits;

        return
            ((redemptionEpochAvailableFrax * _floxStakeUnits * MAX_BASIS_POINTS) / totalFloxStakeUnits) /
            MAX_BASIS_POINTS;
    }

    /* ====================== CORE OPERATION FUNCTIONS ====================== */

    /**
     * @notice Used to initiate the redemption epoch.
     * @param _lastBlock The last block of the redemption epoch
     */
    function initiateRedemptionEpoch(uint64 _lastBlock) external {
        _onlyFloxContributor();
        _onlyWhenOperational();
        if (_lastBlock == 0) revert InvalidLastBlockNumber();

        // Start right after the last block of the previous epoch
        uint64 firstBlock = redemptionEpochs[latestAllocatedDistributionEpoch].lastBlock + 1;
        uint256 fraxToDistribute = weeklyAvailableFrax();

        // The redemption end block must be after the previous epoch's final block and before the current block
        if (_lastBlock < firstBlock || _lastBlock > block.number) revert InvalidLastBlockNumber();

        // Set the epoch info
        RedemptionEpoch storage epoch = redemptionEpochs[latestAllocatedDistributionEpoch + 1];
        epoch.initiated = true;
        epoch.firstBlock = firstBlock;
        epoch.lastBlock = _lastBlock;

        emit RedemptionEpochInitiated(latestAllocatedDistributionEpoch + 1, firstBlock, _lastBlock, fraxToDistribute);
    }

    /**
     * @notice Used to update the user's data for the currently initiated redemption epoch.
     * @dev This can only be called by a Flox contributor.
     * @dev The function will revert if the smart contract is paused.
     * @dev The function will revert if the amount of FXTL points redeemed is 0.
     * @param _user The address of the user
     * @param _amountOfFxtlPointsRedeemed The amount of FXTL points redeemed by the user
     * @param _floxStakeUnits The amount of Flox stake units redeemed by the user
     */
    function updateUserData(address _user, uint256 _amountOfFxtlPointsRedeemed, uint256 _floxStakeUnits) external {
        _onlyFloxContributor();
        _onlyWhenOperational();

        RedemptionEpoch memory epoch = redemptionEpochs[latestAllocatedDistributionEpoch + 1];
        if (!epoch.initiated) revert EpochNotInitiated();
        if (epoch.populated) revert EpochAlreadyPopulated();

        if (_amountOfFxtlPointsRedeemed == 0) revert InvalidFxtlPointsAmount();

        _updateUserStats(_user, _amountOfFxtlPointsRedeemed, _floxStakeUnits);
        _updateRedemptionEpochUserData(_user, _amountOfFxtlPointsRedeemed, _floxStakeUnits);
    }

    /**
     * @notice Used to update multiple users' data for the currently initiated redemption epoch.
     * @dev This can only be called by a Flox contributor.
     * @dev The function will revert if the smart contract is paused.
     * @dev The function will revert if the amount of FXTL points redeemed is 0.
     * @dev The function will revert if the arrays are not of the same length.
     * @param _users An array of user addresses
     * @param _amountsOfFxtlPointsRedeemed An array of amounts of FXTL points redeemed by the users
     * @param _floxStakeUnits An array of amounts of Flox stake units redeemed by the users
     */
    function bulkUpdateUserData(
        address[] memory _users,
        uint256[] memory _amountsOfFxtlPointsRedeemed,
        uint256[] memory _floxStakeUnits
    ) external {
        _onlyFloxContributor();
        _onlyWhenOperational();
        if (_users.length != _amountsOfFxtlPointsRedeemed.length || _users.length != _floxStakeUnits.length) {
            revert InvalidArrayLength();
        }

        RedemptionEpoch memory epoch = redemptionEpochs[latestAllocatedDistributionEpoch + 1];
        if (!epoch.initiated) revert EpochNotInitiated();
        if (epoch.populated) revert EpochAlreadyPopulated();

        for (uint256 i; i < _users.length; ) {
            if (_amountsOfFxtlPointsRedeemed[i] == 0) revert InvalidFxtlPointsAmount();

            _updateUserStats(_users[i], _amountsOfFxtlPointsRedeemed[i], _floxStakeUnits[i]);
            _updateRedemptionEpochUserData(_users[i], _amountsOfFxtlPointsRedeemed[i], _floxStakeUnits[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Used to mark the redemption epoch as populated.
     * @dev Once the redemption epoch is marked as populated, the data cannot be changed and the FRAX distribution can
     *  be started.
     * @dev This can only be called by a Flox contributor.
     * @dev The function will revert if the smart contract is paused.
     * @dev The function will revert if the epoch is not initialized or already finalized.
     */
    function markRedemptionEpochAsPopulated() external {
        _onlyFloxContributor();
        _onlyWhenOperational();

        RedemptionEpoch storage epoch = redemptionEpochs[latestAllocatedDistributionEpoch + 1];
        if (!epoch.initiated) revert EpochNotInitiated();
        if (epoch.populated) revert EpochAlreadyPopulated();

        epoch.populated = true;

        emit RedemptionEpochPopulated(
            latestAllocatedDistributionEpoch + 1,
            epoch.firstBlock,
            epoch.lastBlock,
            epoch.totalFloxStakeUnits
        );
    }

    /**
     * @notice Used to distribute the FRAX to the users.
     * @dev This can only be called by a Flox contributor.
     * @dev The function will revert if the smart contract is paused.
     * @dev The function will revert if the epoch is not initialized and populated or already finalized.
     * @dev The function will revert if the user has already received their FRAX distribution for the distribution epoch.
     * @dev The function will revert if the distribution fails for the user.
     * @param _users An array of user addresses
     */
    function distributeFrax(address[] memory _users) external nonReentrant {
        _onlyFloxContributor();
        _onlyWhenOperational();

        RedemptionEpoch storage epoch = redemptionEpochs[latestAllocatedDistributionEpoch + 1];
        if (!epoch.initiated) revert EpochNotInitiated();
        if (!epoch.populated) revert EpochNotPopulated();
        if (epoch.finalized) revert EpochAlreadyFinalized();

        uint256 totalFraxDistribution = weeklyAvailableFrax();
        uint256 totalFloxStakeUnits = epoch.totalFloxStakeUnits;

        for (uint256 i; i < _users.length; ) {
            address user = _users[i];

            // Get the pre-calculated user data for this epoch
            RedemptionEpochUserData storage userData = redemptionEpochUserData[latestAllocatedDistributionEpoch + 1][
                user
            ];
            if (userData.fraxReceived != 0) revert AlreadyDistributed(user);

            // Calculate the user's share of this epoch's Frax
            uint256 fraxToDistribute = (totalFraxDistribution * userData.floxStakeUnits) / totalFloxStakeUnits;

            // Send the Frax to the user
            (bool success, ) = user.call{ value: fraxToDistribute }("");
            if (!success) revert DistributionFailed(user);

            // Update the user data and stats, as well as the epoch
            userData.fraxReceived = fraxToDistribute;
            userStats[user].totalFraxReceived += fraxToDistribute;
            epoch.totalFraxDistributed += fraxToDistribute;

            emit DistributionAllocated(user, fraxToDistribute);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Used to finalize the redemption epoch.
     * @dev The function will revert if the smart contract is paused.
     * @dev The function will revert if the epoch is not initialized or already finalized.
     */
    function finalizeRedemptionEpoch() external {
        _onlyFloxContributor();
        _onlyWhenOperational();

        RedemptionEpoch storage epoch = redemptionEpochs[latestAllocatedDistributionEpoch + 1];
        if (!epoch.initiated) revert EpochNotInitiated();
        if (!epoch.populated) revert EpochNotPopulated();
        if (epoch.finalized) revert EpochAlreadyFinalized();

        epoch.finalized = true;
        latestAllocatedDistributionEpoch += 1;

        emit RedemptionEpochFinalized(latestAllocatedDistributionEpoch);
    }

    /* ====================== ADMINISTRATIVE FUNCTIONS ====================== */

    /**
     * @notice Adds a Flox contributor.
     * @dev Can only be called by the owner.
     * @param _contributor The address of the Flox contributor to add
     */
    function addFloxContributor(address _contributor) external {
        _onlyOwner();
        if (isFloxContributor[_contributor]) revert AlreadyFloxContributor();
        isFloxContributor[_contributor] = true;
        emit FloxContributorAdded(_contributor);
    }

    /**
     * @notice Removes a Flox contributor.
     * @dev Can only be called by the owner.
     * @param _contributor The address of the Flox contributor to remove
     */
    function removeFloxContributor(address _contributor) external {
        _onlyOwner();
        if (!isFloxContributor[_contributor]) revert NotFloxContributor();
        isFloxContributor[_contributor] = false;
        emit FloxContributorRemoved(_contributor);
    }

    /**
     * @notice Stops the operation of the smart contract.
     * @dev Can only be called by a Flox contributor.
     * @dev Can only be called if the contract is operational.
     */
    function stopOperation() external {
        _onlyFloxContributor();
        _onlyWhenOperational();
        isPaused = true;
        emit OperationPaused(isPaused, block.timestamp);
    }

    /**
     * @notice Enables the operation of the smart contract.
     * @dev Can only be called by the owner.
     * @dev Can only be called if the contract is paused.
     */
    function restartOperation() external {
        _onlyOwner();
        if (!isPaused) revert ContractOperational();
        isPaused = false;
        emit OperationPaused(isPaused, block.timestamp);
    }

    /**
     * @notice Sets the yearly distribution of FRAX.
     * @dev Can only be called by the owner.
     * @param _yearlyFraxDistribution The amount of FRAX to distribute in a year
     */
    function setYearlyFraxDistribution(uint256 _yearlyFraxDistribution) external {
        _onlyOwner();
        if (_yearlyFraxDistribution == 0) revert ZeroYearlyFraxDistribution();

        uint256 oldYearlyFraxDistribution = yearlyFraxDistribution;
        yearlyFraxDistribution = _yearlyFraxDistribution;

        emit YearlyFraxDistributionUpdated(oldYearlyFraxDistribution, yearlyFraxDistribution);
    }

    /* ====================== INTERNAL CORE OPERATION FUNCTIONS ====================== */

    /**
     * @notice Used to update the user's Flox Converter stats.
     * @dev We don't want to double-track the stats for the user, so if the user already has the per-redemption epoch
     *  stats recorded, the global value will first be rolled back and then updated with the new values.
     * @param _user Address of the user
     * @param _amountOfFxtlPointsRedeemed Amount of FXTL points redeemed by the user
     * @param _floxStakeUnits Amount of Flox stake units redeemed by the user
     */
    function _updateUserStats(address _user, uint256 _amountOfFxtlPointsRedeemed, uint256 _floxStakeUnits) internal {
        UserData storage user = userStats[_user];

        uint256 oldFxtlPointsRedeemed = user.totalFxtlPointsRedeemed;
        uint256 epochNumber = latestAllocatedDistributionEpoch + 1;

        RedemptionEpochUserData memory redemptionEpochData = redemptionEpochUserData[epochNumber][_user];
        RedemptionEpoch storage redemptionEpoch = redemptionEpochs[epochNumber];

        if (redemptionEpochData.fxtlPointsRedeemed != 0) {
            user.totalFxtlPointsRedeemed -= redemptionEpochData.fxtlPointsRedeemed;
            redemptionEpoch.totalFxtlPointsRedeemed -= redemptionEpochData.fxtlPointsRedeemed;
            redemptionEpoch.totalFloxStakeUnits -= redemptionEpochData.floxStakeUnits;
            totalFxtlPointsRedeemed -= redemptionEpochData.fxtlPointsRedeemed;
        }

        user.totalFxtlPointsRedeemed += _amountOfFxtlPointsRedeemed;
        redemptionEpoch.totalFxtlPointsRedeemed += _amountOfFxtlPointsRedeemed;
        redemptionEpoch.totalFloxStakeUnits += _floxStakeUnits;
        totalFxtlPointsRedeemed += _amountOfFxtlPointsRedeemed;

        emit UserStatsUpdated(_user, oldFxtlPointsRedeemed, user.totalFxtlPointsRedeemed);
    }

    /**
     * @notice Used to update the user's redemption epoch data.
     * @dev If the user's redemption epoch data is already present, the function overwrites it.
     * @param _user Address of the user getting their redemption epoch data updated
     * @param _amountOfFxtlPointsRedeemed Amount of FXTL points redeemed by the user
     * @param _floxStakeUnits Amount of Flox stake units redeemed by the user
     */
    function _updateRedemptionEpochUserData(
        address _user,
        uint256 _amountOfFxtlPointsRedeemed,
        uint256 _floxStakeUnits
    ) internal {
        uint256 epochNumber = latestAllocatedDistributionEpoch + 1;

        RedemptionEpochUserData storage userData = redemptionEpochUserData[epochNumber][_user];

        userData.fxtlPointsRedeemed = _amountOfFxtlPointsRedeemed;
        userData.floxStakeUnits = _floxStakeUnits;

        emit UserEpochDataUpdated(epochNumber, _user, _amountOfFxtlPointsRedeemed, _floxStakeUnits);
    }

    /* ====================== FUNCTIONS TO REPLACE MODIFIERS FOR BETTER READABILITY ====================== */

    /**
     * @notice Checks if an address is a Flox contributor.
     * @dev The operation will be reverted if the caller is not a Flox contributor.
     */
    function _onlyFloxContributor() internal view {
        if (!isFloxContributor[msg.sender]) revert NotFloxContributor();
    }

    /**
     * @notice Checks if the contract is operational.
     * @dev The operation will be reverted if the contract is paused.
     */
    function _onlyWhenOperational() internal view {
        if (isPaused) revert ContractPaused();
    }

    /* ====================== MODIFIER IS USED WHERE THERE IS NO WAY AROUND IT ====================== */

    /**
     * @notice Prevents reentrancy attacks.
     * @dev The operation will be reverted if the contract is already executing.
     */
    modifier nonReentrant() {
        if (executing) revert Reentrancy();

        executing = true;
        _;
        executing = false;
    }

    /* ====================== EMERGENCIES AND FALLBACK ====================== */

    /**
     * @notice Fallback function to receive FRAX in order to distribute it.
     */
    receive() external payable {
        // Do nothing.
    }

    /// @notice For emergencies if something gets stuck
    /**
     * @notice Used to recover FRAX from the contract.
     * @dev This can only be called by the owner.
     * @dev This transfers the `amount` of FRAX to the owner.
     * @param _amount The amount of FRAX to recover
     */
    function recoverFrax(uint256 _amount) external {
        _onlyOwner();

        (bool _success, ) = address(owner).call{ value: _amount }("");
        if (!_success) revert TransferFailed();

        emit RecoveredFrax(_amount);
    }
}
