"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const setup_1 = require("./../utils/setup");
const execution_1 = require("./../../src/utils/execution");
const chai_1 = require("chai");
const hardhat_1 = require("hardhat");
require("@nomiclabs/hardhat-ethers");
const constants_1 = require("@ethersproject/constants");
const crypto_1 = __importDefault(require("crypto"));
const setup_2 = require("../utils/setup");
const execution_2 = require("../../src/utils/execution");
const encoding_1 = require("../utils/encoding");
describe("Safe", async () => {
    const [user1, user2, user3, user4, user5] = hardhat_1.waffle.provider.getWallets();
    const setupTests = hardhat_1.deployments.createFixture(async ({ deployments }) => {
        await deployments.fixture();
        return {
            safe: await (0, setup_2.getSafeWithOwners)([user1.address]),
        };
    });
    describe("domainSeparator", async () => {
        it("should be correct according to EIP-712", async () => {
            const { safe } = await setupTests();
            const domainSeparator = (0, execution_2.calculateSafeDomainSeparator)(safe, await (0, encoding_1.chainId)());
            await (0, chai_1.expect)(await safe.domainSeparator()).to.be.eq(domainSeparator);
        });
    });
    describe("getTransactionHash", async () => {
        it("should correctly calculate EIP-712 hash", async () => {
            const { safe } = await setupTests();
            const tx = (0, execution_2.buildSafeTransaction)({ to: safe.address, nonce: await safe.nonce() });
            const typedDataHash = (0, execution_2.calculateSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            await (0, chai_1.expect)(await safe.getTransactionHash(tx.to, tx.value, tx.data, tx.operation, tx.safeTxGas, tx.baseGas, tx.gasPrice, tx.gasToken, tx.refundReceiver, tx.nonce)).to.be.eq(typedDataHash);
        });
    });
    describe("getChainId", async () => {
        it("should return correct id", async () => {
            const { safe } = await setupTests();
            (0, chai_1.expect)(await safe.getChainId()).to.be.eq(await (0, encoding_1.chainId)());
        });
    });
    describe("approveHash", async () => {
        it("approving should only be allowed for owners", async () => {
            const { safe } = await setupTests();
            const tx = (0, execution_2.buildSafeTransaction)({ to: safe.address, nonce: await safe.nonce() });
            const txHash = (0, execution_2.calculateSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            const signerSafe = safe.connect(user2);
            await (0, chai_1.expect)(signerSafe.approveHash(txHash)).to.be.revertedWith("GS030");
        });
        it("approving should emit event", async () => {
            const { safe } = await setupTests();
            const tx = (0, execution_2.buildSafeTransaction)({ to: safe.address, nonce: await safe.nonce() });
            const txHash = (0, execution_2.calculateSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            await (0, chai_1.expect)(safe.approveHash(txHash)).emit(safe, "ApproveHash").withArgs(txHash, user1.address);
        });
    });
    describe("execTransaction", async () => {
        it("should fail if signature points into static part", async () => {
            const { safe } = await setupTests();
            const signatures = "0x" +
                "000000000000000000000000" +
                user1.address.slice(2) +
                "0000000000000000000000000000000000000000000000000000000000000020" +
                "00" + // r, s, v
                "0000000000000000000000000000000000000000000000000000000000000000"; // Some data to read
            await (0, chai_1.expect)(safe.execTransaction(safe.address, 0, "0x", 0, 0, 0, 0, constants_1.AddressZero, constants_1.AddressZero, signatures)).to.be.revertedWith("GS021");
        });
        it("should fail if sigantures data is not present", async () => {
            const { safe } = await setupTests();
            const signatures = "0x" +
                "000000000000000000000000" +
                user1.address.slice(2) +
                "0000000000000000000000000000000000000000000000000000000000000041" +
                "00"; // r, s, v
            await (0, chai_1.expect)(safe.execTransaction(safe.address, 0, "0x", 0, 0, 0, 0, constants_1.AddressZero, constants_1.AddressZero, signatures)).to.be.revertedWith("GS022");
        });
        it("should fail if sigantures data is too short", async () => {
            const { safe } = await setupTests();
            const signatures = "0x" +
                "000000000000000000000000" +
                user1.address.slice(2) +
                "0000000000000000000000000000000000000000000000000000000000000041" +
                "00" + // r, s, v
                "0000000000000000000000000000000000000000000000000000000000000020"; // length
            await (0, chai_1.expect)(safe.execTransaction(safe.address, 0, "0x", 0, 0, 0, 0, constants_1.AddressZero, constants_1.AddressZero, signatures)).to.be.revertedWith("GS023");
        });
        it("should be able to use EIP-712 for signature generation", async () => {
            const { safe } = await setupTests();
            const tx = (0, execution_2.buildSafeTransaction)({ to: safe.address, nonce: await safe.nonce() });
            await (0, chai_1.expect)((0, execution_2.logGas)("Execute cancel transaction with EIP-712 signature", (0, execution_2.executeTx)(safe, tx, [await (0, execution_2.safeSignTypedData)(user1, safe, tx)]))).to.emit(safe, "ExecutionSuccess");
        });
        it("should not be able to use different chainId for signing", async () => {
            await setupTests();
            const safe = await (0, setup_2.getSafeWithOwners)([user1.address]);
            const tx = (0, execution_2.buildSafeTransaction)({ to: safe.address, nonce: await safe.nonce() });
            await (0, chai_1.expect)((0, execution_2.executeTx)(safe, tx, [await (0, execution_2.safeSignTypedData)(user1, safe, tx, 1)])).to.be.revertedWith("GS026");
        });
        it("should be able to use Signed Ethereum Messages for signature generation", async () => {
            const { safe } = await setupTests();
            const tx = (0, execution_2.buildSafeTransaction)({ to: safe.address, nonce: await safe.nonce() });
            await (0, chai_1.expect)((0, execution_2.logGas)("Execute cancel transaction with signed Ethereum message", (0, execution_2.executeTx)(safe, tx, [await (0, execution_2.safeSignMessage)(user1, safe, tx)]))).to.emit(safe, "ExecutionSuccess");
        });
        it("msg.sender does not need to approve before", async () => {
            const { safe } = await setupTests();
            const tx = (0, execution_2.buildSafeTransaction)({ to: safe.address, nonce: await safe.nonce() });
            await (0, chai_1.expect)((0, execution_2.logGas)("Without pre approved signature for msg.sender", (0, execution_2.executeTx)(safe, tx, [await (0, execution_2.safeApproveHash)(user1, safe, tx, true)]))).to.emit(safe, "ExecutionSuccess");
        });
        it("if not msg.sender on-chain approval is required", async () => {
            const { safe } = await setupTests();
            const user2Safe = safe.connect(user2);
            const tx = (0, execution_2.buildSafeTransaction)({ to: safe.address, nonce: await safe.nonce() });
            await (0, chai_1.expect)((0, execution_2.executeTx)(user2Safe, tx, [await (0, execution_2.safeApproveHash)(user1, safe, tx, true)])).to.be.revertedWith("GS025");
        });
        it("should be able to use pre approved hashes for signature generation", async () => {
            const { safe } = await setupTests();
            const user2Safe = safe.connect(user2);
            const tx = (0, execution_2.buildSafeTransaction)({ to: safe.address, nonce: await safe.nonce() });
            const txHash = (0, execution_2.calculateSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            const approveHashSig = await (0, execution_2.safeApproveHash)(user1, safe, tx);
            (0, chai_1.expect)(await safe.approvedHashes(user1.address, txHash)).to.be.eq(1);
            await (0, chai_1.expect)((0, execution_2.logGas)("With pre approved signature", (0, execution_2.executeTx)(user2Safe, tx, [approveHashSig]))).to.emit(safe, "ExecutionSuccess");
            // Approved hash should not reset automatically
            (0, chai_1.expect)(await safe.approvedHashes(user1.address, txHash)).to.be.eq(1);
        });
        it("should revert if threshold is not set", async () => {
            await setupTests();
            const safe = await (0, setup_2.getSafeTemplate)();
            const tx = (0, execution_2.buildSafeTransaction)({ to: safe.address, nonce: await safe.nonce() });
            await (0, chai_1.expect)((0, execution_2.executeTx)(safe, tx, [])).to.be.revertedWith("GS001");
        });
        it("should revert if not the required amount of signature data is provided", async () => {
            await setupTests();
            const safe = await (0, setup_2.getSafeWithOwners)([user1.address, user2.address, user3.address]);
            const tx = (0, execution_2.buildSafeTransaction)({ to: safe.address, nonce: await safe.nonce() });
            await (0, chai_1.expect)((0, execution_2.executeTx)(safe, tx, [])).to.be.revertedWith("GS020");
        });
        it("should not be able to use different signature type of same owner", async () => {
            await setupTests();
            const safe = await (0, setup_2.getSafeWithOwners)([user1.address, user2.address, user3.address]);
            const tx = (0, execution_2.buildSafeTransaction)({ to: safe.address, nonce: await safe.nonce() });
            await (0, chai_1.expect)((0, execution_2.executeTx)(safe, tx, [
                await (0, execution_2.safeApproveHash)(user1, safe, tx),
                await (0, execution_2.safeSignTypedData)(user1, safe, tx),
                await (0, execution_2.safeSignTypedData)(user3, safe, tx),
            ])).to.be.revertedWith("GS026");
        });
        it("should be able to mix all signature types", async () => {
            await setupTests();
            const compatFallbackHandler = await (0, setup_1.getCompatFallbackHandler)();
            const signerSafe = await (0, setup_2.getSafeWithOwners)([user5.address], 1, compatFallbackHandler.address);
            const safe = await (0, setup_2.getSafeWithOwners)([user1.address, user2.address, user3.address, user4.address, signerSafe.address]);
            const tx = (0, execution_2.buildSafeTransaction)({ to: safe.address, nonce: await safe.nonce() });
            const txHashData = (0, execution_2.preimageSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            // IMPORTANT: because the safe uses the old EIP-1271 interface which uses `bytes` instead of `bytes32` for the message
            // we need to use the pre-image of the transaction hash to calculate the message hash
            const safeMessageHash = (0, execution_1.calculateSafeMessageHash)(signerSafe, txHashData, await (0, encoding_1.chainId)());
            const signerSafeOwnerSignature = await (0, execution_1.signHash)(user5, safeMessageHash);
            const signerSafeSig = (0, execution_1.buildContractSignature)(signerSafe.address, signerSafeOwnerSignature.data);
            await (0, chai_1.expect)((0, execution_2.logGas)("Execute cancel transaction with 5 owners (1 owner is another Safe)", (0, execution_2.executeTx)(safe, tx, [
                await (0, execution_2.safeApproveHash)(user1, safe, tx, true),
                await (0, execution_2.safeApproveHash)(user4, safe, tx),
                await (0, execution_2.safeSignTypedData)(user2, safe, tx),
                await (0, execution_2.safeSignTypedData)(user3, safe, tx),
                signerSafeSig,
            ]))).to.emit(safe, "ExecutionSuccess");
        });
    });
    describe("checkSignatures", async () => {
        it("should fail if signature points into static part", async () => {
            const { safe } = await setupTests();
            const tx = (0, execution_2.buildSafeTransaction)({ to: safe.address, nonce: await safe.nonce() });
            const txHashData = (0, execution_2.preimageSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            const txHash = (0, execution_2.calculateSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            const signatures = "0x" +
                "000000000000000000000000" +
                user1.address.slice(2) +
                "0000000000000000000000000000000000000000000000000000000000000020" +
                "00" + // r, s, v
                "0000000000000000000000000000000000000000000000000000000000000000"; // Some data to read
            await (0, chai_1.expect)(safe.checkSignatures(txHash, txHashData, signatures)).to.be.revertedWith("GS021");
        });
        it("should fail if signatures data is not present", async () => {
            const { safe } = await setupTests();
            const tx = (0, execution_2.buildSafeTransaction)({ to: safe.address, nonce: await safe.nonce() });
            const txHashData = (0, execution_2.preimageSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            const txHash = (0, execution_2.calculateSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            const signatures = "0x" +
                "000000000000000000000000" +
                user1.address.slice(2) +
                "0000000000000000000000000000000000000000000000000000000000000041" +
                "00"; // r, s, v
            await (0, chai_1.expect)(safe.checkSignatures(txHash, txHashData, signatures)).to.be.revertedWith("GS022");
        });
        it("should fail if signatures data is too short", async () => {
            const { safe } = await setupTests();
            const tx = (0, execution_2.buildSafeTransaction)({ to: safe.address, nonce: await safe.nonce() });
            const txHashData = (0, execution_2.preimageSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            const txHash = (0, execution_2.calculateSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            const signatures = "0x" +
                "000000000000000000000000" +
                user1.address.slice(2) +
                "0000000000000000000000000000000000000000000000000000000000000041" +
                "00" + // r, s, v
                "0000000000000000000000000000000000000000000000000000000000000020"; // length
            await (0, chai_1.expect)(safe.checkSignatures(txHash, txHashData, signatures)).to.be.revertedWith("GS023");
        });
        it("should not be able to use different chainId for signing", async () => {
            await setupTests();
            const safe = await (0, setup_2.getSafeWithOwners)([user1.address]);
            const tx = (0, execution_2.buildSafeTransaction)({ to: safe.address, nonce: await safe.nonce() });
            const txHashData = (0, execution_2.preimageSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            const txHash = (0, execution_2.calculateSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            const signatures = (0, execution_2.buildSignatureBytes)([await (0, execution_2.safeSignTypedData)(user1, safe, tx, 1)]);
            await (0, chai_1.expect)(safe.checkSignatures(txHash, txHashData, signatures)).to.be.revertedWith("GS026");
        });
        it("if not msg.sender on-chain approval is required", async () => {
            const { safe } = await setupTests();
            const user2Safe = safe.connect(user2);
            const tx = (0, execution_2.buildSafeTransaction)({ to: safe.address, nonce: await safe.nonce() });
            const txHashData = (0, execution_2.preimageSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            const txHash = (0, execution_2.calculateSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            const signatures = (0, execution_2.buildSignatureBytes)([await (0, execution_2.safeApproveHash)(user1, safe, tx, true)]);
            await (0, chai_1.expect)(user2Safe.checkSignatures(txHash, txHashData, signatures)).to.be.revertedWith("GS025");
        });
        it("should revert if threshold is not set", async () => {
            await setupTests();
            const safe = await (0, setup_2.getSafeTemplate)();
            const tx = (0, execution_2.buildSafeTransaction)({ to: safe.address, nonce: await safe.nonce() });
            const txHashData = (0, execution_2.preimageSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            const txHash = (0, execution_2.calculateSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            await (0, chai_1.expect)(safe.checkSignatures(txHash, txHashData, "0x")).to.be.revertedWith("GS001");
        });
        it("should revert if not the required amount of signature data is provided", async () => {
            await setupTests();
            const safe = await (0, setup_2.getSafeWithOwners)([user1.address, user2.address, user3.address]);
            const tx = (0, execution_2.buildSafeTransaction)({ to: safe.address, nonce: await safe.nonce() });
            const txHashData = (0, execution_2.preimageSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            const txHash = (0, execution_2.calculateSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            await (0, chai_1.expect)(safe.checkSignatures(txHash, txHashData, "0x")).to.be.revertedWith("GS020");
        });
        it("should not be able to use different signature type of same owner", async () => {
            await setupTests();
            const safe = await (0, setup_2.getSafeWithOwners)([user1.address, user2.address, user3.address]);
            const tx = (0, execution_2.buildSafeTransaction)({ to: safe.address, nonce: await safe.nonce() });
            const txHashData = (0, execution_2.preimageSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            const txHash = (0, execution_2.calculateSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            const signatures = (0, execution_2.buildSignatureBytes)([
                await (0, execution_2.safeApproveHash)(user1, safe, tx),
                await (0, execution_2.safeSignTypedData)(user1, safe, tx),
                await (0, execution_2.safeSignTypedData)(user3, safe, tx),
            ]);
            await (0, chai_1.expect)(safe.checkSignatures(txHash, txHashData, signatures)).to.be.revertedWith("GS026");
        });
        it("should be able to mix all signature types", async () => {
            await setupTests();
            const compatFallbackHandler = await (0, setup_1.getCompatFallbackHandler)();
            const signerSafe = await (0, setup_2.getSafeWithOwners)([user5.address], 1, compatFallbackHandler.address);
            const safe = await (0, setup_2.getSafeWithOwners)([user1.address, user2.address, user3.address, user4.address, signerSafe.address]);
            const tx = (0, execution_2.buildSafeTransaction)({ to: safe.address, nonce: await safe.nonce() });
            const txHashData = (0, execution_2.preimageSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            const txHash = (0, execution_2.calculateSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            // IMPORTANT: because the safe uses the old EIP-1271 interface which uses `bytes` instead of `bytes32` for the message
            // we need to use the pre-image of the transaction hash to calculate the message hash
            const safeMessageHash = (0, execution_1.calculateSafeMessageHash)(signerSafe, txHashData, await (0, encoding_1.chainId)());
            const signerSafeOwnerSignature = await (0, execution_1.signHash)(user5, safeMessageHash);
            const signerSafeSig = (0, execution_1.buildContractSignature)(signerSafe.address, signerSafeOwnerSignature.data);
            const signatures = (0, execution_2.buildSignatureBytes)([
                await (0, execution_2.safeApproveHash)(user1, safe, tx, true),
                await (0, execution_2.safeApproveHash)(user4, safe, tx),
                await (0, execution_2.safeSignTypedData)(user2, safe, tx),
                await (0, execution_2.safeSignTypedData)(user3, safe, tx),
                signerSafeSig,
            ]);
            await safe.checkSignatures(txHash, txHashData, signatures);
        });
    });
    describe("checkSignatures", async () => {
        it("should fail if signature points into static part", async () => {
            const { safe } = await setupTests();
            const tx = (0, execution_2.buildSafeTransaction)({ to: safe.address, nonce: await safe.nonce() });
            const txHashData = (0, execution_2.preimageSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            const txHash = (0, execution_2.calculateSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            const signatures = "0x" +
                "000000000000000000000000" +
                user1.address.slice(2) +
                "0000000000000000000000000000000000000000000000000000000000000020" +
                "00" + // r, s, v
                "0000000000000000000000000000000000000000000000000000000000000000"; // Some data to read
            await (0, chai_1.expect)(safe.checkNSignatures(txHash, txHashData, signatures, 1)).to.be.revertedWith("GS021");
        });
        it("should fail if signatures data is not present", async () => {
            const { safe } = await setupTests();
            const tx = (0, execution_2.buildSafeTransaction)({ to: safe.address, nonce: await safe.nonce() });
            const txHashData = (0, execution_2.preimageSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            const txHash = (0, execution_2.calculateSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            const signatures = "0x" +
                "000000000000000000000000" +
                user1.address.slice(2) +
                "0000000000000000000000000000000000000000000000000000000000000041" +
                "00"; // r, s, v
            await (0, chai_1.expect)(safe.checkNSignatures(txHash, txHashData, signatures, 1)).to.be.revertedWith("GS022");
        });
        it("should fail if signatures data is too short", async () => {
            const { safe } = await setupTests();
            const tx = (0, execution_2.buildSafeTransaction)({ to: safe.address, nonce: await safe.nonce() });
            const txHashData = (0, execution_2.preimageSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            const txHash = (0, execution_2.calculateSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            const signatures = "0x" +
                "000000000000000000000000" +
                user1.address.slice(2) +
                "0000000000000000000000000000000000000000000000000000000000000041" +
                "00" + // r, s, v
                "0000000000000000000000000000000000000000000000000000000000000020"; // length
            await (0, chai_1.expect)(safe.checkNSignatures(txHash, txHashData, signatures, 1)).to.be.revertedWith("GS023");
        });
        it("should not be able to use different chainId for signing", async () => {
            await setupTests();
            const safe = await (0, setup_2.getSafeWithOwners)([user1.address]);
            const tx = (0, execution_2.buildSafeTransaction)({ to: safe.address, nonce: await safe.nonce() });
            const txHashData = (0, execution_2.preimageSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            const txHash = (0, execution_2.calculateSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            const signatures = (0, execution_2.buildSignatureBytes)([await (0, execution_2.safeSignTypedData)(user1, safe, tx, 1)]);
            await (0, chai_1.expect)(safe.checkNSignatures(txHash, txHashData, signatures, 1)).to.be.revertedWith("GS026");
        });
        it("if not msg.sender on-chain approval is required", async () => {
            const { safe } = await setupTests();
            const user2Safe = safe.connect(user2);
            const tx = (0, execution_2.buildSafeTransaction)({ to: safe.address, nonce: await safe.nonce() });
            const txHashData = (0, execution_2.preimageSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            const txHash = (0, execution_2.calculateSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            const signatures = (0, execution_2.buildSignatureBytes)([await (0, execution_2.safeApproveHash)(user1, safe, tx, true)]);
            await (0, chai_1.expect)(user2Safe.checkNSignatures(txHash, txHashData, signatures, 1)).to.be.revertedWith("GS025");
        });
        it("should revert if not the required amount of signature data is provided", async () => {
            await setupTests();
            const safe = await (0, setup_2.getSafeWithOwners)([user1.address, user2.address, user3.address]);
            const tx = (0, execution_2.buildSafeTransaction)({ to: safe.address, nonce: await safe.nonce() });
            const txHashData = (0, execution_2.preimageSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            const txHash = (0, execution_2.calculateSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            await (0, chai_1.expect)(safe.checkNSignatures(txHash, txHashData, "0x", 1)).to.be.revertedWith("GS020");
        });
        it("should not be able to use different signature type of same owner", async () => {
            await setupTests();
            const safe = await (0, setup_2.getSafeWithOwners)([user1.address, user2.address, user3.address]);
            const tx = (0, execution_2.buildSafeTransaction)({ to: safe.address, nonce: await safe.nonce() });
            const txHashData = (0, execution_2.preimageSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            const txHash = (0, execution_2.calculateSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            const signatures = (0, execution_2.buildSignatureBytes)([
                await (0, execution_2.safeApproveHash)(user1, safe, tx),
                await (0, execution_2.safeSignTypedData)(user1, safe, tx),
                await (0, execution_2.safeSignTypedData)(user3, safe, tx),
            ]);
            await (0, chai_1.expect)(safe.checkNSignatures(txHash, txHashData, signatures, 3)).to.be.revertedWith("GS026");
        });
        it("should be able to mix all signature types", async () => {
            await setupTests();
            const compatFallbackHandler = await (0, setup_1.getCompatFallbackHandler)();
            const signerSafe = await (0, setup_2.getSafeWithOwners)([user5.address], 1, compatFallbackHandler.address);
            const safe = await (0, setup_2.getSafeWithOwners)([user1.address, user2.address, user3.address, user4.address, signerSafe.address]);
            const tx = (0, execution_2.buildSafeTransaction)({ to: safe.address, nonce: await safe.nonce() });
            const txHashData = (0, execution_2.preimageSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            const txHash = (0, execution_2.calculateSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            // IMPORTANT: because the safe uses the old EIP-1271 interface which uses `bytes` instead of `bytes32` for the message
            // we need to use the pre-image of the transaction hash to calculate the message hash
            const safeMessageHash = (0, execution_1.calculateSafeMessageHash)(signerSafe, txHashData, await (0, encoding_1.chainId)());
            const signerSafeOwnerSignature = await (0, execution_1.signHash)(user5, safeMessageHash);
            const signerSafeSig = (0, execution_1.buildContractSignature)(signerSafe.address, signerSafeOwnerSignature.data);
            const signatures = (0, execution_2.buildSignatureBytes)([
                await (0, execution_2.safeApproveHash)(user1, safe, tx, true),
                await (0, execution_2.safeApproveHash)(user4, safe, tx),
                await (0, execution_2.safeSignTypedData)(user2, safe, tx),
                await (0, execution_2.safeSignTypedData)(user3, safe, tx),
                signerSafeSig,
            ]);
            await safe.checkNSignatures(txHash, txHashData, signatures, 5);
        });
        it("should be able to require no signatures", async () => {
            await setupTests();
            const safe = await (0, setup_2.getSafeTemplate)();
            const tx = (0, execution_2.buildSafeTransaction)({ to: safe.address, nonce: await safe.nonce() });
            const txHashData = (0, execution_2.preimageSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            const txHash = (0, execution_2.calculateSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            await safe.checkNSignatures(txHash, txHashData, "0x", 0);
        });
        it("should be able to require less signatures than the threshold", async () => {
            await setupTests();
            const safe = await (0, setup_2.getSafeWithOwners)([user1.address, user2.address, user3.address, user4.address]);
            const tx = (0, execution_2.buildSafeTransaction)({ to: safe.address, nonce: await safe.nonce() });
            const txHashData = (0, execution_2.preimageSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            const txHash = (0, execution_2.calculateSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            const signatures = (0, execution_2.buildSignatureBytes)([await (0, execution_2.safeSignTypedData)(user3, safe, tx)]);
            await safe.checkNSignatures(txHash, txHashData, signatures, 1);
        });
        it("should be able to require more signatures than the threshold", async () => {
            await setupTests();
            const safe = await (0, setup_2.getSafeWithOwners)([user1.address, user2.address, user3.address, user4.address], 2);
            const tx = (0, execution_2.buildSafeTransaction)({ to: safe.address, nonce: await safe.nonce() });
            const txHashData = (0, execution_2.preimageSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            const txHash = (0, execution_2.calculateSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)());
            const signatures = (0, execution_2.buildSignatureBytes)([
                await (0, execution_2.safeApproveHash)(user1, safe, tx, true),
                await (0, execution_2.safeApproveHash)(user4, safe, tx),
                await (0, execution_2.safeSignTypedData)(user2, safe, tx),
            ]);
            // Should fail as only 3 signatures are provided
            await (0, chai_1.expect)(safe.checkNSignatures(txHash, txHashData, signatures, 4)).to.be.revertedWith("GS020");
            await safe.checkNSignatures(txHash, txHashData, signatures, 3);
        });
        it("should revert if the hash of the pre-image data and dataHash do not match for EIP-1271 signature", async () => {
            await setupTests();
            const safe = await (0, setup_2.getSafeWithOwners)([user1.address, user2.address, user3.address, user4.address], 2);
            const randomHash = `0x${crypto_1.default.pseudoRandomBytes(32).toString("hex")}`;
            const randomBytes = `0x${crypto_1.default.pseudoRandomBytes(128).toString("hex")}`;
            const randomAddress = `0x${crypto_1.default.pseudoRandomBytes(20).toString("hex")}`;
            const randomSignature = `0x${crypto_1.default.pseudoRandomBytes(65).toString("hex")}`;
            const eip1271Sig = (0, execution_1.buildContractSignature)(randomAddress, randomSignature);
            const signatures = (0, execution_2.buildSignatureBytes)([eip1271Sig]);
            await (0, chai_1.expect)(safe.checkNSignatures(randomHash, randomBytes, signatures, 1)).to.be.revertedWith("GS027");
        });
    });
});
