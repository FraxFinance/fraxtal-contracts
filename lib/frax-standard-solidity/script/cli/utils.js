"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.newGetAbi = exports.isDynamicType = exports.getHelperDirectory = exports.getOutDirectory = exports.getAbi = exports.getAbiFromPath = exports.getAbiFromFile = exports.getAbiWithName = exports.getOutFileFromSourcePath = exports.getFileContractNames = exports.getFilesFromFraxToml = void 0;
const path_1 = __importDefault(require("path"));
const fs_1 = __importDefault(require("fs"));
const toml_1 = __importDefault(require("toml"));
const glob_1 = require("glob");
const child_process_1 = require("child_process");
const getFilesFromFraxToml = () => {
    const fraxConfig = parseFraxToml();
    const files = fraxConfig.files;
    return files;
};
exports.getFilesFromFraxToml = getFilesFromFraxToml;
const getFileContractNames = (fileContents) => {
    const contractNames = [];
    const contractRegex = /contract\s+(\w+)/g;
    let match = contractRegex.exec(fileContents);
    while (match) {
        contractNames.push(match[1]);
        match = contractRegex.exec(fileContents);
    }
    return contractNames;
};
exports.getFileContractNames = getFileContractNames;
const getOutFileFromSourcePath = (sourcePath) => {
    const fileName = path_1.default.basename(sourcePath);
    const fileContents = fs_1.default.readFileSync(sourcePath).toString();
    const contractNames = (0, exports.getFileContractNames)(fileContents);
    const outDirectory = (0, exports.getOutDirectory)();
    const abiFilePaths = contractNames.map((contractName) => path_1.default.join(outDirectory, fileName, `${contractName}.json`));
    return abiFilePaths;
};
exports.getOutFileFromSourcePath = getOutFileFromSourcePath;
const getAbiWithName = async (name) => {
    const outDirectory = (0, exports.getOutDirectory)();
    const abiFilePaths = await (0, glob_1.glob)(`${outDirectory}/**/${name}.json`);
    if (abiFilePaths.length === 0) {
        throw new Error(`No abi file found for ${name}`);
    }
    else if (abiFilePaths.length > 1) {
        throw new Error(`Multiple abi files found for ${name}`);
    }
    const abi = (0, exports.getAbiFromFile)(abiFilePaths[0]);
    return abi;
};
exports.getAbiWithName = getAbiWithName;
const getAbiFromFile = (abiPath) => {
    let abi = JSON.parse(fs_1.default.readFileSync(abiPath).toString());
    if (Object.keys(abi).includes("abi")) {
        abi = abi.abi;
    }
    return abi;
};
exports.getAbiFromFile = getAbiFromFile;
const getAbiFromPath = (abiPath) => {
    const abi = (0, exports.getAbiFromFile)(abiPath);
    return abi;
};
exports.getAbiFromPath = getAbiFromPath;
const getAbi = (abiPath) => {
    if (!abiPath.includes("/")) {
        const outDirectory = (0, exports.getOutDirectory)();
        abiPath = path_1.default.join(outDirectory, abiPath + ".sol", `${abiPath}.json`);
    }
    else {
        abiPath = path_1.default.resolve(abiPath);
    }
    let abi = JSON.parse(fs_1.default.readFileSync(abiPath).toString());
    if (Object.keys(abi).includes("abi")) {
        abi = abi.abi;
    }
    return abi;
};
exports.getAbi = getAbi;
const parseFoundryToml = () => {
    const foundryTomlPath = path_1.default.resolve("foundry.toml");
    const foundryConfigString = fs_1.default.readFileSync(foundryTomlPath, "utf-8").toString();
    const foundryConfig = toml_1.default.parse(foundryConfigString);
    return foundryConfig;
};
const getOutDirectory = () => {
    const foundryConfig = parseFoundryToml();
    const outValue = foundryConfig.profile.default.out;
    const outDirectory = path_1.default.resolve(outValue);
    return outDirectory;
};
exports.getOutDirectory = getOutDirectory;
const parseFraxToml = () => {
    const fraxTomlPath = path_1.default.resolve("frax.toml");
    const fraxConfigString = fs_1.default.readFileSync(fraxTomlPath, "utf-8").toString();
    const fraxConfig = toml_1.default.parse(fraxConfigString);
    return fraxConfig;
};
const getHelperDirectory = () => {
    const fraxConfig = parseFraxToml();
    const helperValue = fraxConfig.helper_dir;
    const helperDirectory = path_1.default.resolve(helperValue);
    return helperDirectory;
};
exports.getHelperDirectory = getHelperDirectory;
const isDynamicType = (internalType) => {
    if (internalType.includes("[")) {
        return true;
    }
    if (internalType === "bytes") {
        return true;
    }
    if (internalType.includes("struct")) {
        return true;
    }
    if (internalType.includes("contract")) {
        return true;
    }
    if (internalType.includes("string")) {
        return true;
    }
    return false;
};
exports.isDynamicType = isDynamicType;
const newGetAbi = async (filePath) => {
    const contractBasename = path_1.default.basename(filePath);
    const input = {
        language: "Solidity",
        sources: {
            [filePath]: {
                urls: [filePath],
            },
        },
        settings: {
            remappings: remappingsToArray(),
            metadata: {
                bytecodeHash: "none",
                appendCBOR: true,
            },
            outputSelection: {
                [filePath]: {
                    "*": ["abi"],
                },
            },
            evmVersion: "london",
            libraries: {},
        },
    };
    const fileName = `${Date.now().toString()}${contractBasename}${Math.random()}.json`;
    fs_1.default.writeFileSync(fileName, JSON.stringify(input));
    const command = `solc --pretty-json ${getIncludeSources()
        .map((item) => "--include-path " + item)
        .join(" ")} --base-path . --standard-json ${fileName}`;
    const output = (0, child_process_1.execSync)(command).toString();
    fs_1.default.unlink(fileName, () => { });
    const parsed = JSON.parse(output);
    delete parsed.sources;
    return parsed.contracts[filePath];
};
exports.newGetAbi = newGetAbi;
const remappingsToArray = () => {
    const contents = fs_1.default.readFileSync("remappings.txt").toString();
    const lines = contents.split("\n").filter(Boolean);
    return lines;
};
const getIncludeSources = () => {
    const foundryConfig = parseFoundryToml();
    const includeSources = foundryConfig.profile.default.libs;
    return includeSources;
};
function importCallbackGenerator(includeSources) {
    return function readFileCallback(sourcePath) {
        const prefixes = includeSources;
        for (const prefix of prefixes) {
            const prefixedSourcePath = (prefix ? prefix + "/" : "") + sourcePath;
            if (fs_1.default.existsSync(prefixedSourcePath)) {
                try {
                    return { contents: fs_1.default.readFileSync(prefixedSourcePath).toString("utf8") };
                }
                catch (e) {
                    return { error: "Error reading " + prefixedSourcePath + ": " + e };
                }
            }
        }
        return { error: "File not found inside the base path or any of the include paths." };
    };
}
