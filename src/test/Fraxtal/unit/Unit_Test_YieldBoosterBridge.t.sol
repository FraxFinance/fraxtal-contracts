// SPDX-License-Identifier: ISC
pragma solidity ^0.8.15;

import { BaseTestFraxtal } from "../BaseTestFraxtal.t.sol";
import { FraxchainPortal } from "src/contracts/Fraxtal/L1/FraxchainPortal.sol";
import { YieldBoosterBridge } from "src/contracts/Fraxtal/yieldboosting/YieldBoosterBridge.sol";
import { CrossDomainMessenger } from "@eth-optimism/contracts-bedrock/src/universal/CrossDomainMessenger.sol";
import { ERC4626PriceOracle } from "src/contracts/Fraxtal/yieldboosting/ERC4626PriceOracle.sol";
import { AddressAliasHelper } from "@eth-optimism/contracts-bedrock/src/vendor/AddressAliasHelper.sol";
import { Types } from "@eth-optimism/contracts-bedrock/src/libraries/Types.sol";
import { Predeploys } from "@eth-optimism/contracts-bedrock/src//libraries/Predeploys.sol";
import { FraxTest } from "frax-std/FraxTest.sol";
import { console } from "frax-std/FraxTest.sol";
import { SigUtils } from "src/test/Fraxtal/utils/SigUtils.sol";
import "src/Constants.sol" as Constants;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { DummyYieldToken } from "../DummyYieldToken.sol";

contract Unit_Test_YieldBoosterBridge is BaseTestFraxtal {
    YieldBoosterBridge public yieldBoosterBridge;
    DummyYieldToken dummyYieldToken;
    address remoteToken = 0xFc00000000000000000000000000000000000001;
    ERC4626PriceOracle priceOracle;
    address remoteYieldDistributor = 0xFc00000000000000000000000000000000000002;
    address remoteBridge = 0x4200000000000000000000000000000000000999;

    function defaultSetup() internal override {
        super.defaultSetup();
        yieldBoosterBridge = new MyYieldBoosterBridge(CrossDomainMessenger(address(messenger)), YieldBoosterBridge(payable(remoteBridge)));
        priceOracle = new ERC4626PriceOracle();
        dummyYieldToken = new DummyYieldToken("Dummy", "DUM");

        dummyYieldToken.transfer(alice, 100e18);
        dummyYieldToken.transfer(bob, 100e18);
    }

    function test_initializePair() public {
        defaultSetup();

        yieldBoosterBridge.initializePair(address(dummyYieldToken), remoteToken, address(priceOracle), remoteYieldDistributor);
    }

    function test_bridgeERC20To() public {
        defaultSetup();

        yieldBoosterBridge.initializePair(address(dummyYieldToken), remoteToken, address(priceOracle), remoteYieldDistributor);

        // Alice bridges the DummyYieldToken
        hoax(alice);
        dummyYieldToken.approve(address(yieldBoosterBridge), 1e18);

        vm.expectCall(address(dummyYieldToken), abi.encodeWithSelector(IERC20.transferFrom.selector, alice, address(yieldBoosterBridge), 1e18));
        vm.expectEmit(true, true, true, true, address(yieldBoosterBridge));
        emit ERC20BridgeInitiated(address(dummyYieldToken), remoteToken, alice, bob, 1e18, bytes(""));

        vm.prank(alice);
        yieldBoosterBridge.bridgeERC20To(address(dummyYieldToken), remoteToken, bob, 1e18, 100_000, bytes(""));

        dummyYieldToken.setPricePerShare(101e16);

        vm.prank(alice);
        dummyYieldToken.approve(address(yieldBoosterBridge), 1e18);

        vm.expectCall(address(dummyYieldToken), abi.encodeWithSelector(IERC20.transferFrom.selector, alice, address(yieldBoosterBridge), 1e18));
        vm.expectEmit(true, true, true, true, address(yieldBoosterBridge));
        emit ERC20BridgeInitiated(address(dummyYieldToken), remoteToken, alice, bob, 101e16, bytes(""));

        vm.prank(alice);
        yieldBoosterBridge.bridgeERC20To(address(dummyYieldToken), remoteToken, bob, 1e18, 100_000, bytes(""));
    }

    function test_bridgeYield() public {
        defaultSetup();

        yieldBoosterBridge.initializePair(address(dummyYieldToken), remoteToken, address(priceOracle), remoteYieldDistributor);

        // Alice bridges the DummyYieldToken
        hoax(alice);
        dummyYieldToken.approve(address(yieldBoosterBridge), 1e18);

        vm.expectCall(address(dummyYieldToken), abi.encodeWithSelector(IERC20.transferFrom.selector, alice, address(yieldBoosterBridge), 1e18));
        vm.expectEmit(true, true, true, true, address(yieldBoosterBridge));
        emit ERC20BridgeInitiated(address(dummyYieldToken), remoteToken, alice, bob, 1e18, bytes(""));

        vm.prank(alice);
        yieldBoosterBridge.bridgeERC20To(address(dummyYieldToken), remoteToken, bob, 1e18, 100_000, bytes(""));

        dummyYieldToken.setPricePerShare(101e16);

        vm.expectEmit(true, true, true, true, address(yieldBoosterBridge));
        emit ERC20BridgeInitiated(address(dummyYieldToken), remoteToken, address(yieldBoosterBridge), remoteYieldDistributor, 1e16, bytes(""));

        vm.prank(alice);
        yieldBoosterBridge.bridgeYield(address(dummyYieldToken), remoteToken, 100_000);
    }

    function test_finalizeBridgeERC20() public {
        defaultSetup();

        yieldBoosterBridge.initializePair(address(dummyYieldToken), remoteToken, address(priceOracle), remoteYieldDistributor);

        hoax(alice);
        dummyYieldToken.approve(address(yieldBoosterBridge), 1e18);

        vm.prank(alice);
        yieldBoosterBridge.bridgeERC20To(address(dummyYieldToken), remoteToken, bob, 1e18, 100_000, bytes(""));

        dummyYieldToken.setPricePerShare(101e16);

        bytes memory finalizeBridgeERC20Data = abi.encodeWithSelector(YieldBoosterBridge.finalizeBridgeERC20.selector, address(dummyYieldToken), address(remoteToken), address(alice), address(bob), uint256(1000), bytes(""));

        bytes memory relayTransactionData = abi.encodeWithSelector(CrossDomainMessenger.relayMessage.selector, uint256(0), address(remoteBridge), address(yieldBoosterBridge), uint256(0), uint256(100_000), finalizeBridgeERC20Data);

        Types.WithdrawalTransaction memory _tx = Types.WithdrawalTransaction({ nonce: 0, sender: Predeploys.L2_CROSS_DOMAIN_MESSENGER, target: address(messenger), value: 0, gasLimit: 100_000, data: relayTransactionData });
        bytes32 _withdrawalHash = proveWithdrawalTransaction(_tx);

        vm.warp(block.timestamp + oracle.FINALIZATION_PERIOD_SECONDS() + 1);
        vm.expectCall(address(dummyYieldToken), abi.encodeWithSelector(IERC20.transfer.selector, address(bob), 990));
        fraxchainPortal.finalizeWithdrawalTransaction(_tx);
    }

    event ERC20BridgeInitiated(address indexed localToken, address indexed remoteToken, address indexed from, address to, uint256 amount, bytes extraData);
}

contract MyYieldBoosterBridge is YieldBoosterBridge {
    constructor(CrossDomainMessenger _messenger, YieldBoosterBridge _portal) YieldBoosterBridge(_portal) {
        messenger = _messenger;
    }
}
