"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.killLibContract = exports.killLibSource = void 0;
const setup_1 = require("./setup");
exports.killLibSource = `
contract Test {
    function killme() public {
        selfdestruct(payable(msg.sender));
    }

    function expose() public returns (address handler) {
        bytes32 slot = 0x6c9a6c4a39284e37ed1cf53d337577d14212a4870fb976a4366c693b939918d5;
        assembly {
            handler := sload(slot)
        }
    }

    function estimate(address to, bytes memory data) public returns (uint256) {
        uint256 startGas = gasleft();
        (bool success,) = to.call{ gas: gasleft() }(data);
        require(success, "Transaction failed");
        return startGas - gasleft();
    }

    address singleton;
    uint256 public value = 0;
    function updateAndGet() public returns (uint256) {
        value++;
        return value;
    }

    function trever() public returns (address handler) {
        revert("Why are you doing this?");
    }
}`;
const killLibContract = async (deployer) => {
    return await (0, setup_1.deployContract)(deployer, exports.killLibSource);
};
exports.killLibContract = killLibContract;
