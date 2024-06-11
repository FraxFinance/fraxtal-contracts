"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.chainId = exports.encodeTransfer = exports.Erc20Interface = exports.Erc20 = void 0;
const hardhat_1 = __importDefault(require("hardhat"));
exports.Erc20 = [
    "function transfer(address _receiver, uint256 _value) public returns (bool success)",
    "function approve(address _spender, uint256 _value) public returns (bool success)",
    "function allowance(address _owner, address _spender) public view returns (uint256 remaining)",
    "function balanceOf(address _owner) public view returns (uint256 balance)",
    "event Approval(address indexed _owner, address indexed _spender, uint256 _value)",
];
exports.Erc20Interface = new hardhat_1.default.ethers.utils.Interface(exports.Erc20);
const encodeTransfer = (target, amount) => {
    return exports.Erc20Interface.encodeFunctionData("transfer", [target, amount]);
};
exports.encodeTransfer = encodeTransfer;
const chainId = async () => {
    return (await hardhat_1.default.ethers.provider.getNetwork()).chainId;
};
exports.chainId = chainId;
