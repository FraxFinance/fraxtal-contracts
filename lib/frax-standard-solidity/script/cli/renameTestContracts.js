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
const fs = __importStar(require("fs/promises"));
const path = __importStar(require("path"));
async function renameSolidity(filePath) {
    const fileExtension = path.basename(filePath).match(/\..*/)?.[0];
    const fileName = path.basename(filePath).replace(fileExtension, "");
    // console.log("file: rename.ts:6 ~ renameSolidity ~ fileName:", fileName);
    // console.log("file: rename.ts:8 ~ renameSolidity ~ fileExtension:", fileExtension);
    const fileContents = (await fs.readFile(filePath, "utf8")).toString();
    const replace = `contract Test${fileName.replace("Test", "")}`;
    const find = fileContents.match(/contract [a-zA-Z0-9_]+/)?.[0];
    // console.log("file: rename.ts:12 ~ renameSolidity ~ replace:", replace);
    // console.log("file: rename.ts:12 ~ renameSolidity ~ find:", find);
    const newFileContents = fileContents.replace(find, replace);
    await fs.writeFile(filePath, newFileContents, "utf8");
    // console.log("file: rename.ts:12 ~ renameSolidity ~ replace:", replace);
}
const args = process.argv.slice(2);
args.forEach(renameSolidity);
