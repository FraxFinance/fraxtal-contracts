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
const units_1 = require("@ethersproject/units");
const setup_1 = require("../utils/setup");
const execution_1 = require("../../src/utils/execution");
const constants_2 = require("../../src/utils/constants");
const encoding_1 = require("../utils/encoding");
describe("Safe", async () => {
    const [user1, user2, user3] = hardhat_1.waffle.provider.getWallets();
    const setupTests = hardhat_1.deployments.createFixture(async ({ deployments }) => {
        await deployments.fixture();
        return {
            template: await (0, setup_1.getSafeTemplate)(),
            mock: await (0, setup_1.getMock)(),
        };
    });
    describe("setup", async () => {
        it("should not allow to call setup on singleton", async () => {
            await hardhat_1.deployments.fixture();
            const singleton = await (0, setup_1.getSafeSingleton)();
            await (0, chai_1.expect)(await singleton.getThreshold()).to.be.deep.eq(ethers_1.BigNumber.from(1));
            // Because setup wasn't called on the singleton it breaks the assumption made
            // within `getModulesPaginated` method that the linked list will be always correctly
            // initialized with 0x1 as a starting element and 0x1 as the end
            // But because `setupModules` wasn't called, it is empty.
            await (0, chai_1.expect)(singleton.getModulesPaginated(constants_2.AddressOne, 10)).to.be.reverted;
            // "Should not be able to retrieve owners (currently the contract will run in an endless loop when not initialized)"
            await (0, chai_1.expect)(singleton.getOwners()).to.be.reverted;
            await (0, chai_1.expect)(singleton.setup([user1.address, user2.address, user3.address], 2, constants_1.AddressZero, "0x", constants_1.AddressZero, constants_1.AddressZero, 0, constants_1.AddressZero)).to.be.revertedWith("GS200");
        });
        it("should set domain hash", async () => {
            const { template } = await setupTests();
            await (0, chai_1.expect)(template.setup([user1.address, user2.address, user3.address], 2, constants_1.AddressZero, "0x", constants_1.AddressZero, constants_1.AddressZero, 0, constants_1.AddressZero))
                .to.emit(template, "SafeSetup")
                .withArgs(user1.address, [user1.address, user2.address, user3.address], 2, constants_1.AddressZero, constants_1.AddressZero);
            await (0, chai_1.expect)(await template.domainSeparator()).to.be.eq((0, execution_1.calculateSafeDomainSeparator)(template, await (0, encoding_1.chainId)()));
            await (0, chai_1.expect)(await template.getOwners()).to.be.deep.eq([user1.address, user2.address, user3.address]);
            await (0, chai_1.expect)(await template.getThreshold()).to.be.deep.eq(ethers_1.BigNumber.from(2));
        });
        it("should revert if called twice", async () => {
            const { template } = await setupTests();
            await template.setup([user1.address, user2.address, user3.address], 2, constants_1.AddressZero, "0x", constants_1.AddressZero, constants_1.AddressZero, 0, constants_1.AddressZero);
            await (0, chai_1.expect)(template.setup([user1.address, user2.address, user3.address], 2, constants_1.AddressZero, "0x", constants_1.AddressZero, constants_1.AddressZero, 0, constants_1.AddressZero)).to.be.revertedWith("GS200");
        });
        it("should revert if same owner is included twice", async () => {
            const { template } = await setupTests();
            await (0, chai_1.expect)(template.setup([user2.address, user1.address, user2.address], 2, constants_1.AddressZero, "0x", constants_1.AddressZero, constants_1.AddressZero, 0, constants_1.AddressZero)).to.be.revertedWith("GS204");
        });
        it("should revert if 0 address is used as an owner", async () => {
            const { template } = await setupTests();
            await (0, chai_1.expect)(template.setup([user2.address, constants_1.AddressZero], 2, constants_1.AddressZero, "0x", constants_1.AddressZero, constants_1.AddressZero, 0, constants_1.AddressZero)).to.be.revertedWith("GS203");
        });
        it("should revert if Safe itself is used as an owner", async () => {
            const { template } = await setupTests();
            await (0, chai_1.expect)(template.setup([user2.address, template.address], 2, constants_1.AddressZero, "0x", constants_1.AddressZero, constants_1.AddressZero, 0, constants_1.AddressZero)).to.be.revertedWith("GS203");
        });
        it("should revert if sentinel is used as an owner", async () => {
            const { template } = await setupTests();
            await (0, chai_1.expect)(template.setup([user2.address, constants_2.AddressOne], 2, constants_1.AddressZero, "0x", constants_1.AddressZero, constants_1.AddressZero, 0, constants_1.AddressZero)).to.be.revertedWith("GS203");
        });
        it("should revert if same owner is included twice one after each other", async () => {
            const { template } = await setupTests();
            await (0, chai_1.expect)(template.setup([user2.address, user2.address], 2, constants_1.AddressZero, "0x", constants_1.AddressZero, constants_1.AddressZero, 0, constants_1.AddressZero)).to.be.revertedWith("GS203");
        });
        it("should revert if threshold is too high", async () => {
            const { template } = await setupTests();
            await (0, chai_1.expect)(template.setup([user1.address, user2.address, user3.address], 4, constants_1.AddressZero, "0x", constants_1.AddressZero, constants_1.AddressZero, 0, constants_1.AddressZero)).to.be.revertedWith("GS201");
        });
        it("should revert if threshold is 0", async () => {
            const { template } = await setupTests();
            await (0, chai_1.expect)(template.setup([user1.address, user2.address, user3.address], 0, constants_1.AddressZero, "0x", constants_1.AddressZero, constants_1.AddressZero, 0, constants_1.AddressZero)).to.be.revertedWith("GS202");
        });
        it("should revert if owners are empty", async () => {
            const { template } = await setupTests();
            await (0, chai_1.expect)(template.setup([], 0, constants_1.AddressZero, "0x", constants_1.AddressZero, constants_1.AddressZero, 0, constants_1.AddressZero)).to.be.revertedWith("GS202");
        });
        it("should set fallback handler and call sub inititalizer", async () => {
            const { template } = await setupTests();
            const source = `
            contract Initializer {
                function init(bytes4 data) public {
                    bytes32 slot = 0x4242424242424242424242424242424242424242424242424242424242424242;
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        sstore(slot, data)
                    }
                }
            }`;
            const testIntializer = await (0, setup_1.deployContract)(user1, source);
            const initData = testIntializer.interface.encodeFunctionData("init", ["0x42baddad"]);
            await (0, chai_1.expect)(template.setup([user1.address, user2.address, user3.address], 2, testIntializer.address, initData, constants_2.AddressOne, constants_1.AddressZero, 0, constants_1.AddressZero))
                .to.emit(template, "SafeSetup")
                .withArgs(user1.address, [user1.address, user2.address, user3.address], 2, testIntializer.address, constants_2.AddressOne);
            await (0, chai_1.expect)(await template.domainSeparator()).to.be.eq((0, execution_1.calculateSafeDomainSeparator)(template, await (0, encoding_1.chainId)()));
            await (0, chai_1.expect)(await template.getOwners()).to.be.deep.eq([user1.address, user2.address, user3.address]);
            await (0, chai_1.expect)(await template.getThreshold()).to.be.deep.eq(ethers_1.BigNumber.from(2));
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getStorageAt(template.address, "0x6c9a6c4a39284e37ed1cf53d337577d14212a4870fb976a4366c693b939918d5")).to.be.eq("0x" + "1".padStart(64, "0"));
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getStorageAt(template.address, "0x4242424242424242424242424242424242424242424242424242424242424242")).to.be.eq("0x" + "42baddad".padEnd(64, "0"));
        });
        it("should fail if sub initializer fails", async () => {
            const { template } = await setupTests();
            const source = `
            contract Initializer {
                function init(bytes4 data) public {
                    require(false, "Computer says nah");
                }
            }`;
            const testIntializer = await (0, setup_1.deployContract)(user1, source);
            const initData = testIntializer.interface.encodeFunctionData("init", ["0x42baddad"]);
            await (0, chai_1.expect)(template.setup([user1.address, user2.address, user3.address], 2, testIntializer.address, initData, constants_1.AddressZero, constants_1.AddressZero, 0, constants_1.AddressZero)).to.be.revertedWith("GS000");
        });
        it("should fail if ether payment fails", async () => {
            const { template, mock } = await setupTests();
            const payment = 133742;
            const transferData = (0, encoding_1.encodeTransfer)(user1.address, payment);
            await mock.givenCalldataRevert(transferData);
            await (0, chai_1.expect)(template.setup([user1.address, user2.address, user3.address], 2, constants_1.AddressZero, "0x", constants_1.AddressZero, constants_1.AddressZero, payment, constants_1.AddressZero)).to.be.revertedWith("GS011");
        });
        it("should work with ether payment to deployer", async () => {
            const { template } = await setupTests();
            const payment = (0, units_1.parseEther)("10");
            await user1.sendTransaction({ to: template.address, value: payment });
            const userBalance = await hardhat_1.default.ethers.provider.getBalance(user1.address);
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getBalance(template.address)).to.be.deep.eq((0, units_1.parseEther)("10"));
            await template.setup([user1.address, user2.address, user3.address], 2, constants_1.AddressZero, "0x", constants_1.AddressZero, constants_1.AddressZero, payment, constants_1.AddressZero);
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getBalance(template.address)).to.be.deep.eq((0, units_1.parseEther)("0"));
            await (0, chai_1.expect)(userBalance.lt(await hardhat_1.default.ethers.provider.getBalance(user1.address))).to.be.true;
        });
        it("should work with ether payment to account", async () => {
            const { template } = await setupTests();
            const payment = (0, units_1.parseEther)("10");
            await user1.sendTransaction({ to: template.address, value: payment });
            const userBalance = await hardhat_1.default.ethers.provider.getBalance(user2.address);
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getBalance(template.address)).to.be.deep.eq((0, units_1.parseEther)("10"));
            await template.setup([user1.address, user2.address, user3.address], 2, constants_1.AddressZero, "0x", constants_1.AddressZero, constants_1.AddressZero, payment, user2.address);
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getBalance(template.address)).to.be.deep.eq((0, units_1.parseEther)("0"));
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getBalance(user2.address)).to.be.deep.eq(userBalance.add(payment));
            await (0, chai_1.expect)(await template.getOwners()).to.be.deep.eq([user1.address, user2.address, user3.address]);
        });
        it("should fail if token payment fails", async () => {
            const { template, mock } = await setupTests();
            const payment = 133742;
            const transferData = (0, encoding_1.encodeTransfer)(user1.address, payment);
            await mock.givenCalldataRevert(transferData);
            await (0, chai_1.expect)(template.setup([user1.address, user2.address, user3.address], 2, constants_1.AddressZero, "0x", constants_1.AddressZero, mock.address, payment, constants_1.AddressZero)).to.be.revertedWith("GS012");
        });
        it("should work with token payment to deployer", async () => {
            const { template, mock } = await setupTests();
            const payment = 133742;
            const transferData = (0, encoding_1.encodeTransfer)(user1.address, payment);
            await mock.givenCalldataReturnBool(transferData, true);
            await template.setup([user1.address, user2.address, user3.address], 2, constants_1.AddressZero, "0x", constants_1.AddressZero, mock.address, payment, constants_1.AddressZero);
            (0, chai_1.expect)(await mock.callStatic.invocationCountForCalldata(transferData)).to.be.deep.equals(ethers_1.BigNumber.from(1));
            await (0, chai_1.expect)(await template.getOwners()).to.be.deep.eq([user1.address, user2.address, user3.address]);
        });
        it("should work with token payment to account", async () => {
            const { template, mock } = await setupTests();
            const payment = 133742;
            const transferData = (0, encoding_1.encodeTransfer)(user2.address, payment);
            await mock.givenCalldataReturnBool(transferData, true);
            await template.setup([user1.address, user2.address, user3.address], 2, constants_1.AddressZero, "0x", constants_1.AddressZero, mock.address, payment, user2.address);
            (0, chai_1.expect)(await mock.callStatic.invocationCountForCalldata(transferData)).to.be.deep.equals(ethers_1.BigNumber.from(1));
            await (0, chai_1.expect)(await template.getOwners()).to.be.deep.eq([user1.address, user2.address, user3.address]);
        });
        it("should revert if the initializer address does not contain code", async () => {
            const { template } = await setupTests();
            await (0, chai_1.expect)(template.setup([user1.address], 1, user2.address, "0xbeef73", constants_1.AddressZero, constants_1.AddressZero, 0, constants_1.AddressZero)).to.be.revertedWith("GS002");
        });
        it("should fail if tried to set the fallback handler address to self", async () => {
            const { template } = await setupTests();
            await (0, chai_1.expect)(template.setup([user1.address], 1, constants_1.AddressZero, "0x", template.address, constants_1.AddressZero, 0, constants_1.AddressZero)).to.be.revertedWith("GS400");
        });
    });
});
