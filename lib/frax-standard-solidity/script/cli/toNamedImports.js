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
exports.toNamedImports = exports.renameFileImports = void 0;
const fs = __importStar(require("fs/promises"));
const path = __importStar(require("path"));
async function renameFileImports(filePath) {
    filePath = path.resolve(filePath);
    if (!(await fs.lstat(filePath)).isFile())
        return;
    const fileContents = (await fs.readFile(path.resolve(filePath), "utf8")).toString();
    const importStatements = fileContents.match(/import\s+".*;/g)?.filter((item) => {
        return !item.includes("forge-std") && !item.includes("frax-std");
    }) ?? [];
    const entries = importStatements.map((statement) => {
        const matches = statement.match(/\/([a-zA-Z0-9_]+)\./g);
        const name = matches?.[matches.length - 1].match(/[a-zA-Z0-9_]+/)?.[0];
        const path = statement.match(/".*?";/)?.[0];
        const replace = `import { ${name} } from ${path}`;
        return { original: statement, name, path, replace };
    });
    const newFileContents = entries.reduce((acc, entry) => {
        return acc.replace(entry.original, entry.replace);
    }, fileContents);
    fs.writeFile(filePath, newFileContents, "utf8");
}
exports.renameFileImports = renameFileImports;
async function toNamedImports(filePaths) {
    filePaths.forEach(renameFileImports);
}
exports.toNamedImports = toNamedImports;
