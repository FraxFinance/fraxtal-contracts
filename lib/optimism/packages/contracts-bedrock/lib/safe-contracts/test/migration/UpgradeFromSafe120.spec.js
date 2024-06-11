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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const chai_1 = require("chai");
const hardhat_1 = __importStar(require("hardhat"));
require("@nomiclabs/hardhat-ethers");
const constants_1 = require("@ethersproject/constants");
const setup_1 = require("../utils/setup");
const execution_1 = require("../../src/utils/execution");
const subTests_spec_1 = require("./subTests.spec");
const safeDeployment_json_1 = __importDefault(require("../json/safeDeployment.json"));
const proxies_1 = require("../../src/utils/proxies");
describe("Upgrade from Safe 1.2.0", () => {
    const [user1] = hardhat_1.waffle.provider.getWallets();
    const ChangeMasterCopyInterface = new hardhat_1.ethers.utils.Interface(["function changeMasterCopy(address target)"]);
    // We migrate the Safe and run the verification tests
    const setupTests = hardhat_1.deployments.createFixture(async ({ deployments }) => {
        await deployments.fixture();
        const mock = await (0, setup_1.getMock)();
        const singleton120 = (await (await user1.sendTransaction({ data: safeDeployment_json_1.default.safe120 })).wait()).contractAddress;
        const singleton140 = (await (0, setup_1.getSafeSingleton)()).address;
        const factory = await (0, setup_1.getFactory)();
        const saltNonce = 42;
        const proxyAddress = await (0, proxies_1.calculateProxyAddress)(factory, singleton120, "0x", saltNonce);
        await factory.createProxyWithNonce(singleton120, "0x", saltNonce).then((tx) => tx.wait());
        const Safe = await hardhat_1.default.ethers.getContractFactory("Safe");
        const safe = Safe.attach(proxyAddress);
        await safe.setup([user1.address], 1, constants_1.AddressZero, "0x", mock.address, constants_1.AddressZero, 0, constants_1.AddressZero);
        (0, chai_1.expect)(await safe.VERSION()).to.be.eq("1.2.0");
        const nonce = await safe.callStatic.nonce();
        const data = ChangeMasterCopyInterface.encodeFunctionData("changeMasterCopy", [singleton140]);
        const tx = (0, execution_1.buildSafeTransaction)({ to: safe.address, data, nonce });
        await (0, execution_1.executeTx)(safe, tx, [await (0, execution_1.safeApproveHash)(user1, safe, tx, true)]);
        (0, chai_1.expect)(await safe.VERSION()).to.be.eq("1.4.0");
        return {
            migratedSafe: safe,
            mock,
            multiSend: await (0, setup_1.getMultiSend)(),
        };
    });
    (0, subTests_spec_1.verificationTests)(setupTests);
});
