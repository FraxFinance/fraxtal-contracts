// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

// src/script/Fraxtal/testnet/Storage.sol

/// @title Storage
/// @notice Storage handles reading and writing to arbitary storage locations
library Storage {
    /// @notice Returns an address stored in an arbitrary storage slot.
    ///         These storage slots decouple the storage layout from
    ///         solc's automation.
    /// @param _slot The storage slot to retrieve the address from.
    function getAddress(bytes32 _slot) internal view returns (address addr_) {
        assembly {
            addr_ := sload(_slot)
        }
    }

    /// @notice Stores an address in an arbitrary storage slot, `_slot`.
    /// @param _slot The storage slot to store the address in.
    /// @param _address The protocol version to store
    /// @dev WARNING! This function must be used cautiously, as it allows for overwriting addresses
    ///      in arbitrary storage slots.
    function setAddress(bytes32 _slot, address _address) internal {
        assembly {
            sstore(_slot, _address)
        }
    }

    /// @notice Returns a uint256 stored in an arbitrary storage slot.
    ///         These storage slots decouple the storage layout from
    ///         solc's automation.
    /// @param _slot The storage slot to retrieve the address from.
    function getUint(bytes32 _slot) internal view returns (uint256 value_) {
        assembly {
            value_ := sload(_slot)
        }
    }

    /// @notice Stores a value in an arbitrary storage slot, `_slot`.
    /// @param _slot The storage slot to store the uint in.
    /// @param _value The protocol version to store
    /// @dev WARNING! This function must be used cautiously, as it allows for overwriting values
    ///      in arbitrary storage slots.
    function setUint(bytes32 _slot, uint256 _value) internal {
        assembly {
            sstore(_slot, _value)
        }
    }

    /// @notice Returns a bytes32 stored in an arbitrary storage slot.
    ///         These storage slots decouple the storage layout from
    ///         solc's automation.
    /// @param _slot The storage slot to retrieve the address from.
    function getBytes32(bytes32 _slot) internal view returns (bytes32 value_) {
        assembly {
            value_ := sload(_slot)
        }
    }

    /// @notice Stores a bytes32 value in an arbitrary storage slot, `_slot`.
    /// @param _slot The storage slot to store the address in.
    /// @param _value The bytes32 value to store.
    /// @dev WARNING! This function must be used cautiously, as it allows for overwriting values
    ///      in arbitrary storage slots.
    function setBytes32(bytes32 _slot, bytes32 _value) internal {
        assembly {
            sstore(_slot, _value)
        }
    }

    /// @notice Stores a bool value in an arbitrary storage slot, `_slot`.
    /// @param _slot The storage slot to store the bool in.
    /// @param _value The bool value to store
    /// @dev WARNING! This function must be used cautiously, as it allows for overwriting values
    ///      in arbitrary storage slots.
    function setBool(bytes32 _slot, bool _value) internal {
        assembly {
            sstore(_slot, _value)
        }
    }

    /// @notice Returns a bool stored in an arbitrary storage slot.
    /// @param _slot The storage slot to retrieve the bool from.
    function getBool(bytes32 _slot) internal view returns (bool value_) {
        assembly {
            value_ := sload(_slot)
        }
    }
}

// src/script/Fraxtal/testnet/StorageSetterRestricted.sol

/// @title StorageSetter
/// @notice A simple contract that only allows clearing slot 0.
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
