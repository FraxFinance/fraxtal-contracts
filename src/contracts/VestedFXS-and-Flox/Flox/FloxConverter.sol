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

/**
 * @title FloxConverter
 * @author Frax Finance
 * @notice A smart contract that allows users to convert their FXTL points to FRAX.
 * @dev The Flox Converter uses Flox Capacitor to boost the user's stake when claiming the FRAX token.
 */
contract FloxConverter is OwnedUpgradeable, FloxConverterStructs {
    /// Instantiation of the Flox Capacitor smart contract.
    FloxCapacitor public FLOX_CAPACITOR;

    /// Instantiation of the FXTL points smart contract.
    FxtlPoints public FXTL_POINTS;

    /// The maximum amount of basis points used in calculations to increase precision (equals 100%).
    uint256 public constant MAX_BASIS_POINTS = 1e5;

    /**
     * @notice Used to track the Flox contributors.
     * @dev contributor Address of the Flox contributor.
     * @dev isContributor True if the address is a Flox contributor.
     */
    mapping(address contributor => bool isContributor) public isFloxContributor;
    /**
     * @notice Used to track the redeemal epochs.
     * @dev epochNumber The number of the epoch.
     * @dev epoch The struct that contains the information of the epoch.
     */
    mapping(uint256 epochNumber => RedeemalEpoch epoch) public redeemalEpochs;
    /**
     * @notice Used to track the user data in the redeemal epochs.
     * @dev epochNumber The number of the redeemal epoch.
     * @dev user The address of the user.
     * @dev userData The struct that contains the information of the user in the epoch.
     */
    mapping(uint256 epochNumber => mapping(address user => RedeemalEpochUserData userData))
        public redeemalEpochUserData;
    /**
     * @notice Used to track the total amonut og Flox stake units per redeemal epoch.
     * @dev epochNumber The number of the redeemal epoch.
     * @dev totalFloxStakeUnits The total amount of Flox stake units in the redeemal epoch.
     */
    mapping(uint256 epochNumber => uint256 totalFloxStakeUnits) public totalFloxStakeUnitsPerRedeemalEpoch;
    /**
     * @notice Used to track the total user data in the Flox Converter.
     * @dev user The address of the user.
     * @dev userData The struct that contains the information of the user in the Flox Converter.
     */
    mapping(address user => UserData userData) public userStats;

    /// Version of the FloxConverter smart contract.
    string public version;
    /// Variable to track if the contract is paused.
    bool public isPaused;
    /// Used to make sure the contract is initialized only once.
    bool private _initialized;
    /// Used to prevent reentrancy attacks.
    bool private executing;
    /// Used to track the number of allocated weekly distribution epochs.
    uint256 public latestAllocatedDistributionEpoch;
    /// Used to track the total amount of FXTL points redeemed for FRAX.
    uint256 public totalFxtlPointsRedeemed;
    /// Amount of FRAX to distribute in a year.
    uint256 public yearlyFraxDistribution;
    /// Percentage of FXTL points to redeem per redeemal epoch.
    uint256 public basisPointsToRedeemPerEpoch;

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
     * @return The amount of FRAX available for distribution weekly
     */
    function weeklyAvailableFrax() public view returns (uint256) {
        uint256 availableFrax = ((yearlyFraxDistribution * MAX_BASIS_POINTS * 7 days) / 365 days) / MAX_BASIS_POINTS;

        return availableFrax;
    }

    /**
     * @notice Returns the amount of FXTL points elegible to be redeemed in the current redeemal epoch.
     * @param _user The address of the user
     * @return The amount of FXTL points elegible to be redeemed in the current redeemal epoch
     */
    function getCurrentUserRedeemalEpochFxtlPoints(address _user) public view returns (uint256) {
        uint256 fxtlPoints = FXTL_POINTS.balanceOf(_user);
        fxtlPoints -= userStats[_user].totalFxtlPointsRedeemed;
        fxtlPoints = (fxtlPoints * basisPointsToRedeemPerEpoch) / MAX_BASIS_POINTS;

        return fxtlPoints;
    }

    /**
     * @notice Returns the amount of FXTL points elegible to be redeemed in the current redeemal epoch for multiple
     *  users at the same time.
     * @param _users An array of user addresses
     * @return The amount of FXTL points elegible to be redeemed in the current redeemal epoch
     */
    function bulkGetCurrentUserRedeemalEpochFxtlPoints(address[] memory _users) public view returns (uint256[] memory) {
        uint256[] memory fxtlPoints = new uint256[](_users.length);

        for (uint256 i; i < _users.length; ) {
            fxtlPoints[i] = FXTL_POINTS.balanceOf(_users[i]);
            fxtlPoints[i] -= userStats[_users[i]].totalFxtlPointsRedeemed;
            fxtlPoints[i] = (fxtlPoints[i] * basisPointsToRedeemPerEpoch) / MAX_BASIS_POINTS;

            unchecked {
                ++i;
            }
        }

        return fxtlPoints;
    }

    /**
     * @notice Returns the amount of FRAX elegible to be redeemed in the current redeemal epoch for given Flox stake
     *  units.
     * @param _floxStakeUnits Amount of Flox stake units to calculate the FRAX allocation for
     * @param _redeemalEpoch The redeemal epoch to calculate the FRAX allocation for
     * @return The amount of FRAX allocated to the user based on their Flox stake units
     */
    function getFraxAllocationFromFloxStakeUnits(
        uint256 _floxStakeUnits,
        uint256 _redeemalEpoch
    ) public view returns (uint256) {
        _redeemalEpoch = _redeemalEpoch == 0 ? latestAllocatedDistributionEpoch + 1 : _redeemalEpoch;

        if (!redeemalEpochs[_redeemalEpoch].initiated) revert UninitiatedRedeemalEpoch();

        uint256 redeemalEpochAvailableFrax = weeklyAvailableFrax();
        uint256 totalFloxStakeUnits = redeemalEpochs[_redeemalEpoch].totalFloxStakeUnits;

        return
            ((redeemalEpochAvailableFrax * _floxStakeUnits * MAX_BASIS_POINTS) / totalFloxStakeUnits) /
            MAX_BASIS_POINTS;
    }

    /* ====================== CORE OPERATION FUNCTIONS ====================== */

    /**
     * @notice Used to initiate the redeemal epoch.
     * @param _lastBlock The last block of the redeemal epoch
     */
    function initiateRedeemalEpoch(uint64 _lastBlock) external {
        _onlyFloxContributor();
        if (isPaused) revert ContractPaused();
        if (_lastBlock == 0) revert InvalidLastBlockNumber();

        uint64 firstBlock = redeemalEpochs[latestAllocatedDistributionEpoch].lastBlock + 1;
        uint256 fraxToDistribute = weeklyAvailableFrax();

        if (_lastBlock < firstBlock || _lastBlock > block.number) revert InvalidLastBlockNumber();

        RedeemalEpoch storage epoch = redeemalEpochs[latestAllocatedDistributionEpoch + 1];
        epoch.initiated = true;
        epoch.firstBlock = firstBlock;
        epoch.lastBlock = _lastBlock;

        emit RedeemalEpochInitiated(latestAllocatedDistributionEpoch + 1, firstBlock, _lastBlock, fraxToDistribute);
    }

    /**
     * @notice Used to update the user's data for the currently initiated redeemal epoch.
     * @dev This can only be called by a Flox contributor.
     * @dev The function will revert if the smart contract is paused.
     * @dev The function will revert if the amount of FXTL points redeemed is 0.
     * @param _user The address of the user
     * @param _amountOfFxtlPointsRedeemed The amount of FXTL points redeemed by the user
     * @param _floxStakeUnits The amount of Flox stake units redeemed by the user
     */
    function updateUserData(address _user, uint256 _amountOfFxtlPointsRedeemed, uint256 _floxStakeUnits) external {
        _onlyFloxContributor();
        if (isPaused) revert ContractPaused();

        RedeemalEpoch memory epoch = redeemalEpochs[latestAllocatedDistributionEpoch + 1];
        if (!epoch.initiated) revert EpochNotInitiated();
        if (epoch.populated) revert EpochAlreadyPopulated();

        if (_amountOfFxtlPointsRedeemed == 0) revert InvalidFxtlPointsAmount();

        _updateUserStats(_user, _amountOfFxtlPointsRedeemed, _floxStakeUnits);
        _updateRedeemalEpochUserData(_user, _amountOfFxtlPointsRedeemed, _floxStakeUnits);
    }

    /**
     * @notice Used to update multiple users' data for the currently initiated redeemal epoch.
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
        if (isPaused) revert ContractPaused();
        if (_users.length != _amountsOfFxtlPointsRedeemed.length || _users.length != _floxStakeUnits.length)
            revert InvalidArrayLength();

        RedeemalEpoch memory epoch = redeemalEpochs[latestAllocatedDistributionEpoch + 1];
        if (!epoch.initiated) revert EpochNotInitiated();
        if (epoch.populated) revert EpochAlreadyPopulated();

        for (uint256 i; i < _users.length; ) {
            if (_amountsOfFxtlPointsRedeemed[i] == 0) revert InvalidFxtlPointsAmount();

            _updateUserStats(_users[i], _amountsOfFxtlPointsRedeemed[i], _floxStakeUnits[i]);
            _updateRedeemalEpochUserData(_users[i], _amountsOfFxtlPointsRedeemed[i], _floxStakeUnits[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Used to mark the redeemal epoch as populated.
     * @dev Once the redeemal epoch is marked as populated, the data cannot be changed and the FRAX distribution can
     *  be started.
     * @dev This can only be called by a Flox contributor.
     * @dev The function will revert if the smart contract is paused.
     * @dev The function will revert if the epoch is not initialized or already finalized.
     */
    function markRedeemalEpochAsPopulated() external {
        _onlyFloxContributor();
        if (isPaused) revert ContractPaused();

        RedeemalEpoch storage epoch = redeemalEpochs[latestAllocatedDistributionEpoch + 1];
        if (!epoch.initiated) revert EpochNotInitiated();
        if (epoch.populated) revert EpochAlreadyPopulated();

        epoch.populated = true;

        emit RedeemalEpochPopulated(
            latestAllocatedDistributionEpoch + 1,
            epoch.firstBlock,
            epoch.lastBlock,
            epoch.totalFloxStakeUnits
        );
    }

    /**
     * @notice Used to distribute the FRAX to the users.
     * @dev This cam only be called by a Flox contributor.
     * @dev The function will revert if the smart contract is paused.
     * @dev The function will revert if the epoch is not initialized and populated or already finalized.
     * @dev The function will revert if the user has already received their FRAX distribution for the distribution epoch.
     * @dev The function will revert if the distribution fails for the user.
     * @param _users An array of user addresses
     */
    function distributeFrax(address[] memory _users) external nonReentrant {
        _onlyFloxContributor();
        if (isPaused) revert ContractPaused();

        RedeemalEpoch storage epoch = redeemalEpochs[latestAllocatedDistributionEpoch + 1];
        if (!epoch.initiated) revert EpochNotInitiated();
        if (!epoch.populated) revert EpochNotPopulated();
        if (epoch.finalized) revert EpochAlreadyFinalized();

        uint256 totalFraxDistribution = weeklyAvailableFrax();
        uint256 totalFloxStakeUnits = epoch.totalFloxStakeUnits;

        for (uint256 i; i < _users.length; ) {
            address user = _users[i];
            RedeemalEpochUserData storage userData = redeemalEpochUserData[latestAllocatedDistributionEpoch + 1][user];
            if (userData.fraxReceived != 0) revert AlreadyDistributed(user);

            uint256 fraxToDistribute = (totalFraxDistribution * userData.floxStakeUnits) / totalFloxStakeUnits;

            (bool success, ) = user.call{ value: fraxToDistribute }("");
            if (!success) revert DistributionFailed(user);

            userData.fraxReceived = fraxToDistribute;
            userStats[user].totalFraxReceived = userStats[user].totalFraxReceived + fraxToDistribute;
            epoch.totalFraxDistributed += fraxToDistribute;

            emit DistributionAllocated(user, fraxToDistribute);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Used to finalize the redeemal epoch.
     * @dev The function will revert if the smart contract is paused.
     * @dev The function will revert if the epoch is not initialized or already finalized.
     */
    function finalizeRedeemalEpoch() external {
        _onlyFloxContributor();
        if (isPaused) revert ContractPaused();

        RedeemalEpoch storage epoch = redeemalEpochs[latestAllocatedDistributionEpoch + 1];
        if (!epoch.initiated) revert EpochNotInitiated();
        if (!epoch.populated) revert EpochNotPopulated();
        if (epoch.finalized) revert EpochAlreadyFinalized();

        epoch.finalized = true;
        latestAllocatedDistributionEpoch += 1;

        emit RedeemalEpochFinalized(latestAllocatedDistributionEpoch);
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
        if (isPaused) revert ContractPaused();
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
     * @dev We don't want to double-track the stats for the user, so if the user already has the per-redeemal epoch
     *  stats recorded, the global value will first be rolled back and then updated with the new values.
     * @param _user Address of the user
     * @param _amountOfFxtlPointsRedeemed Amount of FXTL points redeemed by the user
     * @param _floxStakeUnits Amount of Flox stake units redeemed by the user
     */
    function _updateUserStats(address _user, uint256 _amountOfFxtlPointsRedeemed, uint256 _floxStakeUnits) internal {
        UserData storage user = userStats[_user];

        uint256 oldFxtlPointsRedeemed = user.totalFxtlPointsRedeemed;
        uint256 epochNumber = latestAllocatedDistributionEpoch + 1;

        RedeemalEpochUserData memory redeemalEpochData = redeemalEpochUserData[epochNumber][_user];
        RedeemalEpoch storage redeemalEpoch = redeemalEpochs[epochNumber];

        if (redeemalEpochData.fxtlPointsRedeemed != 0) {
            user.totalFxtlPointsRedeemed -= redeemalEpochData.fxtlPointsRedeemed;
            redeemalEpoch.totalFxtlPointsRedeemed -= redeemalEpochData.fxtlPointsRedeemed;
            redeemalEpoch.totalFloxStakeUnits -= redeemalEpochData.floxStakeUnits;
            totalFxtlPointsRedeemed -= redeemalEpochData.fxtlPointsRedeemed;
        }

        user.totalFxtlPointsRedeemed += _amountOfFxtlPointsRedeemed;
        redeemalEpoch.totalFxtlPointsRedeemed += _amountOfFxtlPointsRedeemed;
        redeemalEpoch.totalFloxStakeUnits += _floxStakeUnits;
        totalFxtlPointsRedeemed += _amountOfFxtlPointsRedeemed;

        emit UserStatsUpdated(_user, oldFxtlPointsRedeemed, user.totalFxtlPointsRedeemed);
    }

    /**
     * @notice Used to update the user's redeemal epoch data.
     * @dev If the user's redeemal epoch data is already present, the function overwrites it.
     * @param _user Address of the user getting their redeemal epoch data updated
     * @param _amountOfFxtlPointsRedeemed Amount of FXTL points redeemed by the user
     * @param _floxStakeUnits Amount of Flox stake units redeemed by the user
     */
    function _updateRedeemalEpochUserData(
        address _user,
        uint256 _amountOfFxtlPointsRedeemed,
        uint256 _floxStakeUnits
    ) internal {
        uint256 epochNumber = latestAllocatedDistributionEpoch + 1;

        RedeemalEpochUserData storage userData = redeemalEpochUserData[epochNumber][_user];

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
}
