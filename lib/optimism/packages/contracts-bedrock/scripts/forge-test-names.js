"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const fs_1 = __importDefault(require("fs"));
const path_1 = __importDefault(require("path"));
const child_process_1 = require("child_process");
/**
 * Series of function name checks.
 */
const checks = [
    {
        error: 'test name parts should be in camelCase',
        check: (parts) => {
            return parts.every((part) => {
                return part[0] === part[0].toLowerCase();
            });
        },
    },
    {
        error: 'test names should have either 3 or 4 parts, each separated by underscores',
        check: (parts) => {
            return parts.length === 3 || parts.length === 4;
        },
    },
    {
        error: 'test names should begin with "test", "testFuzz", or "testDiff"',
        check: (parts) => {
            return ['test', 'testFuzz', 'testDiff'].includes(parts[0]);
        },
    },
    {
        error: 'test names should end with either "succeeds", "reverts", "fails", "works" or "benchmark[_num]"',
        check: (parts) => {
            return (['succeeds', 'reverts', 'fails', 'benchmark', 'works'].includes(parts[parts.length - 1]) ||
                (parts[parts.length - 2] === 'benchmark' &&
                    !isNaN(parseInt(parts[parts.length - 1], 10))));
        },
    },
    {
        error: 'failure tests should have 4 parts, third part should indicate the reason for failure',
        check: (parts) => {
            return (parts.length === 4 ||
                !['reverts', 'fails'].includes(parts[parts.length - 1]));
        },
    },
];
/**
 * Script for checking that all test functions are named correctly.
 */
const main = async () => {
    const result = (0, child_process_1.execSync)('forge config --json');
    const config = JSON.parse(result.toString());
    const out = config.out || 'out';
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
    readFilesRecursively(out);
    console.log('Success:');
    const errors = [];
    for (const filepath of paths) {
        const artifact = JSON.parse(fs_1.default.readFileSync(filepath, 'utf8'));
        let isTest = false;
        for (const element of artifact.abi) {
            if (element.name === 'IS_TEST') {
                isTest = true;
                break;
            }
        }
        if (isTest) {
            let success = true;
            for (const element of artifact.abi) {
                // Skip non-functions and functions that don't start with "test".
                if (element.type !== 'function' || !element.name.startsWith('test')) {
                    continue;
                }
                // Check the rest.
                for (const { check, error } of checks) {
                    if (!check(element.name.split('_'))) {
                        errors.push(`${filepath}#${element.name}: ${error}`);
                        success = false;
                    }
                }
            }
            if (success) {
                console.log(` - ${path_1.default.parse(filepath).name}`);
            }
        }
    }
    if (errors.length > 0) {
        console.error(errors.join('\n'));
        process.exit(1);
    }
};
main();
