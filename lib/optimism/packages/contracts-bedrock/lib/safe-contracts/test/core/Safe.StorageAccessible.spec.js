"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const chai_1 = require("chai");
const hardhat_1 = require("hardhat");
require("@nomiclabs/hardhat-ethers");
const setup_1 = require("../utils/setup");
const ethers_1 = require("ethers");
const contracts_1 = require("../utils/contracts");
describe("StorageAccessible", async () => {
    const [user1, user2] = hardhat_1.waffle.provider.getWallets();
    const setupTests = hardhat_1.deployments.createFixture(async ({ deployments }) => {
        await deployments.fixture();
        const killLib = await (0, contracts_1.killLibContract)(user1);
        return {
            safe: await (0, setup_1.getSafeWithOwners)([user1.address, user2.address], 1),
            killLib,
        };
    });
    describe("getStorageAt", async () => {
        it("can read singleton", async () => {
            await setupTests();
            const singleton = await (0, setup_1.getSafeSingleton)();
            (0, chai_1.expect)(await singleton.getStorageAt(3, 2)).to.be.eq(ethers_1.utils.solidityPack(["uint256", "uint256"], [0, 1]));
        });
        it("can read instantiated Safe", async () => {
            const { safe } = await setupTests();
            const singleton = await (0, setup_1.getSafeSingleton)();
            // Read singleton address, empty slots for module and owner linked lists, owner count and threshold
            (0, chai_1.expect)(await safe.getStorageAt(0, 5)).to.be.eq(ethers_1.utils.solidityPack(["uint256", "uint256", "uint256", "uint256", "uint256"], [singleton.address, 0, 0, 2, 1]));
        });
    });
    describe("simulateAndRevert", async () => {
        it("should revert changes", async () => {
            const { safe, killLib } = await setupTests();
            await (0, chai_1.expect)(safe.callStatic.simulateAndRevert(killLib.address, killLib.interface.encodeFunctionData("killme"))).to.be.reverted;
        });
        it("should revert the revert with message", async () => {
            const { safe, killLib } = await setupTests();
            await (0, chai_1.expect)(safe.callStatic.simulateAndRevert(killLib.address, killLib.interface.encodeFunctionData("trever"))).to.be.reverted;
        });
        it("should return estimate in revert", async () => {
            const { safe, killLib } = await setupTests();
            await (0, chai_1.expect)(safe.callStatic.simulateAndRevert(killLib.address, killLib.interface.encodeFunctionData("estimate", [safe.address, "0x"]))).to.be.reverted;
        });
    });
});
