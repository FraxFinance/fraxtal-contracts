// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin-4/contracts/token/ERC20/IERC20.sol";
import { ERC165Checker } from "@openzeppelin-4/contracts/utils/introspection/ERC165Checker.sol";
import { Address } from "@openzeppelin-4/contracts/utils/Address.sol";
import { SafeERC20 } from "@openzeppelin-4/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeCall } from "@eth-optimism/contracts-bedrock/src/libraries/SafeCall.sol";
import {
    ILegacyMintableERC20
} from "@eth-optimism/contracts-bedrock/src/universal/interfaces/ILegacyMintableERC20.sol";
import {
    IOptimismMintableERC20
} from "@eth-optimism/contracts-bedrock/src/universal/interfaces/IOptimismMintableERC20.sol";
import { CrossDomainMessenger } from "@eth-optimism/contracts-bedrock/src/universal/CrossDomainMessenger.sol";
import { OptimismMintableERC20 } from "@eth-optimism/contracts-bedrock/src/universal/OptimismMintableERC20.sol";
import { Initializable } from "@openzeppelin-4/contracts/proxy/utils/Initializable.sol";
import { IPriceOracle } from "../interfaces/IPriceOracle.sol";

/// @custom:upgradeable
/// @title YieldBoosterBridge
/// @notice YieldBoosterBridge is a base contract for the L1 and L2 standard ERC20 bridges. It handles
///         the core bridging logic, including escrowing tokens that are native to the local chain
///         and minting/burning tokens that are native to the remote chain.
abstract contract YieldBoosterBridge is Initializable {
    using SafeERC20 for IERC20;

    /// @notice The L2 gas limit set when eth is depoisited using the receive() function.
    uint32 internal constant RECEIVE_DEFAULT_GAS_LIMIT = 200_000;

    /// @notice Corresponding bridge on the other domain. This public getter is deprecated
    ///         and will be removed in the future. Please use `otherBridge` instead.
    /// @custom:legacy
    /// @custom:network-specific
    YieldBoosterBridge public immutable OTHER_BRIDGE;

    /// @custom:legacy
    /// @custom:spacer messenger
    /// @notice Spacer for backwards compatibility.
    address private spacer_0_2_20;

    /// @custom:legacy
    /// @custom:spacer l2TokenBridge
    /// @notice Spacer for backwards compatibility.
    address private spacer_1_0_20;

    /// @notice Mapping that stores deposits for a given pair of local and remote tokens.
    mapping(address => mapping(address => PairInfo)) public pairInfo;

    /// @notice Messenger contract on this domain. This public getter is deprecated
    ///         and will be removed in the future. Please use `messenger` instead.
    /// @custom:network-specific
    CrossDomainMessenger public messenger;

    /// @notice Reserve extra slots (to a total of 50) in the storage layout for future upgrades.
    ///         A gap size of 46 was chosen here, so that the first slot used in a child contract
    ///         would be a multiple of 50.
    uint256[46] private __gap;

    /// @notice Emitted when an ERC20 bridge is initiated to the other chain.
    /// @param localToken  Address of the ERC20 on this chain.
    /// @param remoteToken Address of the ERC20 on the remote chain.
    /// @param from        Address of the sender.
    /// @param to          Address of the receiver.
    /// @param amount      Amount of the ERC20 sent.
    /// @param extraData   Extra data sent with the transaction.
    event ERC20BridgeInitiated(
        address indexed localToken,
        address indexed remoteToken,
        address indexed from,
        address to,
        uint256 amount,
        bytes extraData
    );

    /// @notice Emitted when an ERC20 bridge is finalized on this chain.
    /// @param localToken  Address of the ERC20 on this chain.
    /// @param remoteToken Address of the ERC20 on the remote chain.
    /// @param from        Address of the sender.
    /// @param to          Address of the receiver.
    /// @param amount      Amount of the ERC20 sent.
    /// @param extraData   Extra data sent with the transaction.
    event ERC20BridgeFinalized(
        address indexed localToken,
        address indexed remoteToken,
        address indexed from,
        address to,
        uint256 amount,
        bytes extraData
    );

    /// @notice Only allow EOAs to call the functions. Note that this is not safe against contracts
    ///         calling code within their constructors, but also doesn't really matter since we're
    ///         just trying to prevent users accidentally depositing with smart contract wallets.
    modifier onlyEOA() {
        require(!Address.isContract(msg.sender), "YieldBoosterBridge: function can only be called from an EOA");
        _;
    }

    /// @notice Ensures that the caller is a cross-chain message from the other bridge.
    modifier onlyOtherBridge() {
        require(
            msg.sender == address(messenger) && messenger.xDomainMessageSender() == address(OTHER_BRIDGE),
            "YieldBoosterBridge: function can only be called from the other bridge"
        );
        _;
    }

    struct PairInfo {
        uint256 amountEscrowed;
        uint256 amountBridged;
        IPriceOracle priceOracle;
        address remoteYieldDistributor;
        uint256 price;
    }

    /// @param _otherBridge Address of the other YieldBoosterBridge contract.
    constructor(YieldBoosterBridge _otherBridge) {
        OTHER_BRIDGE = _otherBridge;
    }

    /// @notice Initializer.
    /// @param _messenger   Address of CrossDomainMessenger on this network.
    // solhint-disable-next-line func-name-mixedcase
    function __YieldBoosterBridge_init(CrossDomainMessenger _messenger) internal onlyInitializing {
        messenger = _messenger;
    }

    /// @notice Getter for messenger contract.
    /// @custom:legacy
    /// @return Messenger contract on this domain.
    function MESSENGER() external view returns (CrossDomainMessenger) {
        return messenger;
    }

    /// @notice Getter for the remote domain bridge contract.
    function otherBridge() external view returns (YieldBoosterBridge) {
        return OTHER_BRIDGE;
    }

    /// @notice Sends ERC20 tokens to the sender's address on the other chain. Note that if the
    ///         ERC20 token on the other chain does not recognize the local token as the correct
    ///         pair token, the ERC20 bridge will fail and the tokens will be returned to sender on
    ///         this chain.
    /// @param _localToken  Address of the ERC20 on this chain.
    /// @param _remoteToken Address of the corresponding token on the remote chain.
    /// @param _amount      Amount of local tokens to deposit.
    /// @param _minGasLimit Minimum amount of gas that the bridge can be relayed with.
    /// @param _extraData   Extra data to be sent with the transaction. Note that the recipient will
    ///                     not be triggered with this data, but it will be emitted and can be used
    ///                     to identify the transaction.
    function bridgeERC20(
        address _localToken,
        address _remoteToken,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes calldata _extraData
    ) public virtual onlyEOA {
        _initiateBridgeERC20(_localToken, _remoteToken, msg.sender, msg.sender, _amount, _minGasLimit, _extraData);
    }

    /// @notice Sends ERC20 tokens to a receiver's address on the other chain. Note that if the
    ///         ERC20 token on the other chain does not recognize the local token as the correct
    ///         pair token, the ERC20 bridge will fail and the tokens will be returned to sender on
    ///         this chain.
    /// @param _localToken  Address of the ERC20 on this chain.
    /// @param _remoteToken Address of the corresponding token on the remote chain.
    /// @param _to          Address of the receiver.
    /// @param _amount      Amount of local tokens to deposit.
    /// @param _minGasLimit Minimum amount of gas that the bridge can be relayed with.
    /// @param _extraData   Extra data to be sent with the transaction. Note that the recipient will
    ///                     not be triggered with this data, but it will be emitted and can be used
    ///                     to identify the transaction.
    function bridgeERC20To(
        address _localToken,
        address _remoteToken,
        address _to,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes calldata _extraData
    ) public virtual {
        _initiateBridgeERC20(_localToken, _remoteToken, msg.sender, _to, _amount, _minGasLimit, _extraData);
    }

    /// @notice Finalizes an ERC20 bridge on this chain. Can only be triggered by the other
    ///         YieldBoosterBridge contract on the remote chain.
    /// @param _localToken  Address of the ERC20 on this chain.
    /// @param _remoteToken Address of the corresponding token on the remote chain.
    /// @param _from        Address of the sender.
    /// @param _to          Address of the receiver.
    /// @param _amount      Amount of the ERC20 being bridged.
    /// @param _extraData   Extra data to be sent with the transaction. Note that the recipient will
    ///                     not be triggered with this data, but it will be emitted and can be used
    ///                     to identify the transaction.
    function finalizeBridgeERC20(
        address _localToken,
        address _remoteToken,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _extraData
    ) public onlyOtherBridge {
        if (_isOptimismMintableERC20(_localToken)) {
            require(
                _isCorrectTokenPair(_localToken, _remoteToken),
                "YieldBoosterBridge: wrong remote token for Optimism Mintable ERC20 local token"
            );

            OptimismMintableERC20(_localToken).mint(_to, _amount);
        } else {
            PairInfo storage _pairInfo = pairInfo[_localToken][_remoteToken];
            uint256 _amountToSend = (_amount * 1e18) / getPrice(_pairInfo, _localToken);
            _pairInfo.amountEscrowed -= _amountToSend;
            _pairInfo.amountBridged -= _amount;
            IERC20(_localToken).safeTransfer(_to, _amountToSend);
        }

        // Emit the correct events. By default this will be ERC20BridgeFinalized, but child
        // contracts may override this function in order to emit legacy events as well.
        _emitERC20BridgeFinalized(_localToken, _remoteToken, _from, _to, _amount, _extraData);
    }

    /// @notice Sends ERC20 tokens to a receiver's address on the other chain.
    /// @param _localToken  Address of the ERC20 on this chain.
    /// @param _remoteToken Address of the corresponding token on the remote chain.
    /// @param _to          Address of the receiver.
    /// @param _amount      Amount of local tokens to deposit.
    /// @param _minGasLimit Minimum amount of gas that the bridge can be relayed with.
    /// @param _extraData   Extra data to be sent with the transaction. Note that the recipient will
    ///                     not be triggered with this data, but it will be emitted and can be used
    ///                     to identify the transaction.
    function _initiateBridgeERC20(
        address _localToken,
        address _remoteToken,
        address _from,
        address _to,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes memory _extraData
    ) internal {
        uint256 _amountToBridge;
        if (_isOptimismMintableERC20(_localToken)) {
            require(
                _isCorrectTokenPair(_localToken, _remoteToken),
                "YieldBoosterBridge: wrong remote token for Optimism Mintable ERC20 local token"
            );
            _amountToBridge = _amount;
            OptimismMintableERC20(_localToken).burn(_from, _amount);
        } else {
            PairInfo storage _pairInfo = pairInfo[_localToken][_remoteToken];
            _amountToBridge = (_amount * getPrice(_pairInfo, _localToken)) / 1e18;
            _pairInfo.amountEscrowed += _amount;
            _pairInfo.amountBridged += _amountToBridge;
            IERC20(_localToken).safeTransferFrom(_from, address(this), _amount);
        }

        // Emit the correct events. By default this will be ERC20BridgeInitiated, but child
        // contracts may override this function in order to emit legacy events as well.
        _emitERC20BridgeInitiated(_localToken, _remoteToken, _from, _to, _amountToBridge, _extraData);

        messenger.sendMessage(
            address(OTHER_BRIDGE),
            abi.encodeWithSelector(
                this.finalizeBridgeERC20.selector,
                // Because this call will be executed on the remote chain, we reverse the order of
                // the remote and local token addresses relative to their order in the
                // finalizeBridgeERC20 function.
                _remoteToken,
                _localToken,
                _from,
                _to,
                _amountToBridge,
                _extraData
            ),
            _minGasLimit
        );
    }

    function bridgeYield(address _localToken, address _remoteToken, uint32 _minGasLimit) external {
        PairInfo storage _pairInfo = pairInfo[_localToken][_remoteToken];
        uint256 _newAmountBridged = (_pairInfo.amountEscrowed * getPrice(_pairInfo, _localToken)) / 1e18;
        if (_newAmountBridged > _pairInfo.amountBridged) {
            uint256 _yield = _newAmountBridged - _pairInfo.amountBridged;

            _emitERC20BridgeInitiated(
                _localToken,
                _remoteToken,
                address(this),
                _pairInfo.remoteYieldDistributor,
                _yield,
                bytes("")
            );

            messenger.sendMessage(
                address(OTHER_BRIDGE),
                abi.encodeWithSelector(
                    this.finalizeBridgeERC20.selector,
                    // Because this call will be executed on the remote chain, we reverse the order of
                    // the remote and local token addresses relative to their order in the
                    // finalizeBridgeERC20 function.
                    _remoteToken,
                    _localToken,
                    address(this),
                    _pairInfo.remoteYieldDistributor,
                    _yield,
                    bytes("")
                ),
                _minGasLimit
            );
            _pairInfo.amountBridged = _newAmountBridged;
        }
    }

    function initializePair(
        address _localToken,
        address _remoteToken,
        address _priceOracle,
        address _remoteYieldDistributor
    ) external {
        PairInfo storage _pairInfo = pairInfo[_localToken][_remoteToken];
        require(_pairInfo.priceOracle == IPriceOracle(address(0)), "StandardBridge: Pair already initialized");
        require(_remoteYieldDistributor != address(0), "StandardBridge: RemoteYieldDistributor can not be zero");

        _pairInfo.priceOracle = IPriceOracle(_priceOracle);
        _pairInfo.price = IPriceOracle(_priceOracle).getPrice(_localToken);
        _pairInfo.remoteYieldDistributor = _remoteYieldDistributor;
    }

    function getPrice(PairInfo storage _pairInfo, address _localToken) internal returns (uint256) {
        require(_pairInfo.priceOracle != IPriceOracle(address(0)), "StandardBridge: Pair not initialized");
        uint256 _newPrice = IPriceOracle(_pairInfo.priceOracle).getPrice(_localToken);
        if (_newPrice > _pairInfo.price) {
            // Only update the price if it went up.
            _pairInfo.price = _newPrice;
            return _newPrice;
        } else {
            return _pairInfo.price;
        }
    }

    /// @notice Checks if a given address is an OptimismMintableERC20. Not perfect, but good enough.
    ///         Just the way we like it.
    /// @param _token Address of the token to check.
    /// @return True if the token is an OptimismMintableERC20.
    function _isOptimismMintableERC20(address _token) internal view returns (bool) {
        return
            ERC165Checker.supportsInterface(_token, type(ILegacyMintableERC20).interfaceId) ||
            ERC165Checker.supportsInterface(_token, type(IOptimismMintableERC20).interfaceId);
    }

    /// @notice Checks if the "other token" is the correct pair token for the OptimismMintableERC20.
    ///         Calls can be saved in the future by combining this logic with
    ///         `_isOptimismMintableERC20`.
    /// @param _mintableToken OptimismMintableERC20 to check against.
    /// @param _otherToken    Pair token to check.
    /// @return True if the other token is the correct pair token for the OptimismMintableERC20.
    function _isCorrectTokenPair(address _mintableToken, address _otherToken) internal view returns (bool) {
        if (ERC165Checker.supportsInterface(_mintableToken, type(ILegacyMintableERC20).interfaceId)) {
            return _otherToken == ILegacyMintableERC20(_mintableToken).l1Token();
        } else {
            return _otherToken == IOptimismMintableERC20(_mintableToken).remoteToken();
        }
    }

    /// @notice Emits the ERC20BridgeInitiated event and if necessary the appropriate legacy
    ///         event when an ERC20 bridge is initiated to the other chain.
    /// @param _localToken  Address of the ERC20 on this chain.
    /// @param _remoteToken Address of the ERC20 on the remote chain.
    /// @param _from        Address of the sender.
    /// @param _to          Address of the receiver.
    /// @param _amount      Amount of the ERC20 sent.
    /// @param _extraData   Extra data sent with the transaction.
    function _emitERC20BridgeInitiated(
        address _localToken,
        address _remoteToken,
        address _from,
        address _to,
        uint256 _amount,
        bytes memory _extraData
    ) internal virtual {
        emit ERC20BridgeInitiated(_localToken, _remoteToken, _from, _to, _amount, _extraData);
    }

    /// @notice Emits the ERC20BridgeFinalized event and if necessary the appropriate legacy
    ///         event when an ERC20 bridge is initiated to the other chain.
    /// @param _localToken  Address of the ERC20 on this chain.
    /// @param _remoteToken Address of the ERC20 on the remote chain.
    /// @param _from        Address of the sender.
    /// @param _to          Address of the receiver.
    /// @param _amount      Amount of the ERC20 sent.
    /// @param _extraData   Extra data sent with the transaction.
    function _emitERC20BridgeFinalized(
        address _localToken,
        address _remoteToken,
        address _from,
        address _to,
        uint256 _amount,
        bytes memory _extraData
    ) internal virtual {
        emit ERC20BridgeFinalized(_localToken, _remoteToken, _from, _to, _amount, _extraData);
    }
}
