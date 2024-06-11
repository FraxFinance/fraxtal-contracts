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
exports.verificationTests = void 0;
const ethers_1 = require("ethers");
const units_1 = require("@ethersproject/units");
const chai_1 = require("chai");
const hardhat_1 = __importStar(require("hardhat"));
const constants_1 = require("../../src/utils/constants");
const execution_1 = require("../../src/utils/execution");
const multisend_1 = require("../../src/utils/multisend");
const verificationTests = (setupTests) => {
    const [user1, user2, user3] = hardhat_1.waffle.provider.getWallets();
    describe("execTransaction", async () => {
        it("should be able to transfer ETH", async () => {
            const { migratedSafe } = await setupTests();
            await user1.sendTransaction({ to: migratedSafe.address, value: (0, units_1.parseEther)("1") });
            const nonce = await migratedSafe.nonce();
            const tx = (0, execution_1.buildSafeTransaction)({ to: user2.address, value: (0, units_1.parseEther)("1"), nonce });
            const userBalance = await hardhat_1.ethers.provider.getBalance(user2.address);
            await (0, chai_1.expect)(await hardhat_1.ethers.provider.getBalance(migratedSafe.address)).to.be.deep.eq((0, units_1.parseEther)("1"));
            await (0, execution_1.executeTxWithSigners)(migratedSafe, tx, [user1]);
            await (0, chai_1.expect)(await hardhat_1.ethers.provider.getBalance(user2.address)).to.be.deep.eq(userBalance.add((0, units_1.parseEther)("1")));
            await (0, chai_1.expect)(await hardhat_1.ethers.provider.getBalance(migratedSafe.address)).to.be.deep.eq((0, units_1.parseEther)("0"));
        });
    });
    describe("addOwner", async () => {
        it("should add owner and change treshold", async () => {
            const { migratedSafe } = await setupTests();
            await (0, chai_1.expect)((0, execution_1.executeContractCallWithSigners)(migratedSafe, migratedSafe, "addOwnerWithThreshold", [user2.address, 2], [user1]))
                .to.emit(migratedSafe, "AddedOwner")
                .withArgs(user2.address)
                .and.to.emit(migratedSafe, "ChangedThreshold");
            await (0, chai_1.expect)(await migratedSafe.getThreshold()).to.be.deep.eq(ethers_1.BigNumber.from(2));
            await (0, chai_1.expect)(await migratedSafe.getOwners()).to.be.deep.equal([user2.address, user1.address]);
            await (0, chai_1.expect)((0, execution_1.executeContractCallWithSigners)(migratedSafe, migratedSafe, "addOwnerWithThreshold", [user3.address, 1], [user1, user2]))
                .to.emit(migratedSafe, "AddedOwner")
                .withArgs(user3.address)
                .and.to.emit(migratedSafe, "ChangedThreshold");
            await (0, chai_1.expect)(await migratedSafe.getThreshold()).to.be.deep.eq(ethers_1.BigNumber.from(1));
            await (0, chai_1.expect)(await migratedSafe.getOwners()).to.be.deep.equal([user3.address, user2.address, user1.address]);
            await (0, chai_1.expect)(await migratedSafe.isOwner(user1.address)).to.be.true;
            await (0, chai_1.expect)(await migratedSafe.isOwner(user2.address)).to.be.true;
            await (0, chai_1.expect)(await migratedSafe.isOwner(user3.address)).to.be.true;
        });
    });
    describe("enableModule", async () => {
        it("should enabled module and be able to use it", async () => {
            const { migratedSafe, mock } = await setupTests();
            await (0, chai_1.expect)((0, execution_1.executeContractCallWithSigners)(migratedSafe, migratedSafe, "enableModule", [user2.address], [user1]))
                .to.emit(migratedSafe, "EnabledModule")
                .withArgs(user2.address);
            await (0, chai_1.expect)(await migratedSafe.isModuleEnabled(user2.address)).to.be.true;
            await (0, chai_1.expect)(await migratedSafe.getModulesPaginated(constants_1.AddressOne, 10)).to.be.deep.equal([[user2.address], constants_1.AddressOne]);
            const user2Safe = migratedSafe.connect(user2);
            await (0, chai_1.expect)(user2Safe.execTransactionFromModule(mock.address, 0, "0xbaddad", 0))
                .to.emit(migratedSafe, "ExecutionFromModuleSuccess")
                .withArgs(user2.address);
            (0, chai_1.expect)(await mock.callStatic.invocationCountForCalldata("0xbaddad")).to.be.deep.equals(ethers_1.BigNumber.from(1));
        });
    });
    describe("multiSend", async () => {
        it("execute multisend via delegatecall", async () => {
            const { migratedSafe, mock, multiSend } = await setupTests();
            await user1.sendTransaction({ to: migratedSafe.address, value: (0, units_1.parseEther)("1") });
            const userBalance = await hardhat_1.default.ethers.provider.getBalance(user2.address);
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getBalance(migratedSafe.address)).to.be.deep.eq((0, units_1.parseEther)("1"));
            const txs = [
                (0, execution_1.buildSafeTransaction)({ to: user2.address, value: (0, units_1.parseEther)("1"), nonce: 0 }),
                (0, execution_1.buildSafeTransaction)({ to: mock.address, data: "0xbaddad", nonce: 0 }),
            ];
            const safeTx = (0, multisend_1.buildMultiSendSafeTx)(multiSend, txs, await migratedSafe.nonce());
            await (0, chai_1.expect)((0, execution_1.executeTxWithSigners)(migratedSafe, safeTx, [user1])).to.emit(migratedSafe, "ExecutionSuccess");
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getBalance(migratedSafe.address)).to.be.deep.eq((0, units_1.parseEther)("0"));
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getBalance(user2.address)).to.be.deep.eq(userBalance.add((0, units_1.parseEther)("1")));
            (0, chai_1.expect)(await mock.callStatic.invocationCountForCalldata("0xbaddad")).to.be.deep.equals(ethers_1.BigNumber.from(1));
        });
    });
    describe("fallbackHandler", async () => {
        it("should be correctly set", async () => {
            const { migratedSafe, mock } = await setupTests();
            // Check fallback handler
            await (0, chai_1.expect)(await hardhat_1.ethers.provider.getStorageAt(migratedSafe.address, "0x6c9a6c4a39284e37ed1cf53d337577d14212a4870fb976a4366c693b939918d5")).to.be.eq("0x" + mock.address.toLowerCase().slice(2).padStart(64, "0"));
        });
    });
};
exports.verificationTests = verificationTests;
