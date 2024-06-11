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
const CONTRACT_SOURCE = `
contract Test {
    address public creator;
    constructor() payable {
        creator = msg.sender;
    }

    function x() public pure returns (uint) {
        return 21;
    }
}`;
describe("CreateCall", async () => {
    const [user1] = hardhat_1.waffle.provider.getWallets();
    const setupTests = hardhat_1.deployments.createFixture(async ({ deployments }) => {
        await deployments.fixture();
        const testContract = await (0, setup_1.compile)(CONTRACT_SOURCE);
        return {
            safe: await (0, setup_1.getSafeWithOwners)([user1.address]),
            createCall: await (0, setup_1.getCreateCall)(),
            testContract,
        };
    });
    describe("performCreate", async () => {
        it("should revert if called directly and no value is on the factory", async () => {
            const { createCall, testContract } = await setupTests();
            await (0, chai_1.expect)(createCall.performCreate(1, testContract.data)).to.be.revertedWith("Could not deploy contract");
        });
        it("can call factory directly", async () => {
            const { createCall, testContract } = await setupTests();
            const createCallNonce = await hardhat_1.ethers.provider.getTransactionCount(createCall.address);
            const address = hardhat_1.ethers.utils.getContractAddress({ from: createCall.address, nonce: createCallNonce });
            await (0, chai_1.expect)(createCall.performCreate(0, testContract.data)).to.emit(createCall, "ContractCreation").withArgs(address);
            const newContract = new hardhat_1.ethers.Contract(address, testContract.interface, user1);
            (0, chai_1.expect)(await newContract.creator()).to.be.eq(createCall.address);
        });
        it("should fail if Safe does not have value to send along", async () => {
            const { safe, createCall, testContract } = await setupTests();
            const tx = await (0, execution_1.buildContractCall)(createCall, "performCreate", [1, testContract.data], await safe.nonce(), true);
            await (0, chai_1.expect)((0, execution_1.executeTx)(safe, tx, [await (0, execution_1.safeApproveHash)(user1, safe, tx, true)])).to.revertedWith("GS013");
        });
        it("should successfully create contract and emit event", async () => {
            const { safe, createCall, testContract } = await setupTests();
            const safeEthereumNonce = await hardhat_1.ethers.provider.getTransactionCount(safe.address);
            const address = hardhat_1.ethers.utils.getContractAddress({ from: safe.address, nonce: safeEthereumNonce });
            // We require this as 'emit' check the address of the event
            const safeCreateCall = createCall.attach(safe.address);
            const tx = await (0, execution_1.buildContractCall)(createCall, "performCreate", [0, testContract.data], await safe.nonce(), true);
            await (0, chai_1.expect)((0, execution_1.executeTx)(safe, tx, [await (0, execution_1.safeApproveHash)(user1, safe, tx, true)]))
                .to.emit(safe, "ExecutionSuccess")
                .and.to.emit(safeCreateCall, "ContractCreation")
                .withArgs(address);
            const newContract = new hardhat_1.ethers.Contract(address, testContract.interface, user1);
            (0, chai_1.expect)(await newContract.creator()).to.be.eq(safe.address);
        });
        it("should successfully create contract and send along ether", async () => {
            const { safe, createCall, testContract } = await setupTests();
            await user1.sendTransaction({ to: safe.address, value: (0, units_1.parseEther)("1") });
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getBalance(safe.address)).to.be.deep.eq((0, units_1.parseEther)("1"));
            const safeEthereumNonce = await hardhat_1.ethers.provider.getTransactionCount(safe.address);
            const address = hardhat_1.ethers.utils.getContractAddress({ from: safe.address, nonce: safeEthereumNonce });
            // We require this as 'emit' check the address of the event
            const safeCreateCall = createCall.attach(safe.address);
            const tx = await (0, execution_1.buildContractCall)(createCall, "performCreate", [(0, units_1.parseEther)("1"), testContract.data], await safe.nonce(), true);
            await (0, chai_1.expect)((0, execution_1.executeTx)(safe, tx, [await (0, execution_1.safeApproveHash)(user1, safe, tx, true)]))
                .to.emit(safe, "ExecutionSuccess")
                .and.to.emit(safeCreateCall, "ContractCreation")
                .withArgs(address);
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getBalance(safe.address)).to.be.deep.eq((0, units_1.parseEther)("0"));
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getBalance(address)).to.be.deep.eq((0, units_1.parseEther)("1"));
            const newContract = new hardhat_1.ethers.Contract(address, testContract.interface, user1);
            (0, chai_1.expect)(await newContract.creator()).to.be.eq(safe.address);
        });
    });
    describe("performCreate2", async () => {
        const salt = hardhat_1.ethers.utils.keccak256(hardhat_1.ethers.utils.toUtf8Bytes("createCall"));
        it("should revert if called directly and no value is on the factory", async () => {
            const { createCall, testContract } = await setupTests();
            await (0, chai_1.expect)(createCall.performCreate2(1, testContract.data, salt)).to.be.revertedWith("Could not deploy contract");
        });
        it("can call factory directly", async () => {
            const { createCall, testContract } = await setupTests();
            const address = hardhat_1.ethers.utils.getCreate2Address(createCall.address, salt, hardhat_1.ethers.utils.keccak256(testContract.data));
            await (0, chai_1.expect)(createCall.performCreate2(0, testContract.data, salt)).to.emit(createCall, "ContractCreation").withArgs(address);
            const newContract = new hardhat_1.ethers.Contract(address, testContract.interface, user1);
            (0, chai_1.expect)(await newContract.creator()).to.be.eq(createCall.address);
        });
        it("should fail if Safe does not have value to send along", async () => {
            const { safe, createCall, testContract } = await setupTests();
            const tx = await (0, execution_1.buildContractCall)(createCall, "performCreate2", [1, testContract.data, salt], await safe.nonce(), true);
            await (0, chai_1.expect)((0, execution_1.executeTx)(safe, tx, [await (0, execution_1.safeApproveHash)(user1, safe, tx, true)])).to.revertedWith("GS013");
        });
        it("should successfully create contract and emit event", async () => {
            const { safe, createCall, testContract } = await setupTests();
            const address = hardhat_1.ethers.utils.getCreate2Address(safe.address, salt, hardhat_1.ethers.utils.keccak256(testContract.data));
            // We require this as 'emit' check the address of the event
            const safeCreateCall = createCall.attach(safe.address);
            const tx = await (0, execution_1.buildContractCall)(createCall, "performCreate2", [0, testContract.data, salt], await safe.nonce(), true);
            await (0, chai_1.expect)((0, execution_1.executeTx)(safe, tx, [await (0, execution_1.safeApproveHash)(user1, safe, tx, true)]))
                .to.emit(safe, "ExecutionSuccess")
                .and.to.emit(safeCreateCall, "ContractCreation")
                .withArgs(address);
            const newContract = new hardhat_1.ethers.Contract(address, testContract.interface, user1);
            (0, chai_1.expect)(await newContract.creator()).to.be.eq(safe.address);
        });
        it("should successfully create contract and send along ether", async () => {
            const { safe, createCall, testContract } = await setupTests();
            await user1.sendTransaction({ to: safe.address, value: (0, units_1.parseEther)("1") });
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getBalance(safe.address)).to.be.deep.eq((0, units_1.parseEther)("1"));
            const address = hardhat_1.ethers.utils.getCreate2Address(safe.address, salt, hardhat_1.ethers.utils.keccak256(testContract.data));
            // We require this as 'emit' check the address of the event
            const safeCreateCall = createCall.attach(safe.address);
            const tx = await (0, execution_1.buildContractCall)(createCall, "performCreate2", [(0, units_1.parseEther)("1"), testContract.data, salt], await safe.nonce(), true);
            await (0, chai_1.expect)((0, execution_1.executeTx)(safe, tx, [await (0, execution_1.safeApproveHash)(user1, safe, tx, true)]))
                .to.emit(safe, "ExecutionSuccess")
                .and.to.emit(safeCreateCall, "ContractCreation")
                .withArgs(address);
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getBalance(safe.address)).to.be.deep.eq((0, units_1.parseEther)("0"));
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getBalance(address)).to.be.deep.eq((0, units_1.parseEther)("1"));
            const newContract = new hardhat_1.ethers.Contract(address, testContract.interface, user1);
            (0, chai_1.expect)(await newContract.creator()).to.be.eq(safe.address);
        });
    });
});
