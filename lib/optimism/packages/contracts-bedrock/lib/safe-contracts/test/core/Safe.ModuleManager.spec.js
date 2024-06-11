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
const constants_2 = require("../../src/utils/constants");
describe("ModuleManager", async () => {
    const [user1, user2, user3] = hardhat_1.waffle.provider.getWallets();
    const setupTests = hardhat_1.deployments.createFixture(async ({ deployments }) => {
        await deployments.fixture();
        return {
            safe: await (0, setup_1.getSafeWithOwners)([user1.address]),
            mock: await (0, setup_1.getMock)(),
        };
    });
    describe("enableModule", async () => {
        it("can only be called from Safe itself", async () => {
            const { safe } = await setupTests();
            await (0, chai_1.expect)(safe.enableModule(user2.address)).to.be.revertedWith("GS031");
        });
        it("can not set sentinel", async () => {
            const { safe } = await setupTests();
            await (0, chai_1.expect)((0, execution_1.executeContractCallWithSigners)(safe, safe, "enableModule", [constants_2.AddressOne], [user1])).to.revertedWith("GS013");
        });
        it("can not set 0 Address", async () => {
            const { safe } = await setupTests();
            await (0, chai_1.expect)((0, execution_1.executeContractCallWithSigners)(safe, safe, "enableModule", [constants_1.AddressZero], [user1])).to.revertedWith("GS013");
        });
        it("can not add module twice", async () => {
            const { safe } = await setupTests();
            // Use module for execution to see error
            await (0, execution_1.executeContractCallWithSigners)(safe, safe, "enableModule", [user2.address], [user1]);
            await (0, chai_1.expect)((0, execution_1.executeContractCallWithSigners)(safe, safe, "enableModule", [user2.address], [user1])).to.revertedWith("GS013");
        });
        it("emits event for a new module", async () => {
            const { safe } = await setupTests();
            await (0, chai_1.expect)((0, execution_1.executeContractCallWithSigners)(safe, safe, "enableModule", [user2.address], [user1]))
                .to.emit(safe, "EnabledModule")
                .withArgs(user2.address);
            await (0, chai_1.expect)(await safe.isModuleEnabled(user2.address)).to.be.true;
            await (0, chai_1.expect)(await safe.getModulesPaginated(constants_2.AddressOne, 10)).to.be.deep.equal([[user2.address], constants_2.AddressOne]);
        });
        it("can enable multiple", async () => {
            const { safe } = await setupTests();
            await (0, chai_1.expect)((0, execution_1.executeContractCallWithSigners)(safe, safe, "enableModule", [user1.address], [user1]))
                .to.emit(safe, "EnabledModule")
                .withArgs(user1.address);
            await (0, chai_1.expect)(await safe.isModuleEnabled(user1.address)).to.be.true;
            await (0, chai_1.expect)(await safe.getModulesPaginated(constants_2.AddressOne, 10)).to.be.deep.equal([[user1.address], constants_2.AddressOne]);
            await (0, chai_1.expect)((0, execution_1.executeContractCallWithSigners)(safe, safe, "enableModule", [user2.address], [user1]))
                .to.emit(safe, "EnabledModule")
                .withArgs(user2.address);
            await (0, chai_1.expect)(await safe.isModuleEnabled(user2.address)).to.be.true;
            await (0, chai_1.expect)(await safe.getModulesPaginated(constants_2.AddressOne, 10)).to.be.deep.equal([[user2.address, user1.address], constants_2.AddressOne]);
        });
    });
    describe("disableModule", async () => {
        it("can only be called from Safe itself", async () => {
            const { safe } = await setupTests();
            await (0, chai_1.expect)(safe.disableModule(constants_2.AddressOne, user2.address)).to.be.revertedWith("GS031");
        });
        it("can not set sentinel", async () => {
            const { safe } = await setupTests();
            await (0, chai_1.expect)((0, execution_1.executeContractCallWithSigners)(safe, safe, "disableModule", [constants_2.AddressOne, constants_2.AddressOne], [user1])).to.revertedWith("GS013");
        });
        it("can not set 0 Address", async () => {
            const { safe } = await setupTests();
            await (0, chai_1.expect)((0, execution_1.executeContractCallWithSigners)(safe, safe, "disableModule", [constants_2.AddressOne, constants_1.AddressZero], [user1])).to.revertedWith("GS013");
        });
        it("Invalid prevModule, module pair provided - Invalid target", async () => {
            const { safe } = await setupTests();
            await (0, execution_1.executeContractCallWithSigners)(safe, safe, "enableModule", [user2.address], [user1]);
            await (0, chai_1.expect)((0, execution_1.executeContractCallWithSigners)(safe, safe, "disableModule", [constants_2.AddressOne, user1.address], [user1])).to.revertedWith("GS013");
        });
        it("Invalid prevModule, module pair provided - Invalid sentinel", async () => {
            const { safe } = await setupTests();
            await (0, execution_1.executeContractCallWithSigners)(safe, safe, "enableModule", [user2.address], [user1]);
            await (0, chai_1.expect)((0, execution_1.executeContractCallWithSigners)(safe, safe, "disableModule", [constants_1.AddressZero, user2.address], [user1])).to.revertedWith("GS013");
        });
        it("Invalid prevModule, module pair provided - Invalid source", async () => {
            const { safe } = await setupTests();
            await (0, execution_1.executeContractCallWithSigners)(safe, safe, "enableModule", [user1.address], [user1]);
            await (0, execution_1.executeContractCallWithSigners)(safe, safe, "enableModule", [user2.address], [user1]);
            await (0, chai_1.expect)((0, execution_1.executeContractCallWithSigners)(safe, safe, "disableModule", [user1.address, user2.address], [user1])).to.revertedWith("GS013");
        });
        it("emits event for disabled module", async () => {
            const { safe } = await setupTests();
            await (0, execution_1.executeContractCallWithSigners)(safe, safe, "enableModule", [user1.address], [user1]);
            await (0, chai_1.expect)(await safe.isModuleEnabled(user1.address)).to.be.true;
            await (0, execution_1.executeContractCallWithSigners)(safe, safe, "enableModule", [user2.address], [user1]);
            await (0, chai_1.expect)(await safe.isModuleEnabled(user2.address)).to.be.true;
            await (0, chai_1.expect)(await safe.getModulesPaginated(constants_2.AddressOne, 10)).to.be.deep.equal([[user2.address, user1.address], constants_2.AddressOne]);
            await (0, chai_1.expect)((0, execution_1.executeContractCallWithSigners)(safe, safe, "disableModule", [user2.address, user1.address], [user1]))
                .to.emit(safe, "DisabledModule")
                .withArgs(user1.address);
            await (0, chai_1.expect)(await safe.isModuleEnabled(user1.address)).to.be.false;
            await (0, chai_1.expect)(await safe.getModulesPaginated(constants_2.AddressOne, 10)).to.be.deep.equal([[user2.address], constants_2.AddressOne]);
            await (0, chai_1.expect)((0, execution_1.executeContractCallWithSigners)(safe, safe, "disableModule", [constants_2.AddressOne, user2.address], [user1]))
                .to.emit(safe, "DisabledModule")
                .withArgs(user2.address);
            await (0, chai_1.expect)(await safe.isModuleEnabled(user2.address)).to.be.false;
            await (0, chai_1.expect)(await safe.getModulesPaginated(constants_2.AddressOne, 10)).to.be.deep.equal([[], constants_2.AddressOne]);
        });
    });
    describe("execTransactionFromModule", async () => {
        it("can not be called from sentinel", async () => {
            const { safe, mock } = await setupTests();
            const readOnlySafe = safe.connect(hardhat_1.default.ethers.provider);
            await (0, chai_1.expect)(readOnlySafe.callStatic.execTransactionFromModule(mock.address, 0, "0xbaddad", 0, { from: constants_2.AddressOne })).to.be.revertedWith("GS104");
        });
        it("can only be called from enabled module", async () => {
            const { safe, mock } = await setupTests();
            const user2Safe = safe.connect(user2);
            await (0, chai_1.expect)(user2Safe.execTransactionFromModule(mock.address, 0, "0xbaddad", 0)).to.be.revertedWith("GS104");
        });
        it("emits event on execution success", async () => {
            const { safe, mock } = await setupTests();
            const user2Safe = safe.connect(user2);
            await (0, execution_1.executeContractCallWithSigners)(safe, safe, "enableModule", [user2.address], [user1]);
            await (0, chai_1.expect)(user2Safe.execTransactionFromModule(mock.address, 0, "0xbaddad", 0))
                .to.emit(safe, "ExecutionFromModuleSuccess")
                .withArgs(user2.address);
            (0, chai_1.expect)(await mock.callStatic.invocationCountForCalldata("0xbaddad")).to.be.deep.equals(ethers_1.BigNumber.from(1));
        });
        it("emits event on execution failure", async () => {
            const { safe, mock } = await setupTests();
            const user2Safe = safe.connect(user2);
            await (0, execution_1.executeContractCallWithSigners)(safe, safe, "enableModule", [user2.address], [user1]);
            await mock.givenAnyRevert();
            await (0, chai_1.expect)(user2Safe.execTransactionFromModule(mock.address, 0, "0xbaddad", 0))
                .to.emit(safe, "ExecutionFromModuleFailure")
                .withArgs(user2.address);
        });
    });
    describe("execTransactionFromModuleReturnData", async () => {
        it("can not be called from sentinel", async () => {
            const { safe, mock } = await setupTests();
            const readOnlySafe = safe.connect(hardhat_1.default.ethers.provider);
            await (0, chai_1.expect)(readOnlySafe.callStatic.execTransactionFromModuleReturnData(mock.address, 0, "0xbaddad", 0, { from: constants_2.AddressOne })).to.be.revertedWith("GS104");
        });
        it("can only be called from enabled module", async () => {
            const { safe, mock } = await setupTests();
            const user2Safe = safe.connect(user2);
            await (0, chai_1.expect)(user2Safe.execTransactionFromModuleReturnData(mock.address, 0, "0xbaddad", 0)).to.be.revertedWith("GS104");
        });
        it("emits event on execution failure", async () => {
            const { safe, mock } = await setupTests();
            const user2Safe = safe.connect(user2);
            await (0, execution_1.executeContractCallWithSigners)(safe, safe, "enableModule", [user2.address], [user1]);
            await mock.givenAnyRevert();
            await (0, chai_1.expect)(user2Safe.execTransactionFromModuleReturnData(mock.address, 0, "0xbaddad", 0))
                .to.emit(safe, "ExecutionFromModuleFailure")
                .withArgs(user2.address);
        });
        it("emits event on execution success", async () => {
            const { safe, mock } = await setupTests();
            const user2Safe = safe.connect(user2);
            await (0, execution_1.executeContractCallWithSigners)(safe, safe, "enableModule", [user2.address], [user1]);
            await (0, chai_1.expect)(user2Safe.execTransactionFromModuleReturnData(mock.address, 0, "0xbaddad", 0))
                .to.emit(safe, "ExecutionFromModuleSuccess")
                .withArgs(user2.address);
            (0, chai_1.expect)(await mock.callStatic.invocationCountForCalldata("0xbaddad")).to.be.deep.equals(ethers_1.BigNumber.from(1));
        });
        it("Returns expected from contract on successs", async () => {
            const { safe, mock } = await setupTests();
            const user2Safe = safe.connect(user2);
            await (0, execution_1.executeContractCallWithSigners)(safe, safe, "enableModule", [user2.address], [user1]);
            await mock.givenCalldataReturn("0xbaddad", "0xdeaddeed");
            await (0, chai_1.expect)(await user2Safe.callStatic.execTransactionFromModuleReturnData(mock.address, 0, "0xbaddad", 0)).to.be.deep.eq([
                true,
                "0xdeaddeed",
            ]);
        });
        it("Returns expected from contract on failure", async () => {
            const { safe, mock } = await setupTests();
            const user2Safe = safe.connect(user2);
            await (0, execution_1.executeContractCallWithSigners)(safe, safe, "enableModule", [user2.address], [user1]);
            await mock.givenCalldataRevertWithMessage("0xbaddad", "Some random message");
            await (0, chai_1.expect)(await user2Safe.callStatic.execTransactionFromModuleReturnData(mock.address, 0, "0xbaddad", 0)).to.be.deep.eq([
                false,
                "0x08c379a000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000013536f6d652072616e646f6d206d65737361676500000000000000000000000000",
            ]);
        });
    });
    describe("getModulesPaginated", async () => {
        it("requires page size to be greater than 0", async () => {
            const { safe } = await setupTests();
            await (0, chai_1.expect)(safe.getModulesPaginated(constants_2.AddressOne, 0)).to.be.revertedWith("GS106");
        });
        it("requires start to be a module or start pointer", async () => {
            const { safe } = await setupTests();
            await (0, chai_1.expect)(safe.getModulesPaginated(constants_1.AddressZero, 1)).to.be.reverted;
            await (0, execution_1.executeContractCallWithSigners)(safe, safe, "enableModule", [user1.address], [user1]);
            (0, chai_1.expect)(await safe.getModulesPaginated(user1.address, 1)).to.be.deep.equal([[], constants_2.AddressOne]);
            await (0, chai_1.expect)(safe.getModulesPaginated(user2.address, 1)).to.be.revertedWith("GS105");
        });
        it("Returns all modules over multiple pages", async () => {
            const { safe } = await setupTests();
            await (0, chai_1.expect)((0, execution_1.executeContractCallWithSigners)(safe, safe, "enableModule", [user1.address], [user1]))
                .to.emit(safe, "EnabledModule")
                .withArgs(user1.address);
            await (0, chai_1.expect)((0, execution_1.executeContractCallWithSigners)(safe, safe, "enableModule", [user2.address], [user1]))
                .to.emit(safe, "EnabledModule")
                .withArgs(user2.address);
            await (0, chai_1.expect)((0, execution_1.executeContractCallWithSigners)(safe, safe, "enableModule", [user3.address], [user1]))
                .to.emit(safe, "EnabledModule")
                .withArgs(user3.address);
            await (0, chai_1.expect)(await safe.isModuleEnabled(user1.address)).to.be.true;
            await (0, chai_1.expect)(await safe.isModuleEnabled(user2.address)).to.be.true;
            await (0, chai_1.expect)(await safe.isModuleEnabled(user3.address)).to.be.true;
            /*
            This will pass the test which is not correct
            await expect(await safe.getModulesPaginated(AddressOne, 1)).to.be.deep.equal([[user3.address], user2.address])
            await expect(await safe.getModulesPaginated(user2.address, 1)).to.be.deep.equal([[user1.address], AddressOne])
            */
            await (0, chai_1.expect)(await safe.getModulesPaginated(constants_2.AddressOne, 1)).to.be.deep.equal([[user3.address], user3.address]);
            await (0, chai_1.expect)(await safe.getModulesPaginated(user3.address, 1)).to.be.deep.equal([[user2.address], user2.address]);
            await (0, chai_1.expect)(await safe.getModulesPaginated(user2.address, 1)).to.be.deep.equal([[user1.address], constants_2.AddressOne]);
        });
        it("returns an empty array and end pointer for a safe with no modules", async () => {
            const { safe } = await setupTests();
            (0, chai_1.expect)(await safe.getModulesPaginated(constants_2.AddressOne, 10)).to.be.deep.equal([[], constants_2.AddressOne]);
        });
    });
});
