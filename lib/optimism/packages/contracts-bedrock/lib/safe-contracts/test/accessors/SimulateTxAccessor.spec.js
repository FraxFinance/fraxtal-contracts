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
const utils_1 = require("ethers/lib/utils");
describe("SimulateTxAccessor", async () => {
    const killLibSource = `
    contract Test {
        function killme() public {
            selfdestruct(payable(msg.sender));
        }
    }`;
    const [user1, user2] = hardhat_1.waffle.provider.getWallets();
    const setupTests = hardhat_1.deployments.createFixture(async ({ deployments }) => {
        await deployments.fixture();
        const accessor = await (0, setup_1.getSimulateTxAccessor)();
        const source = `
        contract Test {
            function sendAndReturnBalance(address payable target, uint256 amount) public returns (uint256) {
                (bool success,) = target.call{ value: amount }("");
                require(success, "Transfer failed");
                return target.balance;
            }
        }`;
        const interactor = await (0, setup_1.deployContract)(user1, source);
        const handler = await (0, setup_1.getCompatFallbackHandler)();
        const safe = await (0, setup_1.getSafeWithOwners)([user1.address], 1, handler.address);
        const simulator = handler.attach(safe.address);
        return {
            safe,
            accessor,
            interactor,
            simulator,
        };
    });
    describe("estimate", async () => {
        it("should enforce delegatecall", async () => {
            const { accessor } = await setupTests();
            const killLib = await (0, setup_1.deployContract)(user1, killLibSource);
            const tx = (0, execution_1.buildContractCall)(killLib, "killme", [], 0);
            const code = await hardhat_1.default.ethers.provider.getCode(accessor.address);
            await (0, chai_1.expect)(accessor.simulate(tx.to, tx.value, tx.data, tx.operation)).to.be.revertedWith("SimulateTxAccessor should only be called via delegatecall");
            (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getCode(accessor.address)).to.be.eq(code);
        });
        it("simulate call", async () => {
            const { safe, accessor, simulator } = await setupTests();
            const tx = (0, execution_1.buildContractCall)(safe, "getOwners", [], 0);
            const simulationData = accessor.interface.encodeFunctionData("simulate", [tx.to, tx.value, tx.data, tx.operation]);
            const acccessibleData = await simulator.callStatic.simulate(accessor.address, simulationData);
            const simulation = accessor.interface.decodeFunctionResult("simulate", acccessibleData);
            (0, chai_1.expect)(safe.interface.decodeFunctionResult("getOwners", simulation.returnData)[0]).to.be.deep.eq([user1.address]);
            (0, chai_1.expect)(simulation.success).to.be.true;
            (0, chai_1.expect)(simulation.estimate.toNumber()).to.be.lte(10000);
        });
        it("simulate delegatecall", async () => {
            const { safe, accessor, interactor, simulator } = await setupTests();
            await user1.sendTransaction({ to: safe.address, value: (0, utils_1.parseEther)("1") });
            const userBalance = await hardhat_1.default.ethers.provider.getBalance(user2.address);
            const tx = (0, execution_1.buildContractCall)(interactor, "sendAndReturnBalance", [user2.address, (0, utils_1.parseEther)("1")], 0, true);
            const simulationData = accessor.interface.encodeFunctionData("simulate", [tx.to, tx.value, tx.data, tx.operation]);
            const acccessibleData = await simulator.callStatic.simulate(accessor.address, simulationData);
            const simulation = accessor.interface.decodeFunctionResult("simulate", acccessibleData);
            (0, chai_1.expect)(interactor.interface.decodeFunctionResult("sendAndReturnBalance", simulation.returnData)[0]).to.be.deep.eq(userBalance.add((0, utils_1.parseEther)("1")));
            (0, chai_1.expect)(simulation.success).to.be.true;
            (0, chai_1.expect)(simulation.estimate.toNumber()).to.be.lte(15000);
        });
        it("simulate selfdestruct", async () => {
            const { safe, accessor, simulator } = await setupTests();
            const expectedCode = await hardhat_1.default.ethers.provider.getCode(safe.address);
            await user1.sendTransaction({ to: safe.address, value: (0, utils_1.parseEther)("1") });
            const killLib = await (0, setup_1.deployContract)(user1, killLibSource);
            const tx = (0, execution_1.buildContractCall)(killLib, "killme", [], 0, true);
            const simulationData = accessor.interface.encodeFunctionData("simulate", [tx.to, tx.value, tx.data, tx.operation]);
            await simulator.simulate(accessor.address, simulationData);
            const code = await hardhat_1.default.ethers.provider.getCode(safe.address);
            (0, chai_1.expect)(code).to.be.eq(expectedCode);
            (0, chai_1.expect)(code).to.be.not.eq("0x");
            // Selfdestruct Safe (to be sure that this test works)
            await (0, execution_1.executeTxWithSigners)(safe, tx, [user1]);
            (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getCode(safe.address)).to.be.eq("0x");
        });
        it("simulate revert", async () => {
            const { accessor, interactor, simulator } = await setupTests();
            const tx = (0, execution_1.buildContractCall)(interactor, "sendAndReturnBalance", [user2.address, (0, utils_1.parseEther)("1")], 0, true);
            const simulationData = accessor.interface.encodeFunctionData("simulate", [tx.to, tx.value, tx.data, tx.operation]);
            const acccessibleData = await simulator.callStatic.simulate(accessor.address, simulationData);
            const simulation = accessor.interface.decodeFunctionResult("simulate", acccessibleData);
            (0, chai_1.expect)(simulation.returnData).to.be.deep.eq("0x08c379a00000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000f5472616e73666572206661696c65640000000000000000000000000000000000");
            (0, chai_1.expect)(simulation.success).to.be.false;
            (0, chai_1.expect)(simulation.estimate.toNumber()).to.be.lte(20000);
        });
    });
});
