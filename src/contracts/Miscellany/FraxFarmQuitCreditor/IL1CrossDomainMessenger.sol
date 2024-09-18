// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IL1CrossDomainMessenger {
    function MESSAGE_VERSION() external view returns (uint16);

    function MIN_GAS_CALLDATA_OVERHEAD() external view returns (uint64);

    function MIN_GAS_DYNAMIC_OVERHEAD_DENOMINATOR() external view returns (uint64);

    function MIN_GAS_DYNAMIC_OVERHEAD_NUMERATOR() external view returns (uint64);

    function OTHER_MESSENGER() external view returns (address);

    function PORTAL() external view returns (address);

    function RELAY_CALL_OVERHEAD() external view returns (uint64);

    function RELAY_CONSTANT_OVERHEAD() external view returns (uint64);

    function RELAY_GAS_CHECK_BUFFER() external view returns (uint64);

    function RELAY_RESERVED_GAS() external view returns (uint64);

    function baseGas(bytes memory _message, uint32 _minGasLimit) external pure returns (uint64);

    function failedMessages(bytes32) external view returns (bool);

    function initialize(address _superchainConfig) external;

    function messageNonce() external view returns (uint256);

    function paused() external view returns (bool);

    function portal() external view returns (address);

    function relayMessage(
        uint256 _nonce,
        address _sender,
        address _target,
        uint256 _value,
        uint256 _minGasLimit,
        bytes memory _message
    ) external;

    function sendMessage(address _target, bytes memory _message, uint32 _minGasLimit) external payable;

    function successfulMessages(bytes32) external view returns (bool);

    function superchainConfig() external view returns (address);

    function version() external view returns (string memory);

    function xDomainMessageSender() external view returns (address);
}
