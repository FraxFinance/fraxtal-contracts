package preimages

import (
	"context"
	"fmt"
	"math/big"

	"github.com/ethereum-optimism/optimism/op-challenger/game/fault/contracts"
	"github.com/ethereum-optimism/optimism/op-challenger/game/fault/types"
	"github.com/ethereum-optimism/optimism/op-challenger/game/keccak/matrix"
	"github.com/ethereum-optimism/optimism/op-service/txmgr"
	"github.com/ethereum/go-ethereum/common"
)

var ErrNilPreimageData = fmt.Errorf("cannot upload nil preimage data")

// PreimageUploader is responsible for posting preimages.
type PreimageUploader interface {
	// UploadPreimage uploads the provided preimage.
	UploadPreimage(ctx context.Context, claimIdx uint64, data *types.PreimageOracleData) error
}

// PreimageOracleContract is the interface for interacting with the PreimageOracle contract.
type PreimageOracleContract interface {
	InitLargePreimage(uuid *big.Int, partOffset uint32, claimedSize uint32) (txmgr.TxCandidate, error)
	AddLeaves(uuid *big.Int, input []byte, commitments [][32]byte, finalize bool) (txmgr.TxCandidate, error)
	Squeeze(claimant common.Address, uuid *big.Int, stateMatrix *matrix.StateMatrix, preState contracts.Leaf, preStateProof contracts.MerkleProof, postState contracts.Leaf, postStateProof contracts.MerkleProof) (txmgr.TxCandidate, error)
}
