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
const units_1 = require("@ethersproject/units");
const encoding_1 = require("../utils/encoding");
describe("Safe", async () => {
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
        const reverterSource = `
            contract Reverter {
                function revert() public {
                    require(false, "Shit happens");
                }
            }`;
        const reverter = await (0, setup_1.deployContract)(user1, reverterSource);
        return {
            safe: await (0, setup_1.getSafeWithOwners)([user1.address]),
            reverter,
            storageSetter,
        };
    });
    describe("execTransaction", async () => {
        it("should revert if too little gas is provided", async () => {
            const { safe } = await setupTests();
            const tx = (0, execution_1.buildSafeTransaction)({ to: safe.address, safeTxGas: 1000000, nonce: await safe.nonce() });
            const signatureBytes = (0, execution_1.buildSignatureBytes)([await (0, execution_1.safeApproveHash)(user1, safe, tx, true)]);
            await (0, chai_1.expect)(safe.execTransaction(tx.to, tx.value, tx.data, tx.operation, tx.safeTxGas, tx.baseGas, tx.gasPrice, tx.gasToken, tx.refundReceiver, signatureBytes, { gasLimit: 1000000 })).to.be.revertedWith("GS010");
        });
        it("should emit event for successful call execution", async () => {
            const { safe, storageSetter } = await setupTests();
            const txHash = (0, execution_1.calculateSafeTransactionHash)(safe, (0, execution_1.buildContractCall)(storageSetter, "setStorage", ["0xbaddad"], await safe.nonce()), await (0, encoding_1.chainId)());
            await (0, chai_1.expect)((0, execution_1.executeContractCallWithSigners)(safe, storageSetter, "setStorage", ["0xbaddad"], [user1]))
                .to.emit(safe, "ExecutionSuccess")
                .withArgs(txHash, 0);
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getStorageAt(safe.address, "0x4242424242424242424242424242424242424242424242424242424242424242")).to.be.eq("0x" + "".padEnd(64, "0"));
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getStorageAt(storageSetter.address, "0x4242424242424242424242424242424242424242424242424242424242424242")).to.be.eq("0x" + "baddad".padEnd(64, "0"));
        });
        it("should emit event for failed call execution if safeTxGas > 0", async () => {
            const { safe, reverter } = await setupTests();
            await (0, chai_1.expect)((0, execution_1.executeContractCallWithSigners)(safe, reverter, "revert", [], [user1], false, { safeTxGas: 1 })).to.emit(safe, "ExecutionFailure");
        });
        it("should emit event for failed call execution if gasPrice > 0", async () => {
            const { safe, reverter } = await setupTests();
            // Fund refund
            await user1.sendTransaction({ to: safe.address, value: 10000000 });
            await (0, chai_1.expect)((0, execution_1.executeContractCallWithSigners)(safe, reverter, "revert", [], [user1], false, { gasPrice: 1 })).to.emit(safe, "ExecutionFailure");
        });
        it("should revert for failed call execution if gasPrice == 0 and safeTxGas == 0", async () => {
            const { safe, reverter } = await setupTests();
            await (0, chai_1.expect)((0, execution_1.executeContractCallWithSigners)(safe, reverter, "revert", [], [user1])).to.revertedWith("GS013");
        });
        it("should emit event for successful delegatecall execution", async () => {
            const { safe, storageSetter } = await setupTests();
            await (0, chai_1.expect)((0, execution_1.executeContractCallWithSigners)(safe, storageSetter, "setStorage", ["0xbaddad"], [user1], true)).to.emit(safe, "ExecutionSuccess");
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getStorageAt(safe.address, "0x4242424242424242424242424242424242424242424242424242424242424242")).to.be.eq("0x" + "baddad".padEnd(64, "0"));
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getStorageAt(storageSetter.address, "0x4242424242424242424242424242424242424242424242424242424242424242")).to.be.eq("0x" + "".padEnd(64, "0"));
        });
        it("should emit event for failed delegatecall execution  if safeTxGas > 0", async () => {
            const { safe, reverter } = await setupTests();
            const txHash = (0, execution_1.calculateSafeTransactionHash)(safe, (0, execution_1.buildContractCall)(reverter, "revert", [], await safe.nonce(), true, { safeTxGas: 1 }), await (0, encoding_1.chainId)());
            await (0, chai_1.expect)((0, execution_1.executeContractCallWithSigners)(safe, reverter, "revert", [], [user1], true, { safeTxGas: 1 }))
                .to.emit(safe, "ExecutionFailure")
                .withArgs(txHash, 0);
        });
        it("should emit event for failed delegatecall execution if gasPrice > 0", async () => {
            const { safe, reverter } = await setupTests();
            await user1.sendTransaction({ to: safe.address, value: 10000000 });
            await (0, chai_1.expect)((0, execution_1.executeContractCallWithSigners)(safe, reverter, "revert", [], [user1], true, { gasPrice: 1 })).to.emit(safe, "ExecutionFailure");
        });
        it("should emit event for failed delegatecall execution if gasPrice == 0 and safeTxGas == 0", async () => {
            const { safe, reverter } = await setupTests();
            await (0, chai_1.expect)((0, execution_1.executeContractCallWithSigners)(safe, reverter, "revert", [], [user1], true)).to.revertedWith("GS013");
        });
        it("should revert on unknown operation", async () => {
            const { safe } = await setupTests();
            const tx = (0, execution_1.buildSafeTransaction)({ to: safe.address, nonce: await safe.nonce(), operation: 2 });
            await (0, chai_1.expect)((0, execution_1.executeTx)(safe, tx, [await (0, execution_1.safeApproveHash)(user1, safe, tx, true)])).to.be.reverted;
        });
        it("should emit payment in success event", async () => {
            const { safe } = await setupTests();
            const tx = (0, execution_1.buildSafeTransaction)({
                to: user1.address,
                nonce: await safe.nonce(),
                operation: 0,
                gasPrice: 1,
                safeTxGas: 100000,
                refundReceiver: user2.address,
            });
            await user1.sendTransaction({ to: safe.address, value: (0, units_1.parseEther)("1") });
            const userBalance = await hardhat_1.default.ethers.provider.getBalance(user2.address);
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getBalance(safe.address)).to.be.deep.eq((0, units_1.parseEther)("1"));
            let executedTx;
            await (0, chai_1.expect)((0, execution_1.executeTx)(safe, tx, [await (0, execution_1.safeApproveHash)(user1, safe, tx, true)]).then((tx) => {
                executedTx = tx;
                return tx;
            })).to.emit(safe, "ExecutionSuccess");
            const receipt = await hardhat_1.default.ethers.provider.getTransactionReceipt(executedTx.hash);
            const logIndex = receipt.logs.length - 1;
            const successEvent = safe.interface.decodeEventLog("ExecutionSuccess", receipt.logs[logIndex].data, receipt.logs[logIndex].topics);
            (0, chai_1.expect)(successEvent.txHash).to.be.eq((0, execution_1.calculateSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)()));
            // Gas costs are around 3000, so even if we specified a safeTxGas from 100000 we should not use more
            (0, chai_1.expect)(successEvent.payment.toNumber()).to.be.lte(5000);
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getBalance(user2.address)).to.be.deep.eq(userBalance.add(successEvent.payment));
        });
        it("should emit payment in failure event", async () => {
            const { safe, storageSetter } = await setupTests();
            const data = storageSetter.interface.encodeFunctionData("setStorage", [0xbaddad]);
            const tx = (0, execution_1.buildSafeTransaction)({
                to: storageSetter.address,
                data,
                nonce: await safe.nonce(),
                operation: 0,
                gasPrice: 1,
                safeTxGas: 3000,
                refundReceiver: user2.address,
            });
            await user1.sendTransaction({ to: safe.address, value: (0, units_1.parseEther)("1") });
            const userBalance = await hardhat_1.default.ethers.provider.getBalance(user2.address);
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getBalance(safe.address)).to.be.deep.eq((0, units_1.parseEther)("1"));
            let executedTx;
            await (0, chai_1.expect)((0, execution_1.executeTx)(safe, tx, [await (0, execution_1.safeApproveHash)(user1, safe, tx, true)]).then((tx) => {
                executedTx = tx;
                return tx;
            })).to.emit(safe, "ExecutionFailure");
            const receipt = await hardhat_1.default.ethers.provider.getTransactionReceipt(executedTx.hash);
            const logIndex = receipt.logs.length - 1;
            const successEvent = safe.interface.decodeEventLog("ExecutionFailure", receipt.logs[logIndex].data, receipt.logs[logIndex].topics);
            (0, chai_1.expect)(successEvent.txHash).to.be.eq((0, execution_1.calculateSafeTransactionHash)(safe, tx, await (0, encoding_1.chainId)()));
            // FIXME: When running out of gas the gas used is slightly higher than the safeTxGas and the user has to overpay
            (0, chai_1.expect)(successEvent.payment.toNumber()).to.be.lte(10000);
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getBalance(user2.address)).to.be.deep.eq(userBalance.add(successEvent.payment));
        });
        it("should be possible to manually increase gas", async () => {
            const { safe } = await setupTests();
            const gasUserSource = `
            contract GasUser {
        
                uint256[] public data;
        
                constructor() payable {}
        
                function nested(uint256 level, uint256 count) external {
                    if (level == 0) {
                        for (uint256 i = 0; i < count; i++) {
                            data.push(i);
                        }
                        return;
                    }
                    this.nested(level - 1, count);
                }
        
                function useGas(uint256 count) public {
                    this.nested(6, count);
                    this.nested(8, count);
                }
            }`;
            const gasUser = await (0, setup_1.deployContract)(user1, gasUserSource);
            const to = gasUser.address;
            const data = gasUser.interface.encodeFunctionData("useGas", [80]);
            const safeTxGas = 10000;
            const tx = (0, execution_1.buildSafeTransaction)({ to, data, safeTxGas, nonce: await safe.nonce() });
            await (0, chai_1.expect)((0, execution_1.executeTx)(safe, tx, [await (0, execution_1.safeApproveHash)(user1, safe, tx, true)], { gasLimit: 170000 }), "Safe transaction should fail with low gasLimit").to.emit(safe, "ExecutionFailure");
            await (0, chai_1.expect)((0, execution_1.executeTx)(safe, tx, [await (0, execution_1.safeApproveHash)(user1, safe, tx, true)], { gasLimit: 6000000 }), "Safe transaction should succeed with high gasLimit").to.emit(safe, "ExecutionSuccess");
            // This should only work if the gasPrice is 0
            tx.gasPrice = 1;
            await user1.sendTransaction({ to: safe.address, value: (0, units_1.parseEther)("1") });
            await (0, chai_1.expect)((0, execution_1.executeTx)(safe, tx, [await (0, execution_1.safeApproveHash)(user1, safe, tx, true)], { gasLimit: 6000000 }), "Safe transaction should fail with gasPrice 1 and high gasLimit").to.emit(safe, "ExecutionFailure");
        });
    });
});
