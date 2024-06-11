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
describe("OnlyOwnersGuard", async () => {
    const [user1, user2] = hardhat_1.waffle.provider.getWallets();
    const setupTests = hardhat_1.deployments.createFixture(async ({ deployments }) => {
        await deployments.fixture();
        const safe = await (0, setup_1.getSafeWithOwners)([user1.address]);
        const guardFactory = await hardhat_1.default.ethers.getContractFactory("OnlyOwnersGuard");
        const guard = await guardFactory.deploy();
        const mock = await (0, setup_1.getMock)();
        await (0, execution_1.executeContractCallWithSigners)(safe, safe, "setGuard", [guard.address], [user1]);
        return {
            safe,
            mock,
        };
    });
    describe("only owners should be able to exec transactions", async () => {
        it("should allow an owner to exec", async () => {
            const { safe, mock } = await setupTests();
            const nonce = await safe.nonce();
            const safeTx = (0, execution_1.buildSafeTransaction)({ to: mock.address, data: "0xbaddad42", nonce });
            (0, execution_1.executeTxWithSigners)(safe, safeTx, [user1]);
        });
        it("should not allow a random user exec", async () => {
            const { safe, mock } = await setupTests();
            const nonce = await safe.nonce();
            const safeTx = (0, execution_1.buildSafeTransaction)({ to: mock.address, data: "0xbaddad42", nonce });
            await (0, chai_1.expect)((0, execution_1.executeTxWithSigners)(safe, safeTx, [user2])).to.be.reverted;
        });
    });
});
