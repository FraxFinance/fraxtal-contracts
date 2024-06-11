// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

// lib/frax-standard-solidity/lib/forge-std/src/console2.sol

/// @dev The original console.sol uses `int` and `uint` for computing function selectors, but it should
/// use `int256` and `uint256`. This modified version fixes that. This version is recommended
/// over `console.sol` if you don't need compatibility with Hardhat as the logs will show up in
/// forge stack traces. If you do need compatibility with Hardhat, you must use `console.sol`.
/// Reference: https://github.com/NomicFoundation/hardhat/issues/2178
library console2 {
    address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

    function _castLogPayloadViewToPure(
        function(bytes memory) internal view fnIn
    ) internal pure returns (function(bytes memory) internal pure fnOut) {
        assembly {
            fnOut := fnIn
        }
    }

    function _sendLogPayload(bytes memory payload) internal pure {
        _castLogPayloadViewToPure(_sendLogPayloadView)(payload);
    }

    function _sendLogPayloadView(bytes memory payload) private view {
        uint256 payloadLength = payload.length;
        address consoleAddress = CONSOLE_ADDRESS;
        /// @solidity memory-safe-assembly
        assembly {
            let payloadStart := add(payload, 32)
            let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
        }
    }

    function log() internal pure {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }

    function logInt(int256 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
    }

    function logUint(uint256 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
    }

    function logString(string memory p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function logBool(bool p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function logAddress(address p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function logBytes(bytes memory p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
    }

    function logBytes1(bytes1 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
    }

    function logBytes2(bytes2 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
    }

    function logBytes3(bytes3 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
    }

    function logBytes4(bytes4 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
    }

    function logBytes5(bytes5 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
    }

    function logBytes6(bytes6 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
    }

    function logBytes7(bytes7 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
    }

    function logBytes8(bytes8 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
    }

    function logBytes9(bytes9 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
    }

    function logBytes10(bytes10 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
    }

    function logBytes11(bytes11 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
    }

    function logBytes12(bytes12 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
    }

    function logBytes13(bytes13 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
    }

    function logBytes14(bytes14 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
    }

    function logBytes15(bytes15 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
    }

    function logBytes16(bytes16 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
    }

    function logBytes17(bytes17 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
    }

    function logBytes18(bytes18 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
    }

    function logBytes19(bytes19 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
    }

    function logBytes20(bytes20 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
    }

    function logBytes21(bytes21 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
    }

    function logBytes22(bytes22 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
    }

    function logBytes23(bytes23 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
    }

    function logBytes24(bytes24 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
    }

    function logBytes25(bytes25 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
    }

    function logBytes26(bytes26 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
    }

    function logBytes27(bytes27 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
    }

    function logBytes28(bytes28 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
    }

    function logBytes29(bytes29 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
    }

    function logBytes30(bytes30 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
    }

    function logBytes31(bytes31 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
    }

    function logBytes32(bytes32 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
    }

    function log(uint256 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
    }

    function log(int256 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
    }

    function log(string memory p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function log(bool p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function log(address p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function log(uint256 p0, uint256 p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
    }

    function log(uint256 p0, string memory p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
    }

    function log(uint256 p0, bool p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
    }

    function log(uint256 p0, address p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
    }

    function log(string memory p0, uint256 p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
    }

    function log(string memory p0, int256 p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,int256)", p0, p1));
    }

    function log(string memory p0, string memory p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
    }

    function log(string memory p0, bool p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
    }

    function log(string memory p0, address p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
    }

    function log(bool p0, uint256 p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
    }

    function log(bool p0, string memory p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
    }

    function log(bool p0, bool p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
    }

    function log(bool p0, address p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
    }

    function log(address p0, uint256 p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
    }

    function log(address p0, string memory p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
    }

    function log(address p0, bool p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
    }

    function log(address p0, address p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
    }

    function log(uint256 p0, uint256 p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
    }

    function log(string memory p0, address p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
    }

    function log(string memory p0, address p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
    }

    function log(string memory p0, address p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
    }

    function log(string memory p0, address p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
    }

    function log(bool p0, bool p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
    }

    function log(bool p0, bool p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
    }

    function log(bool p0, bool p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
    }

    function log(bool p0, bool p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
    }

    function log(bool p0, address p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
    }

    function log(bool p0, address p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
    }

    function log(bool p0, address p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
    }

    function log(bool p0, address p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
    }

    function log(address p0, string memory p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
    }

    function log(address p0, string memory p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
    }

    function log(address p0, string memory p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
    }

    function log(address p0, string memory p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
    }

    function log(address p0, bool p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
    }

    function log(address p0, bool p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
    }

    function log(address p0, bool p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
    }

    function log(address p0, bool p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
    }

    function log(address p0, address p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
    }

    function log(address p0, address p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
    }

    function log(address p0, address p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
    }

    function log(address p0, address p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
    }
}

// node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// node_modules/@openzeppelin/contracts/utils/Address.sol

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// node_modules/@openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// src/contracts/VestedFXS-and-Flox/FPISLocker/IlFPISStructs.sol

// @version 0.2.8

/**
 * ====================================================================
 * |     ______                   _______                             |
 * |    / _____________ __  __   / ____(_____  ____ _____  ________   |
 * |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
 * |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
 * | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
 * |                                                                  |
 * ====================================================================
 * ======================== lFPISStructs ==============================
 * ====================================================================
 * Structs of lFPIS contracts (lFPIS)
 * Frax Finance: https://github.com/FraxFinance
 */
interface IlFPISStructs {
    /// @notice Detailed lock info for a user
    /// @param user Address of the user
    /// @param allLocks All of the locks of the user
    /// @param numberOfLocks The total number of locks that the user has
    /// @param activeLocks Only the active locks of the user
    /// @param expiredLocks Only the expired locks of the user
    /// @param totalFpis The total amount of FPIS that the user has for all, active, and expired locks respectively
    struct DetailedUserLockInfo {
        address user;
        uint256 numberOfLocks;
        LockedBalanceExtended[] allLocks;
        LockedBalanceExtended[] activeLocks;
        LockedBalanceExtended[] expiredLocks;
        int128[3] totalFpis;
    }

    /// @notice Basic information about a lock
    /// @param amount The amount that is locked
    /// @param end The ending timestamp for the lock
    /// @dev We cannot really do block numbers per se b/c slope is per time, not per block and per block could be fairly bad b/c Ethereum changes blocktimes. What we can do is to extrapolate ***At functions
    struct LockedBalance {
        int128 amount;
        uint128 end; // This should more than suffice for our needs and allows the struct to be packed
    }

    /// @notice Extended information about a lock
    /// @param id The ID of the lock
    /// @param index The index of the lock. If index is 0, do not trust it unless isInUse is also true
    /// @param amount The amount that is locked
    /// @param end The ending timestamp for the lock
    struct LockedBalanceExtended {
        uint256 id;
        uint128 index;
        int128 amount;
        uint128 end;
    }

    /// @notice Lock ID Info. Cannot be a simple mapping because lock indeces are in constant flux and index 0 vs null is ambiguous.
    /// @param id The ID of the lock
    /// @param index The index of the lock. If index is 0, do not trust it unless isInUse is also true
    /// @param isInUse If the lock ID is currently in use
    struct LockIdIdxInfo {
        uint256 id;
        uint128 index;
        bool isInUse;
    }

    /// @notice Point in a user's lock
    /// @param bias The bias of the point
    /// @param slope The slope of the point
    /// @param ts The timestamp of the point
    /// @param blk The block of the point
    /// @param fpisAmt The amount of FPIS at the point
    struct Point {
        int128 bias;
        int128 slope; // - dweight / dt
        uint256 ts;
        uint256 blk; // block
        uint256 fpisAmt;
    }

    /// @notice Longest lock info for a user
    /// @param lock The longest lock of the user
    /// @param lockIndex The index of the longest lock
    /// @param user The address of the user
    struct LongestLock {
        LockedBalance lock;
        uint128 lockIndex;
        address user;
    }
}

// src/contracts/VestedFXS-and-Flox/Flox/TransferHelper.sol

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    error TransferHelperApproveFailed();
    error TransferHelperTransferFailed();
    error TransferHelperTransferFromFailed();
    error TransferHelperTransferETHFailed();

    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        // require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TransferHelperApproveFailed();
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        // require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TransferHelperTransferFailed();
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        // require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TransferHelperTransferFromFailed();
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{ value: value }(new bytes(0));
        // require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
        if (!success) revert TransferHelperTransferETHFailed();
    }
}

// src/contracts/VestedFXS-and-Flox/VestedFXS/IveFXSStructs.sol

// @version 0.2.8

/**
 * ====================================================================
 * |     ______                   _______                             |
 * |    / _____________ __  __   / ____(_____  ____ _____  ________   |
 * |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
 * |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
 * | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
 * |                                                                  |
 * ====================================================================
 * =============================== veFXS ==============================
 * ====================================================================
 * Structs VestedFXS (veFXS)
 * Frax Finance: https://github.com/FraxFinance
 */
interface IveFXSStructs {
    /// @notice Detailed lock info for a user
    /// @param user Address of the user
    /// @param allLocks All of the locks of the user
    /// @param numberOfLocks The total number of locks that the user has
    /// @param activeLocks Only the active locks of the user
    /// @param expiredLocks Only the expired locks of the user
    /// @param totalFxs The total amount of FXS that the user has for all, active, and expired locks respectively
    struct DetailedUserLockInfo {
        address user;
        uint256 numberOfLocks;
        LockedBalanceExtended[] allLocks;
        LockedBalanceExtended[] activeLocks;
        LockedBalanceExtended[] expiredLocks;
        int128[3] totalFxs;
    }

    /// @notice Basic information about a lock
    /// @param amount The amount that is locked
    /// @param end The ending timestamp for the lock
    /// @dev We cannot really do block numbers per se b/c slope is per time, not per block and per block could be fairly bad b/c Ethereum changes blocktimes. What we can do is to extrapolate ***At functions
    struct LockedBalance {
        int128 amount;
        uint128 end; // This should more than suffice for our needs and allows the struct to be packed
    }

    /// @notice Extended information about a lock
    /// @param id The ID of the lock
    /// @param index The index of the lock. If index is 0, do not trust it unless isInUse is also true
    /// @param amount The amount that is locked
    /// @param end The ending timestamp for the lock
    struct LockedBalanceExtended {
        uint256 id;
        uint128 index;
        int128 amount;
        uint128 end;
    }

    /// @notice Extended information about a lock
    /// @param id The ID of the lock
    /// @param index The index of the lock. If index is 0, do not trust it unless isInUse is also true
    /// @param amount The amount that is locked
    /// @param end The ending timestamp for the lock
    /// @param location The address where the lock is being held
    /// @param estimatedCurrLockVeFXS Estimated veFXS of this lock based on amount, end, and when this struct was generated
    struct LockedBalanceExtendedV2 {
        uint256 id;
        uint128 index;
        int128 amount;
        uint128 end;
        address location;
        uint256 estimatedCurrLockVeFXS;
    }

    /// @notice Lock ID Info. Cannot be a simple mapping because lock indeces are in constant flux and index 0 vs null is ambiguous.
    /// @param id The ID of the lock
    /// @param index The index of the lock. If index is 0, do not trust it unless isInUse is also true
    /// @param isInUse If the lock ID is currently in use
    struct LockIdIdxInfo {
        uint256 id;
        uint128 index;
        bool isInUse;
    }

    /// @notice Point in a user's lock
    /// @param bias The bias of the point
    /// @param slope The slope of the point
    /// @param ts The timestamp of the point
    /// @param blk The block of the point
    /// @param fxsAmt The amount of FXS at the point
    struct Point {
        int128 bias;
        int128 slope; // - dweight / dt
        uint256 ts;
        uint256 blk; // block
        uint256 fxsAmt;
    }

    /// @notice Longest lock info for a user
    /// @param lock The longest lock of the user
    /// @param lockIndex The index of the longest lock
    /// @param user The address of the user
    struct LongestLock {
        LockedBalance lock;
        uint128 lockIndex;
        address user;
    }
}

// src/contracts/VestedFXS-and-Flox/VestedFXS/OwnedV2.sol

// https://docs.synthetix.io/contracts/Owned
contract OwnedV2 {
    error OwnerCannotBeZero();
    error InvalidOwnershipAcceptance();
    error OnlyOwner();

    address public owner;
    address public nominatedOwner;

    constructor(address _owner) {
        // require(_owner != address(0), "Owner address cannot be 0");
        if (_owner == address(0)) revert OwnerCannotBeZero();
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        // require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        if (msg.sender != nominatedOwner) revert InvalidOwnershipAcceptance();
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner() {
        // require(msg.sender == owner, "Only the contract owner may perform this action");
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        if (msg.sender != owner) revert OnlyOwner();
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

// src/contracts/VestedFXS-and-Flox/VestedFXS/OwnedV2AutoMsgSender.sol

// https://docs.synthetix.io/contracts/Owned
contract OwnedV2AutoMsgSender {
    error OwnerCannotBeZero();
    error InvalidOwnershipAcceptance();
    error OnlyOwner();

    address public owner;
    address public nominatedOwner;

    constructor() {
        owner = msg.sender;
        emit OwnerChanged(address(0), msg.sender);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        // require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        if (msg.sender != nominatedOwner) revert InvalidOwnershipAcceptance();
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner() {
        // require(msg.sender == owner, "Only the contract owner may perform this action");
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        if (msg.sender != owner) revert OnlyOwner();
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

// src/contracts/VestedFXS-and-Flox/interfaces/IL1VeFXS.sol

// @version 0.2.8

interface IL1VeFXS {
    /// @dev amount and end of lock
    struct LockedBalance {
        uint128 amount;
        uint64 end;
        uint64 blockTimestamp;
    }

    function LOCKED_SLOT_INDEX() external view returns (uint256);

    function acceptOwnership() external;

    function adminProofVeFXS(address[] memory _addresses, LockedBalance[] memory _lockedBalances) external;

    function balanceOf(address _address) external view returns (uint256 _balance);

    function initialize(address _stateRootOracle, address _owner) external;

    function locked(address account) external view returns (LockedBalance memory);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function proofVeFXS(
        address _address,
        uint256 _blockNumber,
        bytes[] memory _accountProof,
        bytes[] memory _storageProof1,
        bytes[] memory _storageProof2
    ) external;

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;

    function veFXSAddress() external view returns (address);
}

// node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// src/contracts/VestedFXS-and-Flox/VestedFXS/L1VeFXSTotalSupplyOracle.sol

/**
 * ====================================================================
 * |     ______                   _______                             |
 * |    / _____________ __  __   / ____(_____  ____ _____  ________   |
 * |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
 * |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
 * | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
 * |                                                                  |
 * ====================================================================
 * ===================== L1VeFXSTotalSupplyOracle =====================
 * ====================================================================
 * Bot-set Oracle for reporting the Ethereum Mainnet veFXS totalSupply() info.
 * Eventually plan to update L1VeFXS with a proof-based solution
 * Frax Finance: https://github.com/FraxFinance
 */

/* solhint-disable max-line-length, not-rely-on-time */

contract L1VeFXSTotalSupplyOracle is OwnedV2 {
    /// @notice The last veFXS totalSupply data point
    uint256 public totalSupplyStored;

    /// @notice The block on Mainnet when the veFXS totalSupply was read
    uint128 public blkWhenTotalSupplyRead;

    /// @notice The timestamp on Mainnet when the veFXS totalSupply was read
    uint128 public tsWhenTotalSupplyRead;

    /// @notice When the information was last updated by the bot
    uint256 public lastBotUpdate;

    /// @notice Address of the bot that is allowed to update the contract
    address public botAddress;

    /**
     * @notice Initialize contract
     * @param _owner The owner of this contract
     * @param _bot Address of the bot that is allowed to post
     * @param _initTtlSupplyStored Initial/seed value of totalSupplyStored
     * @param _initBlkWhenTotalSupplyRead Initial/seed value of blkWhenTotalSupplyRead
     * @param _initTsWhenTtlSupplyRead Initial/seed value of tsWhenTotalSupplyRead
     */
    constructor(
        address _owner,
        address _bot,
        uint256 _initTtlSupplyStored,
        uint128 _initBlkWhenTotalSupplyRead,
        uint128 _initTsWhenTtlSupplyRead
    ) OwnedV2(_owner) {
        // Set bot address
        botAddress = _bot;

        // Set seed values
        totalSupplyStored = _initTtlSupplyStored;
        blkWhenTotalSupplyRead = _initBlkWhenTotalSupplyRead;
        tsWhenTotalSupplyRead = _initTsWhenTtlSupplyRead;
        if (_initTsWhenTtlSupplyRead > 0) lastBotUpdate = _initTsWhenTtlSupplyRead;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyByOwnBot() {
        require(msg.sender == owner || msg.sender == botAddress, "You are not the owner or the bot");
        _;
    }

    /* ============ VIEWS ============ */

    /// @notice Get the most recent totalSupply from Mainnet veFXS
    /// @param _totalSupply The last reported Mainnet veFXS totalSupply
    function totalSupply() external view returns (uint256 _totalSupply) {
        return totalSupplyStored;
    }

    /// @notice Get the most recent totalSupply from Mainnet veFXS along with the time it was read
    /// @param _totalSupply The last reported Mainnet veFXS totalSupply
    /// @param _blk Block when the totalSupply was read on Mainnet
    /// @param _ts Timestamp when the totalSupply was read on Mainnet
    function totalSupplyExtra() external view returns (uint256 _totalSupply, uint128 _blk, uint128 _ts) {
        return (totalSupplyStored, blkWhenTotalSupplyRead, tsWhenTotalSupplyRead);
    }

    // ==============================================================================
    // BOT FUNCTIONS
    // ==============================================================================

    /// @notice Set the most recent totalSupply from Mainnet veFXS
    /// @param _totalSupply The last reported Mainnet veFXS totalSupply
    /// @param _blk Block when the totalSupply was read on Mainnet
    /// @param _ts Timestamp when the totalSupply was read on Mainnet
    function updateInfo(uint256 _totalSupply, uint128 _blk, uint128 _ts) external onlyByOwnBot {
        totalSupplyStored = _totalSupply;
        blkWhenTotalSupplyRead = _blk;
        tsWhenTotalSupplyRead = _ts;
    }

    // ==============================================================================
    // RESTRICTED FUNCTIONS
    // ==============================================================================

    /// @notice Set the bot address
    /// @param _newBot The address of the bot
    function setBot(address _newBot) external onlyOwner {
        botAddress = _newBot;
    }

    // ==============================================================================
    // EVENTS
    // ==============================================================================

    /// @notice When the veFXS info is updated
    /// @param totalSupply veFXS totalSupply from mainnet
    /// @param blk Block when the totalSupply was read on Mainnet
    /// @param ts Timestamp when the totalSupply was read on Mainnet
    event InfoUpdated(uint256 totalSupply, uint128 blk, uint128 ts);
}

// src/contracts/VestedFXS-and-Flox/interfaces/IFPISLocker.sol

// @version 0.2.8

/**
 * ====================================================================
 * |     ______                   _______                             |
 * |    / _____________ __  __   / ____(_____  ____ _____  ________   |
 * |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
 * |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
 * | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
 * |                                                                  |
 * ====================================================================
 * ============================ IFPISLocker ============================
 * ====================================================================
 * Frax Finance: https://github.com/FraxFinance
 */
interface IFPISLocker is IlFPISStructs {
    function MAXTIME_INT128() external view returns (int128);

    function MAXTIME_UINT256() external view returns (uint256);

    function MAX_CONTRIBUTOR_LOCKS() external view returns (uint8);

    function MAX_USER_LOCKS() external view returns (uint8);

    function MULTIPLIER_UINT256() external view returns (uint256);

    function VOTE_WEIGHT_MULTIPLIER_INT128() external view returns (int128);

    function VOTE_WEIGHT_MULTIPLIER_UINT256() external view returns (uint256);

    function VOTE_END_POWER_BASIS_POINTS_INT128() external view returns (int128);

    function VOTE_END_POWER_BASIS_POINTS_UINT256() external view returns (uint256);

    function MAX_BASIS_POINTS_INT128() external view returns (int128);

    function MAX_BASIS_POINTS_UINT256() external view returns (uint256);

    function FXS_CONVERSION_START_TIMESTAMP() external view returns (uint256);

    function WEEK_UINT128() external view returns (uint128);

    function WEEK_UINT256() external view returns (uint256);

    function acceptTransferOwnership() external;

    function admin() external view returns (address);

    function balanceOf(address _addr) external view returns (uint256 _balance);

    function balanceOfAllLocksAtBlock(address _addr, uint256 _block) external view returns (uint256 _balance);

    function balanceOfAllLocksAtTime(address _addr, uint256 _timestamp) external view returns (uint256 _balance);

    function balanceOfAt(address _addr, uint256 _block) external view returns (uint256 _balance);

    function balanceOfOneLockAtBlock(
        address _addr,
        uint128 _lockIndex,
        uint256 _block
    ) external view returns (uint256 _balance);

    function balanceOfOneLockAtTime(
        address _addr,
        uint128 _lockIndex,
        uint256 _timestamp
    ) external view returns (uint256 _balance);

    function checkpoint() external;

    function commitTransferOwnership(address _addr) external;

    function createLock(address _addr, uint256 _value, uint128 _unlockTime) external returns (uint128);

    function decimals() external view returns (uint256);

    function depositFor(address _addr, uint256 _value, uint128 _lockIndex) external;

    function emergencyUnlockActive() external view returns (bool);

    function epoch() external view returns (uint256);

    function findBlockEpoch(uint256 _block, uint256 _maxEpoch) external view returns (uint256);

    function floxContributors(address) external view returns (bool);

    function futureAdmin() external view returns (address);

    function getLastUserSlope(address _addr, uint128 _lockIndex) external view returns (int128);

    function increaseAmount(uint256 _value, uint128 _lockIndex) external;

    function increaseUnlockTime(uint128 _unlockTime, uint128 _lockIndex) external;

    function indicesToIds(address, uint128) external view returns (uint256);

    function isPaused() external view returns (bool);

    function locked(address, uint256) external view returns (int128 amount, uint128 end);

    function lockedById(address _addr, uint256 _id) external view returns (LockedBalance memory _lockInfo);

    function lockedByIndex(address _addr, uint128 _index) external view returns (LockedBalance memory _lockInfo);

    function lockedEnd(address _addr, uint128 _index) external view returns (uint256);

    function name() external view returns (string memory);

    function nextId(address) external view returns (uint256);

    function numLocks(address) external view returns (uint128);

    function pointHistory(
        uint256
    ) external view returns (int128 bias, int128 slope, uint256 ts, uint256 blk, uint256 fpisAmt);

    function recoverIERC20(address _tokenAddr, uint256 _amount) external;

    function setFloxContributor(address _floxContributor, bool _isFloxContributor) external;

    function setLVPIDUtils(address _lFpisUtilsAddr) external;

    function slopeChanges(uint256) external view returns (int128);

    function supply() external view returns (uint256);

    function supplyAt(Point memory _point, uint256 _t) external view returns (uint256);

    function symbol() external view returns (string memory);

    function toggleContractPause() external;

    function activateEmergencyUnlock() external;

    function fpis() external view returns (address);

    function totalFPISSupply() external view returns (uint256);

    function totalFPISSupplyAt(uint256 _block) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalSupply(uint256 _timestamp) external view returns (uint256);

    function totalSupplyAt(uint256 _block) external view returns (uint256);

    function userPointEpoch(address, uint256) external view returns (uint256);

    function userPointHistory(
        address,
        uint256,
        uint256
    ) external view returns (int128 bias, int128 slope, uint256 ts, uint256 blk, uint256 fpisAmt);

    function userPointHistoryTs(address _addr, uint128 _lockIndex, uint256 _idx) external view returns (uint256);

    function lFpisUtils() external view returns (address);

    function version() external view returns (string memory);

    function withdraw(uint128 _lockIndex) external;
}

// src/contracts/VestedFXS-and-Flox/interfaces/IVestedFXS.sol

// @version 0.2.8

/**
 * ====================================================================
 * |     ______                   _______                             |
 * |    / _____________ __  __   / ____(_____  ____ _____  ________   |
 * |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
 * |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
 * | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
 * |                                                                  |
 * ====================================================================
 * ============================ IVestedFXS ============================
 * ====================================================================
 * Frax Finance: https://github.com/FraxFinance
 */
interface IVestedFXS is IveFXSStructs {
    function MAXTIME_INT128() external view returns (int128);

    function MAXTIME_UINT256() external view returns (uint256);

    function MAX_CONTRIBUTOR_LOCKS() external view returns (uint8);

    function MAX_USER_LOCKS() external view returns (uint8);

    function MULTIPLIER_UINT256() external view returns (uint256);

    function VOTE_WEIGHT_MULTIPLIER_INT128() external view returns (int128);

    function VOTE_WEIGHT_MULTIPLIER_UINT256() external view returns (uint256);

    function WEEK_UINT128() external view returns (uint128);

    function WEEK_UINT256() external view returns (uint256);

    function acceptTransferOwnership() external;

    function admin() external view returns (address);

    function balanceOf(address _addr) external view returns (uint256 _balance);

    function balanceOfAllLocksAtBlock(address _addr, uint256 _block) external view returns (uint256 _balance);

    function balanceOfAllLocksAtTime(address _addr, uint256 _timestamp) external view returns (uint256 _balance);

    function balanceOfAt(address _addr, uint256 _block) external view returns (uint256 _balance);

    function balanceOfOneLockAtBlock(
        address _addr,
        uint128 _lockIndex,
        uint256 _block
    ) external view returns (uint256 _balance);

    function balanceOfOneLockAtTime(
        address _addr,
        uint128 _lockIndex,
        uint256 _timestamp
    ) external view returns (uint256 _balance);

    function checkpoint() external;

    function commitTransferOwnership(address _addr) external;

    function createLock(address _addr, uint256 _value, uint128 _unlockTime) external returns (uint128, uint256);

    function decimals() external view returns (uint256);

    function depositFor(address _addr, uint256 _value, uint128 _lockIndex) external;

    function emergencyUnlockActive() external view returns (bool);

    function epoch() external view returns (uint256);

    function findBlockEpoch(uint256 _block, uint256 _maxEpoch) external view returns (uint256);

    function floxContributors(address) external view returns (bool);

    function futureAdmin() external view returns (address);

    function getLastUserSlope(address _addr, uint128 _lockIndex) external view returns (int128);

    function increaseAmount(uint256 _value, uint128 _lockIndex) external;

    function increaseUnlockTime(uint128 _unlockTime, uint128 _lockIndex) external;

    function indicesToIds(address, uint128) external view returns (uint256);

    function isPaused() external view returns (bool);

    function locked(address, uint256) external view returns (int128 amount, uint128 end);

    function lockedById(address _addr, uint256 _id) external view returns (LockedBalance memory _lockInfo);

    function lockedByIndex(address _addr, uint128 _index) external view returns (LockedBalance memory _lockInfo);

    function lockedEnd(address _addr, uint128 _index) external view returns (uint256);

    function name() external view returns (string memory);

    function nextId(address) external view returns (uint256);

    function numLocks(address) external view returns (uint128);

    function pointHistory(
        uint256
    ) external view returns (int128 bias, int128 slope, uint256 ts, uint256 blk, uint256 fxsAmt);

    function recoverIERC20(address _tokenAddr, uint256 _amount) external;

    function setFloxContributor(address _floxContributor, bool _isFloxContributor) external;

    function setVeFXSUtils(address _veFxsUtilsAddr) external;

    function slopeChanges(uint256) external view returns (int128);

    function supply() external view returns (uint256);

    function supplyAt(Point memory _point, uint256 _t) external view returns (uint256);

    function symbol() external view returns (string memory);

    function toggleContractPause() external;

    function activateEmergencyUnlock() external;

    function token() external view returns (address);

    function totalFXSSupply() external view returns (uint256);

    function totalFXSSupplyAt(uint256 _block) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalSupply(uint256 _timestamp) external view returns (uint256);

    function totalSupplyAt(uint256 _block) external view returns (uint256);

    function userPointEpoch(address, uint256) external view returns (uint256);

    function userPointHistory(
        address,
        uint256,
        uint256
    ) external view returns (int128 bias, int128 slope, uint256 ts, uint256 blk, uint256 fxsAmt);

    function userPointHistoryTs(address _addr, uint128 _lockIndex, uint256 _idx) external view returns (uint256);

    function veFxsUtils() external view returns (address);

    function version() external view returns (string memory);

    function withdraw(uint128 _lockIndex) external;

    function numberOfFloxContributorCreatedLocks(address _user) external view returns (uint256);
}

// src/contracts/VestedFXS-and-Flox/interfaces/IVestedFXSUtils.sol

// @version 0.2.8

/**
 * ====================================================================
 * |     ______                   _______                             |
 * |    / _____________ __  __   / ____(_____  ____ _____  ________   |
 * |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
 * |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
 * | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
 * |                                                                  |
 * ====================================================================
 * ========================= IVestedFXSUtils ==========================
 * ====================================================================
 * Interface for helper and utility functions for VestedFXS
 * Frax Finance: https://github.com/FraxFinance
 */
interface IVestedFXSUtils is IveFXSStructs {
    function getDetailedUserLockInfo(address user) external view returns (DetailedUserLockInfo memory);

    function getDetailedUserLockInfoBulk(address[] memory users) external view returns (DetailedUserLockInfo[] memory);

    function getLongestLock(address user) external view returns (LockedBalance memory, uint128);

    function getLongestLockBulk(address[] memory users) external view returns (LongestLock[] memory);

    function getCrudeExpectedVeFXSOneLock(int128 _fxsAmount, uint128 _lockSecsU128) external view returns (uint256);

    function getCrudeExpectedVeFXSMultiLock(
        int128[] memory _fxsAmounts,
        uint128[] memory _lockSecsU128
    ) external view returns (uint256);

    function getCrudeExpectedVeFXSUser(address _user) external view returns (uint256);
}

// node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// src/contracts/VestedFXS-and-Flox/FPISLocker/FPISLockerUtils.sol

// @version 0.2.8

/**
 * ====================================================================
 * |     ______                   _______                             |
 * |    / _____________ __  __   / ____(_____  ____ _____  ________   |
 * |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
 * |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
 * | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
 * |                                                                  |
 * ====================================================================
 * ========================= FPISLockerUtils ==========================
 * ====================================================================
 * Helper and utility functions for VestedFXS
 * Frax Finance: https://github.com/FraxFinance
 */

/**
 *
 * Voting escrow to have time-weighted votes
 * Votes have a weight depending on time, so that users are committed
 * to the future of (whatever they are voting for).
 * The weight in this implementation is linear, and lock cannot be more than maxtime:
 * w ^
 * 1 +        /
 *   |      /
 *   |    /
 *   |  /
 *   |/
 * 0 +--------+------> time
 *       maxtime (4 years?)
 */

/**
 * @title FPISLockerUtils
 * @author Frax Finance
 * @notice This utility smart contract provides functions to get extended information from the FPISLocker contract.
 */
contract FPISLockerUtils is IlFPISStructs {
    IFPISLocker public immutable lFPIS;
    IERC20Metadata public immutable fpis;

    uint256 public constant VOTE_END_POWER_BASIS_POINTS_UINT256 = 3330;
    uint256 public constant MAX_BASIS_POINTS_UINT256 = 10_000;

    /**
     * @notice Contract constructor
     * @param _FPISLocker Address of the FPISLocker contract
     */
    constructor(address _FPISLocker) {
        lFPIS = IFPISLocker(_FPISLocker);
        fpis = IERC20Metadata(lFPIS.fpis());
    }

    /**
     * @notice Used to get all of the locks of a given user.
     * @dev The locks are retrieved indiscriminately, regardless of whether they are active or expired.
     * @param _user Address of the user
     * @return _userLockInfo DetailedUserLockInfo for the user. Includes _allLocks, _activeLocks, _expiredLocks, and FXS totals for these respectively
     * @dev This lives on Fraxtal and will mostly be read-called in UIs, so gas not really an issue here
     */
    function getDetailedUserLockInfo(address _user) public view returns (DetailedUserLockInfo memory _userLockInfo) {
        // Get the total number of locks
        uint256 _totalLocks = lFPIS.numLocks(_user);
        uint128 _numberOfActiveLocks;

        // Set the number locks for the user
        _userLockInfo.numberOfLocks = _totalLocks;

        // Set the user
        _userLockInfo.user = _user;

        // Initialize _allLocks
        _userLockInfo.allLocks = new LockedBalanceExtended[](_totalLocks);

        // Initial _isActive, which tracks if a given index is active
        bool[] memory _isActive = new bool[](_totalLocks);

        // Loop through all of the locks
        for (uint256 i; i < _userLockInfo.allLocks.length; ) {
            // Update the _allLocks return data
            LockedBalance memory _thisLock = lFPIS.lockedByIndex(_user, uint128(i));
            _userLockInfo.allLocks[i].id = lFPIS.indicesToIds(_user, uint128(i));
            _userLockInfo.allLocks[i].index = uint128(i);
            _userLockInfo.allLocks[i].amount = _thisLock.amount;
            _userLockInfo.allLocks[i].end = _thisLock.end;
            _userLockInfo.totalFpis[0] += _thisLock.amount;

            // Determine whether it is active or expired
            if (_thisLock.end > block.timestamp) {
                // Update isActive tracking
                _isActive[i] = true;

                // Update _totalFxs for active locks
                _userLockInfo.totalFpis[1] += _thisLock.amount;

                unchecked {
                    ++_numberOfActiveLocks;
                }
            } else {
                // Update _totalFxs for expired locks
                _userLockInfo.totalFpis[2] += _thisLock.amount;
            }
            unchecked {
                ++i;
            }
        }

        // Initialize _activeLocks and _expiredLocks
        _userLockInfo.activeLocks = new LockedBalanceExtended[](_numberOfActiveLocks);
        _userLockInfo.expiredLocks = new LockedBalanceExtended[](_totalLocks - _numberOfActiveLocks);

        // Loop through all of the locks again, this time for assigning to _activeLocks and _expiredLocks
        uint128 _activeCounter;
        uint128 _expiredCounter;
        for (uint256 i; i < _userLockInfo.allLocks.length; ) {
            // Get the lock info
            LockedBalanceExtended memory _thisLock = _userLockInfo.allLocks[i];

            // Sort the lock as either active or expired
            if (_isActive[i]) {
                // Active
                _userLockInfo.activeLocks[_activeCounter] = _thisLock;

                unchecked {
                    ++_activeCounter;
                }
            } else {
                // Expired
                _userLockInfo.expiredLocks[_expiredCounter] = _thisLock;

                unchecked {
                    ++_expiredCounter;
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Used to get all of the locks of the given users. Same underlying code as getDetailedUserLockInfo
     * @dev The locks are retrieved indiscriminately, regardless of whether they are active or expired.
     * @param _users Addresses of the users
     * @return _userLockInfos DetailedUserLockInfo[] for the users. Includes _allLocks, _activeLocks, _expiredLocks, and FXS totals for these respectively
     * @dev This lives on Fraxtal and will mostly be read-called in UIs, so gas not really an issue here
     */
    function getDetailedUserLockInfoBulk(
        address[] memory _users
    ) public view returns (DetailedUserLockInfo[] memory _userLockInfos) {
        // Save the number of user addresses
        uint256 _numUsers = _users.length;

        // Initialize the return array
        _userLockInfos = new DetailedUserLockInfo[](_numUsers);

        // Loop through all of the users and get their detailed lock info
        for (uint256 i = 0; i < _numUsers; ) {
            _userLockInfos[i] = getDetailedUserLockInfo(_users[i]);

            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Used to get the longest lock of a given user.
     * @dev The longest lock is the lock with the timestamp furthest in the future (can also be in the past if there are no active locks).
     * @param user Address of the user
     * @return The longest lock of the user
     * @return The index of the longest lock
     */
    function getLongestLock(address user) public view returns (LockedBalance memory, uint128) {
        LockedBalance[] memory locks = new LockedBalance[](lFPIS.numLocks(user));
        LockedBalance memory longestLock;
        uint128 longestLockIndex;

        for (uint256 i = 0; i < locks.length; ) {
            uint128 currentEnd = lFPIS.lockedByIndex(user, uint128(i)).end;
            if (currentEnd > longestLock.end) {
                longestLock.end = currentEnd;
                longestLock.amount = lFPIS.lockedByIndex(user, uint128(i)).amount;
                longestLockIndex = uint128(i);
            }

            unchecked {
                i++;
            }
        }

        return (longestLock, longestLockIndex);
    }

    /**
     * @notice Used to get longest locks of muliple users.
     * @dev This returns the longest lock indiscriminately, regardless of whether it is active or expired.
     * @dev The return value is an array of LongestLock structs, which contain the lock, the index of the lock, and the user.
     * @param users Array of addresses of the users
     * @return The LongestLocks of the users
     */
    function getLongestLockBulk(address[] memory users) public view returns (LongestLock[] memory) {
        LongestLock[] memory longestLocks = new LongestLock[](users.length);
        LockedBalance memory longestLock;
        uint128 longestLockIndex;

        for (uint256 i = 0; i < users.length; ) {
            for (uint256 j; j < lFPIS.numLocks(users[i]); ) {
                uint128 currentEnd = lFPIS.lockedByIndex(users[i], uint128(j)).end;
                if (currentEnd > longestLock.end) {
                    longestLock.end = currentEnd;
                    longestLock.amount = lFPIS.lockedByIndex(users[i], uint128(j)).amount;
                    longestLockIndex = uint128(j);
                }

                unchecked {
                    ++j;
                }
            }

            longestLocks[i] = LongestLock({ lock: longestLock, lockIndex: longestLockIndex, user: users[i] });

            delete longestLock;
            delete longestLockIndex;

            unchecked {
                ++i;
            }
        }

        return longestLocks;
    }

    /**
     * @notice Calculate the APPROXIMATE amount of lFPIS, given an FPIS amount and a lock length. Cruder version of balanceOf math. Useful for sanity checks.
     * @param _fpisAmount The amount of FPIS
     * @param _lockSecsU128 The length of the lock
     * @return _expectedLFPIS The expected amount of lFPIS. May be slightly off from actual (~1%)
     * @dev Useful to compare to the slope/bias-based balancedOf to make sure the math is working
     */
    function getCrudeExpectedLFPISOneLock(
        int128 _fpisAmount,
        uint128 _lockSecsU128
    ) public view returns (uint256 _expectedLFPIS) {
        // lFPIS = FPIS in emergency unlock situation
        if (lFPIS.emergencyUnlockActive()) {
            return (uint256(int256(_fpisAmount)) * VOTE_END_POWER_BASIS_POINTS_UINT256) / MAX_BASIS_POINTS_UINT256;
        }

        // Truncate _timeLeft down to the nearest week
        int128 _lockSecsI128 = int128((_lockSecsU128 / lFPIS.WEEK_UINT128()) * lFPIS.WEEK_UINT128());

        // Calculate the expected lFPIS
        _expectedLFPIS = uint256(
            uint128(
                ((_fpisAmount * lFPIS.VOTE_END_POWER_BASIS_POINTS_INT128()) / lFPIS.MAX_BASIS_POINTS_INT128()) +
                    ((_fpisAmount * _lockSecsI128 * lFPIS.VOTE_WEIGHT_MULTIPLIER_INT128()) /
                        lFPIS.MAXTIME_INT128() /
                        lFPIS.MAX_BASIS_POINTS_INT128())
            )
        );
    }

    /**
     * @notice Calculate the APPROXIMATE amount of lFPIS, given FPIS amounts and lock lengths. Cruder version of balanceOf math. Useful for sanity checks.
     * @param _fpisAmounts The amounts of FPIS
     * @param _lockSecsU128 The length of the locks
     * @return _expectedLFPIS The expected amount of lFPIS (summed). May be slightly off from actual (~1%)
     * @dev Useful to compare to the slope/bias-based balancedOf to make sure the math is working
     */
    function getCrudeExpectedLFPISMultiLock(
        int128[] memory _fpisAmounts,
        uint128[] memory _lockSecsU128
    ) public view returns (uint256 _expectedLFPIS) {
        // See if you are in an emergency unlock situation
        bool _isEmergencyUnlockActive = lFPIS.emergencyUnlockActive();

        // Loop through the locks
        for (uint128 i = 0; i < _fpisAmounts.length; ++i) {
            // lFPIS = FPIS in emergency unlock situation
            if (_isEmergencyUnlockActive) {
                _expectedLFPIS +=
                    (uint256(int256(_fpisAmounts[i])) * VOTE_END_POWER_BASIS_POINTS_UINT256) /
                    MAX_BASIS_POINTS_UINT256;
            } else {
                _expectedLFPIS += getCrudeExpectedLFPISOneLock(_fpisAmounts[i], _lockSecsU128[i]);
            }
        }
    }

    /**
     * @notice Calculate the APPROXIMATE amount of lFPIS a specific user should have. Cruder version of balanceOf math. Useful for sanity checks.
     * @param _user The address of the user
     * @return _expectedLFPIS The expected amount of lFPIS (summed). May be slightly off from actual (~1%)
     * @dev Useful to compare to the slope/bias-based balancedOf to make sure the math is working
     */
    function getCrudeExpectedLFPISUser(address _user) public view returns (uint256 _expectedLFPIS) {
        // Get all of the user's locks
        DetailedUserLockInfo memory _userLockInfo = getDetailedUserLockInfo(_user);

        // See if you are in an emergency unlock situation
        bool _isEmergencyUnlockActive = lFPIS.emergencyUnlockActive();

        // Loop through all of the user's locks
        for (uint128 i = 0; i < _userLockInfo.numberOfLocks; ) {
            // Get the lock info
            LockedBalanceExtended memory _lockInfo = _userLockInfo.allLocks[i];

            // For the emergency unlock situation, lFPIS = FPIS
            if (_isEmergencyUnlockActive) {
                _expectedLFPIS +=
                    (uint256(int256(_lockInfo.amount)) * VOTE_END_POWER_BASIS_POINTS_UINT256) /
                    MAX_BASIS_POINTS_UINT256;
            } else {
                // Get the lock time to use
                uint128 _lockSecsToUse;
                if (_lockInfo.end < uint128(block.timestamp)) {
                    _lockSecsToUse = 0;
                } else {
                    _lockSecsToUse = _lockInfo.end - uint128(block.timestamp);
                }

                // Get the approximate lFPIS
                _expectedLFPIS += getCrudeExpectedLFPISOneLock(_lockInfo.amount, _lockSecsToUse);
            }

            unchecked {
                ++i;
            }
        }
    }
}

// src/contracts/VestedFXS-and-Flox/VestedFXS/VeFXSAggregator.sol

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ========================= VeFXSAggregator ==========================
// ====================================================================
// Looks at various sources of veFXS for a given address. Also gives totalSupply
// Includes:
// 1) L1veFXS: Lives on Fraxtal. Users can prove their Ethereum Mainnet vefxs.vy balance and end time so it is visible on Fraxtal
// 2) VestedFXS: Fraxtal-native veFXS. Basically the same as Mainnet vefxs.vy but lives on Fraxtal
// 3) FPISLocker: Locked FPIS on Fraxtal that eventually will be converted to FXS per https://snapshot.org/#/frax.eth/proposal/0x9ec68015d6f6fd185f600a255e494f4ff926bbdd9b268f4bd712983a6e68fb5a
// 4+) Future capability to add even more sources of veFXS

// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna

// Reviewer(s) / Contributor(s)
// Jan Turk: https://github.com/ThunderDeliverer
// Dennis: https://github.com/denett
// Sam Kazemian: https://github.com/samkazemian

// Originally inspired by Synthetix.io, but heavily modified by the Frax team (veFXS portion)
// https://github.com/Synthetixio/synthetix/blob/develop/contracts/StakingRewards.sol

contract VeFXSAggregator is OwnedV2AutoMsgSender, ReentrancyGuard, IveFXSStructs {
    using SafeERC20 for ERC20;

    // ==============================================================================
    // STATE VARIABLES
    // ==============================================================================

    // Instances
    // -------------------------
    /// @notice The Fraxtal veFXS contract
    IVestedFXS public veFXS;

    /// @notice The FPIS Locker contract
    IFPISLocker public fpisLocker;

    /// @notice The IL1VeFXS contract (snapshot of Ethereum Mainnet veFXS.vy)
    IL1VeFXS public l1veFXS;

    /// @notice The Fraxtal veFXS veFXSUtils contract
    IVestedFXSUtils public veFXSUtils;

    /// @notice The Fraxtal FPIS Locker FPISLockerUtils contract
    FPISLockerUtils public lFpisUtils;

    /// @notice Oracle on Fraxtal that reports Mainnet veFXS totalSupply.
    L1VeFXSTotalSupplyOracle public l1VeFXSTotalSupplyOracle;

    // Addresses
    // -------------------------
    /// @notice Address of the timelock
    address public timelockAddress;

    /// @notice Array of additional / future veFXS-like contracts
    address[] public addlVeContractsArr;

    /// @notice Whether an address is an additional / future veFXS-like contract
    mapping(address => bool) public addlVeContracts;

    // Misc
    // -------------------------

    /// @notice If the contract was initialized
    bool wasInitialized;

    // /// @dev reserve extra storage for future upgrades
    // uint256[50] private __gap;

    // ==============================================================================
    // STRUCTS
    // ==============================================================================

    /// @notice A more detailed breakdown of the veFXS supply
    /// @param vestedFXSTotal Fraxtal-native VestedFXS totalSupply
    /// @param fpisLockerTotal FPISLocker's totalSupply
    /// @param l1veFXSTotal Sum of L1veFXS as reported by the L1VeFXSTotalSupplyOracle
    /// @param otherSourcesTotal Sum of the totalSupply's of other veFXS sources
    /// @param grandTotal Grand totalSupply of all veFXS sources
    struct DetailedTotalSupplyInfo {
        uint256 vestedFXSTotal;
        uint256 fpisLockerTotal;
        uint256 l1veFXSTotal;
        uint256 otherSourcesTotal;
        uint256 grandTotal;
    }

    // ==============================================================================
    // MODIFIERS
    // ==============================================================================

    /// @notice A modifier that only allows the contract owner or the timelock to call
    modifier onlyByOwnGov() {
        if (msg.sender != owner && msg.sender != timelockAddress) revert NotOwnerOrTimelock();
        _;
    }

    // ==============================================================================
    // CONSTRUCTOR
    // ==============================================================================

    constructor() {
        // Set the contract as initialized
        wasInitialized = true;
    }

    /**
     * @notice Initialize contract
     * @param _owner The owner of this contract
     * @param _timelockAddress Address of the timelock
     * @param _veAddresses The addresses: 0: veFXS, 1: veFXSUtils, 2: FPIS Locker, 3: FPISLockerUtils, 4: L1VeFXS, 5: L1VeFXSTotalSupplyOracle
     */
    function initialize(address _owner, address _timelockAddress, address[6] memory _veAddresses) public {
        // Safety checks - no validation on admin in case this is initialized without admin
        if (wasInitialized) revert InitializeFailed();

        // Set owner for OwnedV2
        owner = _owner;

        // Set misc addresses
        timelockAddress = _timelockAddress;

        // Set the Fraxtal VestedFXS
        veFXS = IVestedFXS(_veAddresses[0]);
        veFXSUtils = IVestedFXSUtils(_veAddresses[1]);

        // (Optional) Set the FPISLocker
        if ((_veAddresses[2] != address(0)) && (_veAddresses[3] != address(0))) {
            fpisLocker = IFPISLocker(_veAddresses[2]);
            lFpisUtils = FPISLockerUtils(_veAddresses[3]);
        }

        // (Optional) Set the L1VeFXS andL1VeFXSTotalSupplyOracle
        if ((_veAddresses[4] != address(0)) && (_veAddresses[5] != address(0))) {
            l1veFXS = IL1VeFXS(_veAddresses[4]);
            l1VeFXSTotalSupplyOracle = L1VeFXSTotalSupplyOracle(_veAddresses[5]);
        }
    }

    // ==============================================================================
    // VIEWS
    // ==============================================================================

    /// @notice Total veFXS of a user from multiple different sources, such as the FPIS Locker, L1VeFXS, and Fraxtal veFXS
    /// @param _user The user to check
    /// @return _currBal The veFXS balance
    function ttlCombinedVeFXS(address _user) public view returns (uint256 _currBal) {
        // Look at the OG 3 sources first
        // ===========================
        // VestedFXS on Fraxtal
        _currBal = veFXS.balanceOf(_user);

        // (Optional) FPIS Locker on Fraxtal
        if (address(fpisLocker) != address(0)) _currBal += fpisLocker.balanceOf(_user);

        // (Optional) L1VeFXS: snapshot of Ethereum Mainnet veFXS. Lives on Fraxtal
        if ((address(l1veFXS) != address(0)) && (address(l1VeFXSTotalSupplyOracle) != address(0))) {
            _currBal += l1veFXS.balanceOf(_user);
        }

        // (Optional) Look at any extra veFXS sources
        for (uint256 i; i < addlVeContractsArr.length; ) {
            address _veAddr = addlVeContractsArr[i];
            if (_veAddr != address(0)) {
                _currBal += IVestedFXS(_veAddr).balanceOf(_user);
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Detailed veFXS totalSupply from multiple different sources, such as the FPIS Locker, L1VeFXS, and Fraxtal veFXS. Non-checkpointed L1VeFXS is excluded
    /// @return _supplyInfo Detailed breakdown of veFXS from different sources
    function ttlCombinedVeFXSTotalSupplyDetailed() public view returns (DetailedTotalSupplyInfo memory _supplyInfo) {
        // Look at the OG 3 sources first
        // ===========================
        // VestedFXS on Fraxtal
        _supplyInfo.vestedFXSTotal = veFXS.totalSupply();
        _supplyInfo.grandTotal = _supplyInfo.vestedFXSTotal;
        // console2.log("{agg} veFXS.totalSupply(): %s", _supplyInfo.vestedFXSTotal);

        // (Optional) FPIS Locker on Fraxtal
        if (address(fpisLocker) != address(0)) {
            _supplyInfo.fpisLockerTotal = fpisLocker.totalSupply();
            _supplyInfo.grandTotal += _supplyInfo.fpisLockerTotal;
            // console2.log("{agg} fpisLocker.totalSupply(): %s", _supplyInfo.fpisLockerTotal);
        }

        // (Optional) L1VeFXS: snapshot of Ethereum Mainnet veFXS. Lives on Fraxtal
        if ((address(l1veFXS) != address(0)) && (address(l1VeFXSTotalSupplyOracle) != address(0))) {
            _supplyInfo.l1veFXSTotal = l1VeFXSTotalSupplyOracle.totalSupply();
            _supplyInfo.grandTotal += _supplyInfo.l1veFXSTotal;
            // console2.log("{agg} l1VeFXSTotalSupplyOracle.totalSupply(): %s", _supplyInfo.l1veFXSTotal);
        }

        // (Optional) Look at any extra veFXS sources
        for (uint256 i; i < addlVeContractsArr.length; ) {
            address _veAddr = addlVeContractsArr[i];
            if (_veAddr != address(0)) {
                uint256 _thisSupply = IVestedFXS(_veAddr).totalSupply();
                _supplyInfo.otherSourcesTotal += _thisSupply;
                _supplyInfo.grandTotal += _thisSupply;
                // console2.log("{agg} addlVeContractsArr[%s].totalSupply(): %s", i, _thisSupply);
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Total veFXS totalSupply from multiple different sources, such as the FPIS Locker, L1VeFXS, and Fraxtal veFXS. Non-checkpointed L1VeFXS is excluded
    /// @return _totalSupply The veFXS totalSupply from all sources
    /// @dev Summarized version of ttlCombinedVeFXSTotalSupplyDetailed
    function ttlCombinedVeFXSTotalSupply() public view returns (uint256 _totalSupply) {
        DetailedTotalSupplyInfo memory _supplyInfo = ttlCombinedVeFXSTotalSupplyDetailed();
        _totalSupply = _supplyInfo.grandTotal;
    }

    /// @notice Array of all extra veFXS-like contracts
    /// @return _addresses The addresses
    function allAddlVeContractsAddreses() external view returns (address[] memory _addresses) {
        return addlVeContractsArr;
    }

    /// @notice Length of the array of all extra veFXS-like contracts
    /// @return _length The length
    function allAddlVeContractsLength() external view returns (uint256 _length) {
        return addlVeContractsArr.length;
    }

    /// @notice Get all the active locks for a user
    /// @param _account The account to get the locks for
    /// @param _estimateCrudeVeFXS False to save gas. True to add the lock's estimated veFXS
    /// @return _currActiveLocks Array of LockedBalanceExtendedV2 structs (all active locks)
    function getAllCurrActiveLocks(
        address _account,
        bool _estimateCrudeVeFXS
    ) public view returns (LockedBalanceExtendedV2[] memory _currActiveLocks) {
        // Prepare to allocate the return array. Not all of the locks will be active.

        // OG 3 veFXS contracts
        // ===================================
        // Fraxtal VestedFXS
        uint256 _maxArrSize = veFXS.numLocks(_account);

        // (Optional) FPIS Locker
        if (address(fpisLocker) != address(0)) _maxArrSize += fpisLocker.numLocks(_account);

        // (Optional) L1VeFXS
        if ((address(l1veFXS) != address(0)) && (address(l1VeFXSTotalSupplyOracle) != address(0))) {
            _maxArrSize += 1; // Legacy veFXS on Mainnet only has one lock
        }

        // (Optional) Get the total number of locks in the additional veFXS contracts
        for (uint256 i = 0; i < addlVeContractsArr.length; i++) {
            address _veAddr = addlVeContractsArr[i];
            if (_veAddr != address(0)) {
                // Get the total number of locks
                _maxArrSize += IVestedFXS(_veAddr).numLocks(_account);
            }
        }

        // Allocate a temporary dynamic array
        uint256 _activeLockIdx = 0;
        LockedBalanceExtendedV2[] memory _tmpActiveLocks = new LockedBalanceExtendedV2[](_maxArrSize);

        // Go through the OG 3 sources first

        // Fraxtal veFXS
        // -------------------------
        {
            // Get the LockedBalanceExtendeds
            LockedBalanceExtended[] memory _fxtlVeFXSLockedBalExtds = (veFXSUtils.getDetailedUserLockInfo(_account))
                .activeLocks;

            // Loop though the Fraxtal veFXS locks and add them to the combined array
            for (uint256 i; i < _fxtlVeFXSLockedBalExtds.length; ) {
                // Save tmp variable to memory
                IveFXSStructs.LockedBalanceExtended memory _vestedFXSLockInfo = _fxtlVeFXSLockedBalExtds[i];

                // (Optional) Estimate the lock's veFXS based on amount, end, and block.timestamp
                uint256 _estimatedVeFXS;
                if (_estimateCrudeVeFXS) {
                    _estimatedVeFXS = veFXSUtils.getCrudeExpectedVeFXSOneLock(
                        _vestedFXSLockInfo.amount,
                        _vestedFXSLockInfo.end - uint128(block.timestamp)
                    );
                }

                // Add to the temp array
                _tmpActiveLocks[_activeLockIdx] = LockedBalanceExtendedV2({
                    id: _vestedFXSLockInfo.id,
                    index: _vestedFXSLockInfo.index,
                    amount: _vestedFXSLockInfo.amount,
                    end: _vestedFXSLockInfo.end,
                    location: address(veFXS),
                    estimatedCurrLockVeFXS: _estimatedVeFXS
                });

                // Increase the active lock index
                ++_activeLockIdx;

                unchecked {
                    ++i;
                }
            }
        }

        // (Optional) FPIS Locker
        // -------------------------
        if (address(fpisLocker) != address(0)) {
            // Get the LockedBalanceExtendeds
            IlFPISStructs.LockedBalanceExtended[] memory _fpisLockerLockedBalExtds = (
                lFpisUtils.getDetailedUserLockInfo(_account)
            ).activeLocks;

            // Loop though the FPIS Locker locks and add them to the combined array
            for (uint256 i; i < _fpisLockerLockedBalExtds.length; ) {
                // Save tmp variable to memory
                IlFPISStructs.LockedBalanceExtended memory _fpisLockInfo = _fpisLockerLockedBalExtds[i];

                // Double check end time
                if (_fpisLockInfo.end > block.timestamp) {
                    // (Optional) Estimate the lock's veFXS based on amount, end, and block.timestamp
                    uint256 _estimatedVeFXS;
                    if (_estimateCrudeVeFXS) {
                        _estimatedVeFXS = lFpisUtils.getCrudeExpectedLFPISOneLock(
                            _fpisLockInfo.amount,
                            _fpisLockInfo.end - uint128(block.timestamp)
                        );
                    }

                    // Need to save as LockedBalanceExtendedV2
                    _tmpActiveLocks[_activeLockIdx] = LockedBalanceExtendedV2({
                        id: _fpisLockInfo.id,
                        index: _fpisLockInfo.index,
                        amount: _fpisLockInfo.amount,
                        end: _fpisLockInfo.end,
                        location: address(fpisLocker),
                        estimatedCurrLockVeFXS: _estimatedVeFXS
                    });

                    // Increase the active lock index
                    ++_activeLockIdx;
                }

                unchecked {
                    ++i;
                }
            }
        }

        // (Optional) L1VeFXS
        // -------------------------
        if ((address(l1veFXS) != address(0)) && (address(l1VeFXSTotalSupplyOracle) != address(0))) {
            // Get the LockedBalance
            IL1VeFXS.LockedBalance memory _l1LockedBalance = l1veFXS.locked(_account);

            // Convert to LockedBalanceExtendedV2 and push into _currCombinedLockBalExtds if it is active. There is only one lock too
            if (_l1LockedBalance.end > block.timestamp) {
                // (Optional) Estimate the lock's veFXS based on amount, end, and block.timestamp
                uint256 _estimatedVeFXS;
                if (_estimateCrudeVeFXS) {
                    _estimatedVeFXS = l1veFXS.balanceOf(_account);
                }

                // Add to the temp array
                _tmpActiveLocks[_activeLockIdx] = LockedBalanceExtendedV2({
                    id: 0,
                    index: 0,
                    amount: int128(_l1LockedBalance.amount),
                    end: _l1LockedBalance.end,
                    location: address(l1veFXS),
                    estimatedCurrLockVeFXS: _estimatedVeFXS
                });

                // Increase the active lock index
                ++_activeLockIdx;
            }
        }

        // (Optional) Look in the extra veFXS sources next. They should all be IVestedFXS ABI compliant
        for (uint256 i; i < addlVeContractsArr.length; ) {
            address _veAddr = addlVeContractsArr[i];
            if (_veAddr != address(0)) {
                // Get the active locks
                LockedBalanceExtended[] memory _addlVeFXSLockedBalExtds = (
                    IVestedFXSUtils(IVestedFXS(_veAddr).veFxsUtils()).getDetailedUserLockInfo(_account)
                ).activeLocks;

                // Loop though the active locks and add them to the combined array
                for (uint256 j; j < _addlVeFXSLockedBalExtds.length; ) {
                    // Save tmp variable to memory
                    IveFXSStructs.LockedBalanceExtended memory _addVeFXSLockInfo = _addlVeFXSLockedBalExtds[j];

                    // (Optional) Estimate the lock's veFXS based on amount, end, and block.timestamp
                    uint256 _estimatedVeFXS;
                    if (_estimateCrudeVeFXS) {
                        _estimatedVeFXS = IVestedFXSUtils(IVestedFXS(_veAddr).veFxsUtils())
                            .getCrudeExpectedVeFXSOneLock(
                                _addVeFXSLockInfo.amount,
                                _addVeFXSLockInfo.end - uint128(block.timestamp)
                            );
                    }

                    // Add to the temporary array
                    _tmpActiveLocks[_activeLockIdx] = LockedBalanceExtendedV2({
                        id: _addVeFXSLockInfo.id,
                        index: _addVeFXSLockInfo.index,
                        amount: _addVeFXSLockInfo.amount,
                        end: _addVeFXSLockInfo.end,
                        location: _veAddr,
                        estimatedCurrLockVeFXS: _estimatedVeFXS
                    });

                    // Increase the active lock index
                    ++_activeLockIdx;

                    unchecked {
                        ++j;
                    }
                }
            }

            unchecked {
                ++i;
            }
        }

        // Allocate the return array with only the number of active locks
        _currActiveLocks = new LockedBalanceExtendedV2[](_activeLockIdx);

        // Fill the return array
        for (uint256 i; i < _currActiveLocks.length; ) {
            _currActiveLocks[i] = _tmpActiveLocks[i];

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Get all the expired locks for a user
    /// @param _account The account to get the locks for
    /// @return _expiredLocks Array of LockedBalanceExtendedV2 structs (all expired locks)
    /// @dev Technically could combine with getAllCurrActiveLocks to save gas, but getAllExpiredLocks is mainly intended for a UI
    function getAllExpiredLocks(address _account) public view returns (LockedBalanceExtendedV2[] memory _expiredLocks) {
        // Prepare to allocate the return array. Not all of the locks will be expired.

        // OG 3 veFXS contracts
        // ===================================
        // Fraxtal VestedFXS
        uint256 _maxArrSize = veFXS.numLocks(_account);

        // (Optional) FPIS Locker
        if (address(fpisLocker) != address(0)) _maxArrSize += fpisLocker.numLocks(_account);

        // (Optional) L1VeFXS
        if ((address(l1veFXS) != address(0)) && (address(l1VeFXSTotalSupplyOracle) != address(0))) {
            _maxArrSize += 1; // Legacy veFXS on Mainnet only has one lock
        }

        // (Optional) Get the total number of locks in the additional veFXS contracts
        for (uint256 i = 0; i < addlVeContractsArr.length; i++) {
            address _veAddr = addlVeContractsArr[i];
            if (_veAddr != address(0)) {
                // Get the total number of locks
                _maxArrSize += IVestedFXS(_veAddr).numLocks(_account);
            }
        }

        // Allocate a temporary dynamic array
        uint256 _expiredLockIdx = 0;
        LockedBalanceExtendedV2[] memory _tmpExpiredLocks = new LockedBalanceExtendedV2[](_maxArrSize);

        // Go through the OG 3 sources first

        // Fraxtal veFXS
        // -------------------------
        {
            // Get the LockedBalanceExtendeds
            LockedBalanceExtended[] memory _fxtlVeFXSLockedBalExtds = (veFXSUtils.getDetailedUserLockInfo(_account))
                .expiredLocks;

            // Loop though the Fraxtal veFXS locks and add them to the combined array
            for (uint256 i; i < _fxtlVeFXSLockedBalExtds.length; ) {
                // Save tmp variable to memory
                IveFXSStructs.LockedBalanceExtended memory _vestedFXSLockInfo = _fxtlVeFXSLockedBalExtds[i];

                // Add to the temp array
                _tmpExpiredLocks[_expiredLockIdx] = LockedBalanceExtendedV2({
                    id: _vestedFXSLockInfo.id,
                    index: _vestedFXSLockInfo.index,
                    amount: _vestedFXSLockInfo.amount,
                    end: _vestedFXSLockInfo.end,
                    location: address(veFXS),
                    estimatedCurrLockVeFXS: 0
                });

                // Increase the expired lock index
                ++_expiredLockIdx;

                unchecked {
                    ++i;
                }
            }
        }

        // (Optional) FPIS Locker
        // -------------------------
        if (address(fpisLocker) != address(0)) {
            // Get the LockedBalanceExtendeds
            IlFPISStructs.LockedBalanceExtended[] memory _fpisLockerLockedBalExtds = (
                lFpisUtils.getDetailedUserLockInfo(_account)
            ).expiredLocks;

            // Loop though the FPIS Locker locks and add them to the combined array
            for (uint256 i; i < _fpisLockerLockedBalExtds.length; ) {
                // Save tmp variable to memory
                IlFPISStructs.LockedBalanceExtended memory _fpisLockInfo = _fpisLockerLockedBalExtds[i];

                // Need to save as LockedBalanceExtendedV2
                _tmpExpiredLocks[_expiredLockIdx] = LockedBalanceExtendedV2({
                    id: _fpisLockInfo.id,
                    index: _fpisLockInfo.index,
                    amount: _fpisLockInfo.amount,
                    end: _fpisLockInfo.end,
                    location: address(fpisLocker),
                    estimatedCurrLockVeFXS: 0
                });

                // Increase the expired lock index
                ++_expiredLockIdx;

                unchecked {
                    ++i;
                }
            }
        }

        // (Optional) L1VeFXS
        // -------------------------
        if ((address(l1veFXS) != address(0)) && (address(l1VeFXSTotalSupplyOracle) != address(0))) {
            // Get the LockedBalance
            IL1VeFXS.LockedBalance memory _l1LockedBalance = l1veFXS.locked(_account);

            // Convert to LockedBalanceExtendedV2 and push into _currCombinedLockBalExtds if it is expired. There is only one lock too
            if (_l1LockedBalance.end <= block.timestamp) {
                // Add to the temp array
                _tmpExpiredLocks[_expiredLockIdx] = LockedBalanceExtendedV2({
                    id: 0,
                    index: 0,
                    amount: int128(_l1LockedBalance.amount),
                    end: _l1LockedBalance.end,
                    location: address(l1veFXS),
                    estimatedCurrLockVeFXS: 0
                });

                // Increase the expired lock index
                ++_expiredLockIdx;
            }
        }

        // (Optional) Look in the extra veFXS sources next. They should all be IVestedFXS ABI compliant
        for (uint256 i; i < addlVeContractsArr.length; ) {
            address _veAddr = addlVeContractsArr[i];
            if (_veAddr != address(0)) {
                // Get the expired locks
                LockedBalanceExtended[] memory _addlVeFXSLockedBalExtds = (
                    IVestedFXSUtils(IVestedFXS(_veAddr).veFxsUtils()).getDetailedUserLockInfo(_account)
                ).expiredLocks;

                // Loop though the expired locks and add them to the combined array
                for (uint256 j; j < _addlVeFXSLockedBalExtds.length; ) {
                    // Save tmp variable to memory
                    IveFXSStructs.LockedBalanceExtended memory _addVeFXSLockInfo = _addlVeFXSLockedBalExtds[j];

                    // Add to the temporary array
                    _tmpExpiredLocks[_expiredLockIdx] = LockedBalanceExtendedV2({
                        id: _addVeFXSLockInfo.id,
                        index: _addVeFXSLockInfo.index,
                        amount: _addVeFXSLockInfo.amount,
                        end: _addVeFXSLockInfo.end,
                        location: _veAddr,
                        estimatedCurrLockVeFXS: 0
                    });

                    // Increase the expired lock index
                    ++_expiredLockIdx;

                    unchecked {
                        ++j;
                    }
                }
            }

            unchecked {
                ++i;
            }
        }

        // Allocate the return array with only the number of expired locks
        _expiredLocks = new LockedBalanceExtendedV2[](_expiredLockIdx);

        // Fill the return array
        for (uint256 i; i < _expiredLocks.length; ) {
            _expiredLocks[i] = _tmpExpiredLocks[i];

            unchecked {
                ++i;
            }
        }
    }

    // ==============================================================================
    // MUTATIVE FUNCTIONS
    // ==============================================================================

    // None...

    // ==============================================================================
    // RESTRICTED FUNCTIONS
    // ==============================================================================

    /// @notice Adds an additional veFXS-like contract
    /// @param _addr The contract to added
    function addAddlVeFXSContract(address _addr) public onlyByOwnGov {
        require(_addr != address(0), "Zero address detected");

        // Check the ABI here to make sure it is veFXS-like
        // None of these should revert
        IVestedFXS(_addr).totalSupply();
        IVestedFXS(_addr).balanceOf(address(0));
        IVestedFXS(_addr).numLocks(address(0));
        IVestedFXSUtils(IVestedFXS(_addr).veFxsUtils()).getDetailedUserLockInfo(address(0));
        IVestedFXSUtils(IVestedFXS(_addr).veFxsUtils()).getCrudeExpectedVeFXSOneLock(1e18, 604_800);

        require(addlVeContracts[_addr] == false, "Address already exists");
        addlVeContracts[_addr] = true;
        addlVeContractsArr.push(_addr);

        emit AddlVeFXSContractAdded(_addr);
    }

    /// @notice Removes a veFXS-like contract. Will need to mass checkpoint on the yield distributor or other sources to reflect new stored total veFXS
    /// @param _addr The contract to remove
    function removeAddlVeFXSContract(address _addr) public onlyByOwnGov {
        require(_addr != address(0), "Zero address detected");
        require(addlVeContracts[_addr] == true, "Address nonexistent");

        // Delete from the mapping
        delete addlVeContracts[_addr];

        // 'Delete' from the array by setting the address to 0x0
        for (uint256 i = 0; i < addlVeContractsArr.length; i++) {
            if (addlVeContractsArr[i] == _addr) {
                addlVeContractsArr[i] = address(0); // This will leave a null in the array and keep the indices the same
                break;
            }
        }

        emit AddlVeFXSContractRemoved(_addr);
    }

    /// @notice Added to support recovering LP Yield and other mistaken tokens from other systems to be distributed to holders
    /// @param _tokenAddress The token to recover
    /// @param _tokenAmount The amount to recover
    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyByOwnGov {
        // Only the owner address can ever receive the recovery withdrawal
        TransferHelper.safeTransfer(_tokenAddress, owner, _tokenAmount);
        emit RecoveredERC20(_tokenAddress, _tokenAmount);
    }

    /// @notice Set the original 3 veFXS-like contracts on Fraxtal
    /// @param _veAddresses The addresses: 0: veFXS, 1: veFXSUtils, 2: FPIS Locker, 3: FPISLockerUtils, 4: L1VeFXS, 5: L1VeFXSTotalSupplyOracle
    function setAddresses(address[6] calldata _veAddresses) external onlyByOwnGov {
        // Future upgrade: remove this once full support is added and tested
        require(_veAddresses[0] != address(0), "veFXS must not be 0x0");
        require(_veAddresses[1] != address(0), "veFXSUtils must not be 0x0");
        require(_veAddresses[2] != address(0), "Cannot add FPISLocker yet");
        require(_veAddresses[3] != address(0), "Cannot add FPISLockerUtils yet");
        require(_veAddresses[4] != address(0), "Cannot add L1VeFXS yet");
        require(_veAddresses[5] != address(0), "Cannot add L1VeFXSTotalSupplyOracle yet");

        // Set veFXS-like addresses
        veFXS = IVestedFXS(_veAddresses[0]);
        veFXSUtils = IVestedFXSUtils(_veAddresses[1]);

        // FPIS Locker
        if ((_veAddresses[2] != address(0)) && _veAddresses[3] != address(0)) {
            fpisLocker = IFPISLocker(_veAddresses[2]);
            lFpisUtils = FPISLockerUtils(_veAddresses[3]);
        }

        // L1VeFXS and L1VeFXSTotalSupplyOracle
        if ((_veAddresses[4] != address(0)) && (_veAddresses[5] != address(0))) {
            l1veFXS = IL1VeFXS(_veAddresses[4]);
            l1VeFXSTotalSupplyOracle = L1VeFXSTotalSupplyOracle(_veAddresses[5]);
        }
    }

    /// @notice Set the timelock address
    /// @param _newTimelock The address of the timelock
    function setTimelock(address _newTimelock) external onlyByOwnGov {
        timelockAddress = _newTimelock;
    }

    // ==============================================================================
    // EVENTS
    // ==============================================================================

    /// @notice When an additional veFXS contract is added
    /// @param addr The contract that was added
    event AddlVeFXSContractAdded(address addr);

    /// @notice When an additional veFXS contract is removed
    /// @param addr The contract that was removed
    event AddlVeFXSContractRemoved(address addr);

    /// @notice When the contract is initialized
    event DefaultInitialization();

    /// @notice When ERC20 tokens were recovered
    /// @param token Token address
    /// @param amount Amount of tokens collected
    event RecoveredERC20(address token, uint256 amount);

    /// @notice When a reward is deposited
    /// @param reward Amount of tokens deposited
    /// @param yieldRate The resultant yield/emission rate
    event RewardAdded(uint256 reward, uint256 yieldRate);

    /// @notice When yield is collected
    /// @param user Address collecting the yield
    /// @param yield The amount of tokens collected
    /// @param tokenAddress The address collecting the rewards
    event YieldCollected(address indexed user, uint256 yield, address tokenAddress);

    /// @notice When the yield duration is updated
    /// @param newDuration The new duration
    event YieldDurationUpdated(uint256 newDuration);

    // ==============================================================================
    // ERRORS
    // ==============================================================================

    /// @notice Cannot initialize twice
    error InitializeFailed();

    /// @notice If you are trying to call a function not as the owner or timelock
    error NotOwnerOrTimelock();
}

// src/contracts/VestedFXS-and-Flox/VestedFXS/YieldDistributor.sol

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// =========================YieldDistributor===========================
// ====================================================================
// Distributes Frax protocol yield based on the claimer's veFXS balance
// Yield will now not accrue for unlocked veFXS

// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)

// Jan Turk: https://github.com/ThunderDeliverer
// Travis Moore: https://github.com/FortisFortuna

// Reviewer(s) / Contributor(s)
// Sam Kazemian: https://github.com/samkazemian

// Originally inspired by Synthetix.io, but heavily modified by the Frax team (veFXS portion)
// https://github.com/Synthetixio/synthetix/blob/develop/contracts/StakingRewards.sol

contract YieldDistributor is OwnedV2AutoMsgSender, ReentrancyGuard, IveFXSStructs {
    using SafeERC20 for ERC20;

    // ==============================================================================
    // STATE VARIABLES
    // ==============================================================================

    // Instances
    // -------------------------
    /// @notice Aggregator contract that sums a user's veFXS from multiple sources
    VeFXSAggregator public veFXSAggregator;

    /// @notice ERC20 instance of the token being emitted
    ERC20 public emittedToken;

    // Addresses
    // -------------------------
    /// @notice Address of the token being emitted
    address public emittedTokenAddress;

    /// @notice Address of the timelock
    address public timelockAddress;

    // Yield and period related
    // -------------------------
    /// @notice Timestamp when the reward period ends
    uint256 public periodFinish;

    /// @notice Timestamp when the contract was last synced or had rewards deposited
    uint256 public lastUpdateTime;

    /// @notice Emission rate of tokens, in tokens per second
    uint256 public yieldRate;

    /// @notice Duration of the period, in seconds
    uint256 public yieldDuration; // 7 * 86400  (7 days)

    /// @notice Mapping of addresses that are allowed to deposit reward tokens
    mapping(address => bool) public rewardNotifiers;

    // Yield tracking
    // -------------------------
    /// @notice Accumulator for tracking contract-wide rewards paid
    uint256 public yieldPerVeFXSStored;

    /// @notice Accumulator for tracking user-specific rewards paid
    mapping(address => uint256) public userYieldPerTokenPaid;

    /// @notice Last stored version of earned(). Set to 0 on yield claim and to earned() on a checkpoint.
    mapping(address => uint256) public yields;

    // veFXS tracking
    // -------------------------
    /// @notice Total amount of veFXS that was checkpointed and is earning
    uint256 public totalVeFXSParticipating;

    /// @notice Stored version of the total veFXS supply
    uint256 public totalComboVeFXSSupplyStored;

    /// @notice If the user was initialized or not
    mapping(address => bool) public userIsInitialized;

    /// @notice Last stored veFXS balance for the user
    mapping(address => uint256) public userVeFXSCheckpointed;

    /// @notice The stored shortest endpoint of any of the user's veFXS positions. You will need to re-checkpoint after any lock expires if you want to keep earning.
    mapping(address => uint256) public userVeFXSEndpointCheckpointed;

    /// @notice Last time the user claimed their yield
    mapping(address => uint256) private lastRewardClaimTime; // staker addr -> timestamp

    // Greylists
    // -------------------------
    /// @notice A graylist for questionable users
    mapping(address => bool) public greylist;

    // Constants
    // -------------------------
    /// @notice Constant for price precision
    uint256 private constant PRICE_PRECISION = 1e6;

    // Admin related
    // -------------------------

    /// @notice For Convex, StakeDAO, etc whose contract addresses cannot claim for themselves. Admin set on a case-by-case basis
    mapping(address staker => address claimer) public thirdPartyClaimers;

    /// @notice A graylist for questionable users
    bool public yieldCollectionPaused = false; // For emergencies

    // Misc
    // -------------------------
    /// @notice If the contract was initialized
    bool wasInitialized;

    // Gap
    // -------------------------

    /// @dev reserve extra storage for future upgrades
    uint256[50] private __gap;

    // ==============================================================================
    // MODIFIERS
    // ==============================================================================

    /// @notice A modifier that only allows the contract owner or the timelock to call
    modifier onlyByOwnGov() {
        if (msg.sender != owner && msg.sender != timelockAddress) revert NotOwnerOrTimelock();
        _;
    }

    /// @notice Make sure yield collection is not paused
    modifier notYieldCollectionPaused() {
        if (yieldCollectionPaused) revert YieldCollectionPaused();
        _;
    }

    /// @notice Checkpoint the user
    modifier checkpointUser(address account) {
        _checkpointUser(account, true);
        _;
    }

    // ==============================================================================
    // CONSTRUCTOR
    // ==============================================================================

    constructor() {
        // Set the contract as initialized
        wasInitialized = true;
    }

    /// @notice Initialize contract
    /// @param _owner The owner of this contract
    /// @param _timelockAddress Address of the timelock
    /// @param _emittedToken Address of the token being emitted as yield
    /// @param _veFXSAggregator Address of the veFXS aggregator
    function initialize(
        address _owner,
        address _timelockAddress,
        address _emittedToken,
        address _veFXSAggregator
    ) public {
        // Safety checks - no validation on admin in case this is initialized without admin
        if (wasInitialized || _emittedToken == address(0) || emittedTokenAddress != address(0)) {
            revert InitializeFailed();
        }

        // Set owner for OwnedV2
        owner = _owner;

        // Set misc addresses
        emittedTokenAddress = _emittedToken;
        emittedToken = ERC20(_emittedToken);
        timelockAddress = _timelockAddress;

        // Set the veFXS Aggregator
        veFXSAggregator = VeFXSAggregator(_veFXSAggregator);

        // Initialize other variables
        lastUpdateTime = block.timestamp;
        rewardNotifiers[_owner] = true;
        yieldDuration = 604_800;
    }

    // ==============================================================================
    // VIEWS
    // ==============================================================================

    /// @notice Fraction of the total Fraxtal-visible veFXS collecting yield
    /// @return _fraction The Fraction
    function fractionParticipating() external view returns (uint256 _fraction) {
        if (totalComboVeFXSSupplyStored == 0) return 0;
        else return (totalVeFXSParticipating * PRICE_PRECISION) / totalComboVeFXSSupplyStored;
    }

    /// @notice Eligible veFXS for a given user. Only positions with locked veFXS can accrue yield, not expired positions
    /// @param _user The user to check
    /// @return _eligibleVefxsBal Eligible veFXS
    /// @return _storedEndingTimestamp The stored ending timestamp
    function eligibleCurrentVeFXS(
        address _user
    ) public view returns (uint256 _eligibleVefxsBal, uint256 _storedEndingTimestamp) {
        // Get the total combined veFXS from all sources
        uint256 _currVefxsBal = veFXSAggregator.ttlCombinedVeFXS(_user);

        // Stored is used to prevent abuse
        _storedEndingTimestamp = userVeFXSEndpointCheckpointed[_user];

        // Only unexpired veFXS should be eligible
        if (block.timestamp >= _storedEndingTimestamp) {
            _eligibleVefxsBal = 0;
        } else {
            _eligibleVefxsBal = _currVefxsBal;
        }
    }

    /// @notice Last time the yield was accruing
    /// @return _ts The timestamp
    function lastTimeYieldApplicable() public view returns (uint256 _ts) {
        return (block.timestamp < periodFinish ? block.timestamp : periodFinish);
    }

    /// @notice Amount of yield per veFXS
    /// @return _yield The amount of yield
    function yieldPerVeFXS() public view returns (uint256 _yield) {
        if (totalComboVeFXSSupplyStored == 0) {
            return yieldPerVeFXSStored;
        } else {
            return (yieldPerVeFXSStored +
                (((lastTimeYieldApplicable() - lastUpdateTime) * yieldRate * 1e18) / totalComboVeFXSSupplyStored));
        }
    }

    /// @notice Amount of tokens claimaible as yield
    /// @param _account The user to check
    /// @return _earned The amount of yield
    function earned(address _account) public view returns (uint256 _earned) {
        // Uninitialized users should not earn anything yet
        // console2.log("userIsInitialized[_account]: ", userIsInitialized[_account]);
        if (!userIsInitialized[_account]) return 0;

        // Get eligible veFXS balances
        (uint256 eligibleCurrentVefxs, uint256 endingTimestamp) = eligibleCurrentVeFXS(_account);

        // If your veFXS is unlocked
        uint256 eligibleTimeFraction = PRICE_PRECISION;
        // console2.log("eligibleTimeFraction: ", eligibleTimeFraction);
        if (eligibleCurrentVefxs == 0) {
            // console2.log("block.timestamp: ", block.timestamp);
            // console2.log("lastRewardClaimTime[_account]: ", lastRewardClaimTime[_account]);
            // console2.log("endingTimestamp: ", endingTimestamp);

            // And you already claimed after expiration
            if (lastRewardClaimTime[_account] >= endingTimestamp) {
                // You get NOTHING. You LOSE. Good DAY ser!
                return 0;
            }
            // You haven't claimed yet
            else {
                // See what fraction of the time since you last claimed that you were eligible for earning
                // console2.log("calculating eligibleTimeFraction");
                uint256 eligibleTime = endingTimestamp - lastRewardClaimTime[_account];
                // console2.log("eligibleTime: ", eligibleTime);
                uint256 totalTime = block.timestamp - lastRewardClaimTime[_account];
                // console2.log("totalTime: ", totalTime);
                eligibleTimeFraction = (PRICE_PRECISION * eligibleTime) / totalTime;
                // console2.log("eligibleTimeFraction: ", eligibleTimeFraction);
            }
        }

        // If the amount of veFXS increased, only pay off based on the old balance
        // Otherwise, take the midpoint
        uint256 vefxsBalanceToUse;
        uint256 oldVefxsBalance = userVeFXSCheckpointed[_account];
        // console2.log("vefxsBalanceToUse: ", vefxsBalanceToUse);
        // console2.log("oldVefxsBalance: ", oldVefxsBalance);
        if (eligibleCurrentVefxs > oldVefxsBalance) {
            // VeFXS increased so use old amount
            vefxsBalanceToUse = oldVefxsBalance;
            // console2.log("VeFXS increased so use old amount: ", vefxsBalanceToUse);
        } else {
            // VeFXS decreased so use midpoint (average)
            vefxsBalanceToUse = (eligibleCurrentVefxs + oldVefxsBalance) / 2;
            // console2.log("VeFXS decreased so use midpoint (average): ", vefxsBalanceToUse);

            // Print old earnings if there was no midpointing (debug only)
            // uint256 _oldVeFXSEarnings = ((oldVefxsBalance *
            //     (yieldPerVeFXS() - userYieldPerTokenPaid[_account]) *
            //     eligibleTimeFraction) /
            //     (1e18 * PRICE_PRECISION) +
            //     yields[_account]);
            // console2.log("Old earnings would have been: ", _oldVeFXSEarnings);
        }

        // Calculate earnings
        return ((vefxsBalanceToUse * (yieldPerVeFXS() - userYieldPerTokenPaid[_account]) * eligibleTimeFraction) /
            (1e18 * PRICE_PRECISION) +
            yields[_account]);
    }

    /// @notice Total amount of yield for the duration (normally a week)
    /// @return _yield The amount of yield
    function getYieldForDuration() external view returns (uint256 _yield) {
        return (yieldRate * yieldDuration);
    }

    // ==============================================================================
    // MUTATIVE FUNCTIONS
    // ==============================================================================

    /// @notice Checkpoint a user's earnings
    /// @param _account The user to checkpoint
    /// @param _syncToo Should normally be true. Can be false only for bulkCheckpointOtherUsers to save gas since it calls sync() once beforehand
    /// @dev If you want to keep earning, you need to make sure you checkpoint after ANY lock expires
    function _checkpointUser(address _account, bool _syncToo) internal {
        // Need to retro-adjust some things if the period hasn't been renewed, then start a new one

        // Should always sync unless you are bulkCheckpointOtherUsers, which can be called once beforehand to save gas
        if (_syncToo) sync();

        // Calculate the earnings first
        _syncEarned(_account);

        // Get the old and the new veFXS balances
        uint256 _oldVefxsBalance = userVeFXSCheckpointed[_account];

        // Get the total combined veFXS from all sources
        uint256 _newVefxsBalance = veFXSAggregator.ttlCombinedVeFXS(_account);

        // Update the user's stored veFXS balance
        userVeFXSCheckpointed[_account] = _newVefxsBalance;

        // Collect all active locks
        LockedBalanceExtendedV2[] memory _currCombinedLockBalExtds = veFXSAggregator.getAllCurrActiveLocks(
            _account,
            false
        );

        // Update the user's stored ending timestamp
        // TODO: Check this math as well as corner cases
        // TODO: Is there a better way to do this? This might be ok for now since gas is low on Fraxtal, but in the future,
        // I imagine there is a more elegant solution
        // ----------------------
        uint128 _shortestActiveLockEnd;

        // In case there are no active locks anywhere
        if (_currCombinedLockBalExtds.length > 0) {
            // console2.log("_checkpointUser > 0 active locks");
            _shortestActiveLockEnd = _currCombinedLockBalExtds[0].end;
        }

        // Find the timestamp of the lock closest to expiry
        if (_currCombinedLockBalExtds.length > 1) {
            // console2.log("_checkpointUser > 1 active locks");
            for (uint256 i; i < _currCombinedLockBalExtds.length; ) {
                // console2.log("_currCombinedLockBalExtds[i].end: ", _currCombinedLockBalExtds[i].end);
                if (_currCombinedLockBalExtds[i].end < _shortestActiveLockEnd) {
                    _shortestActiveLockEnd = _currCombinedLockBalExtds[i].end;
                }

                unchecked {
                    ++i;
                }
            }
        }
        // console2.log("userVeFXSEndpointCheckpointed result: ", _shortestActiveLockEnd);
        userVeFXSEndpointCheckpointed[_account] = _shortestActiveLockEnd;

        // Update the total amount participating
        if (_newVefxsBalance >= _oldVefxsBalance) {
            uint256 weightDiff = _newVefxsBalance - _oldVefxsBalance;
            totalVeFXSParticipating = totalVeFXSParticipating + weightDiff;
        } else {
            uint256 weightDiff = _oldVefxsBalance - _newVefxsBalance;
            totalVeFXSParticipating = totalVeFXSParticipating - weightDiff;
        }

        // Mark the user as initialized
        if (!userIsInitialized[_account]) {
            userIsInitialized[_account] = true;
            lastRewardClaimTime[_account] = block.timestamp;
        }
    }

    /// @notice Sync a user's earnings
    /// @param _account The user to sync
    function _syncEarned(address _account) internal {
        if (_account != address(0)) {
            uint256 earned0 = earned(_account);
            yields[_account] = earned0;
            userYieldPerTokenPaid[_account] = yieldPerVeFXSStored;
        }
    }

    /// @notice Anyone can checkpoint another user
    /// @param _account The user to sync
    function checkpointOtherUser(address _account) external {
        _checkpointUser(_account, true);
    }

    /// @notice Anyone can checkpoint other users
    /// @param _accounts The users to sync
    function bulkCheckpointOtherUsers(address[] memory _accounts) external {
        // Loop through the addresses
        for (uint256 i = 0; i < _accounts.length; ) {
            // Sync once to save gas
            sync();

            // Can skip syncing here since you did it above
            _checkpointUser(_accounts[i], false);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Checkpoint yourself
    function checkpoint() external {
        _checkpointUser(msg.sender, true);
    }

    /// @notice Retrieve yield for a specific address and send it to the designed recipient
    /// @param _staker The address whose rewards to collect
    /// @param _recipient Recipient of the rewards
    /// @return _yield0 The amount collected
    function _getYield(
        address _staker,
        address _recipient
    ) internal nonReentrant notYieldCollectionPaused checkpointUser(_staker) returns (uint256 _yield0) {
        if (greylist[_staker]) revert AddressGreylisted();

        _yield0 = yields[_staker];
        if (_yield0 > 0) {
            yields[_staker] = 0;
            TransferHelper.safeTransfer(emittedTokenAddress, _recipient, _yield0);
            emit YieldCollected(_staker, _recipient, _yield0, emittedTokenAddress);
        }

        lastRewardClaimTime[_staker] = block.timestamp;
    }

    /// @notice Retrieve own yield
    /// @return _yield0 The amount collected
    function getYield() external returns (uint256 _yield0) {
        // Sender collects rewards for himself
        _yield0 = _getYield(msg.sender, msg.sender);
    }

    /// @notice Retrieve another address's yield. Only for specific cases (e.g. Convex, etc) where the mainnet contract cannot claim for itself
    /// @param _staker Address whose rewards to collect
    /// @return _yield0 The amount collected
    /// @dev Only specific addresses allowed by the admin can do this, and only 1:1 (i.e. the third party can only collect one specified address's rewards)
    function getYieldThirdParty(address _staker) external returns (uint256 _yield0) {
        // Make sure the sender is authorized for this _staker
        if (thirdPartyClaimers[_staker] != msg.sender) revert SenderNotAuthorizedClaimer();

        // Sender collects _staker's rewards and sends to himself
        _yield0 = _getYield(_staker, msg.sender);
    }

    /// @notice Sync contract-wide variables
    function sync() public {
        // Update the yieldPerVeFXSStored
        // console2.log("Update the yieldPerVeFXSStored");
        yieldPerVeFXSStored = yieldPerVeFXS();

        // Update the total veFXS supply
        // console2.log("Update the totalComboVeFXSSupplyStored");
        totalComboVeFXSSupplyStored = veFXSAggregator.ttlCombinedVeFXSTotalSupply();

        // Update the last update time
        // console2.log("Update the lastUpdateTime");
        lastUpdateTime = lastTimeYieldApplicable();

        // console2.log("Sync completed");
    }

    /// @notice Deposit rewards. Only callable by privileged users
    /// @param _amount The amount to deposit
    function notifyRewardAmount(uint256 _amount) external {
        // Only whitelisted addresses can notify rewards
        if (!rewardNotifiers[msg.sender]) revert SenderNotRewarder();

        // Handle the transfer of emission tokens via `transferFrom` to reduce the number
        // of transactions required and ensure correctness of the emission amount
        emittedToken.safeTransferFrom(msg.sender, address(this), _amount);

        // Update some values beforehand
        sync();

        // Update the new yieldRate
        if (block.timestamp >= periodFinish) {
            yieldRate = _amount / yieldDuration;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * yieldRate;
            yieldRate = (_amount + leftover) / yieldDuration;
        }

        // Update duration-related info
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + yieldDuration;

        // Update some values afterwards
        totalComboVeFXSSupplyStored = veFXSAggregator.ttlCombinedVeFXSTotalSupply();

        emit RewardAdded(_amount, yieldRate);
    }

    // ==============================================================================
    // RESTRICTED FUNCTIONS
    // ==============================================================================

    /// @notice Added to support recovering LP Yield and other mistaken tokens from other systems to be distributed to holders
    /// @param _tokenAddress The token to recover
    /// @param _tokenAmount The amount to recover
    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyByOwnGov {
        // Only the owner address can ever receive the recovery withdrawal
        TransferHelper.safeTransfer(_tokenAddress, owner, _tokenAmount);
        emit RecoveredERC20(_tokenAddress, _tokenAmount);
    }

    /// @notice Set the duration of the yield
    /// @param _yieldDuration New duration in seconds
    function setYieldDuration(uint256 _yieldDuration) external onlyByOwnGov {
        if (periodFinish != 0 && block.timestamp <= periodFinish) {
            revert YieldPeriodMustCompleteBeforeChangingToNewPeriod();
        }
        yieldDuration = _yieldDuration;
        emit YieldDurationUpdated(yieldDuration);
    }

    /// @notice Greylist an address that is misbehaving
    /// @dev This is a toggle, so it can re-enable to user as well
    /// @param _address The address to greylist
    function greylistAddress(address _address) external onlyByOwnGov {
        greylist[_address] = !(greylist[_address]);
    }

    /// @notice Toggle an address as being able to be a reward notifier
    /// @param _notifierAddr The address to toggle
    function toggleRewardNotifier(address _notifierAddr) external onlyByOwnGov {
        rewardNotifiers[_notifierAddr] = !rewardNotifiers[_notifierAddr];
    }

    /// @notice Set the veFXS Aggregator contract
    /// @param _veFXSAggregator The new address of the veFXS Aggregator
    function setVeFXSAggregator(address _veFXSAggregator) external onlyByOwnGov {
        veFXSAggregator = VeFXSAggregator(_veFXSAggregator);
    }

    /// @notice Pause / unpause yield collecting
    /// @param _yieldCollectionPaused The new status
    function setPauses(bool _yieldCollectionPaused) external onlyByOwnGov {
        yieldCollectionPaused = _yieldCollectionPaused;
    }

    /// @notice Used for manual reward rates. Only valid until the next notifyRewardAmount() or setYieldRate()
    /// @param _newRate The new rate
    /// @param _syncToo Whether to sync or not
    function setYieldRate(uint256 _newRate, bool _syncToo) external onlyByOwnGov {
        yieldRate = _newRate;

        if (_syncToo) {
            sync();
        }
    }

    /// @notice Allow a 3rd party address to claim the rewards of a specific staker
    /// @param _staker The address of the staker
    /// @param _claimer The address of the claimer
    /// @dev For Convex, StakeDAO, etc whose contract addresses cannot claim for themselves. Admin set on a case-by-case basis
    function setThirdPartyClaimer(address _staker, address _claimer) external onlyByOwnGov {
        thirdPartyClaimers[_staker] = _claimer;
    }

    /// @notice Set the timelock address
    /// @param _newTimelock The address of the timelock
    function setTimelock(address _newTimelock) external onlyByOwnGov {
        timelockAddress = _newTimelock;
    }

    // ==============================================================================
    // EVENTS
    // ==============================================================================

    /// @notice When the contract is initialized
    event DefaultInitialization();

    /// @notice When ERC20 tokens were recovered
    /// @param token Token address
    /// @param amount Amount of tokens collected
    event RecoveredERC20(address token, uint256 amount);

    /// @notice When a reward is deposited
    /// @param reward Amount of tokens deposited
    /// @param yieldRate The resultant yield/emission rate
    event RewardAdded(uint256 reward, uint256 yieldRate);

    /// @notice When yield is collected
    /// @param staker Address whose rewards to collect
    /// @param recipient Address where the yield is ultimately sent
    /// @param yield The amount of tokens collected
    /// @param tokenAddress The address collecting the rewards
    event YieldCollected(address indexed staker, address indexed recipient, uint256 yield, address tokenAddress);

    /// @notice When the yield duration is updated
    /// @param newDuration The new duration
    event YieldDurationUpdated(uint256 newDuration);

    // ==============================================================================
    // ERRORS
    // ==============================================================================

    /// @notice If the address was greylisted
    error AddressGreylisted();

    /// @notice Cannot initialize twice
    error InitializeFailed();

    /// @notice If you are trying to call a function not as the owner or timelock
    error NotOwnerOrTimelock();

    /// @notice If the sender is not an authorized thirdPartyClaimers for the specified staker address
    error SenderNotAuthorizedClaimer();

    /// @notice If the sender is not a rewarder
    error SenderNotRewarder();

    /// @notice If yield collection is paused
    error YieldCollectionPaused();

    /// @notice If you are trying to change a yield period before it ends
    error YieldPeriodMustCompleteBeforeChangingToNewPeriod();

    /* ====================================== A NIFFLER ================================================ */
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0OxdOKKOOkxxxxxxk0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0dl:,',cc:;;;;;;;;,'';cx0XWMMMMMMMMMMMMMMMMMMMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkl:;::::::::::;;;;:::::;;,;cox0NWMMMMMMMMMMMMMMMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXxc;;:;;;;;;;,;,,,,,,,,,;,,,,,,,,;cdOXMMMMMMMMMMMMMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOc;;;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'.;d0NMMMMMMMMMMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd;;:;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'',l0WMMMMMMMMMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo;;;,,,,,,,,,,,,,,,,,,,,,,''''''',,,,,,,,,,ckNMMMMMMMMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd;;,,,,,,,,,,,,,,,,,,,,,,,'''''...'',,,,,,,,,,l0WMMMMMMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'''''',,,,,,,'.'xNMMMMMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'.'kWMMMMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0:',,,,,,,,,,,,,,,;;;,,,,,,,,,,,,,,,,,,,,,,,,,,,,''lKMMMMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO;',,;;,,,,,,,;:cc:;:c;,,,,,,,,,,,,,,,,,,,,,,,,,,,,'c0WMMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk,';lkkxoc;,,,cxl,...cl,,,,,,,,,,,,,,,,,,,,,,,,,,,,'':OWMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx;cx00000OkdooxOd;',;ll,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'.;OWMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKOxdxO00000000000000Oxxxd:,,''',,,,,,,,,,,,,,,,,,,,,,,,'..,OWMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMWKkkOO00OOkxxxO00000000000000000Okddd:.....'''''',,,,,,,,,,,,,,,,,,,'..oNMMMMMMM
    // MMMMMMMMMMMMMMMMMMMM0ookkxxxdxk00000000000000000Okkkxxdl;............',,,,,,,,,,,,,,,,,,'..;OMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMKdoxOOOO000000000000000Okkxdollc:;'.....''..''....',,,,,,,,,,,,,,,,,,'..;KMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMNOxddodddxxxxxxxxddoll:,,,,,'''''''.'',,''',,'','',,,,,,,,,,,,,,,,,,,'..dNMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMNXK0OOOkkkkkkkOkdc;'.',,,,,,''''',,,,,,,,,,,,,,,,,,,,,',,,,,,,,,,,,.,xNMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKko:;:lodxxxxxdolc;,,,,,,,,,,,,,,,,,,,'''',,,,,,,,,,,,''dWMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkddl:lxO000000000000Odc;,,,,,,,,,,,,,,'.',,,,,,,,,,,,,,,,.:KMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0odO0kooxO00000000000000Oxl:::::::;;;::,.',,,,,,,,,,,,,,,,,',kMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXdlk0kdodO000000000000000kxdxOOOOOkkkkOkxc,',,,,,,,,,,,,,,,,'.dWMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMWNKkdoccol:loc:;:lllllllooddxkOOOdllok0OO0000000Od;',,,,,,,,,,,,,,,,'.lNMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMKl:c::c:;,,','',,,,,,,,,,,,,,,;:cllcc::::::clodxxdc,',,,'''..'',,,,,,'.cXMMMM
    // MMMMMMMMMMMMMMMMMMMMMMXo:clc:;,,,,,,,,,,,,,,,,,,,,,,,,,,,,;;,''''''''''''..........',,,,,,,,..cXMMMM
    // MMMMMMMMMMMMMMMMMMMMMMOlol,'',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,''''''''....''''''',,,,,,,,,,,,,..lNMMMM
    // MMMMMMMMMMMMMMMMMMMMMMk:;,,,,,,,,,,,,,,,,,,,,,,,:,',,,,,,,''..............'',,,,,,,,,,,,,,,,..dWMMMM
    // MMMMWWWMWWMMMMMMMMMMMXl'',,,,,,,,,,,,,,,,;:;:olcdocl:'''.....'',,,,,,''',''..',,,,,,,,,,,,,'.;0MMMMM
    // MMMMXdlxllkXWMNXWMMMNo..,,,,,,,,,,,,,,,,,:oxoxkxkOOOl'....'',,,,,,,,,,,,,,,,'.'',,,,,,,,,,'..oWMMMMM
    // MMMMWk,...';ldc,lxk0k;.',,,,,,,,,,,,,,,,,;ckOOO00000l..'',,,,,,,,,,,,,,,,,,,,,'',,,,,,,,,,..'kMMMMMM
    // MMMMMNl..,,,,'''''',,'....'',,,,,,,,,,,,cook0000000Oc..',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'..;0MMMMMM
    // MMMMMMO...',,,,,,,,,,,'.'''..''',,,,,,,,lkkO000000Ox;.',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,...lNMMMMMM
    // MMMMMMNl....'',,,,,,,,,,,,,,''''..',,,,;dkO00000xlc:,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'..'kMMMMMMM
    // MMMMMMMk'....',,,,,,,,,,,,,,,,,''..'',,:xkO000Oxc,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'...cXMMMMMMM
    // MMMMMMMX:....'',,,,,,,,,,,,,,,,,,''..''cxkO0Oxl:,,,,,,,,,,,,,,,,,,,,,,',,,,,,,,,,,,,,,'..,o0MMMMMMMM
    // MMMMMMMM0,.....'',,,,,,,,,,,,,,,,,,,'.':xkOOd;'',,,,,,,,,,,,,,,,,,,,'''',,,,,,,,,,,,,'..'kWMMMMMMMMM
    // MMMMMMMMW0;......'',,,,,,,,,,,,,,,,,,'';dkkd:,,,,,,,,,,,,,,,,,,,,,,'''',,,,,,,,,,,,,'..'xWMMMMMMMMMM
    // MMMMMMMMMMKl.......'',,,,,,,,,,,,,,,,,,,cdl;,,,,,,,,,,,,,,,,,,,,'''''',,,,,,,,,,,,,'..'xNMMMMMMMMMMM
    // MMMMMMMMMMMNx,.......''',,,,,,,,,,,,,,,',;,',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,''...;OWMMMMMMMMMMMM
    // MMMMMMMMMMMMNk;..........'',,,,,,,,,,,,,'..',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'....'oXMMMMMMMMMMMMMM
    // MMMMMMMMMMMMMWXx;.......'',,,,,,,,,,,,,,'..',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'....'l0WMMMMMMMMMMMMMMM
    // MMMMMMMMMMMMMMMMN0o;......''''''''',,,,,,''',,,,,,,,,,,,,,,,,,,,,''',,,,,''....'l0WMMMMMMMMMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMNk:..............'''''','',,,,,,,,,,,,,,,,'''...''''...':ccdKWMMMMMMMMMMMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMN0dc;'..................''''''''''''''..........';cokKNNNMMMMMMMMMMMMMMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMNX0Okxddoolc::;,'............''','...',:loxOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXK0OOOkkkkkOOO0KKK000KXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
}
