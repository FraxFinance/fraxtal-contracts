"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    Object.defineProperty(o, k2, { enumerable: true, get: function() { return m[k]; } });
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
const chai_1 = require("chai");
const hardhat_1 = __importStar(require("hardhat"));
require("@nomiclabs/hardhat-ethers");
const constants_1 = require("@ethersproject/constants");
const setup_1 = require("../utils/setup");
const execution_1 = require("../../src/utils/execution");
const constants_2 = require("../../src/utils/constants");
describe("DelegateCallTransactionGuard", async () => {
    const [user1] = hardhat_1.waffle.provider.getWallets();
    const setupTests = hardhat_1.deployments.createFixture(async ({ deployments }) => {
        await deployments.fixture();
        const safe = await (0, setup_1.getSafeWithOwners)([user1.address]);
        const guardFactory = await hardhat_1.default.ethers.getContractFactory("DelegateCallTransactionGuard");
        const guard = await guardFactory.deploy(constants_1.AddressZero);
        await (0, execution_1.executeContractCallWithSigners)(safe, safe, "setGuard", [guard.address], [user1]);
        return {
            safe,
            guardFactory,
            guard,
        };
    });
    describe("fallback", async () => {
        it("must NOT revert on fallback without value", async () => {
            const { guard } = await setupTests();
            await user1.sendTransaction({
                to: guard.address,
                data: "0xbaddad",
            });
        });
        it("should revert on fallback with value", async () => {
            const { guard } = await setupTests();
            await (0, chai_1.expect)(user1.sendTransaction({
                to: guard.address,
                data: "0xbaddad",
                value: 1,
            })).to.be.reverted;
        });
    });
    describe("checkTransaction", async () => {
        it("should revert delegate call", async () => {
            const { safe, guard } = await setupTests();
            const tx = (0, execution_1.buildContractCall)(safe, "setGuard", [constants_1.AddressZero], 0, true);
            await (0, chai_1.expect)(guard.checkTransaction(tx.to, tx.value, tx.data, tx.operation, tx.safeTxGas, tx.baseGas, tx.gasPrice, tx.gasToken, tx.refundReceiver, "0x", user1.address)).to.be.revertedWith("This call is restricted");
        });
        it("must NOT revert normal call", async () => {
            const { safe, guard } = await setupTests();
            const tx = (0, execution_1.buildContractCall)(safe, "setGuard", [constants_1.AddressZero], 0);
            await guard.checkTransaction(tx.to, tx.value, tx.data, tx.operation, tx.safeTxGas, tx.baseGas, tx.gasPrice, tx.gasToken, tx.refundReceiver, "0x", user1.address);
        });
        it("should revert on delegate call via Safe", async () => {
            const { safe } = await setupTests();
            await (0, chai_1.expect)((0, execution_1.executeContractCallWithSigners)(safe, safe, "setGuard", [constants_1.AddressZero], [user1], true)).to.be.revertedWith("This call is restricted");
            await (0, execution_1.executeContractCallWithSigners)(safe, safe, "setGuard", [constants_1.AddressZero], [user1]);
        });
        it("can set allowed target via Safe", async () => {
            const { safe, guardFactory } = await setupTests();
            const guard = await guardFactory.deploy(constants_2.AddressOne);
            await (0, execution_1.executeContractCallWithSigners)(safe, safe, "setGuard", [guard.address], [user1]);
            (0, chai_1.expect)(await guard.allowedTarget()).to.be.eq(constants_2.AddressOne);
            const allowedTarget = safe.attach(constants_2.AddressOne);
            await (0, chai_1.expect)((0, execution_1.executeContractCallWithSigners)(safe, safe, "setFallbackHandler", [constants_1.AddressZero], [user1], true)).to.be.revertedWith("This call is restricted");
            await (0, execution_1.executeContractCallWithSigners)(safe, allowedTarget, "setFallbackHandler", [constants_1.AddressZero], [user1], true);
        });
    });
});
