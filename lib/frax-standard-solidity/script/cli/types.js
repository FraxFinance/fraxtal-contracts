"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ABIType = exports.StateMutability = exports.InternalTypeEnum = void 0;
var InternalTypeEnum;
(function (InternalTypeEnum) {
    InternalTypeEnum["Address"] = "address";
    InternalTypeEnum["Bool"] = "bool";
    InternalTypeEnum["Bytes"] = "bytes";
    InternalTypeEnum["ContractIERC20"] = "contract IERC20";
    InternalTypeEnum["ContractIRateCalculatorV2"] = "contract IRateCalculatorV2";
    InternalTypeEnum["String"] = "string";
    InternalTypeEnum["StructFraxlendPairCoreCurrentRateInfo"] = "struct FraxlendPairCore.CurrentRateInfo";
    InternalTypeEnum["StructVaultAccount"] = "struct VaultAccount";
    InternalTypeEnum["Tuple"] = "tuple";
    InternalTypeEnum["TypeAddress"] = "address[]";
    InternalTypeEnum["Uint128"] = "uint128";
    InternalTypeEnum["Uint184"] = "uint184";
    InternalTypeEnum["Uint256"] = "uint256";
    InternalTypeEnum["Uint32"] = "uint32";
    InternalTypeEnum["Uint64"] = "uint64";
    InternalTypeEnum["Uint8"] = "uint8";
})(InternalTypeEnum = exports.InternalTypeEnum || (exports.InternalTypeEnum = {}));
var StateMutability;
(function (StateMutability) {
    StateMutability["Nonpayable"] = "nonpayable";
    StateMutability["Pure"] = "pure";
    StateMutability["View"] = "view";
})(StateMutability = exports.StateMutability || (exports.StateMutability = {}));
var ABIType;
(function (ABIType) {
    ABIType["Constructor"] = "constructor";
    ABIType["Error"] = "error";
    ABIType["Event"] = "event";
    ABIType["Function"] = "function";
})(ABIType = exports.ABIType || (exports.ABIType = {}));
