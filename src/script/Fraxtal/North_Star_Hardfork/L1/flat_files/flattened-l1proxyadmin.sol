// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

// lib/optimism/packages/contracts-bedrock/lib/openzeppelin-contracts/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// lib/optimism/packages/contracts-bedrock/src/L1/interfaces/IResourceMetering.sol

interface IResourceMetering {
    struct ResourceParams {
        uint128 prevBaseFee;
        uint64 prevBoughtGas;
        uint64 prevBlockNum;
    }

    struct ResourceConfig {
        uint32 maxResourceLimit;
        uint8 elasticityMultiplier;
        uint8 baseFeeMaxChangeDenominator;
        uint32 minimumBaseFee;
        uint32 systemTxMaxGas;
        uint128 maximumBaseFee;
    }

    error OutOfGas();

    event Initialized(uint8 version);

    function params() external view returns (uint128 prevBaseFee, uint64 prevBoughtGas, uint64 prevBlockNum); // nosemgrep

    function __constructor__() external;
}

// lib/optimism/packages/contracts-bedrock/src/legacy/interfaces/IL1ChugSplashProxy.sol

/// @title IL1ChugSplashProxy
/// @notice Interface for the L1ChugSplashProxy contract.
interface IL1ChugSplashProxy {
    fallback() external payable;

    receive() external payable;

    function getImplementation() external returns (address);
    function getOwner() external returns (address);
    function setCode(bytes memory _code) external;
    function setOwner(address _owner) external;
    function setStorage(bytes32 _key, bytes32 _value) external;

    function __constructor__(address _owner) external;
}

/// @title IStaticL1ChugSplashProxy
/// @notice IStaticL1ChugSplashProxy is a static version of the ChugSplash proxy interface.
interface IStaticL1ChugSplashProxy {
    function getImplementation() external view returns (address);
    function getOwner() external view returns (address);
}

/// @title IL1ChugSplashDeployer
interface IL1ChugSplashDeployer {
    function isUpgrading() external view returns (bool);
}

// lib/optimism/packages/contracts-bedrock/src/universal/interfaces/IOwnable.sol

/// @title IOwnable
/// @notice Interface for Ownable.
interface IOwnable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);
    function renounceOwnership() external;
    function transferOwnership(address newOwner) external; // nosemgrep

    function __constructor__() external;
}

// lib/optimism/packages/contracts-bedrock/src/universal/interfaces/IProxy.sol

interface IProxy {
    event AdminChanged(address previousAdmin, address newAdmin);
    event Upgraded(address indexed implementation);

    fallback() external payable;

    receive() external payable;

    function admin() external returns (address);
    function changeAdmin(address _admin) external;
    function implementation() external returns (address);
    function upgradeTo(address _implementation) external;
    function upgradeToAndCall(address _implementation, bytes memory _data) external payable returns (bytes memory);

    function __constructor__(address _admin) external;
}

// lib/optimism/packages/contracts-bedrock/src/universal/interfaces/IStaticERC1967Proxy.sol

/// @title IStaticERC1967Proxy
/// @notice IStaticERC1967Proxy is a static version of the ERC1967 proxy interface.
interface IStaticERC1967Proxy {
    function implementation() external view returns (address);
    function admin() external view returns (address);
}

// lib/optimism/packages/contracts-bedrock/lib/openzeppelin-contracts/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// lib/optimism/packages/contracts-bedrock/src/legacy/interfaces/IAddressManager.sol

/// @title IAddressManager
/// @notice Interface for the AddressManager contract.
interface IAddressManager is IOwnable {
    event AddressSet(string indexed name, address newAddress, address oldAddress);

    function getAddress(string memory _name) external view returns (address);
    function setAddress(string memory _name, address _address) external;

    function __constructor__() external;
}

// lib/optimism/packages/contracts-bedrock/src/libraries/Constants.sol

/// @title Constants
/// @notice Constants is a library for storing constants. Simple! Don't put everything in here, just
///         the stuff used in multiple contracts. Constants that only apply to a single contract
///         should be defined in that contract instead.
library Constants {
    /// @notice Special address to be used as the tx origin for gas estimation calls in the
    ///         OptimismPortal and CrossDomainMessenger calls. You only need to use this address if
    ///         the minimum gas limit specified by the user is not actually enough to execute the
    ///         given message and you're attempting to estimate the actual necessary gas limit. We
    ///         use address(1) because it's the ecrecover precompile and therefore guaranteed to
    ///         never have any code on any EVM chain.
    address internal constant ESTIMATION_ADDRESS = address(1);

    /// @notice Value used for the L2 sender storage slot in both the OptimismPortal and the
    ///         CrossDomainMessenger contracts before an actual sender is set. This value is
    ///         non-zero to reduce the gas cost of message passing transactions.
    address internal constant DEFAULT_L2_SENDER = 0x000000000000000000000000000000000000dEaD;

    /// @notice The storage slot that holds the address of a proxy implementation.
    /// @dev `bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)`
    bytes32 internal constant PROXY_IMPLEMENTATION_ADDRESS =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// @notice The storage slot that holds the address of the owner.
    /// @dev `bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1)`
    bytes32 internal constant PROXY_OWNER_ADDRESS = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /// @notice The address that represents ether when dealing with ERC20 token addresses.
    address internal constant ETHER = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice The address that represents the system caller responsible for L1 attributes
    ///         transactions.
    address internal constant DEPOSITOR_ACCOUNT = 0xDeaDDEaDDeAdDeAdDEAdDEaddeAddEAdDEAd0001;

    /// @notice Returns the default values for the ResourceConfig. These are the recommended values
    ///         for a production network.
    function DEFAULT_RESOURCE_CONFIG() internal pure returns (IResourceMetering.ResourceConfig memory) {
        IResourceMetering.ResourceConfig memory config = IResourceMetering.ResourceConfig({
            maxResourceLimit: 20_000_000,
            elasticityMultiplier: 10,
            baseFeeMaxChangeDenominator: 8,
            minimumBaseFee: 1 gwei,
            systemTxMaxGas: 1_000_000,
            maximumBaseFee: type(uint128).max
        });
        return config;
    }
}

// lib/optimism/packages/contracts-bedrock/src/universal/ProxyAdmin.sol

// Contracts

// Libraries

// Interfaces

/// @title ProxyAdmin
/// @notice This is an auxiliary contract meant to be assigned as the admin of an ERC1967 Proxy,
///         based on the OpenZeppelin implementation. It has backwards compatibility logic to work
///         with the various types of proxies that have been deployed by Optimism in the past.
contract ProxyAdmin is Ownable {
    /// @notice The proxy types that the ProxyAdmin can manage.
    /// @custom:value ERC1967    Represents an ERC1967 compliant transparent proxy interface.
    /// @custom:value CHUGSPLASH Represents the Chugsplash proxy interface (legacy).
    /// @custom:value RESOLVED   Represents the ResolvedDelegate proxy (legacy).
    enum ProxyType {
        ERC1967,
        CHUGSPLASH,
        RESOLVED
    }

    /// @notice A mapping of proxy types, used for backwards compatibility.
    mapping(address => ProxyType) public proxyType;

    /// @notice A reverse mapping of addresses to names held in the AddressManager. This must be
    ///         manually kept up to date with changes in the AddressManager for this contract
    ///         to be able to work as an admin for the ResolvedDelegateProxy type.
    mapping(address => string) public implementationName;

    /// @notice The address of the address manager, this is required to manage the
    ///         ResolvedDelegateProxy type.
    IAddressManager public addressManager;

    /// @notice A legacy upgrading indicator used by the old Chugsplash Proxy.
    bool internal upgrading;

    /// @param _owner Address of the initial owner of this contract.
    constructor(address _owner) Ownable() {
        _transferOwnership(_owner);
    }

    /// @notice Sets the proxy type for a given address. Only required for non-standard (legacy)
    ///         proxy types.
    /// @param _address Address of the proxy.
    /// @param _type    Type of the proxy.
    function setProxyType(address _address, ProxyType _type) external onlyOwner {
        proxyType[_address] = _type;
    }

    /// @notice Sets the implementation name for a given address. Only required for
    ///         ResolvedDelegateProxy type proxies that have an implementation name.
    /// @param _address Address of the ResolvedDelegateProxy.
    /// @param _name    Name of the implementation for the proxy.
    function setImplementationName(address _address, string memory _name) external onlyOwner {
        implementationName[_address] = _name;
    }

    /// @notice Set the address of the AddressManager. This is required to manage legacy
    ///         ResolvedDelegateProxy type proxy contracts.
    /// @param _address Address of the AddressManager.
    function setAddressManager(IAddressManager _address) external onlyOwner {
        addressManager = _address;
    }

    /// @custom:legacy
    /// @notice Set an address in the address manager. Since only the owner of the AddressManager
    ///         can directly modify addresses and the ProxyAdmin will own the AddressManager, this
    ///         gives the owner of the ProxyAdmin the ability to modify addresses directly.
    /// @param _name    Name to set within the AddressManager.
    /// @param _address Address to attach to the given name.
    function setAddress(string memory _name, address _address) external onlyOwner {
        addressManager.setAddress(_name, _address);
    }

    /// @custom:legacy
    /// @notice Set the upgrading status for the Chugsplash proxy type.
    /// @param _upgrading Whether or not the system is upgrading.
    function setUpgrading(bool _upgrading) external onlyOwner {
        upgrading = _upgrading;
    }

    /// @custom:legacy
    /// @notice Legacy function used to tell ChugSplashProxy contracts if an upgrade is happening.
    /// @return Whether or not there is an upgrade going on. May not actually tell you whether an
    ///         upgrade is going on, since we don't currently plan to use this variable for anything
    ///         other than a legacy indicator to fix a UX bug in the ChugSplash proxy.
    function isUpgrading() external view returns (bool) {
        return upgrading;
    }

    /// @notice Returns the implementation of the given proxy address.
    /// @param _proxy Address of the proxy to get the implementation of.
    /// @return Address of the implementation of the proxy.
    function getProxyImplementation(address _proxy) external view returns (address) {
        ProxyType ptype = proxyType[_proxy];
        if (ptype == ProxyType.ERC1967) {
            return IStaticERC1967Proxy(_proxy).implementation();
        } else if (ptype == ProxyType.CHUGSPLASH) {
            return IStaticL1ChugSplashProxy(_proxy).getImplementation();
        } else if (ptype == ProxyType.RESOLVED) {
            return addressManager.getAddress(implementationName[_proxy]);
        } else {
            revert("ProxyAdmin: unknown proxy type");
        }
    }

    /// @notice Returns the admin of the given proxy address.
    /// @param _proxy Address of the proxy to get the admin of.
    /// @return Address of the admin of the proxy.
    function getProxyAdmin(address payable _proxy) external view returns (address) {
        ProxyType ptype = proxyType[_proxy];
        if (ptype == ProxyType.ERC1967) {
            return IStaticERC1967Proxy(_proxy).admin();
        } else if (ptype == ProxyType.CHUGSPLASH) {
            return IStaticL1ChugSplashProxy(_proxy).getOwner();
        } else if (ptype == ProxyType.RESOLVED) {
            return addressManager.owner();
        } else {
            revert("ProxyAdmin: unknown proxy type");
        }
    }

    /// @notice Updates the admin of the given proxy address.
    /// @param _proxy    Address of the proxy to update.
    /// @param _newAdmin Address of the new proxy admin.
    function changeProxyAdmin(address payable _proxy, address _newAdmin) external onlyOwner {
        ProxyType ptype = proxyType[_proxy];
        if (ptype == ProxyType.ERC1967) {
            IProxy(_proxy).changeAdmin(_newAdmin);
        } else if (ptype == ProxyType.CHUGSPLASH) {
            IL1ChugSplashProxy(_proxy).setOwner(_newAdmin);
        } else if (ptype == ProxyType.RESOLVED) {
            addressManager.transferOwnership(_newAdmin);
        } else {
            revert("ProxyAdmin: unknown proxy type");
        }
    }

    /// @notice Changes a proxy's implementation contract.
    /// @param _proxy          Address of the proxy to upgrade.
    /// @param _implementation Address of the new implementation address.
    function upgrade(address payable _proxy, address _implementation) public onlyOwner {
        ProxyType ptype = proxyType[_proxy];
        if (ptype == ProxyType.ERC1967) {
            IProxy(_proxy).upgradeTo(_implementation);
        } else if (ptype == ProxyType.CHUGSPLASH) {
            IL1ChugSplashProxy(_proxy).setStorage(
                Constants.PROXY_IMPLEMENTATION_ADDRESS,
                bytes32(uint256(uint160(_implementation)))
            );
        } else if (ptype == ProxyType.RESOLVED) {
            string memory name = implementationName[_proxy];
            addressManager.setAddress(name, _implementation);
        } else {
            // It should not be possible to retrieve a ProxyType value which is not matched by
            // one of the previous conditions.
            assert(false);
        }
    }

    /// @notice Changes a proxy's implementation contract and delegatecalls the new implementation
    ///         with some given data. Useful for atomic upgrade-and-initialize calls.
    /// @param _proxy          Address of the proxy to upgrade.
    /// @param _implementation Address of the new implementation address.
    /// @param _data           Data to trigger the new implementation with.
    function upgradeAndCall(
        address payable _proxy,
        address _implementation,
        bytes memory _data
    ) external payable onlyOwner {
        ProxyType ptype = proxyType[_proxy];
        if (ptype == ProxyType.ERC1967) {
            IProxy(_proxy).upgradeToAndCall{ value: msg.value }(_implementation, _data);
        } else {
            // reverts if proxy type is unknown
            upgrade(_proxy, _implementation);
            (bool success, ) = _proxy.call{ value: msg.value }(_data);
            require(success, "ProxyAdmin: call to proxy after upgrade failed");
        }
    }
}
