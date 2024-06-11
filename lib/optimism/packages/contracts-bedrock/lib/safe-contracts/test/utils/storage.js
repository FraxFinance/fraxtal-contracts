"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getContractStorageLayout = void 0;
const fs_1 = __importDefault(require("fs"));
const getContractStorageLayout = async (hre, smartContractName) => {
    const { sourceName, contractName } = await hre.artifacts.readArtifact(smartContractName);
    const stateVariables = [];
    for (const artifactPath of await hre.artifacts.getBuildInfoPaths()) {
        const artifact = fs_1.default.readFileSync(artifactPath);
        const artifactJsonABI = JSON.parse(artifact.toString());
        const artifactIncludesStorageLayout = artifactJsonABI?.output?.contracts?.[sourceName]?.[contractName]?.storageLayout;
        if (!artifactIncludesStorageLayout) {
            continue;
        }
        const contractStateVariablesFromArtifact = artifactJsonABI.output.contracts[sourceName][contractName].storageLayout.storage;
        for (const stateVariable of contractStateVariablesFromArtifact) {
            stateVariables.push({
                name: stateVariable.label,
                slot: stateVariable.slot,
                offset: stateVariable.offset,
                type: stateVariable.type,
            });
        }
        // The same contract can be present in multiple artifacts; thus we break if we already got
        // storage layout once
        break;
    }
    return stateVariables;
};
exports.getContractStorageLayout = getContractStorageLayout;
