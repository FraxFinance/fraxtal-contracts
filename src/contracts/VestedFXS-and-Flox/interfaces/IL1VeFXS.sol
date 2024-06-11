// SPDX-License-Identifier: MIT
// @version 0.2.8
pragma solidity >=0.8.0;

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
