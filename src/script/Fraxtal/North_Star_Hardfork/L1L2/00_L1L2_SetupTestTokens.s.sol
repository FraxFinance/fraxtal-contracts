// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../NorthStarSharedStateScript.s.sol";

contract L1L2_SetupTestTokens is NorthStarSharedStateScript {
    // Track nonces
    uint64 _currNonceL1 = 0;
    uint64 _currNonceL2 = 0;

    // Prevent duplicate ERC20 Names
    string _version = "-MK0";
    uint256 _versionSalt;

    // Current deployment phase
    // uint256 CURRENT_PHASE = 0;
    // uint256 CURRENT_PHASE = 1;
    uint256 CURRENT_PHASE = 2;

    bool GIVE_JUNK_HELPER_SOME_ETH = false;

    function setupState() internal virtual {
        super.defaultSetup();

        _versionSalt = uint256(keccak256(abi.encodePacked(_version)));
    }

    function run() public virtual {
        // Set up the state
        setupState();
        console.log("junkDeployerHelperAddress: ", junkDeployerHelperAddress);

        // The junk deployer helper and/or testerAddress may need some Eth
        if (GIVE_JUNK_HELPER_SOME_ETH) {
            // Move to L1
            vm.selectFork(l1ForkID);

            // Start broadcasting
            vm.startBroadcast(junkDeployerPk);

            // Give the helper some L1 gas
            junkDeployerHelperAddress.call{ value: 1 ether }("");

            // Give the tester some L1 gas
            testerAddress.call{ value: 1 ether }("");

            // Move to L2
            vm.stopBroadcast();
            vm.selectFork(l2ForkID);
            vm.startBroadcast(junkDeployerPk);

            // Give the helper some L2 gas
            junkDeployerHelperAddress.call{ value: 1 ether }("");

            // Give the tester some L2 gas
            testerAddress.call{ value: 1 ether }("");

            // Stop broadcasting
            vm.stopBroadcast();

            // Return early
            return;
        }

        // Phase 0
        if (CURRENT_PHASE == 0) {
            // Make sure you are on L1
            vm.selectFork(l1ForkID);

            // Start broadcasting (don't use the junkDeployerPk because it is also pushing system tx's and nonces could get mixed up)
            vm.startBroadcast(junkDeployerHelperPk);
            console.log("Executing as", junkDeployerHelperAddress);

            // Get the L1 nonce
            _currNonceL1 = vm.getNonce(junkDeployerHelperAddress);

            // On L1
            // =========================================
            l1Token = new MockERC20OwnedV2(
                junkDeployerHelperAddress,
                string.concat("Native L1 Token", _version),
                string.concat("L1T", _version)
            );

            // Mint to junk deployer helper
            l1Token.mint(junkDeployerHelperAddress, 100_000e18);

            // Mint to test address
            l1Token.mint(testerAddress, 100_000e18);

            // Increment the nonce
            _currNonceL1 += 3;

            // Persist addresses
            // vm.makePersistent(address(l1Token));

            console.log("address internal constant L1TOKEN = %s;", address(l1Token));

            vm.stopBroadcast();
        }

        // Phase 1
        if (CURRENT_PHASE == 1) {
            // On L2
            // =========================================
            // Move to L2

            vm.selectFork(l2ForkID);
            // vm.createSelectFork(vm.envString("L2_DEVNET_RPC_URL"));
            vm.startBroadcast(junkDeployerHelperPk);
            _currNonceL2 = vm.getNonce(junkDeployerHelperAddress);

            // Burn a few nonces if the current nonce is 0
            // Otherwise you will get weird EVM CreateCollision errors
            if (_currNonceL2 == 0) {
                testerAddress.call{ value: 1 gwei }("");
                testerAddress.call{ value: 1 gwei }("");
                testerAddress.call{ value: 1 gwei }("");
                // testerAddress.call{ value: 1 gwei }("");
                // testerAddress.call{ value: 1 gwei }("");
                _currNonceL2 = vm.getNonce(junkDeployerHelperAddress);
            }

            // Check the block number as a test
            console.log("block.number: ", block.number);

            // Deploy the L2 ERC20s now
            legacyL2Token = new LegacyMintableERC20({
                _l2Bridge: l2StandardBridgeAddress,
                _l1Token: l1TknAddr,
                _name: string.concat("LegacyL2-", l1TknName),
                _symbol: string.concat("LegacyL2-", l1TknSymbol)
            });
            l2Token = OptimismMintableERC20(
                l2OptimismMintableERC20Factory.createStandardL2Token(
                    l1TknAddr,
                    string(abi.encodePacked("L2-", l1TknName)),
                    string(abi.encodePacked("L2-", l1TknSymbol))
                )
            );
            badL2Token = OptimismMintableERC20(
                address(
                    OptimismMintableERC20(
                        l2OptimismMintableERC20Factory.createStandardL2Token(
                            address(uint160(_versionSalt)),
                            string(abi.encodePacked("L2-BAD-", l1TknName)),
                            string(abi.encodePacked("L2-BAD-", l1TknSymbol))
                        )
                    )
                )
            );

            nativeL2Token = new MockERC20OwnedV2{ salt: bytes32(_versionSalt) }(
                junkDeployerHelperAddress,
                string.concat("Native L2 Token", _version),
                string.concat("L2T", _version)
            );

            // Mint to junk deployer helper
            nativeL2Token.mint(junkDeployerHelperAddress, 100_000e18);

            // Mint to test address
            nativeL2Token.mint(testerAddress, 100_000e18);

            // Increment the nonce
            _currNonceL2 += 6;

            console.log("===================== L2 TEST TOKEN ADDRESSES =====================");
            console.log("address internal constant L2TOKEN = %s;", address(l2Token));
            console.log("address internal constant BADL2TOKEN = %s;", address(badL2Token));
            console.log("address internal constant LEGACYL2TOKEN = %s;", address(legacyL2Token));
            console.log("address internal constant NATIVEL2TOKEN = %s;", address(nativeL2Token));

            vm.stopBroadcast();
        }

        // Persist addresses
        // vm.makePersistent(address(legacyL2Token));
        // vm.makePersistent(address(l2Token));
        // vm.makePersistent(address(badL2Token));
        // vm.makePersistent(address(nativeL2Token));

        // Phase 2
        if (CURRENT_PHASE == 2) {
            // Back to L1
            // =========================================
            // Move back to L1

            vm.selectFork(l1ForkID);
            vm.startBroadcast(junkDeployerHelperPk);
            // vm.setNonce(junkDeployerHelperAddress, _currNonceL1);
            _currNonceL1 = vm.getNonce(junkDeployerHelperAddress);

            // Deploy L2-native tokens IOUs on L1
            remoteL1Token = OptimismMintableERC20(
                l1OptimismMintableERC20Factory.createStandardL2Token(
                    nativeL2TknAddr,
                    string(abi.encodePacked("L1-", nativeL2TknName)),
                    string(abi.encodePacked("L1-", nativeL2TknSymbol))
                )
            );
            badL1Token = OptimismMintableERC20(
                address(
                    OptimismMintableERC20(
                        l1OptimismMintableERC20Factory.createStandardL2Token(
                            address(1), // Bad address on purpose
                            string(abi.encodePacked("L1-", nativeL2TknName)),
                            string(abi.encodePacked("L1-", nativeL2TknSymbol))
                        )
                    )
                )
            );

            // Persist addresses
            // vm.makePersistent(address(remoteL1Token));
            // vm.makePersistent(address(badL1Token));

            // Print new test token addresses
            // Need to paste in the Constants.sol
            console.log("===================== L1 TEST TOKEN ADDRESSES =====================");
            console.log("address internal constant L1TOKEN = %s;", address(l1Token));
            console.log("address internal constant BADL1TOKEN = %s;", address(badL1Token));
            console.log("address internal constant REMOTEL1TOKEN = %s;", address(remoteL1Token));

            console.log("===================== L2 TEST TOKEN ADDRESSES =====================");
            console.log("address internal constant L2TOKEN = %s;", address(l2Token));
            console.log("address internal constant BADL2TOKEN = %s;", address(badL1Token));
            console.log("address internal constant LEGACYL2TOKEN = %s;", address(legacyL2Token));
            console.log("address internal constant NATIVEL2TOKEN = %s;", address(nativeL2Token));
        }
    }
}
