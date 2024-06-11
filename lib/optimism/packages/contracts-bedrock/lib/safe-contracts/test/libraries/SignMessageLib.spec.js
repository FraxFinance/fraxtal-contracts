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
const encoding_1 = require("../utils/encoding");
describe("SignMessageLib", async () => {
    const [user1, user2] = hardhat_1.waffle.provider.getWallets();
    const setupTests = hardhat_1.deployments.createFixture(async ({ deployments }) => {
        await deployments.fixture();
        const lib = await (await hardhat_1.default.ethers.getContractFactory("SignMessageLib")).deploy();
        return {
            safe: await (0, setup_1.getSafeWithOwners)([user1.address, user2.address]),
            lib,
        };
    });
    describe("signMessage", async () => {
        it("can only if msg.sender provides domain separator", async () => {
            const { lib } = await setupTests();
            await (0, chai_1.expect)(lib.signMessage("0xbaddad")).to.be.reverted;
        });
        it("should emit event", async () => {
            const { safe, lib } = await setupTests();
            // Required to check that the event was emitted from the right address
            const libSafe = lib.attach(safe.address);
            const messageHash = (0, execution_1.calculateSafeMessageHash)(safe, "0xbaddad", await (0, encoding_1.chainId)());
            (0, chai_1.expect)(await safe.signedMessages(messageHash)).to.be.eq(0);
            await (0, chai_1.expect)((0, execution_1.executeContractCallWithSigners)(safe, lib, "signMessage", ["0xbaddad"], [user1, user2], true))
                .to.emit(libSafe, "SignMsg")
                .withArgs(messageHash);
            (0, chai_1.expect)(await safe.signedMessages(messageHash)).to.be.eq(1);
        });
        it("can be used only via DELEGATECALL opcode", async () => {
            const { lib } = await setupTests();
            (0, chai_1.expect)(lib.signMessage("0xbaddad")).to.revertedWith("function selector was not recognized and there's no fallback function");
        });
        it("changes the expected storage slot without touching the most important ones", async () => {
            const { safe, lib } = await setupTests();
            const SIGNED_MESSAGES_MAPPING_STORAGE_SLOT = 7;
            const message = "no rugpull, funds must be safu";
            const eip191MessageHash = hardhat_1.default.ethers.utils.hashMessage(message);
            const safeInternalMsgHash = (0, execution_1.calculateSafeMessageHash)(safe, hardhat_1.default.ethers.utils.hashMessage(message), await (0, encoding_1.chainId)());
            const expectedStorageSlot = hardhat_1.default.ethers.utils.keccak256(hardhat_1.default.ethers.utils.defaultAbiCoder.encode(["bytes32", "uint256"], [safeInternalMsgHash, SIGNED_MESSAGES_MAPPING_STORAGE_SLOT]));
            const masterCopyAddressBeforeSigning = await hardhat_1.default.ethers.provider.getStorageAt(safe.address, 0);
            const ownerCountBeforeSigning = await hardhat_1.default.ethers.provider.getStorageAt(safe.address, 3);
            const thresholdBeforeSigning = await hardhat_1.default.ethers.provider.getStorageAt(safe.address, 4);
            const nonceBeforeSigning = await hardhat_1.default.ethers.provider.getStorageAt(safe.address, 5);
            const msgStorageSlotBeforeSigning = await hardhat_1.default.ethers.provider.getStorageAt(safe.address, expectedStorageSlot);
            (0, chai_1.expect)(nonceBeforeSigning).to.be.eq(`0x${"0".padStart(64, "0")}`);
            (0, chai_1.expect)(await safe.signedMessages(safeInternalMsgHash)).to.be.eq(0);
            (0, chai_1.expect)(msgStorageSlotBeforeSigning).to.be.eq(`0x${"0".padStart(64, "0")}`);
            await (0, execution_1.executeContractCallWithSigners)(safe, lib, "signMessage", [eip191MessageHash], [user1, user2], true);
            const masterCopyAddressAfterSigning = await hardhat_1.default.ethers.provider.getStorageAt(safe.address, 0);
            const ownerCountAfterSigning = await hardhat_1.default.ethers.provider.getStorageAt(safe.address, 3);
            const thresholdAfterSigning = await hardhat_1.default.ethers.provider.getStorageAt(safe.address, 4);
            const nonceAfterSigning = await hardhat_1.default.ethers.provider.getStorageAt(safe.address, 5);
            const msgStorageSlotAfterSigning = await hardhat_1.default.ethers.provider.getStorageAt(safe.address, expectedStorageSlot);
            (0, chai_1.expect)(await safe.signedMessages(safeInternalMsgHash)).to.be.eq(1);
            (0, chai_1.expect)(masterCopyAddressBeforeSigning).to.be.eq(masterCopyAddressAfterSigning);
            (0, chai_1.expect)(thresholdBeforeSigning).to.be.eq(thresholdAfterSigning);
            (0, chai_1.expect)(ownerCountBeforeSigning).to.be.eq(ownerCountAfterSigning);
            (0, chai_1.expect)(nonceAfterSigning).to.be.eq(`0x${"1".padStart(64, "0")}`);
            (0, chai_1.expect)(msgStorageSlotAfterSigning).to.be.eq(`0x${"1".padStart(64, "0")}`);
        });
    });
});
