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
exports.benchmark = exports.setupBenchmarkContracts = exports.configs = void 0;
const chai_1 = require("chai");
const hardhat_1 = __importStar(require("hardhat"));
require("@nomiclabs/hardhat-ethers");
const setup_1 = require("../../test/utils/setup");
const execution_1 = require("../../src/utils/execution");
const constants_1 = require("@ethersproject/constants");
const [user1, user2, user3, user4, user5] = hardhat_1.waffle.provider.getWallets();
const generateTarget = async (owners, threshold, guardAddress, logGasUsage) => {
    const fallbackHandler = await (0, setup_1.getTokenCallbackHandler)();
    const safe = await (0, setup_1.getSafeWithOwners)(owners.map((owner) => owner.address), threshold, fallbackHandler.address, logGasUsage);
    await (0, execution_1.executeContractCallWithSigners)(safe, safe, "setGuard", [guardAddress], owners);
    return safe;
};
exports.configs = [
    { name: "single owner", signers: [user1], threshold: 1 },
    { name: "single owner and guard", signers: [user1], threshold: 1, useGuard: true },
    { name: "2 out of 2", signers: [user1, user2], threshold: 2 },
    { name: "3 out of 3", signers: [user1, user2, user3], threshold: 3 },
    { name: "3 out of 5", signers: [user1, user2, user3, user4, user5], threshold: 3 },
];
const setupBenchmarkContracts = (benchmarkFixture, logGasUsage) => {
    return hardhat_1.deployments.createFixture(async ({ deployments }) => {
        await deployments.fixture();
        const guardFactory = await hardhat_1.default.ethers.getContractFactory("DelegateCallTransactionGuard");
        const guard = await guardFactory.deploy(constants_1.AddressZero);
        const targets = [];
        for (const config of exports.configs) {
            targets.push(await generateTarget(config.signers, config.threshold, config.useGuard ? guard.address : constants_1.AddressZero, logGasUsage));
        }
        return {
            targets,
            additions: (benchmarkFixture ? await benchmarkFixture() : undefined)
        };
    });
};
exports.setupBenchmarkContracts = setupBenchmarkContracts;
const benchmark = async (topic, benchmarks) => {
    for (const benchmark of benchmarks) {
        const { name, prepare, after, fixture } = benchmark;
        const contractSetup = (0, exports.setupBenchmarkContracts)(fixture);
        describe(`${topic} - ${name}`, async () => {
            it("with an EOA", async () => {
                const contracts = await contractSetup();
                const tx = await prepare(contracts, user2.address, 0);
                await (0, execution_1.logGas)(name, user2.sendTransaction({
                    to: tx.to,
                    value: tx.value,
                    data: tx.data
                }));
                if (after)
                    await after(contracts);
            });
            for (const i in exports.configs) {
                const config = exports.configs[i];
                it(`with a ${config.name} Safe`, async () => {
                    const contracts = await contractSetup();
                    const target = contracts.targets[i];
                    const nonce = await target.nonce();
                    const tx = await prepare(contracts, target.address, nonce);
                    const threshold = await target.getThreshold();
                    const sigs = await Promise.all(config.signers.slice(0, threshold).map(async (signer) => {
                        return await (0, execution_1.safeSignTypedData)(signer, target, tx);
                    }));
                    await (0, chai_1.expect)((0, execution_1.logGas)(name, (0, execution_1.executeTx)(target, tx, sigs))).to.emit(target, "ExecutionSuccess");
                    if (after)
                        await after(contracts);
                });
            }
        });
    }
};
exports.benchmark = benchmark;
