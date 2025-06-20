"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.setupProxyContract = void 0;
const assert_1 = __importDefault(require("assert"));
const ethers_1 = require("ethers");
const { getAddress } = ethers_1.utils;
// Sets up the newly deployed proxy contract such that:
// 1. The proxy's implementation is set to the target implementation
// 2. The proxy's admin is set to the target proxy owner
//
// If the values are set correctly already, it makes no transactions.
const setupProxyContract = async (proxyContract, signer, { targetImplAddress, targetProxyOwnerAddress, postUpgradeCallCalldata, }) => {
    const currentAdmin = await proxyContract
        .connect(ethers_1.ethers.constants.AddressZero)
        .callStatic.admin();
    const signerAddress = await signer.getAddress();
    // Gets the current implementation address the proxy is pointing to.
    // callStatic is used since the `Proxy.implementation()` is not a view function and ethers will
    // try to make a transaction if we don't use callStatic. Using the zero address as `from` lets us
    // call functions on the proxy and not trigger the delegatecall. See Proxy.sol proxyCallIfNotAdmin
    // modifier for more details.
    const currentImplementation = await proxyContract
        .connect(ethers_1.ethers.constants.AddressZero)
        .callStatic.implementation();
    console.log(`implementation currently set to ${currentImplementation}`);
    if (getAddress(currentImplementation) !== getAddress(targetImplAddress)) {
        // If the proxy isn't pointing to the correct implementation, we need to set it to the correct
        // one, then call initialize() in the proxy's context.
        console.log('implementation not set to correct contract');
        console.log(`Setting implementation to ${targetImplAddress}`);
        // The signer needs to be the current admin, otherwise we don't have permission
        // to update the implementation or admin
        (0, assert_1.default)(signerAddress === currentAdmin, 'the passed signer is not the admin, cannot update implementation');
        let tx;
        if (!postUpgradeCallCalldata) {
            console.log('postUpgradeCallCalldata is not provided. Using Proxy.upgrade()');
            // Point the proxy to the target implementation
            tx = await proxyContract.connect(signer).upgradeTo(targetImplAddress);
        }
        else {
            console.log('postUpgradeCallCalldata is provided. Using Proxy.upgradeAndCall()');
            // Point the proxy to the target implementation,
            // and call function in the proxy's context
            tx = await proxyContract
                .connect(signer)
                .upgradeToAndCall(targetImplAddress, postUpgradeCallCalldata);
        }
        const receipt = await tx.wait();
        console.log(`implementation set in ${receipt.transactionHash}`);
    }
    else {
        console.log(`implementation already set correctly to ${targetImplAddress}`);
    }
    console.log(`admin set to ${currentAdmin}`);
    if (getAddress(currentAdmin) !== getAddress(targetProxyOwnerAddress)) {
        // If the proxy admin isn't the l2ProxyOwnerAddress, we need to update it
        // We're assuming that the proxy admin is the ddd right now.
        console.log('detected admin is not set correctly');
        console.log(`Setting admin to ${targetProxyOwnerAddress}`);
        // The signer needs to be the current admin, otherwise we don't have permission
        // to update the implementation or admin
        (0, assert_1.default)(signerAddress === currentAdmin, 'proxyOwnerSigner is not the admin, cannot update admin');
        // change admin to the l2ProxyOwnerAddress
        const tx = await proxyContract
            .connect(signer)
            .changeAdmin(targetProxyOwnerAddress);
        const receipt = await tx.wait();
        console.log(`admin set in ${receipt.transactionHash}`);
    }
    else {
        console.log(`admin already set correctly to ${targetProxyOwnerAddress}`);
    }
    const updatedImplementation = await proxyContract
        .connect(ethers_1.ethers.constants.AddressZero)
        .callStatic.implementation();
    const updatedAdmin = await proxyContract
        .connect(ethers_1.ethers.constants.AddressZero)
        .callStatic.admin();
    (0, assert_1.default)(getAddress(updatedAdmin) === getAddress(targetProxyOwnerAddress), 'Something went wrong - admin not set correctly after transaction');
    (0, assert_1.default)(getAddress(updatedImplementation) === getAddress(targetImplAddress), 'Something went wrong - implementation not set correctly after transaction');
    console.log(`Proxy at ${proxyContract.address} is set up with implementation: ${updatedImplementation} and admin: ${updatedAdmin}`);
};
exports.setupProxyContract = setupProxyContract;
