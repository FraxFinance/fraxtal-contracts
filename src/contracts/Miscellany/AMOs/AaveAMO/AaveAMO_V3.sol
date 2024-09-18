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
// ============================= AaveAMO_V3 ==============================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna

// Reviewer(s) / Contributor(s)
// Sam Kazemian: https://github.com/samkazemian
// Dennis: https://github.com/denett
import { DataTypes } from "./misc/DataTypes.sol";
import { IATokenInstance } from "./interfaces/IATokenInstance.sol";
import { IeETH } from "./interfaces/IeETH.sol";
import { IERC20 } from "@openzeppelin-5/contracts/token/ERC20/IERC20.sol";
import { Initializable } from "@openzeppelin-5/contracts/proxy/utils/Initializable.sol";
import { IFrax } from "src/contracts/Miscellany/interfaces/IFrax.sol";
import { IsFrax } from "src/contracts/Miscellany/interfaces/IsFrax.sol";
import { IAaveOracle } from "./interfaces/IAaveOracle.sol";
import { IAaveProtocolDataProvider } from "./interfaces/IAaveProtocolDataProvider.sol";
import { IPoolAddressesProvider } from "./interfaces/IPoolAddressesProvider.sol";
import { IPoolInstanceWithCustomInitialize } from "./interfaces/IPoolInstanceWithCustomInitialize.sol";
import { OwnedV2AutoMsgSender } from "src/contracts/VestedFXS-and-Flox/VestedFXS/OwnedV2AutoMsgSender.sol";
import { ReserveConfiguration } from "src/contracts/Miscellany/AMOs/AaveAMO/misc/ReserveConfiguration.sol";
import { SafeERC20 } from "@openzeppelin-5/contracts/token/ERC20/utils/SafeERC20.sol";
import { IVariableDebtToken } from "./interfaces/IVariableDebtToken.sol";
import { IweETH } from "./interfaces/IweETH.sol";

contract AaveAMO_V3 is OwnedV2AutoMsgSender, Initializable {
    using SafeERC20 for IERC20;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    /* ========== STATE VARIABLES ========== */
    /// @notice Address of the timelock
    address public timelockAddress;

    /// @notice Address of the operator
    address public operatorAddress;

    // Instances
    // ----------------------------
    /// @notice Address of the FRAX token
    IFrax public FRAX;

    /// @notice Address of the sFRAX token
    IsFrax public sFRAX;

    // Aave-related
    // ----------------------------
    /// @notice AMO-defined parameters for a given pool
    mapping(address _poolAddress => AMOPoolSettings _settings) public poolSettings;

    // ==============================================================================
    // STRUCTS
    // ==============================================================================

    /// @notice AMO-defined parameters for a given pool
    /// @param poolAddress Address for the pool
    /// @param baseCurrency Address for the price feed (base) currency
    /// @param baseCurrencyUnit Units for the price feed (base) currency (e.g. 1e8)
    /// @param poolPaused If the pool is paused in general
    /// @param newBorrowsPaused If new borrowing is disabled for this pool
    /// @param newDepositsPaused If new collateral deposits / supplies are disabled for this pool
    /// @param minHealthFactor Minimum health factor the AMO needs to maintain to be able to borrow. Usually >= Aave's minimum
    /// @param maxCollateralBase Max collateral the AMO can deploy in this pool. In price feed base currency units.
    /// @param maxDebtBase Max debt the AMO can borrow in this pool. In price feed base currency units.
    struct AMOPoolSettings {
        address poolAddress;
        address baseCurrency;
        uint256 baseCurrencyUnit;
        bool poolPaused;
        bool newBorrowsPaused;
        bool newDepositsPaused;
        uint256 minHealthFactor;
        uint256 maxCollateralBase;
        uint256 maxDebtBase;
    }

    // ==============================================================================
    // MODIFIERS
    // ==============================================================================

    /// @notice A modifier that only allows the contract owner or the timelock to call
    modifier onlyByOwnGov() {
        if (msg.sender != owner && msg.sender != timelockAddress) revert NotOwnerOrTimelock();
        _;
    }

    /// @notice A modifier that only allows the contract owner, operator, or timelock to call
    modifier onlyByOwnOprGov() {
        if (msg.sender != owner && msg.sender != operatorAddress && msg.sender != timelockAddress)
            revert NotOwnerOperatorOrTimelock();
        _;
    }

    // ==============================================================================
    // CONSTRUCTOR & INITIALIZER
    // ==============================================================================

    /// @notice Initialize contract
    /// @param _owner Owner of the AMO
    /// @param _operator Operator for the AMO
    /// @param _timelock Timelock for the AMO
    function initialize(address _owner, address _operator, address _timelock) public initializer {
        // Set owner for OwnedV2
        owner = _owner;

        // Set operator
        operatorAddress = _operator;

        // Set timelock
        timelockAddress = _timelock;

        // Set misc tokens
        FRAX = IFrax(0x853d955aCEf822Db058eb8505911ED77F175b99e);
        sFRAX = IsFrax(0xA663B02CF0a4b149d2aD41910CB81e23e1c41c32);
    }

    // ==============================================================================
    // VIEWS
    // ==============================================================================

    /// @notice Calls getUserAccountData on the Aave V3 Pool
    /// @param _poolAddress Address of the Aave V3 Pool
    /// @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
    /// @return totalDebtBase The total debt of the user in the base currency used by the price feed
    /// @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
    /// @return currentLiquidationThreshold The liquidation threshold of the user
    /// @return ltv The loan to value of The user
    /// @return healthFactor The current health factor of the user
    function getAmoUserAccountData(
        address _poolAddress
    )
        public
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        )
    {
        // Call the pool
        return IPoolInstanceWithCustomInitialize(_poolAddress).getUserAccountData(address(this));
    }

    /// @notice Get AToken and debt token addresses for a given pool and asset
    /// @param _pool Address of the Aave V3 Pool
    /// @param _asset Address of the asset
    /// @return _aTokenAddress Address of the AToken (received when depositing / supplying)
    /// @return _stableDebtTokenAddress Address of the StableDebtToken (received when borrowing)
    /// @return _variableDebtTokenAddress Address of the VariableDebtToken (received when borrowing)
    function getReserveTokensAddresses(
        address _pool,
        address _asset
    )
        external
        view
        returns (address _aTokenAddress, address _stableDebtTokenAddress, address _variableDebtTokenAddress)
    {
        // Get the IAaveProtocolDataProvider
        (, , address _protocolDataProvider) = getUsefulPoolAddresses(_pool);

        return IAaveProtocolDataProvider(_protocolDataProvider).getReserveTokensAddresses(_asset);
    }

    /// @notice Checks Aave V3 Pool health as well as AMO-defined limits
    /// @param _poolAddress Address of the Aave V3 Pool
    /// @return _poolIsPaused Whether the pool is paused
    /// @return _belowMinHealthFactor If the AMO is below its own defined minimum health factor
    /// @return _aboveMaxCollateral If the AMO has more collateral than its defined max
    /// @return _aboveMaxDebt If the AMO has more debt than it its max setting
    function checkPoolHealthAndLimits(
        address _poolAddress
    )
        public
        view
        returns (bool _poolIsPaused, bool _belowMinHealthFactor, bool _aboveMaxCollateral, bool _aboveMaxDebt)
    {
        // Fetch information about the AMO's position in the pool
        (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            ,
            ,
            ,
            uint256 healthFactor
        ) = IPoolInstanceWithCustomInitialize(_poolAddress).getUserAccountData(address(this));

        // Fetch the AMOPoolSettings
        AMOPoolSettings memory _settings = poolSettings[_poolAddress];

        // Set return values
        _poolIsPaused = _settings.poolPaused;
        _belowMinHealthFactor = (healthFactor < _settings.minHealthFactor);
        _aboveMaxCollateral = (totalCollateralBase > _settings.maxCollateralBase);
        _aboveMaxDebt = (totalDebtBase > _settings.maxDebtBase);
    }

    /// @notice AMO-defined parameters for a given pool. Returns struct vs poolSettings() tuple
    /// @param _poolAddress Address of the Aave V3 Pool
    /// @return _poolSettings AMOPoolSettings struct
    function getPoolInfo(address _poolAddress) public view returns (AMOPoolSettings memory _poolSettings) {
        _poolSettings = poolSettings[_poolAddress];
    }

    /// @notice Get reserve configuration info for a given pool and asset
    /// @param _poolAddress Address of the Aave V3 Pool
    /// @param _assetAddress Address of the asset
    /// @return _flags [_active, _frozen, _borrowingEnabled, getBorrowableInIsolation, getSiloedBorrowing, _stabRateBrwEnabled, _paused]
    /// @return _params [_ltv, _liqThreshold, _liqBonus, _rsvDecimals, _rsvFactor, _eModeCat]
    /// @return _caps [_borrowCap, getDebtCeiling, _supplyCap]
    function getReserveConfig(
        address _poolAddress,
        address _assetAddress
    ) public view returns (bool[7] memory _flags, uint256[6] memory _params, uint256[3] memory _caps) {
        // Fetch the current ReserveConfigurationMap
        DataTypes.ReserveConfigurationMap memory _currConfig = IPoolInstanceWithCustomInitialize(_poolAddress)
            .getConfiguration(_assetAddress);

        // Flags
        {
            // Get the flags
            (bool _active, bool _frozen, bool _borrowingEnabled, bool _stabRateBrwEnabled, bool _paused) = _currConfig
                .getFlags();
            _flags = [
                _active,
                _frozen,
                _borrowingEnabled,
                _currConfig.getBorrowableInIsolation(),
                _currConfig.getSiloedBorrowing(),
                _stabRateBrwEnabled,
                _paused
            ];
        }

        // Params
        {
            // Get the params
            (
                uint256 _ltv,
                uint256 _liqThreshold,
                uint256 _liqBonus,
                uint256 _rsvDecimals,
                uint256 _rsvFactor,
                uint256 _eModeCat
            ) = _currConfig.getParams();
            _params = [_ltv, _liqThreshold, _liqBonus, _rsvDecimals, _rsvFactor, _eModeCat];
        }

        // Caps
        {
            // Get the caps
            (uint256 _borrowCap, uint256 _supplyCap) = _currConfig.getCaps();
            _caps = [_borrowCap, _currConfig.getDebtCeiling(), _supplyCap];
        }
    }

    /// @notice Get useful addresses for a given pool
    /// @param _poolAddress Address of the Aave V3 Pool
    /// @return _addressesProvider IPoolAddressesProvider
    /// @return _aaveOracle IAaveOracle
    /// @return _protocolDataProvider IAaveProtocolDataProvider
    function getUsefulPoolAddresses(
        address _poolAddress
    ) public view returns (address _addressesProvider, address _aaveOracle, address _protocolDataProvider) {
        // Get the pool
        IPoolInstanceWithCustomInitialize _thePool = IPoolInstanceWithCustomInitialize(_poolAddress);

        // IPoolAddressesProvider
        _addressesProvider = _thePool.ADDRESSES_PROVIDER();

        // IAaveOracle
        _aaveOracle = IPoolAddressesProvider(_addressesProvider).getPriceOracle();

        // IAaveProtocolDataProvider
        _protocolDataProvider = IPoolAddressesProvider(_addressesProvider).getPoolDataProvider();
    }

    /// @notice Get reserve data for given pool, asset, and user
    /// @param _pool Address of the Aave V3 Pool
    /// @param _asset Address of the asset
    /// @param _user Address of the user
    function getUserReserveData(
        address _pool,
        address _asset,
        address _user
    )
        public
        view
        returns (
            uint256 currentATokenBalance,
            uint256 currentStableDebt,
            uint256 currentVariableDebt,
            uint256 principalStableDebt,
            uint256 scaledVariableDebt,
            uint256 stableBorrowRate,
            uint256 liquidityRate,
            uint40 stableRateLastUpdated,
            bool usageAsCollateralEnabled
        )
    {
        // Get the IAaveProtocolDataProvider
        (, , address _protocolDataProvider) = getUsefulPoolAddresses(_pool);

        return IAaveProtocolDataProvider(_protocolDataProvider).getUserReserveData(_asset, _user);
    }

    // ==============================================================================
    // MUTATIVE FUNCTIONS
    // ==============================================================================

    /// @notice Deposit / supply an asset token into an Aave pool
    /// @param _depositToken Address of the asset token to deposit / supply
    /// @param _poolAddress Address of the Aave V3 Pool
    /// @param _depositAmt Amount of asset token (not ATokenShares) to deposit / supply
    function deposit(address _depositToken, address _poolAddress, uint256 _depositAmt) external onlyByOwnOprGov {
        // Check for deposit pausing
        if (poolSettings[_poolAddress].newDepositsPaused) {
            revert NewDepositsPaused();
        }

        // Approve asset to pool. Handles USDT too
        IERC20(_depositToken).forceApprove(_poolAddress, _depositAmt);

        // Deposit / supply into the pool
        IPoolInstanceWithCustomInitialize(_poolAddress).supply(_depositToken, _depositAmt, address(this), 0);

        // Check the AMO status afterwards
        // Don't care about health factor and debt here
        // ----------------------------------------
        (bool _poolIsPaused, , bool _aboveMaxCollateral, ) = checkPoolHealthAndLimits(_poolAddress);
        if (_poolIsPaused) revert PoolIsPaused(); // Revert if the pool is paused
        if (_aboveMaxCollateral) revert TooMuchCollateral(); // Disallow depositing too much collateral

        emit AmoDeposit(_depositToken, _poolAddress, _depositAmt);
    }

    /// @notice Withdraw a previously deposited / supplied asset token from an Aave pool
    /// @param _withdrawToken Address of the asset token to withdraw
    /// @param _poolAddress Address of the Aave V3 Pool
    /// @param _withdrawAmt Amount of asset token (not AToken shares) to withdraw
    function withdraw(address _withdrawToken, address _poolAddress, uint256 _withdrawAmt) external onlyByOwnOprGov {
        // Withdraw
        IPoolInstanceWithCustomInitialize(_poolAddress).withdraw(_withdrawToken, _withdrawAmt, address(this));

        // Check the AMO status afterwards
        // Don't care about max collateral
        // ----------------------------------------
        (bool _poolIsPaused, bool _belowMinHealthFactor, , bool _aboveMaxDebt) = checkPoolHealthAndLimits(_poolAddress);
        if (_poolIsPaused) revert PoolIsPaused(); // Revert if the pool is paused
        if (_belowMinHealthFactor) revert BelowMinimumHealth(); // Don't allow collateral withdrawal if health is too poor
        if (_aboveMaxDebt) revert TooMuchDebt(); // Don't allow collateral withdrawal if there is too much debt

        emit AmoWithdraw(_withdrawToken, _poolAddress, _withdrawAmt);
    }

    /// @notice Borrow an asset token
    /// @param _borrowToken Address of the asset token to borrow
    /// @param _poolAddress Address of the Aave V3 Pool
    /// @param _borrowAmt Amount of asset token to borrow
    /// @param _interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
    function borrow(
        address _borrowToken,
        address _poolAddress,
        uint256 _borrowAmt,
        uint256 _interestRateMode
    ) external onlyByOwnOprGov {
        // Check for borrow pausing
        if (poolSettings[_poolAddress].newBorrowsPaused) {
            revert NewBorrowsPaused();
        }

        // Borrow
        IPoolInstanceWithCustomInitialize(_poolAddress).borrow(
            _borrowToken,
            _borrowAmt,
            _interestRateMode,
            0,
            address(this)
        );

        // Check the AMO status afterwards
        // Don't care about max collateral
        // ----------------------------------------
        (bool _poolIsPaused, bool _belowMinHealthFactor, , bool _aboveMaxDebt) = checkPoolHealthAndLimits(_poolAddress);
        if (_poolIsPaused) revert PoolIsPaused();
        if (_belowMinHealthFactor) revert BelowMinimumHealth(); // Don't allow borrowing if health is too poor
        if (_aboveMaxDebt) revert TooMuchDebt(); // Don't allow borrowing if there is already too much debt

        emit AmoBorrow(_borrowToken, _poolAddress, _borrowAmt, _interestRateMode);
    }

    /// @notice Repay an asset token
    /// @param _repayToken Address of the asset token to repay
    /// @param _poolAddress Address of the Aave V3 Pool
    /// @param _repayAmt Amount of asset token to repay (not VariableDebtToken shares)
    /// @param _interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
    function repay(
        address _repayToken,
        address _poolAddress,
        uint256 _repayAmt,
        uint256 _interestRateMode
    ) external onlyByOwnOprGov {
        // Approve asset to pool. Handles USDT too
        IERC20(_repayToken).forceApprove(_poolAddress, _repayAmt);

        // Repay
        IPoolInstanceWithCustomInitialize(_poolAddress).repay(_repayToken, _repayAmt, _interestRateMode, address(this));

        // Check the AMO status afterwards
        // Don't care about max collateral
        // ----------------------------------------
        (bool _poolIsPaused, , , ) = checkPoolHealthAndLimits(_poolAddress);
        if (_poolIsPaused) revert PoolIsPaused();

        emit AmoRepay(_repayToken, _poolAddress, _repayAmt, _interestRateMode);
    }

    fallback() external payable {
        // This function is executed on a call to the contract if none of the other
        // functions match the given function signature, or if no data is supplied at all
    }

    /// @notice Deposit FRAX -> sFRAX
    /// @param _fraxIn Amount of FRAX to deposit
    /// @return _sfraxOut Amount of sFRAX out
    function depositFraxToSfrax(uint256 _fraxIn) external onlyByOwnOprGov returns (uint256 _sfraxOut) {
        // Approve FRAX to sFRAX
        FRAX.approve(address(sFRAX), _fraxIn);

        // Deposit FRAX to sFRAX
        _sfraxOut = sFRAX.deposit(_fraxIn, address(this));

        emit DepositFraxToSfrax(_fraxIn, _sfraxOut);
    }

    /// @notice Redeem sFRAX -> FRAX
    /// @param _sfraxIn Amount of sFRAX to redeem
    /// @return _fraxOut Amount of FRAX out
    function redeemSfraxForFrax(uint256 _sfraxIn) external onlyByOwnOprGov returns (uint256 _fraxOut) {
        // Redeem sFRAX for FRAX
        _fraxOut = sFRAX.redeem(_sfraxIn, address(this), address(this));

        emit RedeemSfraxForFrax(_sfraxIn, _fraxOut);
    }

    // ==============================================================================
    // RESTRICTED FUNCTIONS
    // ==============================================================================

    /// @notice Set AMO-defined parameters for a given pool
    /// @param _poolAddress Address for the pool
    /// @param _poolPaused If the pool is paused in general
    /// @param _newBorrowsPaused If new borrowing is disabled for this pool
    /// @param _newDepositsPaused If new collateral deposits / supplies are disabled for this pool
    /// @param _minHealthFactor Minimum health factor the AMO needs to maintain to be able to borrow. Usually >= Aave's minimum
    /// @param _maxCollateralBase Max collateral the AMO can deploy in this pool. In price feed base currency units.
    /// @param _maxDebtBase Max debt the AMO can borrow in this pool. In price feed base currency units.
    function setAmoPoolSettings(
        address _poolAddress,
        bool _poolPaused,
        bool _newBorrowsPaused,
        bool _newDepositsPaused,
        uint256 _minHealthFactor,
        uint256 _maxCollateralBase,
        uint256 _maxDebtBase
    ) external onlyByOwnGov {
        // Initialize variables
        address _baseCurrency;
        uint256 _baseCurrencyUnit;

        // Fetch base currency info
        {
            IPoolAddressesProvider _addressesProvider = IPoolAddressesProvider(
                IPoolInstanceWithCustomInitialize(_poolAddress).ADDRESSES_PROVIDER()
            );
            IAaveOracle _oracle = IAaveOracle(_addressesProvider.getPriceOracle());
            _baseCurrency = _oracle.BASE_CURRENCY();
            _baseCurrencyUnit = _oracle.BASE_CURRENCY_UNIT();
        }

        // Set AMO Pool settings
        poolSettings[_poolAddress] = AMOPoolSettings(
            _poolAddress,
            _baseCurrency,
            _baseCurrencyUnit,
            _poolPaused,
            _newBorrowsPaused,
            _newDepositsPaused,
            _minHealthFactor,
            _maxCollateralBase,
            _maxDebtBase
        );

        emit AmoPoolSettingsSet(
            _poolAddress,
            _poolPaused,
            _newBorrowsPaused,
            _newDepositsPaused,
            _minHealthFactor,
            _maxCollateralBase,
            _maxDebtBase
        );
    }

    /// @notice Enable / disable an asset as collateral. Calls setUserUseReserveAsCollateral on the Aave pool
    /// @param _assetToken Address of the token to borrow
    /// @param _poolAddress Address of the Aave V3 Pool
    /// @param _useAsCollateral If true, enable the _assetToken as collateral
    function setAssetCollateralStatus(
        address _assetToken,
        address _poolAddress,
        bool _useAsCollateral
    ) external onlyByOwnGov {
        // Set the collateral status
        IPoolInstanceWithCustomInitialize(_poolAddress).setUserUseReserveAsCollateral(_assetToken, _useAsCollateral);
    }

    /// @notice Sends an ERC20 token back to the owner
    /// @param _tokenAddress The token to recover
    /// @param _tokenAmount The amount to recover
    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyByOwnGov {
        // Only the owner address can ever receive the recovery withdrawal
        IERC20(_tokenAddress).safeTransfer(owner, _tokenAmount);
        emit RecoveredERC20(_tokenAddress, _tokenAmount);
    }

    /// @notice For emergencies if something gets stuck
    function recoverEther(uint256 _amount) external onlyByOwnGov {
        (bool _success, ) = address(owner).call{ value: _amount }("");
        require(_success, "Invalid transfer");

        emit RecoveredEther(_amount);
    }

    /// @notice Sets the operator address
    /// @param _operatorAddress Address of the operator
    function setOperator(address _operatorAddress) public onlyByOwnGov {
        require(_operatorAddress != address(0), "Zero address detected");
        operatorAddress = _operatorAddress;
        emit OperatorChanged(_operatorAddress);
    }

    /// @notice Sets the timelock address
    /// @param _timelockAddress Address of the timelock
    function setTimelock(address _timelockAddress) public onlyByOwnGov {
        require(_timelockAddress != address(0), "Zero address detected");
        timelockAddress = _timelockAddress;
        emit TimelockChanged(_timelockAddress);
    }

    // ==============================================================================
    // EVENTS
    // ==============================================================================

    /// @notice When the AMO borrows an asset token
    /// @param borrowToken Address of the asset token being borrowed
    /// @param poolAddress Address for the Aave V3 Pool
    /// @param borrowAmt Amount of asset token being borrowed
    /// @param interestRateMode The interest rate mode for the borrow: 1 for Stable, 2 for Variable
    event AmoBorrow(address borrowToken, address poolAddress, uint256 borrowAmt, uint256 interestRateMode);

    /// @notice When the AMO deposits / supplies an asset token into an Aave pool
    /// @param depositToken Address of the asset token being deposited / supplied
    /// @param poolAddress Address for the Aave V3 Pool
    /// @param depositAmt Amount of asset token (not ATokenShares) being deposited / supplied
    event AmoDeposit(address depositToken, address poolAddress, uint256 depositAmt);

    /// @notice When AMO-defined parameters for a given pool are set
    /// @param poolAddress Address for the pool
    /// @param poolPaused If the pool is enabled in general
    /// @param newBorrowsPaused If new borrowing is disabled for this pool
    /// @param newDepositsPaused If new collateral deposits / supplies are disabled for this pool
    /// @param minHealthFactor Minimum health factor the AMO needs to maintain to be able to borrow. Usually >= Aave's minimum
    /// @param maxCollateralBase Max collateral the AMO can deploy in this pool. In price feed base currency units.
    /// @param maxDebtBase Max debt the AMO can borrow in this pool. In price feed base currency units.
    event AmoPoolSettingsSet(
        address indexed poolAddress,
        bool poolPaused,
        bool newBorrowsPaused,
        bool newDepositsPaused,
        uint256 minHealthFactor,
        uint256 maxCollateralBase,
        uint256 maxDebtBase
    );

    /// @notice When the AMO repays an asset token
    /// @param repayToken Address of the asset token being repaid
    /// @param poolAddress Address for the Aave V3 Pool
    /// @param repayAmt Amount of asset token being repaid (not VariableDebtToken shares)
    /// @param interestRateMode The interest rate mode for the repay: 1 for Stable, 2 for Variable
    event AmoRepay(address repayToken, address poolAddress, uint256 repayAmt, uint256 interestRateMode);

    /// @notice When the AMO withdraws a previously deposited / supplied asset token from an Aave pool
    /// @param withdrawToken Address of the asset token that is being withdrawn
    /// @param poolAddress Address for the Aave V3 Pool
    /// @param withdrawAmt Amount of asset token (not AToken shares) being withdrawn
    event AmoWithdraw(address withdrawToken, address poolAddress, uint256 withdrawAmt);

    /// @notice When the AMO converts FRAX to sFRAX
    /// @param fraxIn Amount of FRAX in
    /// @param sfraxOut Amount of sFRAX out
    event DepositFraxToSfrax(uint256 fraxIn, uint256 sfraxOut);

    /// @notice Emitted when the operator address is changed
    /// @param operatorAddress Address of the removed operator
    event OperatorChanged(address operatorAddress);

    /// @notice When the AMO converts sFRAX to FRAX
    /// @param sfraxIn Amount of sFRAX in
    /// @param fraxOut Amount of FRAX out
    event RedeemSfraxForFrax(uint256 sfraxIn, uint256 fraxOut);

    /// @notice When ERC20 tokens were recovered
    /// @param token Token address
    /// @param amount Amount of tokens collected
    event RecoveredERC20(address token, uint256 amount);

    /// @notice When ether was recovered
    /// @param amount Amount of ether recovered
    event RecoveredEther(uint256 amount);

    /// @notice Emitted when the timelock address is changed
    /// @param timelockAddress Address of the removed timelock
    event TimelockChanged(address timelockAddress);

    // ==============================================================================
    // ERRORS
    // ==============================================================================

    /// @notice If the health of the AMO's position in a pool is below the defined limit
    error BelowMinimumHealth();

    /// @notice If new borrows are paused for a pool
    error NewBorrowsPaused();

    /// @notice If new deposits are paused for a pool
    error NewDepositsPaused();

    /// @notice If you are trying to call a function not as the owner or timelock
    error NotOwnerOrTimelock();

    /// @notice If you are trying to call a function not as the owner, operator, or timelock
    error NotOwnerOperatorOrTimelock();

    /// @notice If the pool is paused
    error PoolIsPaused();

    /// @notice If the AMO has too much collateral for this pool
    error TooMuchCollateral();

    /// @notice If the AMO has too much debt for this pool
    error TooMuchDebt();
}
