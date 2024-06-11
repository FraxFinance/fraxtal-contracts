#!/usr/bin/env node
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const commander_1 = require("commander");
const library_1 = require("./build-helper/library");
const library_2 = require("./build-hoax-helper/library");
const toNamedImports_1 = require("./toNamedImports");
const utils_1 = require("./utils");
const program = new commander_1.Command();
program.name("frax");
program
    .command("buildStructHelper")
    .argument("<abi-path>", "path to abi file or name of contract")
    .argument("<name>", "name of Library Helper")
    .option("-i <type>", "--interface <type>", "name of interface")
    .action(async (abiPath, name, options) => {
    const abi = (0, utils_1.getAbi)(abiPath);
    await (0, library_1.buildHelperAction)(abi, name, options);
});
program
    .command("buildHoaxHelper")
    .argument("<abi-path>", "path to abi file or name of contract")
    .argument("<name>", "name of Library Helper")
    .action(async (abiPath, name, options) => {
    const abi = (0, utils_1.getAbi)(abiPath);
    await (0, library_2.buildHoaxHelperAction)(abi, name);
});
program
    .command("hoax")
    .option("-w, --watch", "watch files")
    .argument("[paths...]", "paths to source files")
    .action(async (paths, options) => {
    if (paths.length > 0) {
        await (0, library_2.hoaxAction)(paths, options.watch);
    }
    else {
        const defaultPaths = (0, utils_1.getFilesFromFraxToml)();
        await (0, library_2.hoaxAction)(defaultPaths, options.watch);
    }
});
program
    .command("renameImports")
    .argument("<paths...>", "glob path to abi file")
    .action((paths) => {
    (0, toNamedImports_1.toNamedImports)(paths);
});
program
    .command("abi")
    .argument("<paths...>", "glob path to abi file")
    .action(async (paths) => {
    const abi = await (0, utils_1.newGetAbi)(paths[0]);
    const abiString = JSON.stringify(abi, null, 2);
    process.stdout.write(abiString);
});
program.parse();
