// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Storage } from "./Storage.sol";

/// @title StorageSetter
/// @notice A simple contract that only allows clearing slot 0 or 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00.
/// See OZ-5 // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
///         WARNING: this contract is not safe to be called by untrusted parties.
///         It is only meant as an intermediate step during upgrades.
contract StorageSetterRestricted {
    /// @notice Semantic version.
    /// @custom:semver 1.2.1-beta.2
    string public constant version = "1.2.1-beta.2";

    /// @notice Stores a bytes32 `_value` at `_slot`. Any storage slots that
    ///         are packed should be set through this interface.
    function clearSlotZero() public {
        Storage.setBytes32(bytes32(uint256(0)), bytes32(uint256(0)));
    }

    /// @notice Stores a bytes32 `_value` at `_slot`. Any storage slots that
    ///         are packed should be set through this interface.
    function clearSlotOZ5Zero() public {
        Storage.setBytes32(0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00, bytes32(uint256(0)));
    }

    /// @notice Retrieves a bytes32 value from `_slot`.
    function getBytes32(bytes32 _slot) external view returns (bytes32 value_) {
        value_ = Storage.getBytes32(_slot);
    }

    /// @notice Retrieves a uint256 value from `_slot`.
    function getUint(bytes32 _slot) external view returns (uint256 value_) {
        value_ = Storage.getUint(_slot);
    }

    /// @notice Retrieves an address value from `_slot`.
    function getAddress(bytes32 _slot) external view returns (address addr_) {
        addr_ = Storage.getAddress(_slot);
    }

    /// @notice Retrieves a bool value from `_slot`.
    function getBool(bytes32 _slot) external view returns (bool value_) {
        value_ = Storage.getBool(_slot);
    }
}
