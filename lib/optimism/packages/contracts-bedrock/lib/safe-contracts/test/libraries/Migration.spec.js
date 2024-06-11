"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const chai_1 = require("chai");
const hardhat_1 = require("hardhat");
require("@nomiclabs/hardhat-ethers");
const constants_1 = require("@ethersproject/constants");
const setup_1 = require("../utils/setup");
const safeDeployment_json_1 = __importDefault(require("../json/safeDeployment.json"));
const execution_1 = require("../../src/utils/execution");
describe("Migration", async () => {
    const MigratedInterface = new hardhat_1.ethers.utils.Interface([
        "function domainSeparator() view returns(bytes32)",
        "function masterCopy() view returns(address)",
    ]);
    const [user1, user2] = hardhat_1.waffle.provider.getWallets();
    const setupTests = hardhat_1.deployments.createFixture(async ({ deployments }) => {
        await deployments.fixture();
        const singleton120 = (await (await user1.sendTransaction({ data: safeDeployment_json_1.default.safe120 })).wait()).contractAddress;
        const migration = await (await (0, setup_1.migrationContract)()).deploy(singleton120);
        return {
            singleton: await (0, setup_1.getSafeSingleton)(),
            singleton120,
            safe: await (0, setup_1.getSafeWithOwners)([user1.address]),
            migration,
        };
    });
    describe("constructor", async () => {
        it("can not use 0 Address", async () => {
            await setupTests();
            const tx = (await (0, setup_1.migrationContract)()).getDeployTransaction(constants_1.AddressZero);
            await (0, chai_1.expect)(user1.sendTransaction(tx)).to.be.revertedWith("Invalid singleton address provided");
        });
    });
    describe("migrate", async () => {
        it("can only be called from Safe itself", async () => {
            const { migration } = await setupTests();
            await (0, chai_1.expect)(migration.migrate()).to.be.revertedWith("Migration should only be called via delegatecall");
        });
        it("can migrate", async () => {
            const { safe, migration, singleton120 } = await setupTests();
            // The emit matcher checks the address, which is the Safe as delegatecall is used
            const migrationSafe = migration.attach(safe.address);
            await (0, chai_1.expect)(await hardhat_1.ethers.provider.getStorageAt(safe.address, "0x" + "".padEnd(62, "0") + "06")).to.be.eq("0x" + "".padEnd(64, "0"));
            await (0, chai_1.expect)((0, execution_1.executeContractCallWithSigners)(safe, migration, "migrate", [], [user1], true))
                .to.emit(migrationSafe, "ChangedMasterCopy")
                .withArgs(singleton120);
            const expectedDomainSeparator = hardhat_1.ethers.utils._TypedDataEncoder.hashDomain({ verifyingContract: safe.address });
            await (0, chai_1.expect)(await hardhat_1.ethers.provider.getStorageAt(safe.address, "0x06")).to.be.eq(expectedDomainSeparator);
            const respData = await user1.call({ to: safe.address, data: MigratedInterface.encodeFunctionData("domainSeparator") });
            await (0, chai_1.expect)(MigratedInterface.decodeFunctionResult("domainSeparator", respData)[0]).to.be.eq(expectedDomainSeparator);
            const masterCopyResp = await user1.call({ to: safe.address, data: MigratedInterface.encodeFunctionData("masterCopy") });
            await (0, chai_1.expect)(MigratedInterface.decodeFunctionResult("masterCopy", masterCopyResp)[0]).to.be.eq(singleton120);
        });
    });
});
