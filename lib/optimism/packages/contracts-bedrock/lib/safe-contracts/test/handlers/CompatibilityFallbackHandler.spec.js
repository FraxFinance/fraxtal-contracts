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
const execution_1 = require("./../../src/utils/execution");
const chai_1 = require("chai");
const hardhat_1 = __importStar(require("hardhat"));
require("@nomiclabs/hardhat-ethers");
const constants_1 = require("@ethersproject/constants");
const setup_1 = require("../utils/setup");
const execution_2 = require("../../src/utils/execution");
const encoding_1 = require("../utils/encoding");
const ethers_1 = require("ethers");
const contracts_1 = require("../utils/contracts");
describe("CompatibilityFallbackHandler", async () => {
    const [user1, user2] = hardhat_1.waffle.provider.getWallets();
    const setupTests = hardhat_1.deployments.createFixture(async ({ deployments }) => {
        await deployments.fixture();
        const signLib = await (await hardhat_1.default.ethers.getContractFactory("SignMessageLib")).deploy();
        const handler = await (0, setup_1.getCompatFallbackHandler)();
        const signerSafe = await (0, setup_1.getSafeWithOwners)([user1.address], 1, handler.address);
        const safe = await (0, setup_1.getSafeWithOwners)([user1.address, user2.address, signerSafe.address], 2, handler.address);
        const validator = (await (0, setup_1.compatFallbackHandlerContract)()).attach(safe.address);
        const killLib = await (0, contracts_1.killLibContract)(user1);
        return {
            safe,
            validator,
            handler,
            killLib,
            signLib,
            signerSafe,
        };
    });
    describe("ERC1155", async () => {
        it("to handle onERC1155Received", async () => {
            const { handler } = await setupTests();
            await (0, chai_1.expect)(await handler.callStatic.onERC1155Received(constants_1.AddressZero, constants_1.AddressZero, 0, 0, "0x")).to.be.eq("0xf23a6e61");
        });
        it("to handle onERC1155BatchReceived", async () => {
            const { handler } = await setupTests();
            await (0, chai_1.expect)(await handler.callStatic.onERC1155BatchReceived(constants_1.AddressZero, constants_1.AddressZero, [], [], "0x")).to.be.eq("0xbc197c81");
        });
    });
    describe("ERC721", async () => {
        it("to handle onERC721Received", async () => {
            const { handler } = await setupTests();
            await (0, chai_1.expect)(await handler.callStatic.onERC721Received(constants_1.AddressZero, constants_1.AddressZero, 0, "0x")).to.be.eq("0x150b7a02");
        });
    });
    describe("ERC777", async () => {
        it("to handle tokensReceived", async () => {
            const { handler } = await setupTests();
            await handler.callStatic.tokensReceived(constants_1.AddressZero, constants_1.AddressZero, constants_1.AddressZero, 0, "0x", "0x");
        });
    });
    describe("isValidSignature(bytes,bytes)", async () => {
        it("should revert if called directly", async () => {
            const { handler } = await setupTests();
            await (0, chai_1.expect)(handler.callStatic["isValidSignature(bytes,bytes)"]("0xbaddad", "0x")).to.be.revertedWith("function call to a non-contract account");
        });
        it("should revert if message was not signed", async () => {
            const { validator } = await setupTests();
            await (0, chai_1.expect)(validator.callStatic["isValidSignature(bytes,bytes)"]("0xbaddad", "0x")).to.be.revertedWith("Hash not approved");
        });
        it("should revert if signature is not valid", async () => {
            const { validator } = await setupTests();
            await (0, chai_1.expect)(validator.callStatic["isValidSignature(bytes,bytes)"]("0xbaddad", "0xdeaddeaddeaddead")).to.be.reverted;
        });
        it("should return magic value if message was signed", async () => {
            const { safe, validator, signLib } = await setupTests();
            await (0, execution_2.executeContractCallWithSigners)(safe, signLib, "signMessage", ["0xbaddad"], [user1, user2], true);
            (0, chai_1.expect)(await validator.callStatic["isValidSignature(bytes,bytes)"]("0xbaddad", "0x")).to.be.eq("0x20c13b0b");
        });
        it("should return magic value if enough owners signed and allow a mix different signature types", async () => {
            const { validator, signerSafe } = await setupTests();
            const sig1 = {
                signer: user1.address,
                data: await user1._signTypedData({ verifyingContract: validator.address, chainId: await (0, encoding_1.chainId)() }, execution_2.EIP712_SAFE_MESSAGE_TYPE, { message: "0xbaddad" }),
            };
            const sig2 = await (0, execution_2.signHash)(user2, (0, execution_2.calculateSafeMessageHash)(validator, "0xbaddad", await (0, encoding_1.chainId)()));
            const validatorPreImageMessage = (0, execution_2.preimageSafeMessageHash)(validator, "0xbaddad", await (0, encoding_1.chainId)());
            const signerSafeMessageHash = (0, execution_2.calculateSafeMessageHash)(signerSafe, validatorPreImageMessage, await (0, encoding_1.chainId)());
            const signerSafeOwnerSignature = await (0, execution_2.signHash)(user1, signerSafeMessageHash);
            const signerSafeSig = (0, execution_1.buildContractSignature)(signerSafe.address, signerSafeOwnerSignature.data);
            (0, chai_1.expect)(await validator.callStatic["isValidSignature(bytes,bytes)"]("0xbaddad", (0, execution_2.buildSignatureBytes)([sig1, sig2, signerSafeSig]))).to.be.eq("0x20c13b0b");
        });
    });
    describe("isValidSignature(bytes32,bytes)", async () => {
        it("should revert if called directly", async () => {
            const { handler } = await setupTests();
            const dataHash = hardhat_1.ethers.utils.keccak256("0xbaddad");
            await (0, chai_1.expect)(handler.callStatic["isValidSignature(bytes32,bytes)"](dataHash, "0x")).to.be.revertedWith("function call to a non-contract account");
        });
        it("should revert if message was not signed", async () => {
            const { validator } = await setupTests();
            const dataHash = hardhat_1.ethers.utils.keccak256("0xbaddad");
            await (0, chai_1.expect)(validator.callStatic["isValidSignature(bytes32,bytes)"](dataHash, "0x")).to.be.revertedWith("Hash not approved");
        });
        it("should revert if signature is not valid", async () => {
            const { validator } = await setupTests();
            const dataHash = hardhat_1.ethers.utils.keccak256("0xbaddad");
            await (0, chai_1.expect)(validator.callStatic["isValidSignature(bytes32,bytes)"](dataHash, "0xdeaddeaddeaddead")).to.be.reverted;
        });
        it("should return magic value if message was signed", async () => {
            const { safe, validator, signLib } = await setupTests();
            const dataHash = hardhat_1.ethers.utils.keccak256("0xbaddad");
            await (0, execution_2.executeContractCallWithSigners)(safe, signLib, "signMessage", [dataHash], [user1, user2], true);
            (0, chai_1.expect)(await validator.callStatic["isValidSignature(bytes32,bytes)"](dataHash, "0x")).to.be.eq("0x1626ba7e");
        });
        it("should return magic value if enough owners signed and allow a mix different signature types", async () => {
            const { validator, signerSafe } = await setupTests();
            const dataHash = hardhat_1.ethers.utils.keccak256("0xbaddad");
            const typedDataSig = {
                signer: user1.address,
                data: await user1._signTypedData({ verifyingContract: validator.address, chainId: await (0, encoding_1.chainId)() }, execution_2.EIP712_SAFE_MESSAGE_TYPE, { message: dataHash }),
            };
            const ethSignSig = await (0, execution_2.signHash)(user2, (0, execution_2.calculateSafeMessageHash)(validator, dataHash, await (0, encoding_1.chainId)()));
            const validatorPreImageMessage = (0, execution_2.preimageSafeMessageHash)(validator, dataHash, await (0, encoding_1.chainId)());
            const signerSafeMessageHash = (0, execution_2.calculateSafeMessageHash)(signerSafe, validatorPreImageMessage, await (0, encoding_1.chainId)());
            const signerSafeOwnerSignature = await (0, execution_2.signHash)(user1, signerSafeMessageHash);
            const signerSafeSig = (0, execution_1.buildContractSignature)(signerSafe.address, signerSafeOwnerSignature.data);
            (0, chai_1.expect)(await validator.callStatic["isValidSignature(bytes32,bytes)"](dataHash, (0, execution_2.buildSignatureBytes)([typedDataSig, ethSignSig, signerSafeSig]))).to.be.eq("0x1626ba7e");
        });
    });
    describe("getModules", async () => {
        it("returns enabled modules", async () => {
            const { safe, validator } = await setupTests();
            await (0, chai_1.expect)((0, execution_2.executeContractCallWithSigners)(safe, safe, "enableModule", [user2.address], [user1, user2]))
                .to.emit(safe, "EnabledModule")
                .withArgs(user2.address);
            await (0, chai_1.expect)(await safe.isModuleEnabled(user2.address)).to.be.true;
            await (0, chai_1.expect)(await validator.getModules()).to.be.deep.equal([user2.address]);
        });
    });
    describe("getMessageHash", async () => {
        it("should generate the correct hash", async () => {
            const { safe, validator } = await setupTests();
            (0, chai_1.expect)(await validator.getMessageHash("0xdead")).to.be.eq((0, execution_2.calculateSafeMessageHash)(safe, "0xdead", await (0, encoding_1.chainId)()));
        });
    });
    describe("getMessageHashForSafe", async () => {
        it("should revert if target does not return domain separator", async () => {
            const { handler } = await setupTests();
            await (0, chai_1.expect)(handler.getMessageHashForSafe(handler.address, "0xdead")).to.be.reverted;
        });
        it("should generate the correct hash", async () => {
            const { handler, safe } = await setupTests();
            (0, chai_1.expect)(await handler.getMessageHashForSafe(safe.address, "0xdead")).to.be.eq((0, execution_2.calculateSafeMessageHash)(safe, "0xdead", await (0, encoding_1.chainId)()));
        });
    });
    describe("simulate", async () => {
        // eslint-disable-next-line @typescript-eslint/no-empty-function
        it.skip("can be called for any Safe", async () => { });
        it("should revert changes", async () => {
            const { validator, killLib } = await setupTests();
            const code = await hardhat_1.ethers.provider.getCode(validator.address);
            (0, chai_1.expect)(await validator.callStatic.simulate(killLib.address, killLib.interface.encodeFunctionData("killme"))).to.be.eq("0x");
            (0, chai_1.expect)(await hardhat_1.ethers.provider.getCode(validator.address)).to.be.eq(code);
        });
        it("should return result", async () => {
            const { validator, killLib, handler } = await setupTests();
            (0, chai_1.expect)(await validator.callStatic.simulate(killLib.address, killLib.interface.encodeFunctionData("expose"))).to.be.eq("0x000000000000000000000000" + handler.address.slice(2).toLowerCase());
        });
        it("should propagate revert message", async () => {
            const { validator, killLib } = await setupTests();
            await (0, chai_1.expect)(validator.callStatic.simulate(killLib.address, killLib.interface.encodeFunctionData("trever"))).to.revertedWith("Why are you doing this?");
        });
        it("should simulate transaction", async () => {
            const { validator, killLib } = await setupTests();
            const estimate = await validator.callStatic.simulate(killLib.address, killLib.interface.encodeFunctionData("estimate", [validator.address, "0x"]));
            (0, chai_1.expect)(ethers_1.BigNumber.from(estimate).toNumber()).to.be.lte(5000);
        });
        it("should return modified state", async () => {
            const { validator, killLib } = await setupTests();
            const value = await validator.callStatic.simulate(killLib.address, killLib.interface.encodeFunctionData("updateAndGet", []));
            (0, chai_1.expect)(ethers_1.BigNumber.from(value).toNumber()).to.be.eq(1);
            (0, chai_1.expect)((await killLib.value()).toNumber()).to.be.eq(0);
        });
    });
});
