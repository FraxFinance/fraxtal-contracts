"use strict";
var __createBinding =
  (this && this.__createBinding) ||
  (Object.create
    ? function (o, m, k, k2) {
        if (k2 === undefined) k2 = k;
        Object.defineProperty(o, k2, {
          enumerable: true,
          get: function () {
            return m[k];
          },
        });
      }
    : function (o, m, k, k2) {
        if (k2 === undefined) k2 = k;
        o[k2] = m[k];
      });
var __setModuleDefault =
  (this && this.__setModuleDefault) ||
  (Object.create
    ? function (o, v) {
        Object.defineProperty(o, "default", { enumerable: true, value: v });
      }
    : function (o, v) {
        o["default"] = v;
      });
var __importStar =
  (this && this.__importStar) ||
  function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null)
      for (var k in mod)
        if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
  };
var __importDefault =
  (this && this.__importDefault) ||
  function (mod) {
    return mod && mod.__esModule ? mod : { default: mod };
  };
Object.defineProperty(exports, "__esModule", { value: true });
const fs = __importStar(require("fs/promises"));
const path_1 = __importDefault(require("path"));
const constants = __importStar(require("./constants"));
async function main() {
  const networks = Object.keys(constants);
  const outputStringsPromises = networks.map((networkName) => {
    return handleSingleNetwork(networkName, constants[networkName]);
  });
  const outputStrings = await Promise.all(outputStringsPromises);
  const finalString =
    `// SPDX-License-Identifier: ISC
pragma solidity >=0.8.0;

// **NOTE** Generated code, do not modify.  Run 'npm run generate:constants'.

import { TestBase } from "forge-std/Test.sol";

` + outputStrings.join("\n");
  await fs.writeFile(path_1.default.resolve("src", "Constants.sol"), finalString);
}
async function handleSingleNetwork(networkName, constants) {
  const constantString = Object.entries(constants)
    .map(([key, value]) => {
      if (value.startsWith("0x")) {
        return `    address internal constant ${key} = ${value};`;
      }
      return `    string internal constant ${key} = "${value}";`;
    })
    .join("\n");
  const labelStrings = Object.entries(constants)
    .map(([key, value]) => {
      return `        vm.label(${value}, "Constants.${key}");`;
    })
    .join("\n");
  const contractString = `library ${networkName} {
${constantString}
}
`;
  if (networkName == "Mainnet") {
    const constantsHelper = `
abstract contract Helper is TestBase {
    constructor() {
        labelConstants();
    }

    function labelConstants() public {
${labelStrings}
    }
}
`;
    return contractString + constantsHelper;
  }
  return contractString;
}
main();
