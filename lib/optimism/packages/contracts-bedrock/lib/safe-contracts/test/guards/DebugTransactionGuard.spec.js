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
const setup_1 = require("../utils/setup");
const execution_2 = require("../../src/utils/execution");
const encoding_1 = require("../utils/encoding");
describe("DebugTransactionGuard", async () => {
    const [user1] = hardhat_1.waffle.provider.getWallets();
    const setupTests = hardhat_1.deployments.createFixture(async ({ deployments }) => {
        await deployments.fixture();
        const safe = await (0, setup_1.getSafeWithOwners)([user1.address]);
        const guardFactory = await hardhat_1.default.ethers.getContractFactory("DebugTransactionGuard");
        const guard = await guardFactory.deploy();
        const mock = await (0, setup_1.getMock)();
        await (0, execution_2.executeContractCallWithSigners)(safe, safe, "setGuard", [guard.address], [user1]);
        return {
            safe,
            mock,
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
        it("should emit debug events", async () => {
            const { safe, mock, guard } = await setupTests();
            const nonce = await safe.nonce();
            const safeTx = (0, execution_2.buildSafeTransaction)({ to: mock.address, data: "0xbaddad42", nonce });
            const safeTxHash = (0, execution_2.calculateSafeTransactionHash)(safe, safeTx, await (0, encoding_1.chainId)());
            const signature = await (0, execution_1.signHash)(user1, safeTxHash);
            await (0, chai_1.expect)((0, execution_2.executeTx)(safe, safeTx, [signature]))
                .to.emit(guard, "TransactionDetails")
                .withArgs(safe.address, safeTxHash, safeTx.to, safeTx.value, safeTx.data, safeTx.operation, safeTx.safeTxGas, false, safeTx.nonce, signature.data, user1.address)
                .and.to.emit(guard, "GasUsage")
                .withArgs(safe.address, safeTxHash, nonce, true);
            (0, chai_1.expect)(await mock.callStatic.invocationCount()).to.be.eq(1);
            (0, chai_1.expect)(await mock.callStatic.invocationCountForCalldata("0xbaddad42")).to.be.eq(1);
        });
    });
});
