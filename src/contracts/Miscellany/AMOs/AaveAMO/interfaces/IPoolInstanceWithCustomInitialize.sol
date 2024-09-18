// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import { DataTypes } from "../misc/DataTypes.sol";

interface IPoolInstanceWithCustomInitialize {
    function ADDRESSES_PROVIDER() external view returns (address);

    function BRIDGE_PROTOCOL_FEE() external view returns (uint256);

    function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint128);

    function FLASHLOAN_PREMIUM_TO_PROTOCOL() external view returns (uint128);

    function MAX_NUMBER_RESERVES() external view returns (uint16);

    function MAX_STABLE_RATE_BORROW_SIZE_PERCENT() external view returns (uint256);

    function POOL_REVISION() external view returns (uint256);

    function backUnbacked(address asset, uint256 amount, uint256 fee) external returns (uint256);

    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    function configureEModeCategory(uint8 id, DataTypes.EModeCategory memory category) external;

    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    function dropReserve(address asset) external;

    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromBefore,
        uint256 balanceToBefore
    ) external;

    function flashLoan(
        address receiverAddress,
        address[] memory assets,
        uint256[] memory amounts,
        uint256[] memory interestRateModes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes memory params,
        uint16 referralCode
    ) external;

    function getBorrowLogic() external pure returns (address);

    function getBridgeLogic() external pure returns (address);

    function getConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory);

    function getEModeCategoryData(uint8 id) external view returns (DataTypes.EModeCategory memory);

    function getEModeLogic() external pure returns (address);

    function getFlashLoanLogic() external pure returns (address);

    function getLiquidationGracePeriod(address asset) external returns (uint40);

    function getLiquidationLogic() external pure returns (address);

    function getPoolLogic() external pure returns (address);

    function getReserveAddressById(uint16 id) external view returns (address);

    function getReserveData(address asset) external view returns (DataTypes.ReserveDataLegacy memory);

    function getReserveDataExtended(address asset) external view returns (DataTypes.ReserveData memory);

    function getReserveNormalizedIncome(address asset) external view returns (uint256);

    function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

    function getReservesCount() external view returns (uint256);

    function getReservesList() external view returns (address[] memory);

    function getSupplyLogic() external pure returns (address);

    function getUserAccountData(
        address user
    )
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function getUserConfiguration(address user) external view returns (DataTypes.UserConfigurationMap memory);

    function getUserEMode(address user) external view returns (uint256);

    function getVirtualUnderlyingBalance(address asset) external view returns (uint128);

    function initReserve(
        address asset,
        address aTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    function initialize(address provider) external;

    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    function mintToTreasury(address[] memory assets) external;

    function mintUnbacked(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    function rebalanceStableBorrowRate(address asset, address user) external;

    function repay(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf
    ) external returns (uint256);

    function repayWithATokens(address asset, uint256 amount, uint256 interestRateMode) external returns (uint256);

    function repayWithPermit(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external returns (uint256);

    function rescueTokens(address token, address to, uint256 amount) external;

    function resetIsolationModeTotalDebt(address asset) external;

    function setConfiguration(address asset, DataTypes.ReserveConfigurationMap calldata configuration) external;

    function setLiquidationGracePeriod(address asset, uint40 until) external;

    function setReserveInterestRateStrategyAddress(address asset, address rateStrategyAddress) external;

    function setUserEMode(uint8 categoryId) external;

    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    function supplyWithPermit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external;

    function swapBorrowRateMode(address asset, uint256 interestRateMode) external;

    function swapToVariable(address asset, address user) external;

    function syncIndexesState(address asset) external;

    function syncRatesState(address asset) external;

    function updateBridgeProtocolFee(uint256 protocolFee) external;

    function updateFlashloanPremiums(uint128 flashLoanPremiumTotal, uint128 flashLoanPremiumToProtocol) external;

    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}
