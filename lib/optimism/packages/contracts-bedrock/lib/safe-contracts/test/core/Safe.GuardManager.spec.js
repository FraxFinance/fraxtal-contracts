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
const ethers_1 = require("ethers");
require("@nomiclabs/hardhat-ethers");
const constants_1 = require("@ethersproject/constants");
const setup_1 = require("../utils/setup");
const execution_1 = require("../../src/utils/execution");
const encoding_1 = require("../utils/encoding");
describe("GuardManager", async () => {
    const [user1, user2] = hardhat_1.waffle.provider.getWallets();
    const setupWithTemplate = hardhat_1.deployments.createFixture(async ({ deployments }) => {
        await deployments.fixture();
        const mock = await (0, setup_1.getMock)();
        const guardContract = await hardhat_1.default.ethers.getContractAt("Guard", constants_1.AddressZero);
        const guardEip165Calldata = guardContract.interface.encodeFunctionData("supportsInterface", ["0xe6d7a83a"]);
        await mock.givenCalldataReturnBool(guardEip165Calldata, true);
        const safe = await (0, setup_1.getSafeWithOwners)([user2.address]);
        await (0, execution_1.executeContractCallWithSigners)(safe, safe, "setGuard", [mock.address], [user2]);
        return {
            safe,
            mock,
            guardEip165Calldata,
        };
    });
    describe("setGuard", async () => {
        it("is not called when setting initially", async () => {
            const { safe, mock, guardEip165Calldata } = await setupWithTemplate();
            const slot = hardhat_1.ethers.utils.keccak256(hardhat_1.ethers.utils.toUtf8Bytes("guard_manager.guard.address"));
            await (0, execution_1.executeContractCallWithSigners)(safe, safe, "setGuard", [constants_1.AddressZero], [user2]);
            // Check guard
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getStorageAt(safe.address, slot)).to.be.eq("0x" + "".padStart(64, "0"));
            await mock.reset();
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getStorageAt(safe.address, slot)).to.be.eq("0x" + "".padStart(64, "0"));
            // Reverts if it doesn't implement ERC165 Guard Interface
            await (0, chai_1.expect)((0, execution_1.executeContractCallWithSigners)(safe, safe, "setGuard", [mock.address], [user2])).to.be.revertedWith("GS013");
            await mock.givenCalldataReturnBool(guardEip165Calldata, true);
            await (0, chai_1.expect)((0, execution_1.executeContractCallWithSigners)(safe, safe, "setGuard", [mock.address], [user2]))
                .to.emit(safe, "ChangedGuard")
                .withArgs(mock.address);
            // Check guard
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getStorageAt(safe.address, slot)).to.be.eq("0x" + mock.address.toLowerCase().slice(2).padStart(64, "0"));
            // Guard should not be called, as it was not set before the transaction execution
            (0, chai_1.expect)(await mock.callStatic.invocationCount()).to.be.eq(0);
        });
        it("is called when removed", async () => {
            const { safe, mock } = await setupWithTemplate();
            const slot = hardhat_1.ethers.utils.keccak256(hardhat_1.ethers.utils.toUtf8Bytes("guard_manager.guard.address"));
            // Check guard
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getStorageAt(safe.address, slot)).to.be.eq("0x" + mock.address.toLowerCase().slice(2).padStart(64, "0"));
            const safeTx = (0, execution_1.buildContractCall)(safe, "setGuard", [constants_1.AddressZero], await safe.nonce());
            const signature = await (0, execution_1.safeApproveHash)(user2, safe, safeTx);
            const signatureBytes = (0, execution_1.buildSignatureBytes)([signature]);
            await (0, chai_1.expect)((0, execution_1.executeTx)(safe, safeTx, [signature]))
                .to.emit(safe, "ChangedGuard")
                .withArgs(constants_1.AddressZero);
            // Check guard
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getStorageAt(safe.address, slot)).to.be.eq("0x" + "".padStart(64, "0"));
            (0, chai_1.expect)(await mock.callStatic.invocationCount()).to.be.eq(2);
            const guardInterface = (await hardhat_1.default.ethers.getContractAt("Guard", mock.address)).interface;
            const checkTxData = guardInterface.encodeFunctionData("checkTransaction", [
                safeTx.to,
                safeTx.value,
                safeTx.data,
                safeTx.operation,
                safeTx.safeTxGas,
                safeTx.baseGas,
                safeTx.gasPrice,
                safeTx.gasToken,
                safeTx.refundReceiver,
                signatureBytes,
                user1.address,
            ]);
            (0, chai_1.expect)(await mock.callStatic.invocationCountForCalldata(checkTxData)).to.be.eq(1);
            // Guard should also be called for post exec check, even if it is removed with the Safe tx
            const checkExecData = guardInterface.encodeFunctionData("checkAfterExecution", [
                (0, execution_1.calculateSafeTransactionHash)(safe, safeTx, await (0, encoding_1.chainId)()),
                true,
            ]);
            (0, chai_1.expect)(await mock.callStatic.invocationCountForCalldata(checkExecData)).to.be.eq(1);
        });
    });
    describe("execTransaction", async () => {
        it("reverts if the pre hook of the guard reverts", async () => {
            const { safe, mock } = await setupWithTemplate();
            const safeTx = (0, execution_1.buildSafeTransaction)({ to: mock.address, data: "0xbaddad42", nonce: 1 });
            const signature = await (0, execution_1.safeApproveHash)(user2, safe, safeTx);
            const signatureBytes = (0, execution_1.buildSignatureBytes)([signature]);
            const guardInterface = (await hardhat_1.default.ethers.getContractAt("Guard", mock.address)).interface;
            const checkTxData = guardInterface.encodeFunctionData("checkTransaction", [
                safeTx.to,
                safeTx.value,
                safeTx.data,
                safeTx.operation,
                safeTx.safeTxGas,
                safeTx.baseGas,
                safeTx.gasPrice,
                safeTx.gasToken,
                safeTx.refundReceiver,
                signatureBytes,
                user1.address,
            ]);
            await mock.givenCalldataRevertWithMessage(checkTxData, "Computer says Nah");
            const checkExecData = guardInterface.encodeFunctionData("checkAfterExecution", [
                (0, execution_1.calculateSafeTransactionHash)(safe, safeTx, await (0, encoding_1.chainId)()),
                true,
            ]);
            await (0, chai_1.expect)((0, execution_1.executeTx)(safe, safeTx, [signature])).to.be.revertedWith("Computer says Nah");
            await mock.reset();
            await (0, chai_1.expect)((0, execution_1.executeTx)(safe, safeTx, [signature])).to.emit(safe, "ExecutionSuccess");
            (0, chai_1.expect)(await mock.callStatic.invocationCount()).to.be.deep.equals(ethers_1.BigNumber.from(3));
            (0, chai_1.expect)(await mock.callStatic.invocationCountForCalldata(checkTxData)).to.be.deep.equals(ethers_1.BigNumber.from(1));
            (0, chai_1.expect)(await mock.callStatic.invocationCountForCalldata(checkExecData)).to.be.deep.equals(ethers_1.BigNumber.from(1));
            (0, chai_1.expect)(await mock.callStatic.invocationCountForCalldata("0xbaddad42")).to.be.deep.equals(ethers_1.BigNumber.from(1));
        });
        it("reverts if the post hook of the guard reverts", async () => {
            const { safe, mock } = await setupWithTemplate();
            const safeTx = (0, execution_1.buildSafeTransaction)({ to: mock.address, data: "0xbaddad42", nonce: 1 });
            const signature = await (0, execution_1.safeApproveHash)(user2, safe, safeTx);
            const signatureBytes = (0, execution_1.buildSignatureBytes)([signature]);
            const guardInterface = (await hardhat_1.default.ethers.getContractAt("Guard", mock.address)).interface;
            const checkTxData = guardInterface.encodeFunctionData("checkTransaction", [
                safeTx.to,
                safeTx.value,
                safeTx.data,
                safeTx.operation,
                safeTx.safeTxGas,
                safeTx.baseGas,
                safeTx.gasPrice,
                safeTx.gasToken,
                safeTx.refundReceiver,
                signatureBytes,
                user1.address,
            ]);
            const checkExecData = guardInterface.encodeFunctionData("checkAfterExecution", [
                (0, execution_1.calculateSafeTransactionHash)(safe, safeTx, await (0, encoding_1.chainId)()),
                true,
            ]);
            await mock.givenCalldataRevertWithMessage(checkExecData, "Computer says Nah");
            await (0, chai_1.expect)((0, execution_1.executeTx)(safe, safeTx, [signature])).to.be.revertedWith("Computer says Nah");
            await mock.reset();
            await (0, chai_1.expect)((0, execution_1.executeTx)(safe, safeTx, [signature])).to.emit(safe, "ExecutionSuccess");
            (0, chai_1.expect)(await mock.callStatic.invocationCount()).to.be.deep.equals(ethers_1.BigNumber.from(3));
            (0, chai_1.expect)(await mock.callStatic.invocationCountForCalldata(checkTxData)).to.be.deep.equals(ethers_1.BigNumber.from(1));
            (0, chai_1.expect)(await mock.callStatic.invocationCountForCalldata(checkExecData)).to.be.deep.equals(ethers_1.BigNumber.from(1));
            (0, chai_1.expect)(await mock.callStatic.invocationCountForCalldata("0xbaddad42")).to.be.deep.equals(ethers_1.BigNumber.from(1));
        });
    });
});
