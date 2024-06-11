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
const constants_1 = require("@ethersproject/constants");
const ethers_1 = require("ethers");
const proxies_1 = require("../../src/utils/proxies");
const encoding_1 = require("./../utils/encoding");
describe("ProxyFactory", async () => {
    const SINGLETON_SOURCE = `
    contract Test {
        address _singleton;
        address public creator;
        bool public isInitialized;
        constructor() payable {
            creator = msg.sender;
        }

        function init() public {
            require(!isInitialized, "Is initialized");
            creator = msg.sender;
            isInitialized = true;
        }

        function masterCopy() public pure returns (address) {
            return address(0);
        }

        function forward(address to, bytes memory data) public returns (bytes memory result) {
            (,result) = to.call(data);
        }
    }`;
    const [user1] = hardhat_1.waffle.provider.getWallets();
    const setupTests = hardhat_1.deployments.createFixture(async ({ deployments }) => {
        await deployments.fixture();
        const singleton = await (0, setup_1.deployContract)(user1, SINGLETON_SOURCE);
        return {
            safe: await (0, setup_1.getSafeWithOwners)([user1.address]),
            factory: await (0, setup_1.getFactory)(),
            mock: await (0, setup_1.getMock)(),
            singleton,
        };
    });
    describe("createProxyWithNonce", async () => {
        const saltNonce = 42;
        it("should revert if singleton address is not a contract", async () => {
            const { factory } = await setupTests();
            const randomAddress = hardhat_1.ethers.utils.getAddress(hardhat_1.ethers.utils.hexlify(hardhat_1.ethers.utils.randomBytes(20)));
            await (0, chai_1.expect)(factory.createProxyWithNonce(randomAddress, "0x", saltNonce)).to.be.revertedWith("Singleton contract not deployed");
        });
        it("should revert with invalid initializer", async () => {
            const { factory, singleton } = await setupTests();
            await (0, chai_1.expect)(factory.createProxyWithNonce(singleton.address, "0x42baddad", saltNonce)).to.be.revertedWith("Transaction reverted without a reason");
        });
        it("should emit event without initializing", async () => {
            const { factory, singleton } = await setupTests();
            const initCode = "0x";
            const proxyAddress = await (0, proxies_1.calculateProxyAddress)(factory, singleton.address, initCode, saltNonce);
            await (0, chai_1.expect)(factory.createProxyWithNonce(singleton.address, initCode, saltNonce))
                .to.emit(factory, "ProxyCreation")
                .withArgs(proxyAddress, singleton.address);
            const proxy = singleton.attach(proxyAddress);
            (0, chai_1.expect)(await proxy.creator()).to.be.eq(constants_1.AddressZero);
            (0, chai_1.expect)(await proxy.isInitialized()).to.be.eq(false);
            (0, chai_1.expect)(await proxy.masterCopy()).to.be.eq(singleton.address);
            (0, chai_1.expect)(await singleton.masterCopy()).to.be.eq(constants_1.AddressZero);
            (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getCode(proxyAddress)).to.be.eq(await (0, setup_1.getSafeProxyRuntimeCode)());
        });
        it("should emit event with initializing", async () => {
            const { factory, singleton } = await setupTests();
            const initCode = singleton.interface.encodeFunctionData("init", []);
            const proxyAddress = await (0, proxies_1.calculateProxyAddress)(factory, singleton.address, initCode, saltNonce);
            await (0, chai_1.expect)(factory.createProxyWithNonce(singleton.address, initCode, saltNonce))
                .to.emit(factory, "ProxyCreation")
                .withArgs(proxyAddress, singleton.address);
            const proxy = singleton.attach(proxyAddress);
            (0, chai_1.expect)(await proxy.creator()).to.be.eq(factory.address);
            (0, chai_1.expect)(await proxy.isInitialized()).to.be.eq(true);
            (0, chai_1.expect)(await proxy.masterCopy()).to.be.eq(singleton.address);
            (0, chai_1.expect)(await singleton.masterCopy()).to.be.eq(constants_1.AddressZero);
            (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getCode(proxyAddress)).to.be.eq(await (0, setup_1.getSafeProxyRuntimeCode)());
        });
        it("should not be able to deploy same proxy twice", async () => {
            const { factory, singleton } = await setupTests();
            const initCode = singleton.interface.encodeFunctionData("init", []);
            const proxyAddress = await (0, proxies_1.calculateProxyAddress)(factory, singleton.address, initCode, saltNonce);
            await (0, chai_1.expect)(factory.createProxyWithNonce(singleton.address, initCode, saltNonce))
                .to.emit(factory, "ProxyCreation")
                .withArgs(proxyAddress, singleton.address);
            await (0, chai_1.expect)(factory.createProxyWithNonce(singleton.address, initCode, saltNonce)).to.be.revertedWith("Create2 call failed");
        });
    });
    describe("createChainSpecificProxyWithNonce", async () => {
        const saltNonce = 42;
        it("should revert if singleton address is not a contract", async () => {
            const { factory } = await setupTests();
            await (0, chai_1.expect)(factory.createProxyWithNonce(constants_1.AddressZero, "0x", saltNonce)).to.be.revertedWith("Singleton contract not deployed");
        });
        it("should revert with invalid initializer", async () => {
            const { factory, singleton } = await setupTests();
            await (0, chai_1.expect)(factory.createProxyWithNonce(singleton.address, "0x42baddad", saltNonce)).to.be.revertedWith("Transaction reverted without a reason");
        });
        it("should emit event without initializing", async () => {
            const { factory, singleton } = await setupTests();
            const initCode = "0x";
            const proxyAddress = await (0, proxies_1.calculateProxyAddress)(factory, singleton.address, initCode, saltNonce);
            await (0, chai_1.expect)(factory.createProxyWithNonce(singleton.address, initCode, saltNonce))
                .to.emit(factory, "ProxyCreation")
                .withArgs(proxyAddress, singleton.address);
            const proxy = singleton.attach(proxyAddress);
            (0, chai_1.expect)(await proxy.creator()).to.be.eq(constants_1.AddressZero);
            (0, chai_1.expect)(await proxy.isInitialized()).to.be.eq(false);
            (0, chai_1.expect)(await proxy.masterCopy()).to.be.eq(singleton.address);
            (0, chai_1.expect)(await singleton.masterCopy()).to.be.eq(constants_1.AddressZero);
            (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getCode(proxyAddress)).to.be.eq(await (0, setup_1.getSafeProxyRuntimeCode)());
        });
        it("should emit event with initializing", async () => {
            const { factory, singleton } = await setupTests();
            const initCode = singleton.interface.encodeFunctionData("init", []);
            const proxyAddress = await (0, proxies_1.calculateProxyAddress)(factory, singleton.address, initCode, saltNonce);
            await (0, chai_1.expect)(factory.createProxyWithNonce(singleton.address, initCode, saltNonce))
                .to.emit(factory, "ProxyCreation")
                .withArgs(proxyAddress, singleton.address);
            const proxy = singleton.attach(proxyAddress);
            (0, chai_1.expect)(await proxy.creator()).to.be.eq(factory.address);
            (0, chai_1.expect)(await proxy.isInitialized()).to.be.eq(true);
            (0, chai_1.expect)(await proxy.masterCopy()).to.be.eq(singleton.address);
            (0, chai_1.expect)(await singleton.masterCopy()).to.be.eq(constants_1.AddressZero);
            (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getCode(proxyAddress)).to.be.eq(await (0, setup_1.getSafeProxyRuntimeCode)());
        });
        it("should deploy proxy to create2 address with chainid included in salt", async () => {
            const { factory, singleton } = await setupTests();
            const provider = hardhat_1.default.ethers.provider;
            const initCode = singleton.interface.encodeFunctionData("init", []);
            const proxyAddress = await (0, proxies_1.calculateChainSpecificProxyAddress)(factory, singleton.address, initCode, saltNonce, await (0, encoding_1.chainId)());
            (0, chai_1.expect)(await provider.getCode(proxyAddress)).to.eq("0x");
            await factory.createChainSpecificProxyWithNonce(singleton.address, initCode, saltNonce);
            (0, chai_1.expect)(await provider.getCode(proxyAddress)).to.be.eq(await (0, setup_1.getSafeProxyRuntimeCode)());
        });
        it("should not be able to deploy same proxy twice", async () => {
            const { factory, singleton } = await setupTests();
            const initCode = singleton.interface.encodeFunctionData("init", []);
            const proxyAddress = await (0, proxies_1.calculateProxyAddress)(factory, singleton.address, initCode, saltNonce);
            await (0, chai_1.expect)(factory.createProxyWithNonce(singleton.address, initCode, saltNonce))
                .to.emit(factory, "ProxyCreation")
                .withArgs(proxyAddress, singleton.address);
            await (0, chai_1.expect)(factory.createProxyWithNonce(singleton.address, initCode, saltNonce)).to.be.revertedWith("Create2 call failed");
        });
    });
    describe("createProxyWithCallback", async () => {
        const saltNonce = 42;
        it("check callback is invoked", async () => {
            const { factory, mock, singleton } = await setupTests();
            const callback = await hardhat_1.default.ethers.getContractAt("IProxyCreationCallback", mock.address);
            const initCode = singleton.interface.encodeFunctionData("init", []);
            const proxyAddress = await (0, proxies_1.calculateProxyAddressWithCallback)(factory, singleton.address, initCode, saltNonce, mock.address);
            await (0, chai_1.expect)(factory.createProxyWithCallback(singleton.address, initCode, saltNonce, mock.address))
                .to.emit(factory, "ProxyCreation")
                .withArgs(proxyAddress, singleton.address);
            (0, chai_1.expect)(await mock.callStatic.invocationCount()).to.be.deep.equal(ethers_1.BigNumber.from(1));
            const callbackData = callback.interface.encodeFunctionData("proxyCreated", [
                proxyAddress,
                factory.address,
                initCode,
                saltNonce,
            ]);
            (0, chai_1.expect)(await mock.callStatic.invocationCountForMethod(callbackData)).to.be.deep.equal(ethers_1.BigNumber.from(1));
        });
        it("check callback error cancels deployment", async () => {
            const { factory, mock, singleton } = await setupTests();
            const initCode = "0x";
            await mock.givenAnyRevert();
            await (0, chai_1.expect)(factory.createProxyWithCallback(singleton.address, initCode, saltNonce, mock.address), "Should fail if callback fails").to.be.reverted;
            await mock.reset();
            // Should be successfull now
            const proxyAddress = await (0, proxies_1.calculateProxyAddressWithCallback)(factory, singleton.address, initCode, saltNonce, mock.address);
            await (0, chai_1.expect)(factory.createProxyWithCallback(singleton.address, initCode, saltNonce, mock.address))
                .to.emit(factory, "ProxyCreation")
                .withArgs(proxyAddress, singleton.address);
        });
        it("should work without callback", async () => {
            const { factory, singleton } = await setupTests();
            const initCode = "0x";
            const proxyAddress = await (0, proxies_1.calculateProxyAddressWithCallback)(factory, singleton.address, initCode, saltNonce, constants_1.AddressZero);
            await (0, chai_1.expect)(factory.createProxyWithCallback(singleton.address, initCode, saltNonce, constants_1.AddressZero))
                .to.emit(factory, "ProxyCreation")
                .withArgs(proxyAddress, singleton.address);
            const proxy = singleton.attach(proxyAddress);
            (0, chai_1.expect)(await proxy.creator()).to.be.eq(constants_1.AddressZero);
            (0, chai_1.expect)(await proxy.isInitialized()).to.be.eq(false);
            (0, chai_1.expect)(await proxy.masterCopy()).to.be.eq(singleton.address);
            (0, chai_1.expect)(await singleton.masterCopy()).to.be.eq(constants_1.AddressZero);
            (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getCode(proxyAddress)).to.be.eq(await (0, setup_1.getSafeProxyRuntimeCode)());
        });
    });
});
