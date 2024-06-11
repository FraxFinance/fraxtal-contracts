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
const setup_1 = require("../utils/setup");
const execution_1 = require("../../src/utils/execution");
const multisend_1 = require("../../src/utils/multisend");
const units_1 = require("@ethersproject/units");
describe("MultiSendCallOnly", async () => {
    const [user1, user2] = hardhat_1.waffle.provider.getWallets();
    const setupTests = hardhat_1.deployments.createFixture(async ({ deployments }) => {
        await deployments.fixture();
        const setterSource = `
            contract StorageSetter {
                function setStorage(bytes3 data) public {
                    bytes32 slot = 0x4242424242424242424242424242424242424242424242424242424242424242;
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        sstore(slot, data)
                    }
                }
            }`;
        const storageSetter = await (0, setup_1.deployContract)(user1, setterSource);
        return {
            safe: await (0, setup_1.getSafeWithOwners)([user1.address]),
            multiSend: await (0, setup_1.getMultiSendCallOnly)(),
            mock: await (0, setup_1.getMock)(),
            storageSetter,
        };
    });
    describe("multiSend", async () => {
        it("Should fail when using invalid operation", async () => {
            const { safe, multiSend } = await setupTests();
            const txs = [(0, execution_1.buildSafeTransaction)({ to: user2.address, operation: 2, nonce: 0 })];
            const safeTx = (0, multisend_1.buildMultiSendSafeTx)(multiSend, txs, await safe.nonce());
            await (0, chai_1.expect)((0, execution_1.executeTx)(safe, safeTx, [await (0, execution_1.safeApproveHash)(user1, safe, safeTx, true)])).to.revertedWith("GS013");
        });
        it("Should fail when using delegatecall operation", async () => {
            const { safe, multiSend } = await setupTests();
            const txs = [(0, execution_1.buildSafeTransaction)({ to: user2.address, operation: 1, nonce: 0 })];
            const safeTx = (0, multisend_1.buildMultiSendSafeTx)(multiSend, txs, await safe.nonce());
            await (0, chai_1.expect)((0, execution_1.executeTx)(safe, safeTx, [await (0, execution_1.safeApproveHash)(user1, safe, safeTx, true)])).to.revertedWith("GS013");
        });
        it("Can execute empty multisend", async () => {
            const { safe, multiSend } = await setupTests();
            const txs = [];
            const safeTx = (0, multisend_1.buildMultiSendSafeTx)(multiSend, txs, await safe.nonce());
            await (0, chai_1.expect)((0, execution_1.executeTx)(safe, safeTx, [await (0, execution_1.safeApproveHash)(user1, safe, safeTx, true)])).to.emit(safe, "ExecutionSuccess");
        });
        it("Can execute single ether transfer", async () => {
            const { safe, multiSend } = await setupTests();
            await user1.sendTransaction({ to: safe.address, value: (0, units_1.parseEther)("1") });
            const userBalance = await hardhat_1.default.ethers.provider.getBalance(user2.address);
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getBalance(safe.address)).to.be.deep.eq((0, units_1.parseEther)("1"));
            const txs = [(0, execution_1.buildSafeTransaction)({ to: user2.address, value: (0, units_1.parseEther)("1"), nonce: 0 })];
            const safeTx = (0, multisend_1.buildMultiSendSafeTx)(multiSend, txs, await safe.nonce());
            await (0, chai_1.expect)((0, execution_1.executeTx)(safe, safeTx, [await (0, execution_1.safeApproveHash)(user1, safe, safeTx, true)])).to.emit(safe, "ExecutionSuccess");
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getBalance(safe.address)).to.be.deep.eq((0, units_1.parseEther)("0"));
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getBalance(user2.address)).to.be.deep.eq(userBalance.add((0, units_1.parseEther)("1")));
        });
        it("reverts all tx if any fails", async () => {
            const { safe, multiSend } = await setupTests();
            await user1.sendTransaction({ to: safe.address, value: (0, units_1.parseEther)("1") });
            const userBalance = await hardhat_1.default.ethers.provider.getBalance(user2.address);
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getBalance(safe.address)).to.be.deep.eq((0, units_1.parseEther)("1"));
            const txs = [
                (0, execution_1.buildSafeTransaction)({ to: user2.address, value: (0, units_1.parseEther)("1"), nonce: 0 }),
                (0, execution_1.buildSafeTransaction)({ to: user2.address, value: (0, units_1.parseEther)("1"), nonce: 0 }),
            ];
            const safeTx = (0, multisend_1.buildMultiSendSafeTx)(multiSend, txs, await safe.nonce(), { safeTxGas: 1 });
            await (0, chai_1.expect)((0, execution_1.executeTx)(safe, safeTx, [await (0, execution_1.safeApproveHash)(user1, safe, safeTx, true)])).to.emit(safe, "ExecutionFailure");
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getBalance(safe.address)).to.be.deep.eq((0, units_1.parseEther)("1"));
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getBalance(user2.address)).to.be.deep.eq(userBalance);
        });
        it("can be used when ETH is sent with execution", async () => {
            const { safe, multiSend, storageSetter } = await setupTests();
            const txs = [(0, execution_1.buildContractCall)(storageSetter, "setStorage", ["0xbaddad"], 0)];
            const safeTx = (0, multisend_1.buildMultiSendSafeTx)(multiSend, txs, await safe.nonce());
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getBalance(safe.address)).to.be.deep.eq((0, units_1.parseEther)("0"));
            await (0, chai_1.expect)((0, execution_1.executeTx)(safe, safeTx, [await (0, execution_1.safeApproveHash)(user1, safe, safeTx, true)], { value: (0, units_1.parseEther)("1") })).to.emit(safe, "ExecutionSuccess");
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getBalance(safe.address)).to.be.deep.eq((0, units_1.parseEther)("1"));
        });
        it("can execute contract calls", async () => {
            const { safe, multiSend, storageSetter } = await setupTests();
            const txs = [(0, execution_1.buildContractCall)(storageSetter, "setStorage", ["0xbaddad"], 0)];
            const safeTx = (0, multisend_1.buildMultiSendSafeTx)(multiSend, txs, await safe.nonce());
            await (0, chai_1.expect)((0, execution_1.executeTx)(safe, safeTx, [await (0, execution_1.safeApproveHash)(user1, safe, safeTx, true)])).to.emit(safe, "ExecutionSuccess");
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getStorageAt(safe.address, "0x4242424242424242424242424242424242424242424242424242424242424242")).to.be.eq("0x" + "".padEnd(64, "0"));
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getStorageAt(storageSetter.address, "0x4242424242424242424242424242424242424242424242424242424242424242")).to.be.eq("0x" + "baddad".padEnd(64, "0"));
        });
        it("can execute combinations", async () => {
            const { safe, multiSend, storageSetter } = await setupTests();
            await user1.sendTransaction({ to: safe.address, value: (0, units_1.parseEther)("1") });
            const userBalance = await hardhat_1.default.ethers.provider.getBalance(user2.address);
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getBalance(safe.address)).to.be.deep.eq((0, units_1.parseEther)("1"));
            const txs = [
                (0, execution_1.buildSafeTransaction)({ to: user2.address, value: (0, units_1.parseEther)("1"), nonce: 0 }),
                (0, execution_1.buildContractCall)(storageSetter, "setStorage", ["0xbaddad"], 0),
            ];
            const safeTx = (0, multisend_1.buildMultiSendSafeTx)(multiSend, txs, await safe.nonce());
            await (0, chai_1.expect)((0, execution_1.executeTx)(safe, safeTx, [await (0, execution_1.safeApproveHash)(user1, safe, safeTx, true)])).to.emit(safe, "ExecutionSuccess");
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getBalance(safe.address)).to.be.deep.eq((0, units_1.parseEther)("0"));
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getBalance(user2.address)).to.be.deep.eq(userBalance.add((0, units_1.parseEther)("1")));
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getStorageAt(safe.address, "0x4242424242424242424242424242424242424242424242424242424242424242")).to.be.eq("0x" + "".padEnd(64, "0"));
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getStorageAt(storageSetter.address, "0x4242424242424242424242424242424242424242424242424242424242424242")).to.be.eq("0x" + "baddad".padEnd(64, "0"));
        });
    });
});
