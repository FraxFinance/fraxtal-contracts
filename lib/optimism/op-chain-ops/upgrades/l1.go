package upgrades

import (
	"fmt"
	"math/big"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"

	"github.com/ethereum-optimism/optimism/op-bindings/bindings"
	"github.com/ethereum-optimism/optimism/op-bindings/predeploys"
	"github.com/ethereum-optimism/optimism/op-chain-ops/genesis"
	"github.com/ethereum-optimism/optimism/op-chain-ops/safe"

	"github.com/ethereum-optimism/superchain-registry/superchain"
)

const (
	// upgradeAndCall represents the signature of the upgradeAndCall function
	// on the ProxyAdmin contract.
	upgradeAndCall = "upgradeAndCall(address,address,bytes)"

	method = "setBytes32"
)

var (
	// storageSetterAddr represents the address of the StorageSetter contract.
	storageSetterAddr = common.HexToAddress("0xd81f43eDBCAcb4c29a9bA38a13Ee5d79278270cC")

	// superchainConfigProxy refers to the address of the Sepolia superchain config proxy.
	// NOTE: this is currently hardcoded and we will need to move this to the superchain-registry
	// and have 1 deployed for each superchain target.
	superchainConfigProxy = common.HexToAddress("0xC2Be75506d5724086DEB7245bd260Cc9753911Be")
)

// L1 will add calls for upgrading each of the L1 contracts.
func L1(batch *safe.Batch, implementations superchain.ImplementationList, list superchain.AddressList, config *genesis.DeployConfig, chainConfig *superchain.ChainConfig, backend bind.ContractBackend) error {
	if err := L1CrossDomainMessenger(batch, implementations, list, config, chainConfig, backend); err != nil {
		return fmt.Errorf("upgrading L1CrossDomainMessenger: %w", err)
	}
	if err := L1ERC721Bridge(batch, implementations, list, config, chainConfig, backend); err != nil {
		return fmt.Errorf("upgrading L1ERC721Bridge: %w", err)
	}
	if err := L1StandardBridge(batch, implementations, list, config, chainConfig, backend); err != nil {
		return fmt.Errorf("upgrading L1StandardBridge: %w", err)
	}
	if err := L2OutputOracle(batch, implementations, list, config, chainConfig, backend); err != nil {
		return fmt.Errorf("upgrading L2OutputOracle: %w", err)
	}
	if err := OptimismMintableERC20Factory(batch, implementations, list, config, chainConfig, backend); err != nil {
		return fmt.Errorf("upgrading OptimismMintableERC20Factory: %w", err)
	}
	if err := OptimismPortal(batch, implementations, list, config, chainConfig, backend); err != nil {
		return fmt.Errorf("upgrading OptimismPortal: %w", err)
	}
	if err := SystemConfig(batch, implementations, list, config, chainConfig, backend); err != nil {
		return fmt.Errorf("upgrading SystemConfig: %w", err)
	}
	return nil
}

// L1CrossDomainMessenger will add a call to the batch that upgrades the L1CrossDomainMessenger.
func L1CrossDomainMessenger(batch *safe.Batch, implementations superchain.ImplementationList, list superchain.AddressList, config *genesis.DeployConfig, chainConfig *superchain.ChainConfig, backend bind.ContractBackend) error {
	proxyAdminABI, err := bindings.ProxyAdminMetaData.GetAbi()
	if err != nil {
		return err
	}

	// 2 Step Upgrade
	{
		storageSetterABI, err := bindings.StorageSetterMetaData.GetAbi()
		if err != nil {
			return err
		}

		input := []bindings.StorageSetterSlot{
			// https://github.com/ethereum-optimism/optimism/blob/86a96023ffd04d119296dff095d02fff79fa15de/packages/contracts-bedrock/.storage-layout#L11-L13
			{
				Key:   common.Hash{},
				Value: common.Hash{},
			},
		}

		calldata, err := storageSetterABI.Pack(method, input)
		if err != nil {
			return err
		}
		args := []any{
			common.HexToAddress(list.L1CrossDomainMessengerProxy.String()),
			storageSetterAddr,
			calldata,
		}
		proxyAdmin := common.HexToAddress(list.ProxyAdmin.String())
		if err := batch.AddCall(proxyAdmin, common.Big0, upgradeAndCall, args, proxyAdminABI); err != nil {
			return err
		}
	}

	l1CrossDomainMessengerABI, err := bindings.L1CrossDomainMessengerMetaData.GetAbi()
	if err != nil {
		return err
	}

	l1CrossDomainMessenger, err := bindings.NewL1CrossDomainMessengerCaller(common.HexToAddress(list.L1CrossDomainMessengerProxy.String()), backend)
	if err != nil {
		return err
	}
	optimismPortal, err := l1CrossDomainMessenger.PORTAL(&bind.CallOpts{})
	if err != nil {
		return err
	}
	otherMessenger, err := l1CrossDomainMessenger.OTHERMESSENGER(&bind.CallOpts{})
	if err != nil {
		return err
	}

	if optimismPortal != common.Address(list.OptimismPortalProxy) {
		return fmt.Errorf("upgrading L1CrossDomainMessenger: Portal address doesn't match config")
	}

	if otherMessenger != predeploys.L2CrossDomainMessengerAddr {
		return fmt.Errorf("upgrading L1CrossDomainMessenger: OtherMessenger address doesn't match config")
	}

	calldata, err := l1CrossDomainMessengerABI.Pack("initialize", superchainConfigProxy, optimismPortal)
	if err != nil {
		return err
	}

	args := []any{
		common.HexToAddress(list.L1CrossDomainMessengerProxy.String()),
		common.HexToAddress(implementations.L1CrossDomainMessenger.Address.String()),
		calldata,
	}

	proxyAdmin := common.HexToAddress(list.ProxyAdmin.String())
	if err := batch.AddCall(proxyAdmin, common.Big0, upgradeAndCall, args, proxyAdminABI); err != nil {
		return err
	}

	return nil
}

// L1ERC721Bridge will add a call to the batch that upgrades the L1ERC721Bridge.
func L1ERC721Bridge(batch *safe.Batch, implementations superchain.ImplementationList, list superchain.AddressList, config *genesis.DeployConfig, chainConfig *superchain.ChainConfig, backend bind.ContractBackend) error {
	proxyAdminABI, err := bindings.ProxyAdminMetaData.GetAbi()
	if err != nil {
		return err
	}

	// 2 Step Upgrade
	{
		storageSetterABI, err := bindings.StorageSetterMetaData.GetAbi()
		if err != nil {
			return err
		}

		input := []bindings.StorageSetterSlot{
			// https://github.com/ethereum-optimism/optimism/blob/86a96023ffd04d119296dff095d02fff79fa15de/packages/contracts-bedrock/.storage-layout#L100-L102
			{
				Key:   common.Hash{},
				Value: common.Hash{},
			},
		}

		calldata, err := storageSetterABI.Pack(method, input)
		if err != nil {
			return fmt.Errorf("setBytes32: %w", err)
		}
		args := []any{
			common.HexToAddress(list.L1ERC721BridgeProxy.String()),
			storageSetterAddr,
			calldata,
		}
		proxyAdmin := common.HexToAddress(list.ProxyAdmin.String())
		if err := batch.AddCall(proxyAdmin, common.Big0, upgradeAndCall, args, proxyAdminABI); err != nil {
			return err
		}
	}

	l1ERC721BridgeABI, err := bindings.L1ERC721BridgeMetaData.GetAbi()
	if err != nil {
		return err
	}

	l1ERC721Bridge, err := bindings.NewL1ERC721BridgeCaller(common.HexToAddress(list.L1ERC721BridgeProxy.String()), backend)
	if err != nil {
		return err
	}
	messenger, err := l1ERC721Bridge.Messenger(&bind.CallOpts{})
	if err != nil {
		return err
	}
	otherBridge, err := l1ERC721Bridge.OtherBridge(&bind.CallOpts{})
	if err != nil {
		return err
	}

	if messenger != common.Address(list.L1CrossDomainMessengerProxy) {
		return fmt.Errorf("upgrading L1ERC721Bridge: Messenger address doesn't match config")
	}

	if otherBridge != predeploys.L2ERC721BridgeAddr {
		return fmt.Errorf("upgrading L1ERC721Bridge: OtherBridge address doesn't match config")
	}

	calldata, err := l1ERC721BridgeABI.Pack("initialize", messenger, superchainConfigProxy)
	if err != nil {
		return err
	}

	args := []any{
		common.HexToAddress(list.L1ERC721BridgeProxy.String()),
		common.HexToAddress(implementations.L1ERC721Bridge.Address.String()),
		calldata,
	}

	proxyAdmin := common.HexToAddress(list.ProxyAdmin.String())
	if err := batch.AddCall(proxyAdmin, common.Big0, upgradeAndCall, args, proxyAdminABI); err != nil {
		return err
	}

	return nil
}

// L1StandardBridge will add a call to the batch that upgrades the L1StandardBridge.
func L1StandardBridge(batch *safe.Batch, implementations superchain.ImplementationList, list superchain.AddressList, config *genesis.DeployConfig, chainConfig *superchain.ChainConfig, backend bind.ContractBackend) error {
	proxyAdminABI, err := bindings.ProxyAdminMetaData.GetAbi()
	if err != nil {
		return err
	}

	// 2 Step Upgrade
	{
		storageSetterABI, err := bindings.StorageSetterMetaData.GetAbi()
		if err != nil {
			return err
		}

		input := []bindings.StorageSetterSlot{
			// https://github.com/ethereum-optimism/optimism/blob/86a96023ffd04d119296dff095d02fff79fa15de/packages/contracts-bedrock/.storage-layout#L36-L37
			{
				Key:   common.Hash{},
				Value: common.Hash{},
			},
		}

		calldata, err := storageSetterABI.Pack(method, input)
		if err != nil {
			return err
		}
		args := []any{
			common.HexToAddress(list.L1StandardBridgeProxy.String()),
			storageSetterAddr,
			calldata,
		}
		proxyAdmin := common.HexToAddress(list.ProxyAdmin.String())
		if err := batch.AddCall(proxyAdmin, common.Big0, upgradeAndCall, args, proxyAdminABI); err != nil {
			return err
		}
	}

	l1StandardBridgeABI, err := bindings.L1StandardBridgeMetaData.GetAbi()
	if err != nil {
		return err
	}

	l1StandardBridge, err := bindings.NewL1StandardBridgeCaller(common.HexToAddress(list.L1StandardBridgeProxy.String()), backend)
	if err != nil {
		return err
	}

	messenger, err := l1StandardBridge.MESSENGER(&bind.CallOpts{})
	if err != nil {
		return err
	}

	otherBridge, err := l1StandardBridge.OTHERBRIDGE(&bind.CallOpts{})
	if err != nil {
		return err
	}

	if messenger != common.Address(list.L1CrossDomainMessengerProxy) {
		return fmt.Errorf("upgrading L1StandardBridge: Messenger address doesn't match config")
	}

	if otherBridge != predeploys.L2StandardBridgeAddr {
		return fmt.Errorf("upgrading L1StandardBridge: OtherBridge address doesn't match config")
	}

	calldata, err := l1StandardBridgeABI.Pack("initialize", messenger, superchainConfigProxy)
	if err != nil {
		return err
	}

	args := []any{
		common.HexToAddress(list.L1StandardBridgeProxy.String()),
		common.HexToAddress(implementations.L1StandardBridge.Address.String()),
		calldata,
	}

	proxyAdmin := common.HexToAddress(list.ProxyAdmin.String())
	if err := batch.AddCall(proxyAdmin, common.Big0, upgradeAndCall, args, proxyAdminABI); err != nil {
		return err
	}

	return nil
}

// L2OutputOracle will add a call to the batch that upgrades the L2OutputOracle.
func L2OutputOracle(batch *safe.Batch, implementations superchain.ImplementationList, list superchain.AddressList, config *genesis.DeployConfig, chainConfig *superchain.ChainConfig, backend bind.ContractBackend) error {
	proxyAdminABI, err := bindings.ProxyAdminMetaData.GetAbi()
	if err != nil {
		return err
	}

	// 2 Step Upgrade
	{
		storageSetterABI, err := bindings.StorageSetterMetaData.GetAbi()
		if err != nil {
			return err
		}

		input := []bindings.StorageSetterSlot{
			// https://github.com/ethereum-optimism/optimism/blob/86a96023ffd04d119296dff095d02fff79fa15de/packages/contracts-bedrock/.storage-layout#L50-L51
			{
				Key:   common.Hash{},
				Value: common.Hash{},
			},
		}

		calldata, err := storageSetterABI.Pack(method, input)
		if err != nil {
			return err
		}
		args := []any{
			common.HexToAddress(list.L2OutputOracleProxy.String()),
			storageSetterAddr,
			calldata,
		}
		proxyAdmin := common.HexToAddress(list.ProxyAdmin.String())
		if err := batch.AddCall(proxyAdmin, common.Big0, upgradeAndCall, args, proxyAdminABI); err != nil {
			return err
		}
	}

	l2OutputOracleABI, err := bindings.L2OutputOracleMetaData.GetAbi()
	if err != nil {
		return err
	}

	l2OutputOracle, err := bindings.NewL2OutputOracleCaller(common.HexToAddress(list.L2OutputOracleProxy.String()), backend)
	if err != nil {
		return err
	}

	l2OutputOracleSubmissionInterval, err := l2OutputOracle.SUBMISSIONINTERVAL(&bind.CallOpts{})
	if err != nil {
		return err
	}

	l2BlockTime, err := l2OutputOracle.L2BLOCKTIME(&bind.CallOpts{})
	if err != nil {
		return err
	}

	l2OutputOracleStartingBlockNumber, err := l2OutputOracle.StartingBlockNumber(&bind.CallOpts{})
	if err != nil {
		return err
	}

	l2OutputOracleStartingTimestamp, err := l2OutputOracle.StartingTimestamp(&bind.CallOpts{})
	if err != nil {
		return err
	}

	l2OutputOracleProposer, err := l2OutputOracle.PROPOSER(&bind.CallOpts{})
	if err != nil {
		return err
	}

	l2OutputOracleChallenger, err := l2OutputOracle.CHALLENGER(&bind.CallOpts{})
	if err != nil {
		return err
	}

	finalizationPeriodSeconds, err := l2OutputOracle.FINALIZATIONPERIODSECONDS(&bind.CallOpts{})
	if err != nil {
		return err
	}

	if config != nil {
		if l2OutputOracleSubmissionInterval.Uint64() != config.L2OutputOracleSubmissionInterval {
			return fmt.Errorf("upgrading L2OutputOracle: L2OutputOracleSubmissionInterval address doesn't match config")
		}

		if l2BlockTime.Uint64() != config.L2BlockTime {
			return fmt.Errorf("upgrading L2OutputOracle: L2BlockTime address doesn't match config")
		}

		if l2OutputOracleStartingBlockNumber.Uint64() != config.L2OutputOracleStartingBlockNumber {
			return fmt.Errorf("upgrading L2OutputOracle: L2OutputOracleStartingBlockNumber address doesn't match config")
		}

		if config.L2OutputOracleStartingTimestamp < 0 {
			return fmt.Errorf("L2OutputOracleStartingTimestamp must be concrete")
		}

		if int(l2OutputOracleStartingTimestamp.Int64()) != config.L2OutputOracleStartingTimestamp {
			return fmt.Errorf("upgrading L2OutputOracle: L2OutputOracleStartingTimestamp address doesn't match config")
		}

		if l2OutputOracleProposer != config.L2OutputOracleProposer {
			return fmt.Errorf("upgrading L2OutputOracle: L2OutputOracleProposer address doesn't match config")
		}

		if l2OutputOracleChallenger != config.L2OutputOracleChallenger {
			return fmt.Errorf("upgrading L2OutputOracle: L2OutputOracleChallenger address doesn't match config")
		}

		if finalizationPeriodSeconds.Uint64() != config.FinalizationPeriodSeconds {
			return fmt.Errorf("upgrading L2OutputOracle: FinalizationPeriodSeconds address doesn't match config")
		}
	}

	calldata, err := l2OutputOracleABI.Pack(
		"initialize",
		l2OutputOracleSubmissionInterval,
		l2BlockTime,
		l2OutputOracleStartingBlockNumber,
		l2OutputOracleStartingTimestamp,
		l2OutputOracleProposer,
		l2OutputOracleChallenger,
		finalizationPeriodSeconds,
	)
	if err != nil {
		return err
	}

	args := []any{
		common.HexToAddress(list.L2OutputOracleProxy.String()),
		common.HexToAddress(implementations.L2OutputOracle.Address.String()),
		calldata,
	}

	proxyAdmin := common.HexToAddress(list.ProxyAdmin.String())
	if err := batch.AddCall(proxyAdmin, common.Big0, upgradeAndCall, args, proxyAdminABI); err != nil {
		return err
	}

	return nil
}

// OptimismMintableERC20Factory will add a call to the batch that upgrades the OptimismMintableERC20Factory.
func OptimismMintableERC20Factory(batch *safe.Batch, implementations superchain.ImplementationList, list superchain.AddressList, config *genesis.DeployConfig, chainConfig *superchain.ChainConfig, backend bind.ContractBackend) error {
	proxyAdminABI, err := bindings.ProxyAdminMetaData.GetAbi()
	if err != nil {
		return err
	}

	// 2 Step Upgrade
	{
		storageSetterABI, err := bindings.StorageSetterMetaData.GetAbi()
		if err != nil {
			return err
		}

		input := []bindings.StorageSetterSlot{
			// https://github.com/ethereum-optimism/optimism/blob/86a96023ffd04d119296dff095d02fff79fa15de/packages/contracts-bedrock/.storage-layout#L287-L289
			{
				Key:   common.Hash{},
				Value: common.Hash{},
			},
		}

		calldata, err := storageSetterABI.Pack(method, input)
		if err != nil {
			return err
		}
		args := []any{
			common.HexToAddress(list.OptimismMintableERC20FactoryProxy.String()),
			storageSetterAddr,
			calldata,
		}
		proxyAdmin := common.HexToAddress(list.ProxyAdmin.String())
		if err := batch.AddCall(proxyAdmin, common.Big0, upgradeAndCall, args, proxyAdminABI); err != nil {
			return err
		}
	}

	optimismMintableERC20FactoryABI, err := bindings.OptimismMintableERC20FactoryMetaData.GetAbi()
	if err != nil {
		return err
	}

	optimismMintableERC20Factory, err := bindings.NewOptimismMintableERC20FactoryCaller(common.HexToAddress(list.OptimismMintableERC20FactoryProxy.String()), backend)
	if err != nil {
		return err
	}

	bridge, err := optimismMintableERC20Factory.BRIDGE(&bind.CallOpts{})
	if err != nil {
		return err
	}

	if bridge != common.Address(list.L1StandardBridgeProxy) {
		return fmt.Errorf("upgrading OptimismMintableERC20Factory: Bridge address doesn't match config")
	}

	calldata, err := optimismMintableERC20FactoryABI.Pack("initialize", bridge)
	if err != nil {
		return err
	}

	args := []any{
		common.HexToAddress(list.OptimismMintableERC20FactoryProxy.String()),
		common.HexToAddress(implementations.OptimismMintableERC20Factory.Address.String()),
		calldata,
	}

	proxyAdmin := common.HexToAddress(list.ProxyAdmin.String())
	if err := batch.AddCall(proxyAdmin, common.Big0, upgradeAndCall, args, proxyAdminABI); err != nil {
		return err
	}

	return nil
}

// OptimismPortal will add a call to the batch that upgrades the OptimismPortal.
func OptimismPortal(batch *safe.Batch, implementations superchain.ImplementationList, list superchain.AddressList, config *genesis.DeployConfig, chainConfig *superchain.ChainConfig, backend bind.ContractBackend) error {
	proxyAdminABI, err := bindings.ProxyAdminMetaData.GetAbi()
	if err != nil {
		return err
	}

	// 2 Step Upgrade
	{
		storageSetterABI, err := bindings.StorageSetterMetaData.GetAbi()
		if err != nil {
			return err
		}

		input := []bindings.StorageSetterSlot{
			// https://github.com/ethereum-optimism/optimism/blob/86a96023ffd04d119296dff095d02fff79fa15de/packages/contracts-bedrock/.storage-layout#L64-L65
			{
				Key:   common.Hash{},
				Value: common.Hash{},
			},
		}

		calldata, err := storageSetterABI.Pack(method, input)
		if err != nil {
			return err
		}
		args := []any{
			common.HexToAddress(list.OptimismPortalProxy.String()),
			storageSetterAddr,
			calldata,
		}
		proxyAdmin := common.HexToAddress(list.ProxyAdmin.String())
		if err := batch.AddCall(proxyAdmin, common.Big0, upgradeAndCall, args, proxyAdminABI); err != nil {
			return err
		}
	}

	optimismPortalABI, err := bindings.OptimismPortalMetaData.GetAbi()
	if err != nil {
		return err
	}

	optimismPortal, err := bindings.NewOptimismPortalCaller(common.HexToAddress(list.OptimismPortalProxy.String()), backend)
	if err != nil {
		return err
	}
	l2OutputOracle, err := optimismPortal.L2ORACLE(&bind.CallOpts{})
	if err != nil {
		return err
	}
	systemConfig, err := optimismPortal.SYSTEMCONFIG(&bind.CallOpts{})
	if err != nil {
		return err
	}

	if l2OutputOracle != common.HexToAddress(list.L2OutputOracleProxy.String()) {
		return fmt.Errorf("upgrading OptimismPortal: L2OutputOracle address doesn't match config")
	}

	if systemConfig != common.HexToAddress(chainConfig.SystemConfigAddr.String()) {
		return fmt.Errorf("upgrading OptimismPortal: SystemConfig address doesn't match config")
	}

	calldata, err := optimismPortalABI.Pack("initialize", l2OutputOracle, systemConfig, superchainConfigProxy)
	if err != nil {
		return err
	}

	args := []any{
		common.HexToAddress(list.OptimismPortalProxy.String()),
		common.HexToAddress(implementations.OptimismPortal.Address.String()),
		calldata,
	}

	proxyAdmin := common.HexToAddress(list.ProxyAdmin.String())
	if err := batch.AddCall(proxyAdmin, common.Big0, upgradeAndCall, args, proxyAdminABI); err != nil {
		return err
	}

	return nil
}

// SystemConfig will add a call to the batch that upgrades the SystemConfig.
func SystemConfig(batch *safe.Batch, implementations superchain.ImplementationList, list superchain.AddressList, config *genesis.DeployConfig, chainConfig *superchain.ChainConfig, backend bind.ContractBackend) error {
	proxyAdminABI, err := bindings.ProxyAdminMetaData.GetAbi()
	if err != nil {
		return err
	}

	// 2 Step Upgrade
	{
		storageSetterABI, err := bindings.StorageSetterMetaData.GetAbi()
		if err != nil {
			return err
		}

		startBlock := common.Hash{}

		if config != nil {
			startBlock = common.BigToHash(new(big.Int).SetUint64(config.SystemConfigStartBlock))
		}

		input := []bindings.StorageSetterSlot{
			// https://github.com/ethereum-optimism/optimism/blob/86a96023ffd04d119296dff095d02fff79fa15de/packages/contracts-bedrock/.storage-layout#L82-L83
			{
				Key:   common.Hash{},
				Value: common.Hash{},
			},
			// bytes32 public constant START_BLOCK_SLOT = bytes32(uint256(keccak256("systemconfig.startBlock")) - 1);
			{
				Key:   common.HexToHash("0xa11ee3ab75b40e88a0105e935d17cd36c8faee0138320d776c411291bdbbb19f"),
				Value: startBlock,
			},
		}

		calldata, err := storageSetterABI.Pack(method, input)
		if err != nil {
			return err
		}
		args := []any{
			common.HexToAddress(chainConfig.SystemConfigAddr.String()),
			storageSetterAddr,
			calldata,
		}
		proxyAdmin := common.HexToAddress(list.ProxyAdmin.String())
		if err := batch.AddCall(proxyAdmin, common.Big0, upgradeAndCall, args, proxyAdminABI); err != nil {
			return err
		}
	}

	systemConfigABI, err := bindings.SystemConfigMetaData.GetAbi()
	if err != nil {
		return err
	}

	systemConfig, err := bindings.NewSystemConfigCaller(common.HexToAddress(chainConfig.SystemConfigAddr.String()), backend)
	if err != nil {
		return err
	}

	gasPriceOracleOverhead, err := systemConfig.Overhead(&bind.CallOpts{})
	if err != nil {
		return err
	}

	gasPriceOracleScalar, err := systemConfig.Scalar(&bind.CallOpts{})
	if err != nil {
		return err
	}

	batcherHash, err := systemConfig.BatcherHash(&bind.CallOpts{})
	if err != nil {
		return err
	}

	l2GenesisBlockGasLimit, err := systemConfig.GasLimit(&bind.CallOpts{})
	if err != nil {
		return err
	}

	p2pSequencerAddress, err := systemConfig.UnsafeBlockSigner(&bind.CallOpts{})
	if err != nil {
		return err
	}

	finalSystemOwner, err := systemConfig.Owner(&bind.CallOpts{})
	if err != nil {
		return err
	}

	if config != nil {
		if gasPriceOracleOverhead.Uint64() != config.GasPriceOracleOverhead {
			return fmt.Errorf("upgrading SystemConfig: GasPriceOracleOverhead address doesn't match config")
		}
		if gasPriceOracleScalar.Uint64() != config.GasPriceOracleScalar {
			return fmt.Errorf("upgrading SystemConfig: GasPriceOracleScalar address doesn't match config")
		}
		if batcherHash != common.BytesToHash(config.BatchSenderAddress.Bytes()) {
			return fmt.Errorf("upgrading SystemConfig: BatchSenderAddress address doesn't match config")
		}
		if l2GenesisBlockGasLimit != uint64(config.L2GenesisBlockGasLimit) {
			return fmt.Errorf("upgrading SystemConfig: L2GenesisBlockGasLimit address doesn't match config")
		}
		if p2pSequencerAddress != config.P2PSequencerAddress {
			return fmt.Errorf("upgrading SystemConfig: P2PSequencerAddress address doesn't match config")
		}
		if finalSystemOwner != config.FinalSystemOwner {
			return fmt.Errorf("upgrading SystemConfig: FinalSystemOwner address doesn't match config")
		}
	}

	calldata, err := systemConfigABI.Pack(
		"initialize",
		finalSystemOwner,
		gasPriceOracleOverhead,
		gasPriceOracleScalar,
		batcherHash,
		l2GenesisBlockGasLimit,
		p2pSequencerAddress,
		genesis.DefaultResourceConfig,
		chainConfig.BatchInboxAddr,
		bindings.SystemConfigAddresses{
			L1CrossDomainMessenger:       common.Address(list.L1CrossDomainMessengerProxy),
			L1ERC721Bridge:               common.Address(list.L1ERC721BridgeProxy),
			L1StandardBridge:             common.Address(list.L1StandardBridgeProxy),
			L2OutputOracle:               common.Address(list.L2OutputOracleProxy),
			OptimismPortal:               common.Address(list.OptimismPortalProxy),
			OptimismMintableERC20Factory: common.Address(list.OptimismMintableERC20FactoryProxy),
		},
	)
	if err != nil {
		return err
	}

	args := []any{
		common.HexToAddress(chainConfig.SystemConfigAddr.String()),
		common.HexToAddress(implementations.SystemConfig.Address.String()),
		calldata,
	}

	proxyAdmin := common.HexToAddress(list.ProxyAdmin.String())
	if err := batch.AddCall(proxyAdmin, common.Big0, upgradeAndCall, args, proxyAdminABI); err != nil {
		return err
	}

	return nil
}
