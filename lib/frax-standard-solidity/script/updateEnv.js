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
const date_fns_1 = require("date-fns");
const fs = __importStar(require("fs-extra"));
const path_1 = __importDefault(require("path"));
const DEPLOYMENTS_PATH = path_1.default.resolve("deployments");
const METADATA_PATH = path_1.default.resolve("out");
const chainToNetwork = {
    1: "mainnet",
};
const main = async () => {
    const args = process.argv.slice(2);
    const chainId = args[0];
    const contractName = args[1];
    const contractAddress = args[2];
    const constructorArguments = args[3];
    if (!fs.existsSync(DEPLOYMENTS_PATH))
        fs.mkdirSync(DEPLOYMENTS_PATH);
    const networkName = chainToNetwork[chainId];
    const networkDirPath = path_1.default.resolve(DEPLOYMENTS_PATH, networkName);
    if (!fs.existsSync(networkDirPath)) {
        fs.mkdirSync(networkDirPath);
        const chainIdFilePath = path_1.default.resolve(networkDirPath, ".chainId");
        fs.writeFileSync(chainIdFilePath, chainId.toString());
    }
    const metadataPath = path_1.default.resolve(METADATA_PATH, contractName + ".sol", contractName + ".json");
    const metadata = JSON.parse(fs.readFileSync(metadataPath, "utf8"));
    const outputData = {
        abi: metadata.abi,
        bytecode: metadata.bytecode,
        deployedBytecode: metadata.deployedBytecode,
        metadata: metadata.metadata,
        address: contractAddress,
        constructorArgs: constructorArguments,
    };
    const outputString = JSON.stringify(outputData, null, 2);
    const latestFilePath = path_1.default.resolve(networkDirPath, contractName + ".json");
    void (await Promise.all([
        fs.promises.writeFile(latestFilePath, outputString),
        (() => {
            const newDeploymentPath = path_1.default.resolve(networkDirPath, (0, date_fns_1.format)(Date.now(), "yyyyMMdd_HH.mm.ss"));
            const thisDeploymentFilePath = path_1.default.resolve(newDeploymentPath, contractName + ".json");
            if (!["hardhat", "localhost"].includes(networkName)) {
                if (!fs.existsSync(newDeploymentPath))
                    fs.mkdirSync(newDeploymentPath);
                return fs.promises.writeFile(thisDeploymentFilePath, outputString);
            }
        })(),
    ]));
};
void main();
