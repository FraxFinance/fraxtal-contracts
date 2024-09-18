// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { BaseTestMisc } from "../BaseTestMisc.t.sol";
import { FraxtalERC4626MintRedeemer } from "src/contracts/Miscellany/FraxtalERC4626MintRedeemer.sol";
import { FRAXToFXBLockerRouter } from "src/contracts/Miscellany/FRAXToFXBLockerRouter.sol";
import { MintableBurnableTestERC20 } from "src/test/VestedFXS-and-Flox/helpers/MintableBurnableTestERC20.sol";
import { OwnedV2 } from "src/contracts/Miscellany/OwnedV2.sol";
import { ISlippageAuction } from "src/contracts/Miscellany/interfaces/ISlippageAuction.sol";
import { TimedLocker } from "src/contracts/Miscellany/TimedLocker.sol";
import { console } from "frax-std/FraxTest.sol";
import "src/Constants.sol" as Constants;
import "forge-std/console2.sol";

contract Unit_Test_FRAXToFXBLockerRouterTest is BaseTestMisc {
    // Create local instances here apart from BaseTestMisc
    // -----------------------------
    uint256 public fxtlAlicePrivateKey;
    address payable public fxtlAlice;
    MintableBurnableTestERC20 public fxtlFrax;
    MintableBurnableTestERC20 public fxtlFxs;
    MintableBurnableTestERC20 public fxtlFxb2027;
    ISlippageAuction public auction2027;
    TimedLocker public timedLocker2027L2025;
    FRAXToFXBLockerRouter public lockerRouter2027L2025;

    function LockerRouterSetup() public {
        console.log("LockerRouterSetup() called");
        super.defaultSetup();

        // Switch to Fraxtal immediately, ignoring BaseTestMisc setup
        vm.createSelectFork(vm.envString("FRAXTAL_RPC_URL"), 8_259_697);

        // Instantiate existing contracts
        fxtlFrax = MintableBurnableTestERC20(Constants.FraxtalStandardProxies.FRAX_PROXY);
        fxtlFxs = MintableBurnableTestERC20(Constants.FraxtalStandardProxies.FXS_PROXY);
        fxtlFxb2027 = MintableBurnableTestERC20(Constants.FraxtalMainnet.FXB_20271231);
        auction2027 = ISlippageAuction(0x0eAbf4a9b73Ec031AD499082c5Dcb55759Fbd6Dd);
        timedLocker2027L2025 = TimedLocker(0xbAF15fA061d83608B7F59226b8491C1eb9DF48B2);

        // Create the LockerRouter
        lockerRouter2027L2025 = new FRAXToFXBLockerRouter(address(this));

        // Labels
        // ----------------------------------------------
        vm.label(address(fxtlFrax), "fxtlFrax");
        vm.label(address(fxtlFxs), "fxtlFxs");
        vm.label(address(fxtlFxb2027), "fxtlFxb2027");
        vm.label(address(auction2027), "auction2027");
        vm.label(address(timedLocker2027L2025), "timedLocker2027L2025");
        vm.label(address(lockerRouter2027L2025), "lockerRouter2027L2025");

        // Set up Alice
        fxtlAlicePrivateKey = 0xA11CE;
        fxtlAlice = payable(vm.addr(fxtlAlicePrivateKey));
        vm.label(fxtlAlice, "FxtlAlice");

        // Set a route
        lockerRouter2027L2025.setRouteStatus(address(fxtlFxb2027), address(auction2027), address(timedLocker2027L2025), true);

        // Give FRAX to the test user
        hoax(Constants.FraxtalMainnet.FRAXCHAIN_MAIN_MULTISIG);
        fxtlFrax.transfer(fxtlAlice, 1000e18);
    }

    function test_MainLockerRouter() public {
        LockerRouterSetup();

        // Approve to the LockerRouter
        vm.startPrank(fxtlAlice);
        fxtlFrax.approve(address(lockerRouter2027L2025), 100e18);

        // Execute the routing (should succeed)
        lockerRouter2027L2025.routeFraxToTimedLocker(address(fxtlFxb2027), address(auction2027), address(timedLocker2027L2025), 100e18, 90e18);

        // Approve to the LockerRouter again
        fxtlFrax.approve(address(lockerRouter2027L2025), 100e18);

        // Too high minOut (should fail)
        vm.expectRevert();
        lockerRouter2027L2025.routeFraxToTimedLocker(address(fxtlFxb2027), address(auction2027), address(timedLocker2027L2025), 100e18, 200e18);

        // Wrong FXB address(should fail)
        vm.expectRevert(FRAXToFXBLockerRouter.InvalidRoute.selector);
        lockerRouter2027L2025.routeFraxToTimedLocker(address(fxtlAlice), address(auction2027), address(timedLocker2027L2025), 100e18, 90e18);

        // Wrong SlippageAuction address (should fail)
        vm.expectRevert(FRAXToFXBLockerRouter.InvalidRoute.selector);
        lockerRouter2027L2025.routeFraxToTimedLocker(address(fxtlFxb2027), address(fxtlAlice), address(timedLocker2027L2025), 100e18, 90e18);

        // Wrong TimedLocker address (should fail)
        vm.expectRevert(FRAXToFXBLockerRouter.InvalidRoute.selector);
        lockerRouter2027L2025.routeFraxToTimedLocker(address(fxtlFxb2027), address(auction2027), address(fxtlAlice), 100e18, 90e18);

        vm.stopPrank();

        // Disable the route
        hoax(lockerRouter2027L2025.owner());
        lockerRouter2027L2025.setRouteStatus(address(fxtlFxb2027), address(auction2027), address(timedLocker2027L2025), false);

        // Try the old route (should fail)
        vm.expectRevert(FRAXToFXBLockerRouter.InvalidRoute.selector);
        hoax(fxtlAlice);
        lockerRouter2027L2025.routeFraxToTimedLocker(address(fxtlFxb2027), address(auction2027), address(timedLocker2027L2025), 100e18, 90e18);

        // Try setting a route with a zero-address FXB (should fail)
        vm.expectRevert(FRAXToFXBLockerRouter.InvalidFXB.selector);
        lockerRouter2027L2025.setRouteStatus(address(0), address(auction2027), address(timedLocker2027L2025), true);

        // // Try setting a route with an incorrect SlippageAuction (should fail)
        // vm.expectRevert(FRAXToFXBLockerRouter.InvalidAuction.selector);
        // lockerRouter2027L2025.setRouteStatus(address(fxtlFxb2027), fxtlAlice, address(timedLocker2027L2025), true);

        // // Try setting a route with an incorrect TimedLocker (should fail)
        // vm.expectRevert(FRAXToFXBLockerRouter.InvalidTimedLocker.selector);
        // lockerRouter2027L2025.setRouteStatus(address(fxtlFxb2027), address(auction2027), fxtlAlice, true);
    }
}
