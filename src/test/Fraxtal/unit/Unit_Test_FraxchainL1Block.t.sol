// SPDX-License-Identifier: ISC
pragma solidity ^0.8.15;

import { BaseTestFraxtal } from "../BaseTestFraxtal.t.sol";
import { FraxchainL1Block } from "src/contracts/Fraxtal/L2/FraxchainL1Block.sol";
import { console } from "frax-std/FraxTest.sol";
import { Encoding } from "src/contracts/Fraxtal/libraries/Encoding.sol";
import { VmSafe } from "forge-std/Vm.sol";

contract Unit_Test is BaseTestFraxtal {
    function test_setL1BlockValues() public {
        FraxchainL1Block l1Block = new FraxchainL1Block();

        uint64 _number = 18_226_221;
        uint64 _timestamp = 1_695_807_095;
        uint256 _basefee = 9_821_308_246;
        bytes32 _hash = 0xf7cf8627ed2f3bbbd04abb73c996c7def0e0aa290c5ea3f263d84460b624dacb;
        uint64 _sequenceNumber = 2;
        bytes32 _batcherHash = 0x0000000000000000000000006887246668a3b87f54deb3b94ba47a6f63f32985;
        uint256 _l1FeeOverhead = 188;
        uint256 _l1FeeScalar = 684_000;

        // Hash has not yet been stored
        require(l1Block.blockHashStored(_hash) == false);

        vm.expectEmit(true, true, true, true, address(l1Block));
        emit BlockHashReceived(_hash);

        hoax(l1Block.DEPOSITOR_ACCOUNT());
        l1Block.setL1BlockValues(_number, _timestamp, _basefee, _hash, _sequenceNumber, _batcherHash, _l1FeeOverhead, _l1FeeScalar);

        require(l1Block.number() == _number);
        require(l1Block.timestamp() == _timestamp);
        require(l1Block.basefee() == _basefee);
        require(l1Block.hash() == _hash);
        require(l1Block.sequenceNumber() == _sequenceNumber);
        require(l1Block.batcherHash() == _batcherHash);
        require(l1Block.l1FeeOverhead() == _l1FeeOverhead);
        require(l1Block.l1FeeScalar() == _l1FeeScalar);
        require(l1Block.blockHashStored(_hash) == true);
        require(l1Block.blockHashStored(_batcherHash) == false);
    }

    event BlockHashReceived(bytes32 blockHash);
}

contract L1BlockEcotone_Test is BaseTestFraxtal {
    FraxchainL1Block l1Block;

    function setUp() external {
        l1Block = new FraxchainL1Block();
    }

    event BlockHashReceived(bytes32 blockHash);

    /// @dev Tests that setL1BlockValuesEcotone updates the values appropriately.
    function testFuzz_setL1BlockValuesEcotone_succeeds(uint32 baseFeeScalar, uint32 blobBaseFeeScalar, uint64 sequenceNumber, uint64 timestamp, uint64 number, uint256 baseFee, uint256 blobBaseFee, bytes32 hash, bytes32 batcherHash) external {
        vm.assume(hash != bytes32(0));
        bytes memory functionCallDataPacked = Encoding.encodeSetL1BlockValuesEcotone(baseFeeScalar, blobBaseFeeScalar, sequenceNumber, timestamp, number, baseFee, blobBaseFee, hash, batcherHash);

        vm.prank(l1Block.DEPOSITOR_ACCOUNT());
        vm.expectEmit(address(l1Block));
        emit BlockHashReceived(hash);
        (bool success,) = address(l1Block).call(functionCallDataPacked);
        assertTrue(success, "Function call failed");

        assertEq(l1Block.baseFeeScalar(), baseFeeScalar);
        assertEq(l1Block.blobBaseFeeScalar(), blobBaseFeeScalar);
        assertEq(l1Block.sequenceNumber(), sequenceNumber);
        assertEq(l1Block.timestamp(), timestamp);
        assertEq(l1Block.number(), number);
        assertEq(l1Block.basefee(), baseFee);
        assertEq(l1Block.blobBaseFee(), blobBaseFee);
        assertEq(l1Block.hash(), hash);
        assertEq(l1Block.batcherHash(), batcherHash);
        assertTrue(l1Block.storedBlockHashes(hash));

        // ensure we didn't accidentally pollute the 128 bits of the sequencenum+scalars slot that
        // should be empty
        bytes32 scalarsSlot = vm.load(address(l1Block), bytes32(uint256(3)));
        bytes32 mask128 = hex"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000000000000000";

        assertEq(0, scalarsSlot & mask128);

        // ensure we didn't accidentally pollute the 128 bits of the number & timestamp slot that
        // should be empty
        bytes32 numberTimestampSlot = vm.load(address(l1Block), bytes32(uint256(0)));
        assertEq(0, numberTimestampSlot & mask128);

        // Ensure on a second call, the event is not emitted
        VmSafe.Log[] memory entriesOld = vm.getRecordedLogs();
        vm.prank(l1Block.DEPOSITOR_ACCOUNT());
        (success,) = address(l1Block).call(functionCallDataPacked);
        assertTrue(success);
        VmSafe.Log[] memory entriesNew = vm.getRecordedLogs();
        assertEq(entriesOld.length, entriesNew.length);
        assertEq(entriesOld.length, 0);
    }

    /// @dev Tests that `setL1BlockValuesEcotone` succeeds if sender address is the depositor
    function test_setL1BlockValuesEcotone_isDepositor_succeeds() external {
        bytes memory functionCallDataPacked = Encoding.encodeSetL1BlockValuesEcotone(type(uint32).max, type(uint32).max, type(uint64).max, type(uint64).max, type(uint64).max, type(uint256).max, type(uint256).max, bytes32(type(uint256).max), bytes32(type(uint256).max));

        vm.prank(l1Block.DEPOSITOR_ACCOUNT());
        (bool success,) = address(l1Block).call(functionCallDataPacked);
        assertTrue(success, "function call failed");
    }

    /// @dev Tests that `setL1BlockValuesEcotone` fails if sender address is not the depositor
    function test_setL1BlockValuesEcotone_notDepositor_fails() external {
        bytes memory functionCallDataPacked = Encoding.encodeSetL1BlockValuesEcotone(type(uint32).max, type(uint32).max, type(uint64).max, type(uint64).max, type(uint64).max, type(uint256).max, type(uint256).max, bytes32(type(uint256).max), bytes32(type(uint256).max));

        (bool success, bytes memory data) = address(l1Block).call(functionCallDataPacked);
        assertTrue(!success, "function call should have failed");
        // make sure return value is the expected function selector for "NotDepositor()"
        bytes memory expReturn = hex"3cc50b45";
        assertEq(data, expReturn);
    }
}
