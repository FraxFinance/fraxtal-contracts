// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { IPreimageOracle } from "./interfaces/IPreimageOracle.sol";
import { PreimageKeyLib } from "./PreimageKeyLib.sol";
import { LibKeccak } from "@lib-keccak/LibKeccak.sol";
import "src/cannon/libraries/CannonErrors.sol";
import "src/cannon/libraries/CannonTypes.sol";

/// @title PreimageOracle
/// @notice A contract for storing permissioned pre-images.
/// @custom:attribution Solady <https://github.com/Vectorized/solady/blob/main/src/utils/MerkleProofLib.sol#L13-L43>
/// @custom:attribution Beacon Deposit Contract <0x00000000219ab540356cbb839cbe05303d7705fa>
contract PreimageOracle is IPreimageOracle {
    ////////////////////////////////////////////////////////////////
    //                   Constants & Immutables                   //
    ////////////////////////////////////////////////////////////////

    /// @notice The duration of the large preimage proposal challenge period.
    uint256 internal immutable CHALLENGE_PERIOD;
    /// @notice The minimum size of a preimage that can be proposed in the large preimage path.
    uint256 internal immutable MIN_LPP_SIZE_BYTES;
    /// @notice The depth of the keccak256 merkle tree. Supports up to 65,536 keccak blocks, or ~8.91MB preimages.
    uint256 public constant KECCAK_TREE_DEPTH = 16;
    /// @notice The maximum number of keccak blocks that can fit into the merkle tree.
    uint256 public constant MAX_LEAF_COUNT = 2 ** KECCAK_TREE_DEPTH - 1;

    ////////////////////////////////////////////////////////////////
    //                 Authorized Preimage Parts                  //
    ////////////////////////////////////////////////////////////////

    /// @notice Mapping of pre-image keys to pre-image lengths.
    mapping(bytes32 => uint256) public preimageLengths;
    /// @notice Mapping of pre-image keys to pre-image offsets to pre-image parts.
    mapping(bytes32 => mapping(uint256 => bytes32)) public preimageParts;
    /// @notice Mapping of pre-image keys to pre-image part offsets to preimage preparedness.
    mapping(bytes32 => mapping(uint256 => bool)) public preimagePartOk;

    ////////////////////////////////////////////////////////////////
    //                  Large Preimage Proposals                  //
    ////////////////////////////////////////////////////////////////

    /// @notice A raw leaf of the large preimage proposal merkle tree.
    struct Leaf {
        /// @notice The input absorbed for the block, exactly 136 bytes.
        bytes input;
        /// @notice The index of the block in the absorption process.
        uint256 index;
        /// @notice The hash of the internal state after absorbing the input.
        bytes32 stateCommitment;
    }

    /// @notice Unpacked keys for large preimage proposals.
    struct LargePreimageProposalKeys {
        /// @notice The claimant of the large preimage proposal.
        address claimant;
        /// @notice The UUID of the large preimage proposal.
        uint256 uuid;
    }

    /// @notice Static padding hashes. These values are persisted in storage, but are entirely immutable
    ///         after the constructor's execution.
    bytes32[KECCAK_TREE_DEPTH] public zeroHashes;
    /// @notice Append-only array of large preimage proposals for off-chain reference.
    LargePreimageProposalKeys[] public proposals;
    /// @notice Mapping of claimants to proposal UUIDs to the current branch path of the merkleization process.
    mapping(address => mapping(uint256 => bytes32[KECCAK_TREE_DEPTH])) public proposalBranches;
    /// @notice Mapping of claimants to proposal UUIDs to the timestamp of creation of the proposal as well as the
    /// challenged status.
    mapping(address => mapping(uint256 => LPPMetaData)) public proposalMetadata;
    /// @notice Mapping of claimants to proposal UUIDs to the preimage part picked up during the absorbtion process.
    mapping(address => mapping(uint256 => bytes32)) public proposalParts;
    /// @notice Mapping of claimants to proposal UUIDs to blocks which leaves were added to the merkle tree.
    mapping(address => mapping(uint256 => uint64[])) public proposalBlocks;

    ////////////////////////////////////////////////////////////////
    //                        Constructor                         //
    ////////////////////////////////////////////////////////////////

    constructor(uint256 _minProposalSize, uint256 _challengePeriod) {
        MIN_LPP_SIZE_BYTES = _minProposalSize;
        CHALLENGE_PERIOD = _challengePeriod;

        // Compute hashes in empty sparse Merkle tree. The first hash is not set, and kept as zero as the identity.
        for (uint256 height = 0; height < KECCAK_TREE_DEPTH - 1; height++) {
            zeroHashes[height + 1] = keccak256(abi.encodePacked(zeroHashes[height], zeroHashes[height]));
        }
    }

    ////////////////////////////////////////////////////////////////
    //             Standard Preimage Route (External)             //
    ////////////////////////////////////////////////////////////////

    /// @inheritdoc IPreimageOracle
    function readPreimage(bytes32 _key, uint256 _offset) external view returns (bytes32 dat_, uint256 datLen_) {
        require(preimagePartOk[_key][_offset], "pre-image must exist");

        // Calculate the length of the pre-image data
        // Add 8 for the length-prefix part
        datLen_ = 32;
        uint256 length = preimageLengths[_key];
        if (_offset + 32 >= length + 8) {
            datLen_ = length + 8 - _offset;
        }

        // Retrieve the pre-image data
        dat_ = preimageParts[_key][_offset];
    }

    /// @inheritdoc IPreimageOracle
    function loadLocalData(
        uint256 _ident,
        bytes32 _localContext,
        bytes32 _word,
        uint256 _size,
        uint256 _partOffset
    )
        external
        returns (bytes32 key_)
    {
        // Compute the localized key from the given local identifier.
        key_ = PreimageKeyLib.localizeIdent(_ident, _localContext);

        // Revert if the given part offset is not within bounds.
        if (_partOffset > _size + 8 || _size > 32) {
            revert PartOffsetOOB();
        }

        // Prepare the local data part at the given offset
        bytes32 part;
        assembly {
            // Clean the memory in [0x20, 0x40)
            mstore(0x20, 0x00)

            // Store the full local data in scratch space.
            mstore(0x00, shl(192, _size))
            mstore(0x08, _word)

            // Prepare the local data part at the requested offset.
            part := mload(_partOffset)
        }

        // Store the first part with `_partOffset`.
        preimagePartOk[key_][_partOffset] = true;
        preimageParts[key_][_partOffset] = part;
        // Assign the length of the preimage at the localized key.
        preimageLengths[key_] = _size;
    }

    /// @inheritdoc IPreimageOracle
    function loadKeccak256PreimagePart(uint256 _partOffset, bytes calldata _preimage) external {
        uint256 size;
        bytes32 key;
        bytes32 part;
        assembly {
            // len(sig) + len(partOffset) + len(preimage offset) = 4 + 32 + 32 = 0x44
            size := calldataload(0x44)

            // revert if part offset >= size+8 (i.e. parts must be within bounds)
            if iszero(lt(_partOffset, add(size, 8))) {
                // Store "PartOffsetOOB()"
                mstore(0, 0xfe254987)
                // Revert with "PartOffsetOOB()"
                revert(0x1c, 4)
            }
            // we leave solidity slots 0x40 and 0x60 untouched,
            // and everything after as scratch-memory.
            let ptr := 0x80
            // put size as big-endian uint64 at start of pre-image
            mstore(ptr, shl(192, size))
            ptr := add(ptr, 8)
            // copy preimage payload into memory so we can hash and read it.
            calldatacopy(ptr, _preimage.offset, size)
            // Note that it includes the 8-byte big-endian uint64 length prefix.
            // this will be zero-padded at the end, since memory at end is clean.
            part := mload(add(sub(ptr, 8), _partOffset))
            let h := keccak256(ptr, size) // compute preimage keccak256 hash
            // mask out prefix byte, replace with type 2 byte
            key := or(and(h, not(shl(248, 0xFF))), shl(248, 2))
        }
        preimagePartOk[key][_partOffset] = true;
        preimageParts[key][_partOffset] = part;
        preimageLengths[key] = size;
    }

    /// @inheritdoc IPreimageOracle
    function loadSha256PreimagePart(uint256 _partOffset, bytes calldata _preimage) external {
        uint256 size;
        bytes32 key;
        bytes32 part;
        assembly {
            // len(sig) + len(partOffset) + len(preimage offset) = 4 + 32 + 32 = 0x44
            size := calldataload(0x44)

            // revert if part offset >= size+8 (i.e. parts must be within bounds)
            if iszero(lt(_partOffset, add(size, 8))) {
                // Store "PartOffsetOOB()"
                mstore(0, 0xfe254987)
                // Revert with "PartOffsetOOB()"
                revert(0x1c, 4)
            }
            // we leave solidity slots 0x40 and 0x60 untouched,
            // and everything after as scratch-memory.
            let ptr := 0x80
            // put size as big-endian uint64 at start of pre-image
            mstore(ptr, shl(192, size))
            ptr := add(ptr, 8)
            // copy preimage payload into memory so we can hash and read it.
            calldatacopy(ptr, _preimage.offset, size)
            // Note that it includes the 8-byte big-endian uint64 length prefix.
            // this will be zero-padded at the end, since memory at end is clean.
            part := mload(add(sub(ptr, 8), _partOffset))

            // compute SHA2-256 hash with pre-compile
            let success :=
                staticcall(
                    gas(), // Forward all available gas
                    0x02, // Address of SHA-256 precompile
                    ptr, // Start of input data in memory
                    size, // Size of input data
                    0, // Store output in scratch memory
                    0x20 // Output is always 32 bytes
                )
            // Check if the staticcall succeeded
            if iszero(success) { revert(0, 0) }
            let h := mload(0) // get return data
            // mask out prefix byte, replace with type 4 byte
            key := or(and(h, not(shl(248, 0xFF))), shl(248, 4))
        }
        preimagePartOk[key][_partOffset] = true;
        preimageParts[key][_partOffset] = part;
        preimageLengths[key] = size;
    }

    // TODO 4844 point-evaluation preimage

    ////////////////////////////////////////////////////////////////
    //            Large Preimage Proposals (External)             //
    ////////////////////////////////////////////////////////////////

    /// @notice Returns the length of the `proposals` array
    function proposalCount() external view returns (uint256 count_) {
        count_ = proposals.length;
    }

    /// @notice Returns the length of the array with the block numbers of `addLeavesLPP` calls for a given large
    ///         preimage proposal.
    function proposalBlocksLen(address _claimant, uint256 _uuid) external view returns (uint256 len_) {
        len_ = proposalBlocks[_claimant][_uuid].length;
    }

    /// @notice Returns the length of the large preimage proposal challenge period.
    function challengePeriod() external view returns (uint256 challengePeriod_) {
        challengePeriod_ = CHALLENGE_PERIOD;
    }

    /// @notice Returns the minimum size (in bytes) of a large preimage proposal.
    function minProposalSize() external view returns (uint256 minProposalSize_) {
        minProposalSize_ = MIN_LPP_SIZE_BYTES;
    }

    /// @notice Initialize a large preimage proposal. Must be called before adding any leaves.
    function initLPP(uint256 _uuid, uint32 _partOffset, uint32 _claimedSize) external {
        // The caller of `addLeavesLPP` must be an EOA.
        if (msg.sender != tx.origin) revert NotEOA();

        // The part offset must be within the bounds of the claimed size + 8.
        if (_partOffset >= _claimedSize + 8) revert PartOffsetOOB();

        // The claimed size must be at least `MIN_LPP_SIZE_BYTES`.
        if (_claimedSize < MIN_LPP_SIZE_BYTES) revert InvalidInputSize();

        LPPMetaData metaData = proposalMetadata[msg.sender][_uuid];
        proposalMetadata[msg.sender][_uuid] = metaData.setPartOffset(_partOffset).setClaimedSize(_claimedSize);
        proposals.push(LargePreimageProposalKeys(msg.sender, _uuid));
    }

    /// @notice Adds a contiguous list of keccak state matrices to the merkle tree.
    function addLeavesLPP(
        uint256 _uuid,
        bytes calldata _input,
        bytes32[] calldata _stateCommitments,
        bool _finalize
    )
        external
    {
        // The caller of `addLeavesLPP` must be an EOA.
        if (msg.sender != tx.origin) revert NotEOA();

        // If we're finalizing, pad the input for the submitter. If not, copy the input into memory verbatim.
        bytes memory input;
        if (_finalize) {
            input = LibKeccak.pad(_input);
        } else {
            input = _input;
        }

        // Pull storage variables onto the stack / into memory for operations.
        bytes32[KECCAK_TREE_DEPTH] memory branch = proposalBranches[msg.sender][_uuid];
        LPPMetaData metaData = proposalMetadata[msg.sender][_uuid];

        // Revert if the proposal has not been initialized. 0-size preimages are *not* allowed.
        if (metaData.claimedSize() == 0) revert NotInitialized();

        // Revert if the proposal has already been finalized. No leaves can be added after this point.
        if (metaData.timestamp() != 0) revert AlreadyFinalized();

        // Check if the part offset is present in the input data being posted. If it is, assign the part to the mapping.
        uint256 offset = metaData.partOffset();
        uint256 currentSize = metaData.bytesProcessed();
        if (offset < 8 && currentSize == 0) {
            uint32 claimedSize = metaData.claimedSize();
            bytes32 preimagePart;
            assembly {
                mstore(0x00, shl(192, claimedSize))
                mstore(0x08, calldataload(_input.offset))
                preimagePart := mload(offset)
            }
            proposalParts[msg.sender][_uuid] = preimagePart;
        } else if (offset >= 8 && (offset = offset - 8) >= currentSize && offset < currentSize + _input.length) {
            uint256 relativeOffset = offset - currentSize;

            // Revert if the full preimage part is not available in the data we're absorbing. The submitter must
            // supply data that contains the full preimage part so that no partial preimage parts are stored in the
            // oracle. Partial parts are *only* allowed at the tail end of the preimage, where no more data is available
            // to be absorbed.
            if (relativeOffset + 32 >= _input.length && !_finalize) revert PartOffsetOOB();

            // If the preimage part is in the data we're about to absorb, persist the part to the caller's large
            // preimaage metadata.
            bytes32 preimagePart;
            assembly {
                preimagePart := calldataload(add(_input.offset, relativeOffset))
            }
            proposalParts[msg.sender][_uuid] = preimagePart;
        }

        uint256 blocksProcessed = metaData.blocksProcessed();
        assembly {
            let inputLen := mload(input)
            let inputPtr := add(input, 0x20)

            // The input length must be a multiple of 136 bytes
            // The input lenth / 136 must be equal to the number of state commitments.
            if or(mod(inputLen, 136), iszero(eq(_stateCommitments.length, div(inputLen, 136)))) {
                // Store "InvalidInputSize()" error selector
                mstore(0x00, 0x7b1daf1)
                revert(0x1C, 0x04)
            }

            // Allocate a hashing buffer the size of the leaf preimage.
            let hashBuf := mload(0x40)
            mstore(0x40, add(hashBuf, 0xC8))

            for { let i := 0 } lt(i, inputLen) { i := add(i, 136) } {
                // Copy the leaf preimage into the hashing buffer.
                let inputStartPtr := add(inputPtr, i)
                mstore(hashBuf, mload(inputStartPtr))
                mstore(add(hashBuf, 0x20), mload(add(inputStartPtr, 0x20)))
                mstore(add(hashBuf, 0x40), mload(add(inputStartPtr, 0x40)))
                mstore(add(hashBuf, 0x60), mload(add(inputStartPtr, 0x60)))
                mstore(add(hashBuf, 0x80), mload(add(inputStartPtr, 0x80)))
                mstore(add(hashBuf, 136), blocksProcessed)
                mstore(add(hashBuf, 168), calldataload(add(_stateCommitments.offset, shl(0x05, div(i, 136)))))

                // Hash the leaf preimage to get the node to add.
                let node := keccak256(hashBuf, 0xC8)

                // Increment the number of blocks processed.
                blocksProcessed := add(blocksProcessed, 0x01)

                // Add the node to the tree.
                let size := blocksProcessed
                for { let height := 0x00 } lt(height, shl(0x05, KECCAK_TREE_DEPTH)) { height := add(height, 0x20) } {
                    if and(size, 0x01) {
                        mstore(add(branch, height), node)
                        break
                    }

                    // Hash the node at `height` in the branch and the node together.
                    mstore(0x00, mload(add(branch, height)))
                    mstore(0x20, node)
                    node := keccak256(0x00, 0x40)
                    size := shr(0x01, size)
                }
            }
        }

        // Do not allow for posting preimages larger than the merkle tree can support.
        if (blocksProcessed > MAX_LEAF_COUNT) revert TreeSizeOverflow();

        // Perist the branch to storage.
        proposalBranches[msg.sender][_uuid] = branch;
        // Track the block number that these leaves were added at.
        proposalBlocks[msg.sender][_uuid].push(uint64(block.number));

        // Update the proposal metadata.
        metaData =
            metaData.setBlocksProcessed(uint32(blocksProcessed)).setBytesProcessed(uint32(_input.length + currentSize));
        if (_finalize) metaData = metaData.setTimestamp(uint64(block.timestamp));
        proposalMetadata[msg.sender][_uuid] = metaData;
    }

    /// @notice Challenge a keccak256 block that was committed to in the merkle tree.
    function challengeLPP(
        address _claimant,
        uint256 _uuid,
        LibKeccak.StateMatrix memory _stateMatrix,
        Leaf calldata _preState,
        bytes32[] calldata _preStateProof,
        Leaf calldata _postState,
        bytes32[] calldata _postStateProof
    )
        external
    {
        // Verify that both leaves are present in the merkle tree.
        bytes32 root = getTreeRootLPP(_claimant, _uuid);
        if (
            !(
                _verify(_preStateProof, root, _preState.index, _hashLeaf(_preState))
                    && _verify(_postStateProof, root, _postState.index, _hashLeaf(_postState))
            )
        ) revert InvalidProof();

        // Verify that the prestate passed matches the intermediate state claimed in the leaf.
        if (keccak256(abi.encode(_stateMatrix)) != _preState.stateCommitment) revert InvalidPreimage();

        // Verify that the pre/post state are contiguous.
        if (_preState.index + 1 != _postState.index) revert StatesNotContiguous();

        // Absorb and permute the input bytes.
        LibKeccak.absorb(_stateMatrix, _postState.input);
        LibKeccak.permutation(_stateMatrix);

        // Verify that the post state hash doesn't match the expected hash.
        if (keccak256(abi.encode(_stateMatrix)) == _postState.stateCommitment) revert PostStateMatches();

        // Mark the keccak claim as countered.
        proposalMetadata[_claimant][_uuid] = proposalMetadata[_claimant][_uuid].setCountered(true);
    }

    /// @notice Challenge the first keccak256 block that was absorbed.
    function challengeFirstLPP(
        address _claimant,
        uint256 _uuid,
        Leaf calldata _postState,
        bytes32[] calldata _postStateProof
    )
        external
    {
        // Verify that the leaf is present in the merkle tree.
        bytes32 root = getTreeRootLPP(_claimant, _uuid);
        if (!_verify(_postStateProof, root, _postState.index, _hashLeaf(_postState))) revert InvalidProof();

        // The poststate index must be 0 in order to challenge it with this function.
        if (_postState.index != 0) revert StatesNotContiguous();

        // Absorb and permute the input bytes into a fresh state matrix.
        LibKeccak.StateMatrix memory stateMatrix;
        LibKeccak.absorb(stateMatrix, _postState.input);
        LibKeccak.permutation(stateMatrix);

        // Verify that the post state hash doesn't match the expected hash.
        if (keccak256(abi.encode(stateMatrix)) == _postState.stateCommitment) revert PostStateMatches();

        // Mark the keccak claim as countered.
        proposalMetadata[_claimant][_uuid] = proposalMetadata[_claimant][_uuid].setCountered(true);
    }

    /// @notice Finalize a large preimage proposal after the challenge period has passed.
    function squeezeLPP(
        address _claimant,
        uint256 _uuid,
        LibKeccak.StateMatrix memory _stateMatrix,
        Leaf calldata _preState,
        bytes32[] calldata _preStateProof,
        Leaf calldata _postState,
        bytes32[] calldata _postStateProof
    )
        external
    {
        LPPMetaData metaData = proposalMetadata[_claimant][_uuid];

        // Check if the proposal was countered.
        if (metaData.countered()) revert BadProposal();

        // Check if the challenge period has passed since the proposal was finalized.
        if (block.timestamp - metaData.timestamp() <= CHALLENGE_PERIOD) revert ActiveProposal();

        // Verify that both leaves are present in the merkle tree.
        bytes32 root = getTreeRootLPP(_claimant, _uuid);
        if (
            !(
                _verify(_preStateProof, root, _preState.index, _hashLeaf(_preState))
                    && _verify(_postStateProof, root, _postState.index, _hashLeaf(_postState))
            )
        ) revert InvalidProof();

        // Verify that the prestate passed matches the intermediate state claimed in the leaf.
        if (keccak256(abi.encode(_stateMatrix)) != _preState.stateCommitment) revert InvalidPreimage();

        // Verify that the pre/post state are contiguous.
        if (_preState.index + 1 != _postState.index || _postState.index != metaData.blocksProcessed() - 1) {
            revert StatesNotContiguous();
        }

        // The claimed size must match the actual size of the preimage.
        uint256 claimedSize = metaData.claimedSize();
        if (metaData.bytesProcessed() != claimedSize) revert InvalidInputSize();

        // Absorb and permute the input bytes. We perform no final verification on the state matrix here, since the
        // proposal has passed the challenge period and is considered valid.
        LibKeccak.absorb(_stateMatrix, _postState.input);
        LibKeccak.permutation(_stateMatrix);
        bytes32 finalDigest = LibKeccak.squeeze(_stateMatrix);

        // Write the preimage part to the authorized preimage parts mapping.
        uint256 partOffset = metaData.partOffset();
        preimagePartOk[finalDigest][partOffset] = true;
        preimageParts[finalDigest][partOffset] = proposalParts[_claimant][_uuid];
        preimageLengths[finalDigest] = claimedSize;
    }

    /// @notice Gets the current merkle root of the large preimage proposal tree.
    function getTreeRootLPP(address _owner, uint256 _uuid) public view returns (bytes32 treeRoot_) {
        uint256 size = proposalMetadata[_owner][_uuid].blocksProcessed();
        for (uint256 height = 0; height < KECCAK_TREE_DEPTH; height++) {
            if ((size & 1) == 1) {
                treeRoot_ = keccak256(abi.encode(proposalBranches[_owner][_uuid][height], treeRoot_));
            } else {
                treeRoot_ = keccak256(abi.encode(treeRoot_, zeroHashes[height]));
            }
            size >>= 1;
        }
    }

    /// Check if leaf` at `index` verifies against the Merkle `root` and `branch`.
    /// https://github.com/ethereum/consensus-specs/blob/dev/specs/phase0/beacon-chain.md#is_valid_merkle_branch
    function _verify(
        bytes32[] calldata _proof,
        bytes32 _root,
        uint256 _index,
        bytes32 _leaf
    )
        internal
        pure
        returns (bool isValid_)
    {
        /// @solidity memory-safe-assembly
        assembly {
            function hashTwo(a, b) -> hash {
                mstore(0x00, a)
                mstore(0x20, b)
                hash := keccak256(0x00, 0x40)
            }

            let value := _leaf
            for { let i := 0x00 } lt(i, KECCAK_TREE_DEPTH) { i := add(i, 0x01) } {
                let branchValue := calldataload(add(_proof.offset, shl(0x05, i)))

                switch and(shr(i, _index), 0x01)
                case 1 { value := hashTwo(branchValue, value) }
                default { value := hashTwo(value, branchValue) }
            }

            isValid_ := eq(value, _root)
        }
    }

    /// @notice Hashes leaf data for the preimage proposals tree
    function _hashLeaf(Leaf memory _leaf) internal pure returns (bytes32 leaf_) {
        leaf_ = keccak256(abi.encodePacked(_leaf.input, _leaf.index, _leaf.stateCommitment));
    }
}
