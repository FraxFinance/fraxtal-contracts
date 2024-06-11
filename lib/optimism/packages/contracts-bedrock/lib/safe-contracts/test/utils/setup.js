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
exports.deployContract = exports.compile = exports.getSafeProxyRuntimeCode = exports.getCompatFallbackHandler = exports.getTokenCallbackHandler = exports.getSafeWithOwners = exports.getSafeTemplate = exports.getMock = exports.migrationContract = exports.getCreateCall = exports.getMultiSendCallOnly = exports.getMultiSend = exports.getSimulateTxAccessor = exports.getFactory = exports.getSafeSingleton = exports.compatFallbackHandlerContract = exports.compatFallbackHandlerDeployment = exports.defaultTokenCallbackHandlerContract = exports.defaultTokenCallbackHandlerDeployment = void 0;
const hardhat_1 = __importStar(require("hardhat"));
const ethers_1 = require("ethers");
const constants_1 = require("@ethersproject/constants");
const solc_1 = __importDefault(require("solc"));
const execution_1 = require("../../src/utils/execution");
const config_1 = require("./config");
const numbers_1 = require("./numbers");
const defaultTokenCallbackHandlerDeployment = async () => {
    return await hardhat_1.deployments.get("TokenCallbackHandler");
};
exports.defaultTokenCallbackHandlerDeployment = defaultTokenCallbackHandlerDeployment;
const defaultTokenCallbackHandlerContract = async () => {
    return await hardhat_1.default.ethers.getContractFactory("TokenCallbackHandler");
};
exports.defaultTokenCallbackHandlerContract = defaultTokenCallbackHandlerContract;
const compatFallbackHandlerDeployment = async () => {
    return await hardhat_1.deployments.get("CompatibilityFallbackHandler");
};
exports.compatFallbackHandlerDeployment = compatFallbackHandlerDeployment;
const compatFallbackHandlerContract = async () => {
    return await hardhat_1.default.ethers.getContractFactory("CompatibilityFallbackHandler");
};
exports.compatFallbackHandlerContract = compatFallbackHandlerContract;
const getSafeSingleton = async () => {
    const SafeDeployment = await hardhat_1.deployments.get((0, config_1.safeContractUnderTest)());
    const Safe = await hardhat_1.default.ethers.getContractFactory((0, config_1.safeContractUnderTest)());
    return Safe.attach(SafeDeployment.address);
};
exports.getSafeSingleton = getSafeSingleton;
const getFactory = async () => {
    const FactoryDeployment = await hardhat_1.deployments.get("SafeProxyFactory");
    const Factory = await hardhat_1.default.ethers.getContractFactory("SafeProxyFactory");
    return Factory.attach(FactoryDeployment.address);
};
exports.getFactory = getFactory;
const getSimulateTxAccessor = async () => {
    const SimulateTxAccessorDeployment = await hardhat_1.deployments.get("SimulateTxAccessor");
    const SimulateTxAccessor = await hardhat_1.default.ethers.getContractFactory("SimulateTxAccessor");
    return SimulateTxAccessor.attach(SimulateTxAccessorDeployment.address);
};
exports.getSimulateTxAccessor = getSimulateTxAccessor;
const getMultiSend = async () => {
    const MultiSendDeployment = await hardhat_1.deployments.get("MultiSend");
    const MultiSend = await hardhat_1.default.ethers.getContractFactory("MultiSend");
    return MultiSend.attach(MultiSendDeployment.address);
};
exports.getMultiSend = getMultiSend;
const getMultiSendCallOnly = async () => {
    const MultiSendDeployment = await hardhat_1.deployments.get("MultiSendCallOnly");
    const MultiSend = await hardhat_1.default.ethers.getContractFactory("MultiSendCallOnly");
    return MultiSend.attach(MultiSendDeployment.address);
};
exports.getMultiSendCallOnly = getMultiSendCallOnly;
const getCreateCall = async () => {
    const CreateCallDeployment = await hardhat_1.deployments.get("CreateCall");
    const CreateCall = await hardhat_1.default.ethers.getContractFactory("CreateCall");
    return CreateCall.attach(CreateCallDeployment.address);
};
exports.getCreateCall = getCreateCall;
const migrationContract = async () => {
    return await hardhat_1.default.ethers.getContractFactory("Migration");
};
exports.migrationContract = migrationContract;
const getMock = async () => {
    const Mock = await hardhat_1.default.ethers.getContractFactory("MockContract");
    return await Mock.deploy();
};
exports.getMock = getMock;
const getSafeTemplate = async (saltNumber = (0, numbers_1.getRandomIntAsString)()) => {
    const singleton = await (0, exports.getSafeSingleton)();
    const factory = await (0, exports.getFactory)();
    const template = await factory.callStatic.createProxyWithNonce(singleton.address, "0x", saltNumber);
    await factory.createProxyWithNonce(singleton.address, "0x", saltNumber).then((tx) => tx.wait());
    const Safe = await hardhat_1.default.ethers.getContractFactory((0, config_1.safeContractUnderTest)());
    return Safe.attach(template);
};
exports.getSafeTemplate = getSafeTemplate;
const getSafeWithOwners = async (owners, threshold, fallbackHandler, logGasUsage, saltNumber = (0, numbers_1.getRandomIntAsString)()) => {
    const template = await (0, exports.getSafeTemplate)(saltNumber);
    await (0, execution_1.logGas)(`Setup Safe with ${owners.length} owner(s)${fallbackHandler && fallbackHandler !== constants_1.AddressZero ? " and fallback handler" : ""}`, template.setup(owners, threshold || owners.length, constants_1.AddressZero, "0x", fallbackHandler || constants_1.AddressZero, constants_1.AddressZero, 0, constants_1.AddressZero), !logGasUsage);
    return template;
};
exports.getSafeWithOwners = getSafeWithOwners;
const getTokenCallbackHandler = async () => {
    return (await (0, exports.defaultTokenCallbackHandlerContract)()).attach((await (0, exports.defaultTokenCallbackHandlerDeployment)()).address);
};
exports.getTokenCallbackHandler = getTokenCallbackHandler;
const getCompatFallbackHandler = async () => {
    return (await (0, exports.compatFallbackHandlerContract)()).attach((await (0, exports.compatFallbackHandlerDeployment)()).address);
};
exports.getCompatFallbackHandler = getCompatFallbackHandler;
const getSafeProxyRuntimeCode = async () => {
    const proxyArtifact = await hardhat_1.default.artifacts.readArtifact("SafeProxy");
    return proxyArtifact.deployedBytecode;
};
exports.getSafeProxyRuntimeCode = getSafeProxyRuntimeCode;
const compile = async (source) => {
    const input = JSON.stringify({
        language: "Solidity",
        settings: {
            outputSelection: {
                "*": {
                    "*": ["abi", "evm.bytecode"],
                },
            },
        },
        sources: {
            "tmp.sol": {
                content: source,
            },
        },
    });
    const solcData = await solc_1.default.compile(input);
    const output = JSON.parse(solcData);
    if (!output["contracts"]) {
        console.log(output);
        throw Error("Could not compile contract");
    }
    const fileOutput = output["contracts"]["tmp.sol"];
    const contractOutput = fileOutput[Object.keys(fileOutput)[0]];
    const abi = contractOutput["abi"];
    const data = "0x" + contractOutput["evm"]["bytecode"]["object"];
    return {
        data: data,
        interface: abi,
    };
};
exports.compile = compile;
const deployContract = async (deployer, source) => {
    const output = await (0, exports.compile)(source);
    const transaction = await deployer.sendTransaction({ data: output.data, gasLimit: 6000000 });
    const receipt = await transaction.wait();
    return new ethers_1.Contract(receipt.contractAddress, output.interface, deployer);
};
exports.deployContract = deployContract;
