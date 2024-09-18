// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/StdStorage.sol";
import { FraxTest } from "frax-std/FraxTest.sol";
import { console } from "frax-std/FraxTest.sol";
import { AaveAMO_V3 } from "src/contracts/Miscellany/AMOs/AaveAMO/AaveAMO_V3.sol";
import { DataTypes } from "src/contracts/Miscellany/AMOs/AaveAMO/misc/DataTypes.sol";
import { DecimalStringHelper } from "src/test/VestedFXS-and-Flox/helpers/DecimalStringHelper.sol";
import { IeETH } from "src/contracts/Miscellany/AMOs/AaveAMO/interfaces/IeETH.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IFrax } from "src/contracts/Miscellany/interfaces/IFrax.sol";
import { IsFrax } from "src/contracts/Miscellany/interfaces/IsFrax.sol";
import { IAaveOracle } from "src/contracts/Miscellany/AMOs/AaveAMO/interfaces/IAaveOracle.sol";
import { IAaveProtocolDataProvider } from "src/contracts/Miscellany/AMOs/AaveAMO/interfaces/IAaveProtocolDataProvider.sol";
import { IPoolAddressesProvider } from "src/contracts/Miscellany/AMOs/AaveAMO/interfaces/IPoolAddressesProvider.sol";
import { IPoolInstanceWithCustomInitialize } from "src/contracts/Miscellany/AMOs/AaveAMO/interfaces/IPoolInstanceWithCustomInitialize.sol";
import { OwnedV2AutoMsgSender } from "src/contracts/VestedFXS-and-Flox/VestedFXS/OwnedV2AutoMsgSender.sol";
import { ReserveConfiguration } from "src/contracts/Miscellany/AMOs/AaveAMO/misc/ReserveConfiguration.sol";
import { TransferHelper } from "src/contracts/VestedFXS-and-Flox/Flox/TransferHelper.sol";
import { IVariableDebtToken } from "src/contracts/Miscellany/AMOs/AaveAMO/interfaces/IVariableDebtToken.sol";
import { IweETH } from "src/contracts/Miscellany/AMOs/AaveAMO/interfaces/IweETH.sol";

import "src/Constants.sol" as Constants;

contract Misc_Test_AaveAMO_V3 is FraxTest {
    using stdStorage for StdStorage;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using DecimalStringHelper for uint256;

    // Avoid stack-too-deep

    // Aave
    // =========================================
    AaveAMO_V3 public aaveAMO;

    // Ethereum V3
    IPoolInstanceWithCustomInitialize public aaveEthV3Pool = IPoolInstanceWithCustomInitialize(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);
    IPoolAddressesProvider public aaveEthV3AddressesProvider;
    IAaveOracle public aaveEthV3Oracle;
    IAaveProtocolDataProvider public aaveEthV3ProtocolDataProvider;
    address public aaveEthV3BaseCurrency;
    uint256 public aaveEthV3BaseCurrencyUnit;

    // EtherFi V3
    IPoolInstanceWithCustomInitialize public aaveEtherFiV3Pool = IPoolInstanceWithCustomInitialize(0x0AA97c284e98396202b6A04024F5E2c65026F3c0);
    IPoolAddressesProvider public aaveEtherFiV3AddressesProvider;
    IAaveOracle public aaveEtherFiV3Oracle;
    IAaveProtocolDataProvider public aaveEtherFiV3ProtocolDataProvider;
    address public aaveEtherFiV3BaseCurrency;
    uint256 public aaveEtherFiV3BaseCurrencyUnit;

    // ERC20s
    // =========================================
    IeETH public eETH = IeETH(0x35fA164735182de50811E8e2E824cFb9B6118ac2);
    IFrax public FRAX = IFrax(0x853d955aCEf822Db058eb8505911ED77F175b99e);
    IERC20 public GHO = IERC20(0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f);
    IsFrax public sFRAX = IsFrax(0xA663B02CF0a4b149d2aD41910CB81e23e1c41c32);
    IweETH public weETH = IweETH(0xCd5fE23C85820F7B72D0926FC9b05b43E359b7ee);
    IERC20 public USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    // Misc
    // =========================================

    uint256 public operatorPrivateKey;
    address payable public operator;

    // Constants
    // ========================================

    function defaultSetup() public {
        // Switch to Ethereum
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"), 20_728_768);

        // Set up the operator
        operatorPrivateKey = 0x0f324702;
        operator = payable(vm.addr(operatorPrivateKey));
        vm.label(operator, "Operator");

        // Instantiate the AaveAMO_V3
        aaveAMO = new AaveAMO_V3();
        aaveAMO.initialize({ _owner: address(this), _operator: operator, _timelock: address(this) });

        // Fetch the ReserveConfigurationMaps
        DataTypes.ReserveConfigurationMap memory resConfFRAXEthV3 = aaveEthV3Pool.getConfiguration(address(FRAX));
        DataTypes.ReserveConfigurationMap memory resConfFRAXEtherFiV3 = aaveEtherFiV3Pool.getConfiguration(address(FRAX));

        // Set Aave Instances
        // Ethereum V3
        aaveEthV3AddressesProvider = IPoolAddressesProvider(aaveEthV3Pool.ADDRESSES_PROVIDER());
        aaveEthV3Oracle = IAaveOracle(aaveEthV3AddressesProvider.getPriceOracle());
        aaveEthV3ProtocolDataProvider = IAaveProtocolDataProvider(aaveEthV3AddressesProvider.getPoolDataProvider());
        aaveEthV3BaseCurrency = aaveEthV3Oracle.BASE_CURRENCY();
        aaveEthV3BaseCurrencyUnit = aaveEthV3Oracle.BASE_CURRENCY_UNIT();

        // EtherFi V3
        aaveEtherFiV3AddressesProvider = IPoolAddressesProvider(aaveEtherFiV3Pool.ADDRESSES_PROVIDER());
        aaveEtherFiV3Oracle = IAaveOracle(aaveEtherFiV3AddressesProvider.getPriceOracle());
        aaveEtherFiV3ProtocolDataProvider = IAaveProtocolDataProvider(aaveEtherFiV3AddressesProvider.getPoolDataProvider());
        aaveEtherFiV3BaseCurrency = aaveEtherFiV3Oracle.BASE_CURRENCY();
        aaveEtherFiV3BaseCurrencyUnit = aaveEtherFiV3Oracle.BASE_CURRENCY_UNIT();

        // Labels
        vm.label(address(aaveAMO), "AaveAMO_V3");
        vm.label(address(eETH), "eETH");
        vm.label(address(FRAX), "FRAX");
        vm.label(address(GHO), "GHO");
        vm.label(address(sFRAX), "sFRAX");
        vm.label(address(weETH), "weETH");
        vm.label(address(USDC), "USDC");
        vm.label(address(aaveEthV3Pool), "aaveEthV3Pool");
        vm.label(address(aaveEtherFiV3Pool), "aaveEtherFiV3Pool");

        // Give the AMO some ETH
        vm.deal(address(aaveAMO), 1 ether);

        // Give the AMO some FRAX
        vm.startPrank(0xB1748C79709f4Ba2Dd82834B8c82D4a505003f27);
        FRAX.transfer(address(aaveAMO), 10_000e18);
        vm.stopPrank();

        // Give the AMO some USDC
        vm.startPrank(0x37305B1cD40574E4C5Ce33f8e8306Be057fD7341);
        USDC.transfer(address(aaveAMO), 10_000e6);
        vm.stopPrank();

        // Remove FRAX from isolation mode
        // ---------------------------------------
        // Switch to the PoolConfigurator proxy (aaveEthV3Pool -> ADDRESSES_PROVIDER() -> getPoolConfigurator())
        vm.startPrank(0x64b761D848206f447Fe2dd461b0c635Ec39EbB27);
        resConfFRAXEthV3.setBorrowableInIsolation(true);
        resConfFRAXEthV3.setLtv(7500);
        resConfFRAXEthV3.setLiquidationThreshold(7800);
        resConfFRAXEthV3.setDebtCeiling(0);
        aaveEthV3Pool.setConfiguration(address(FRAX), resConfFRAXEthV3);
        vm.stopPrank();

        // Switch to the PoolConfigurator proxy (aaveEtherFiV3Pool -> ADDRESSES_PROVIDER() -> getPoolConfigurator())
        vm.startPrank(0x8438F4D29D895d75C86BDC25360c25eF0607E65d);
        resConfFRAXEtherFiV3.setBorrowableInIsolation(true);
        resConfFRAXEtherFiV3.setLtv(7500);
        resConfFRAXEtherFiV3.setLiquidationThreshold(7800);
        resConfFRAXEtherFiV3.setDebtCeiling(0);
        aaveEtherFiV3Pool.setConfiguration(address(FRAX), resConfFRAXEtherFiV3);
        vm.stopPrank();

        // Configure AMO settings
        // ---------------------------------------
        aaveAMO.setAmoPoolSettings(address(aaveEthV3Pool), false, false, false, 5e18, 1000 * aaveEthV3BaseCurrencyUnit, 200 * aaveEthV3BaseCurrencyUnit);
        aaveAMO.setAmoPoolSettings(address(aaveEtherFiV3Pool), false, false, false, 5e18, 1000 * aaveEtherFiV3BaseCurrencyUnit, 200 * aaveEtherFiV3BaseCurrencyUnit);
    }

    function printAMOUserStatus(address _poolAddress, string memory _description) public {
        // Print title
        console.log(unicode"\n🏦🏦🏦🏦🏦🏦🏦🏦 AMO STATUS (%s) 🏦🏦🏦🏦🏦🏦🏦🏦", _description);

        // Fetch the User Account Data
        (uint256 _totalCollateralBase, uint256 _totalDebtBase, uint256 _availableBorrowsBase, uint256 _currentLiquidationThreshold, uint256 _ltv, uint256 _healthFactor) = aaveAMO.getAmoUserAccountData(_poolAddress);

        // Print
        console.log("_totalCollateralBase: %s", _totalCollateralBase);
        console.log("_totalDebtBase: %s", _totalDebtBase);
        console.log("_availableBorrowsBase: %s", _availableBorrowsBase);
        console.log("_currentLiquidationThreshold: %s", _currentLiquidationThreshold);
        console.log("_ltv: %s", _ltv);
        console.log("_healthFactor: %s", _healthFactor);
    }

    function printReserveConfiguration(address _poolAddress, address _assetAddress) public {
        // Print title
        console.log(unicode"\n🌊🌊🌊🌊🌊🌊🌊🌊 %s: POOL STATUS 🌊🌊🌊🌊🌊🌊🌊🌊", vm.getLabel(_poolAddress), vm.getLabel(_assetAddress));

        // Get the current Reserve Configuration Info
        (bool[7] memory _flags, uint256[6] memory _params, uint256[3] memory _caps) = aaveAMO.getReserveConfig(_poolAddress, _assetAddress);

        // Flags
        {
            // Print the flags
            console.log("~~~~~ FLAGS ~~~~~");
            console.log("_active: %s", _flags[0]);
            console.log("_frozen: %s", _flags[1]);
            console.log("_borrowingEnabled: %s", _flags[2]);
            console.log("_borrowingInIsolation: %s", _flags[3]);
            console.log("_siloedBorrowing: %s", _flags[4]);
            console.log("_stabRateBrwEnabled: %s", _flags[5]);
            console.log("_paused: %s", _flags[6]);
        }

        // Params
        {
            // Print the params
            console.log("~~~~~ PARAMS ~~~~~");
            console.log("_ltv: %s", _params[0]);
            console.log("_liqThreshold: %s", _params[1]);
            console.log("_liqBonus: %s", _params[2]);
            console.log("_rsvDecimals: %s", _params[3]);
            console.log("_rsvFactor: %s", _params[4]);
            console.log("_eModeCat: %s", _params[5]);
        }

        // Caps
        {
            // Print the caps
            console.log("~~~~~ CAPS ~~~~~");
            console.log("_borrowCap: %s", _caps[0]);
            console.log("_isoModeDebtCeiling: %s", _caps[1]);
            console.log("_supplyCap: %s", _caps[2]);
        }
    }

    function test_EthV3Main() public {
        defaultSetup();

        // Attacker tries to re-initialize but fails
        hoax(address(5));
        vm.expectRevert();
        aaveAMO.initialize({ _owner: address(5), _operator: address(5), _timelock: address(5) });

        // Check initial setting
        // --------------------------
        printReserveConfiguration(address(aaveEthV3Pool), address(FRAX));
        // printReserveConfiguration(address(aaveEthV3Pool), address(USDC));

        // // Set FRAX as a collateral if it is not already
        // aaveAMO.setAssetCollateralStatus(address(FRAX), address(aaveEthV3Pool), true);

        // Deposit 1000 FRAX as collateral
        aaveAMO.deposit(address(FRAX), address(aaveEthV3Pool), 1000e18);

        // Print the AMO status
        printAMOUserStatus(address(aaveEthV3Pool), "0");

        // Try to deposit an additional 1000 FRAX (should fail due to AMO collateral limit)
        vm.expectRevert(AaveAMO_V3.TooMuchCollateral.selector);
        aaveAMO.deposit(address(FRAX), address(aaveEthV3Pool), 1000e18);

        // Operator cannot change limits
        hoax(operator);
        vm.expectRevert(AaveAMO_V3.NotOwnerOrTimelock.selector);
        aaveAMO.setAmoPoolSettings(address(aaveEthV3Pool), false, false, false, 2e18, 1001 * aaveEthV3BaseCurrencyUnit, 200 * aaveEthV3BaseCurrencyUnit);

        // Raise the borrow limit by 1 base unit
        aaveAMO.setAmoPoolSettings(address(aaveEthV3Pool), false, false, false, 2e18, 1001 * aaveEthV3BaseCurrencyUnit, 200 * aaveEthV3BaseCurrencyUnit);

        // Deposit 1 more FRAX as collateral (should be able to now)
        hoax(operator);
        aaveAMO.deposit(address(FRAX), address(aaveEthV3Pool), 1e18);

        // Withdraw 1 FRAX
        aaveAMO.withdraw(address(FRAX), address(aaveEthV3Pool), 1e18);

        // Borrow 50 GHO as operator
        hoax(operator);
        aaveAMO.borrow(address(GHO), address(aaveEthV3Pool), 50e18, 2);

        // Borrow 50 GHO as owner/timelock
        aaveAMO.borrow(address(GHO), address(aaveEthV3Pool), 50e18, 2);

        // Try to borrow 200 GHO (should fail due to AMO debt limit)
        vm.expectRevert(AaveAMO_V3.TooMuchDebt.selector);
        aaveAMO.borrow(address(GHO), address(aaveEthV3Pool), 200e18, 2);

        // Lower the AMO minimum health. Also put collateral limit back to 1000
        aaveAMO.setAmoPoolSettings(address(aaveEthV3Pool), false, false, false, 5e18, 1000 * aaveEthV3BaseCurrencyUnit, 200 * aaveEthV3BaseCurrencyUnit);

        // Try to borrow 100 GHO (should fail due to being below the AMO-set health)
        vm.expectRevert(AaveAMO_V3.BelowMinimumHealth.selector);
        aaveAMO.borrow(address(GHO), address(aaveEthV3Pool), 100e18, 2);

        // Print the AMO status
        printAMOUserStatus(address(aaveEthV3Pool), "1");

        // Repay as operator
        hoax(operator);
        aaveAMO.repay(address(GHO), address(aaveEthV3Pool), 50e18, 2);

        // Repay as owner / timelock
        aaveAMO.repay(address(GHO), address(aaveEthV3Pool), 50e18, 2);

        // Withdraw some collateral
        hoax(operator);
        aaveAMO.withdraw(address(FRAX), address(aaveEthV3Pool), 500e18);

        // Print the AMO status
        printAMOUserStatus(address(aaveEthV3Pool), "2");

        // Turn off deposits and borrows
        aaveAMO.setAmoPoolSettings(address(aaveEthV3Pool), false, true, true, 2e18, 1001 * aaveEthV3BaseCurrencyUnit, 200 * aaveEthV3BaseCurrencyUnit);

        // Try to borrow 1 GHO (should fail due to being paused)
        vm.expectRevert(AaveAMO_V3.NewBorrowsPaused.selector);
        aaveAMO.borrow(address(GHO), address(aaveEthV3Pool), 1e18, 2);

        // Try to deposit 1 GHO (should fail due to being paused)
        vm.expectRevert(AaveAMO_V3.NewDepositsPaused.selector);
        aaveAMO.deposit(address(FRAX), address(aaveEthV3Pool), 1e18);

        // Turn on deposits and borrows, but turn off the pool in general
        aaveAMO.setAmoPoolSettings(address(aaveEthV3Pool), true, false, false, 2e18, 1001 * aaveEthV3BaseCurrencyUnit, 200 * aaveEthV3BaseCurrencyUnit);

        // Try to borrow 1 GHO (should fail due to being paused)
        vm.expectRevert(AaveAMO_V3.PoolIsPaused.selector);
        aaveAMO.borrow(address(GHO), address(aaveEthV3Pool), 1e18, 2);

        // Try to deposit 1 GHO (should fail due to being paused)
        vm.expectRevert(AaveAMO_V3.PoolIsPaused.selector);
        aaveAMO.deposit(address(FRAX), address(aaveEthV3Pool), 1e18);

        // FRAX <> sFRAX
        {
            // Swap FRAX to sFRAX
            uint256 _sfraxOut = aaveAMO.depositFraxToSfrax(10);

            // Swap sFRAX to FRAX
            aaveAMO.redeemSfraxForFrax(_sfraxOut);
        }

        // Print the AMO status
        printAMOUserStatus(address(aaveEthV3Pool), "3");

        // Recover ether
        aaveAMO.recoverEther(1 wei);

        // Operator cannot recover ether
        hoax(operator);
        vm.expectRevert(AaveAMO_V3.NotOwnerOrTimelock.selector);
        aaveAMO.recoverEther(1 wei);

        // Recover ERC20
        aaveAMO.recoverERC20(address(FRAX), 1e18);

        // Operator cannot recover ERC20s
        hoax(operator);
        vm.expectRevert(AaveAMO_V3.NotOwnerOrTimelock.selector);
        aaveAMO.recoverERC20(address(FRAX), 1e18);

        // Operator cannot change the operator
        hoax(operator);
        vm.expectRevert(AaveAMO_V3.NotOwnerOrTimelock.selector);
        aaveAMO.setOperator(operator);

        // Operator cannot change the timelock
        hoax(operator);
        vm.expectRevert(AaveAMO_V3.NotOwnerOrTimelock.selector);
        aaveAMO.setTimelock(operator);
    }

    // function test_EtherFiV3Main() public {
    //     defaultSetup();

    //     // Check initial setting
    //     // --------------------------
    //     printReserveConfiguration(address(aaveEtherFiV3Pool), address(FRAX));
    // }

    function _warpToAndRollOne(uint256 _newTs) public {
        vm.warp(_newTs);
        vm.roll(block.number + 1);
    }

    fallback() external payable {
        // This function is executed on a call to the contract if none of the other
        // functions match the given function signature, or if no data is supplied at all
    }
}
