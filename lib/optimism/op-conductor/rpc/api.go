package rpc

import (
	"context"
	"errors"
	"math/big"

	"github.com/ethereum-optimism/optimism/op-service/eth"
	"github.com/ethereum/go-ethereum/core/types"
)

var (
	ErrNotLeader = errors.New("refusing to proxy request to non-leader sequencer")
)

type ServerInfo struct {
	ID   string `json:"id"`
	Addr string `json:"addr"`
}

// API defines the interface for the op-conductor API.
type API interface {
	// Pause pauses op-conductor.
	Pause(ctx context.Context) error
	// Resume resumes op-conductor.
	Resume(ctx context.Context) error
	// SequencerHealthy returns true if the sequencer is healthy.
	SequencerHealthy(ctx context.Context) (bool, error)

	// Consensus related APIs
	// Leader returns true if the server is the leader.
	Leader(ctx context.Context) (bool, error)
	// LeaderWithID returns the current leader's server info.
	LeaderWithID(ctx context.Context) (*ServerInfo, error)
	// AddServerAsVoter adds a server as a voter to the cluster.
	AddServerAsVoter(ctx context.Context, id string, addr string) error
	// AddServerAsNonvoter adds a server as a non-voter to the cluster. non-voter will not participate in leader election.
	AddServerAsNonvoter(ctx context.Context, id string, addr string) error
	// RemoveServer removes a server from the cluster.
	RemoveServer(ctx context.Context, id string) error
	// TransferLeader transfers leadership to another server.
	TransferLeader(ctx context.Context) error
	// TransferLeaderToServer transfers leadership to a specific server.
	TransferLeaderToServer(ctx context.Context, id string, addr string) error

	// APIs called by op-node
	// Active returns true if op-conductor is active.
	Active(ctx context.Context) (bool, error)
	// CommitUnsafePayload commits a unsafe payload (lastest head) to the consensus layer.
	CommitUnsafePayload(ctx context.Context, payload *eth.ExecutionPayloadEnvelope) error
}

// ExecutionProxyAPI defines the methods proxied to the execution rpc backend
// This should include all methods that are called by op-batcher or op-proposer
type ExecutionProxyAPI interface {
	BlockByNumber(ctx context.Context, number *big.Int) (*types.Block, error)
}

// NodeProxyAPI defines the methods proxied to the node rpc backend
// This should include all methods that are called by op-batcher or op-proposer
type NodeProxyAPI interface {
	OutputAtBlock(ctx context.Context, blockNum uint64) (*eth.OutputResponse, error)
	SequencerActive(ctx context.Context) (bool, error)
	SyncStatus(ctx context.Context) (*eth.SyncStatus, error)
}
