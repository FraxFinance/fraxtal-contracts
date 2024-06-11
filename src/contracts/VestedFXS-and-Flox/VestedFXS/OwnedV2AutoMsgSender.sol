// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

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
