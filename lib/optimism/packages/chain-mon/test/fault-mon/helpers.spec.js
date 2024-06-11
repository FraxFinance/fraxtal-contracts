"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const hardhat_1 = __importDefault(require("hardhat"));
require("@nomiclabs/hardhat-ethers");
const ethers_1 = require("ethers");
const core_utils_1 = require("@eth-optimism/core-utils");
const L2OutputOracle_json_1 = __importDefault(require("@eth-optimism/contracts-bedrock/forge-artifacts/L2OutputOracle.sol/L2OutputOracle.json"));
const Proxy_json_1 = __importDefault(require("@eth-optimism/contracts-bedrock/forge-artifacts/Proxy.sol/Proxy.json"));
const setup_1 = require("./setup");
const fault_mon_1 = require("../../src/fault-mon");
describe('helpers', () => {
    const deployConfig = {
        l2OutputOracleSubmissionInterval: 6,
        l2BlockTime: 2,
        l2OutputOracleStartingBlockNumber: 0,
        l2OutputOracleStartingTimestamp: 0,
        l2OutputOracleProposer: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
        l2OutputOracleChallenger: '0x6925B8704Ff96DEe942623d6FB5e946EF5884b63',
        // Can be any non-zero value, 1000 is fine.
        finalizationPeriodSeconds: 1000,
    };
    let signer;
    before(async () => {
        ;
        [signer] = await hardhat_1.default.ethers.getSigners();
    });
    let L2OutputOracle;
    let Proxy;
    beforeEach(async () => {
        const Factory__Proxy = new hardhat_1.default.ethers.ContractFactory(Proxy_json_1.default.abi, Proxy_json_1.default.bytecode.object, signer);
        Proxy = await Factory__Proxy.deploy(signer.address);
        const Factory__L2OutputOracle = new hardhat_1.default.ethers.ContractFactory(L2OutputOracle_json_1.default.abi, L2OutputOracle_json_1.default.bytecode.object, signer);
        const L2OutputOracleImplementation = await Factory__L2OutputOracle.deploy(deployConfig.l2OutputOracleSubmissionInterval, deployConfig.l2BlockTime, deployConfig.l2OutputOracleStartingBlockNumber, deployConfig.l2OutputOracleStartingTimestamp, deployConfig.l2OutputOracleProposer, deployConfig.l2OutputOracleChallenger, deployConfig.finalizationPeriodSeconds);
        await Proxy.upgradeToAndCall(L2OutputOracleImplementation.address, L2OutputOracleImplementation.interface.encodeFunctionData('initialize', [
            deployConfig.l2OutputOracleStartingBlockNumber,
            deployConfig.l2OutputOracleStartingTimestamp,
        ]));
        L2OutputOracle = new hardhat_1.default.ethers.Contract(Proxy.address, L2OutputOracle_json_1.default.abi, signer);
    });
    describe('findOutputForIndex', () => {
        describe('when the output exists once', () => {
            beforeEach(async () => {
                const latestBlock = await hardhat_1.default.ethers.provider.getBlock('latest');
                const params = {
                    _outputRoot: ethers_1.utils.formatBytes32String('testhash'),
                    _l2BlockNumber: deployConfig.l2OutputOracleStartingBlockNumber +
                        deployConfig.l2OutputOracleSubmissionInterval,
                    _l1BlockHash: latestBlock.hash,
                    _l1BlockNumber: latestBlock.number,
                };
                await L2OutputOracle.proposeL2Output(params._outputRoot, params._l2BlockNumber, params._l1BlockHash, params._l1BlockNumber);
            });
            it('should return the output', async () => {
                const output = await (0, fault_mon_1.findOutputForIndex)(L2OutputOracle, 0);
                (0, setup_1.expect)(output.l2OutputIndex).to.equal(0);
            });
        });
        describe('when the output does not exist', () => {
            it('should throw an error', async () => {
                await (0, setup_1.expect)((0, fault_mon_1.findOutputForIndex)(L2OutputOracle, 0)).to.eventually.be.rejectedWith('unable to find output for index');
            });
        });
    });
    describe('findFirstUnfinalizedIndex', () => {
        describe('when the chain is more then FPW seconds old', () => {
            beforeEach(async () => {
                const latestBlock = await hardhat_1.default.ethers.provider.getBlock('latest');
                const params = {
                    _l2BlockNumber: deployConfig.l2OutputOracleStartingBlockNumber +
                        deployConfig.l2OutputOracleSubmissionInterval,
                    _l1BlockHash: latestBlock.hash,
                    _l1BlockNumber: latestBlock.number,
                };
                await L2OutputOracle.proposeL2Output(ethers_1.utils.formatBytes32String('outputRoot1'), params._l2BlockNumber, params._l1BlockHash, params._l1BlockNumber);
                // Simulate FPW passing
                await hardhat_1.default.ethers.provider.send('evm_increaseTime', [
                    (0, core_utils_1.toRpcHexString)(deployConfig.finalizationPeriodSeconds * 2),
                ]);
                await L2OutputOracle.proposeL2Output(ethers_1.utils.formatBytes32String('outputRoot2'), params._l2BlockNumber + deployConfig.l2OutputOracleSubmissionInterval, params._l1BlockHash, params._l1BlockNumber);
                await L2OutputOracle.proposeL2Output(ethers_1.utils.formatBytes32String('outputRoot3'), params._l2BlockNumber +
                    deployConfig.l2OutputOracleSubmissionInterval * 2, params._l1BlockHash, params._l1BlockNumber);
            });
            it('should find the first batch older than the FPW', async () => {
                const first = await (0, fault_mon_1.findFirstUnfinalizedOutputIndex)(L2OutputOracle, deployConfig.finalizationPeriodSeconds);
                (0, setup_1.expect)(first).to.equal(1);
            });
        });
        describe('when the chain is less than FPW seconds old', () => {
            beforeEach(async () => {
                const latestBlock = await hardhat_1.default.ethers.provider.getBlock('latest');
                const params = {
                    _outputRoot: ethers_1.utils.formatBytes32String('testhash'),
                    _l2BlockNumber: deployConfig.l2OutputOracleStartingBlockNumber +
                        deployConfig.l2OutputOracleSubmissionInterval,
                    _l1BlockHash: latestBlock.hash,
                    _l1BlockNumber: latestBlock.number,
                };
                await L2OutputOracle.proposeL2Output(params._outputRoot, params._l2BlockNumber, params._l1BlockHash, params._l1BlockNumber);
                await L2OutputOracle.proposeL2Output(params._outputRoot, params._l2BlockNumber + deployConfig.l2OutputOracleSubmissionInterval, params._l1BlockHash, params._l1BlockNumber);
                await L2OutputOracle.proposeL2Output(params._outputRoot, params._l2BlockNumber +
                    deployConfig.l2OutputOracleSubmissionInterval * 2, params._l1BlockHash, params._l1BlockNumber);
            });
            it('should return zero', async () => {
                const first = await (0, fault_mon_1.findFirstUnfinalizedOutputIndex)(L2OutputOracle, deployConfig.finalizationPeriodSeconds);
                (0, setup_1.expect)(first).to.equal(0);
            });
        });
        describe('when no batches submitted for the entire FPW', () => {
            beforeEach(async () => {
                const latestBlock = await hardhat_1.default.ethers.provider.getBlock('latest');
                const params = {
                    _outputRoot: ethers_1.utils.formatBytes32String('testhash'),
                    _l2BlockNumber: deployConfig.l2OutputOracleStartingBlockNumber +
                        deployConfig.l2OutputOracleSubmissionInterval,
                    _l1BlockHash: latestBlock.hash,
                    _l1BlockNumber: latestBlock.number,
                };
                await L2OutputOracle.proposeL2Output(params._outputRoot, params._l2BlockNumber, params._l1BlockHash, params._l1BlockNumber);
                await L2OutputOracle.proposeL2Output(params._outputRoot, params._l2BlockNumber + deployConfig.l2OutputOracleSubmissionInterval, params._l1BlockHash, params._l1BlockNumber);
                await L2OutputOracle.proposeL2Output(params._outputRoot, params._l2BlockNumber +
                    deployConfig.l2OutputOracleSubmissionInterval * 2, params._l1BlockHash, params._l1BlockNumber);
                // Simulate FPW passing and no new batches
                await hardhat_1.default.ethers.provider.send('evm_increaseTime', [
                    (0, core_utils_1.toRpcHexString)(deployConfig.finalizationPeriodSeconds * 2),
                ]);
                // Mine a block to force timestamp to update
                await hardhat_1.default.ethers.provider.send('hardhat_mine', ['0x1']);
            });
            it('should return undefined', async () => {
                const first = await (0, fault_mon_1.findFirstUnfinalizedOutputIndex)(L2OutputOracle, deployConfig.finalizationPeriodSeconds);
                (0, setup_1.expect)(first).to.equal(undefined);
            });
        });
    });
});
