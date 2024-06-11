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
const config_1 = require("../utils/config");
describe("SafeL2", async () => {
    before(function () {
        if ((0, config_1.safeContractUnderTest)() != "SafeL2") {
            this.skip();
        }
    });
    const [user1, user2] = hardhat_1.waffle.provider.getWallets();
    const setupTests = hardhat_1.deployments.createFixture(async ({ deployments }) => {
        await deployments.fixture();
        const mock = await (0, setup_1.getMock)();
        return {
            safe: await (0, setup_1.getSafeWithOwners)([user1.address]),
            mock,
        };
    });
    describe("execTransactions", async () => {
        it("should emit SafeMultiSigTransaction event", async () => {
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
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getBalance(safe.address)).to.be.deep.eq((0, units_1.parseEther)("1"));
            const additionalInfo = hardhat_1.ethers.utils.defaultAbiCoder.encode(["uint256", "address", "uint256"], [tx.nonce, user1.address, 1]);
            const signatures = [await (0, execution_1.safeApproveHash)(user1, safe, tx, true)];
            const signatureBytes = (0, execution_1.buildSignatureBytes)(signatures).toLowerCase();
            let executedTx;
            await (0, chai_1.expect)((0, execution_1.executeTx)(safe, tx, signatures).then((tx) => {
                executedTx = tx;
                return tx;
            }))
                .to.emit(safe, "ExecutionSuccess")
                .to.emit(safe, "SafeMultiSigTransaction")
                .withArgs(tx.to, tx.value, tx.data, tx.operation, tx.safeTxGas, tx.baseGas, tx.gasPrice, tx.gasToken, tx.refundReceiver, signatureBytes, additionalInfo);
        });
        it("should emit SafeModuleTransaction event", async () => {
            const { safe, mock } = await setupTests();
            const user2Safe = safe.connect(user2);
            await (0, execution_1.executeContractCallWithSigners)(safe, safe, "enableModule", [user2.address], [user1]);
            await (0, chai_1.expect)(user2Safe.execTransactionFromModule(mock.address, 0, "0xbaddad", 0))
                .to.emit(safe, "SafeModuleTransaction")
                .withArgs(user2.address, mock.address, 0, "0xbaddad", 0)
                .to.emit(safe, "ExecutionFromModuleSuccess")
                .withArgs(user2.address);
        });
    });
});
