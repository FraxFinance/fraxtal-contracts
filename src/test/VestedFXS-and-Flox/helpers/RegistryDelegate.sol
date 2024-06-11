// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract RegistryDelegate {
    string public foo;

    constructor(address delegationRegistry, address initialDelegate, bool disableDelegationManagement) {
        delegationRegistry.call(abi.encodeWithSignature("setDelegationForSelf(address)", initialDelegate));
        delegationRegistry.call(abi.encodeWithSignature("disableSelfManagingDelegations()"));
        if (disableDelegationManagement) {
            delegationRegistry.call(abi.encodeWithSignature("disableDelegationManagement()"));
        }
    }

    function setFoo(string memory _foo) external {
        foo = _foo;
    }
}
