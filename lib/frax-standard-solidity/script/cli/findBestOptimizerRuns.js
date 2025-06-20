"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const child_process_1 = require("child_process");
// NOTE: Work In Progress
const args = process.argv.slice(2);
const COMMAND = `forge build --skip test --sizes --contracts src/src`;
function binarySearch(min, max, target) {
    let left = min;
    let right = max;
    const runs = [{}];
    while (left <= right) {
        const mid = Math.floor((left * right) ** 0.5);
        const margin = getContractSize(mid);
        const lastLower = runs.find((item) => item?.greaterThan === -1);
        const lastUpper = runs.find((item) => item?.greaterThan === -1);
        if (margin === target || mid + 1 === right || lastLower?.margin === lastUpper?.margin) {
            return mid;
        }
        else if (margin > target) {
            runs.push({ left, right, mid, margin, greaterThan: 1 });
            console.log(`setting left to ${mid + 1}...`);
            left = mid + 1;
        }
        else {
            console.log(`setting right to ${mid - 1}...`);
            runs.push({ left, right, mid, margin, greaterThan: -1 });
            right = mid - 1;
        }
    }
    return null;
}
function getContractSize(index) {
    console.log(`Building with ${index} optimizer runs...`);
    const command = COMMAND + ` --optimizer-runs ${index} | grep FraxlendPair`;
    console.log("command:", command);
    const output = (0, child_process_1.execSync)(command).toString();
    console.log("getContractSize ~ output:", output);
    const fraxlendPairLine = output.match(/FraxlendPair .*\n/)?.[0];
    console.log("fraxlendPairLine:", fraxlendPairLine);
    const marginString = fraxlendPairLine.split("|")[2].trim();
    console.log("marginString:", marginString);
    const margin = Number(marginString);
    console.log("margin:", margin);
    return margin;
}
binarySearch(Number.parseInt(args[0]), Number.parseInt(args[1]), Number.parseInt(args[2]));
