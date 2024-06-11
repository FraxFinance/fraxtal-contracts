"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const fs_1 = __importDefault(require("fs"));
const path_1 = __importDefault(require("path"));
const outdir = process.argv[2] || path_1.default.join(__dirname, '..', 'snapshots');
const forgeArtifactsDir = path_1.default.join(__dirname, '..', 'forge-artifacts');
const getAllContractsSources = () => {
    const paths = [];
    const readFilesRecursively = (dir) => {
        const files = fs_1.default.readdirSync(dir);
        for (const file of files) {
            const filePath = path_1.default.join(dir, file);
            const fileStat = fs_1.default.statSync(filePath);
            if (fileStat.isDirectory()) {
                readFilesRecursively(filePath);
            }
            else {
                paths.push(filePath);
            }
        }
    };
    readFilesRecursively(path_1.default.join(__dirname, '..', 'src'));
    return paths
        .filter((x) => x.endsWith('.sol'))
        .map((p) => path_1.default.basename(p))
        .sort();
};
const sortKeys = (obj) => {
    if (typeof obj !== 'object' || obj === null) {
        return obj;
    }
    return Object.keys(obj)
        .sort()
        .reduce((acc, key) => {
        acc[key] = sortKeys(obj[key]);
        return acc;
    }, Array.isArray(obj) ? [] : {});
};
// ContractName.0.9.8.json -> ContractName.sol
// ContractName.json -> ContractName.sol
const parseArtifactName = (artifactVersionFile) => {
    const match = artifactVersionFile.match(/(.*?)\.([0-9]+\.[0-9]+\.[0-9]+)?/);
    if (!match) {
        throw new Error(`Invalid artifact file name: ${artifactVersionFile}`);
    }
    return match[1];
};
const main = async () => {
    console.log(`writing abi and storage layout snapshots to ${outdir}`);
    const storageLayoutDir = path_1.default.join(outdir, 'storageLayout');
    const abiDir = path_1.default.join(outdir, 'abi');
    fs_1.default.mkdirSync(storageLayoutDir, { recursive: true });
    fs_1.default.mkdirSync(abiDir, { recursive: true });
    const contractSources = getAllContractsSources();
    const knownAbis = {};
    for (const contractFile of contractSources) {
        const contractArtifacts = path_1.default.join(forgeArtifactsDir, contractFile);
        for (const name of fs_1.default.readdirSync(contractArtifacts)) {
            const data = fs_1.default.readFileSync(path_1.default.join(contractArtifacts, name));
            const artifact = JSON.parse(data.toString());
            const contractName = parseArtifactName(name);
            // HACK: This is a hack to ignore libraries and abstract contracts. Not robust against changes to solc's internal ast repr
            const isContract = artifact.ast.nodes.some((node) => {
                return (node.nodeType === 'ContractDefinition' &&
                    node.name === contractName &&
                    node.contractKind === 'contract' &&
                    (node.abstract === undefined || // solc < 0.6 doesn't have explicit abstract contracts
                        node.abstract === false));
            });
            if (!isContract) {
                console.log(`ignoring library/interface ${contractName}`);
                continue;
            }
            const storageLayout = [];
            for (const storageEntry of artifact.storageLayout.storage) {
                // convert ast-based type to solidity type
                const typ = artifact.storageLayout.types[storageEntry.type];
                if (typ === undefined) {
                    throw new Error(`undefined type for ${contractName}:${storageEntry.label}`);
                }
                storageLayout.push({
                    label: storageEntry.label,
                    bytes: typ.numberOfBytes,
                    offset: storageEntry.offset,
                    slot: storageEntry.slot,
                    type: typ.label,
                });
            }
            if (knownAbis[contractName] === undefined) {
                knownAbis[contractName] = artifact.abi;
            }
            else if (JSON.stringify(knownAbis[contractName]) !== JSON.stringify(artifact.abi)) {
                throw Error(`detected multiple artifact versions with different ABIs for ${contractFile}`);
            }
            else {
                console.log(`detected multiple artifacts for ${contractName}`);
            }
            // Sort snapshots for easier manual inspection
            fs_1.default.writeFileSync(`${abiDir}/${contractName}.json`, JSON.stringify(sortKeys(artifact.abi), null, 2));
            fs_1.default.writeFileSync(`${storageLayoutDir}/${contractName}.json`, JSON.stringify(sortKeys(storageLayout), null, 2));
        }
    }
};
main();
