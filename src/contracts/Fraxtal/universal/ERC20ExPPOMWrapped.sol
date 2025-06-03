// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ======================== ERC20ExPPOMWrapped ========================
// ====================================================================
// Converts a ERC20PermitPermissionedOptiMintable to a WETH-like contract.
// Combines OZ's ERC20Permit and EIP721 into one contract.
// EIP712's _cached & _hashed immutables needed to be converted to private variables so _buildDomainSeparator w,
// as the token name & symbol changed to "Wrapped Frax" and "wFRAX" respectively

// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna

// Reviewer(s) / Contributor(s)
// Dennis: https://github.com/denett
// Sam Kazemian: https://github.com/samkazemian
//
//
import { ECDSA } from "@openzeppelin-5/contracts/utils/cryptography/ECDSA.sol";
import { EIP712StoragePad } from "src/contracts/Fraxtal/universal/vanity/EIP712StoragePad.sol";
import { ERC20 } from "@openzeppelin-5/contracts/token/ERC20/ERC20.sol";
import { IERC20Permit } from "@openzeppelin-5/contracts/token/ERC20/extensions/IERC20Permit.sol";
import { IERC5267 } from "@openzeppelin-5/contracts/interfaces/IERC5267.sol";
import {
    ILegacyMintableERC20
} from "@eth-optimism/contracts-bedrock/src/universal/interfaces/ILegacyMintableERC20.sol";
import {
    IOptimismMintableERC20
} from "@eth-optimism/contracts-bedrock/src/universal/interfaces/IOptimismMintableERC20.sol";
import { ISemver } from "@eth-optimism/contracts-bedrock/src/universal/interfaces/ISemver.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable-5/proxy/utils/Initializable.sol";
import { MessageHashUtils } from "@openzeppelin-5/contracts/utils/cryptography/MessageHashUtils.sol";
import { Nonces } from "@openzeppelin-5/contracts/utils/Nonces.sol";
import { ShortStrings, ShortString } from "@openzeppelin-5/contracts/utils/ShortStrings.sol";

/// @title New contract for wFRAX, which is the old FXS token (now the gas token) wrapped and renamed.
/**
 * @notice Has Openzeppelin's ERC20Permit with Synthetix's Owned.
 *     Added WETH9-like features.
 *     Has OZ's ERC20Permit
 *     Has OZ's EIP721
 *     To preserve storage patterns, some variables are no longer used but need to be included.
 */
contract ERC20ExPPOMWrapped is Initializable, ERC20, IERC20Permit, IERC5267, ISemver, EIP712StoragePad, Nonces {
    using ShortStrings for *;

    // ERC20Permit
    // =======================================

    // mapping(address => Counters.Counter) private _nonces;

    bytes32 private constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    // ORIGINAL STATE
    // =======================================

    /// @dev
    // WARNING!!! CHECK FOR STORAGE COLLISIONS FROM _balances, _allowances, and _nonces?
    // WARNING!!! CHECK FOR STORAGE COLLISIONS FROM _balances, _allowances, and _nonces?
    // WARNING!!! CHECK FOR STORAGE COLLISIONS FROM _balances, _allowances, and _nonces?
    // WARNING!!! CHECK FOR STORAGE COLLISIONS FROM _balances, _allowances, and _nonces?
    // WARNING!!! CHECK FOR STORAGE COLLISIONS FROM _balances, _allowances, and _nonces?
    // WARNING!!! CHECK FOR STORAGE COLLISIONS FROM _balances, _allowances, and _nonces?

    /// @notice [DEPRECATED] The owner address
    address private DEPRECATED___owner;

    /// @notice [DEPRECATED] The nominated owner address
    address private DEPRECATED___nominated_owner;

    /// @notice [DEPRECATED] The timelock address
    address private DEPRECATED___timelock_address;

    // /// @notice [DEPRECATED] Address of the L2 StandardBridge on this network.
    // address public immutable DEPRECATED___BRIDGE;

    // /// @notice [DEPRECATED] Address of the corresponding version of this token on the remote chain.
    // address public immutable DEPRECATED___REMOTE_TOKEN;

    /// @notice [DEPRECATED] Array of the non-bridge minters
    address[] private DEPRECATED___minters_array;

    /// @notice [DEPRECATED] Mapping of the non-bridge minters
    /// @dev Mapping is used for faster verification
    mapping(address => bool) private DEPRECATED___minters;

    // EIP721
    // =======================================
    bytes32 private constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    string private _nameFallback;
    string private _versionFallback;

    bytes32 private _cachedDomainSeparator;
    uint256 private _cachedChainId;
    address private _cachedThis;

    bytes32 private _hashedName;
    bytes32 private _hashedVersion;

    ShortString private _SStrName;
    ShortString private _SStrVersion;

    // ISemver
    // =======================================

    /// @custom:semver 1.0.1
    string public version;

    // ==============================================================================
    // CONSTRUCTOR
    // ==============================================================================

    constructor() ERC20("Dummy Name", "DUMMY") {
        _disableInitializers();
    }

    /// @notice Initializer.
    /// @param _nameIn ERC20 name
    /// @param _symbolIn ERC20 symbol
    /// @param _versionIn Version
    function initialize(string memory _nameIn, string memory _symbolIn, string memory _versionIn) public initializer {
        // Set version
        version = _versionIn;

        // Overwrite ERC20 _name and _symbol
        //--------------------------------------
        // Make sure _nameIn and _symbolIn are below 31 bytes
        uint256 _nameLength = bytes(_nameIn).length;
        uint256 _symbolLength = bytes(_symbolIn).length;
        if ((_nameLength >= 32) || (_symbolLength >= 32)) {
            revert("Name and/or symbol must be lt 32 bytes");
        }

        // Write to the storage slots
        // https://ethereum.stackexchange.com/questions/126269/how-to-store-and-retrieve-string-which-is-more-than-32-bytesor-could-be-less-th
        assembly {
            // If string length <= 31 we store a short array
            // length storage variable layout :
            // bytes 0 - 31 : string data
            // byte 32 : length * 2
            // data storage variable is UNUSED in this case
            sstore(3, or(mload(add(_nameIn, 0x20)), mul(_nameLength, 2)))
            sstore(4, or(mload(add(_symbolIn, 0x20)), mul(_symbolLength, 2)))
        }

        // Set EIP712 variables
        //--------------------------------------
        _SStrName = _nameIn.toShortStringWithFallback(_nameFallback);
        _SStrVersion = _versionIn.toShortStringWithFallback(_versionFallback);
        _hashedName = keccak256(bytes(_nameIn));
        _hashedVersion = keccak256(bytes(_versionIn));
        _cachedChainId = block.chainid;
        _cachedDomainSeparator = _buildDomainSeparator();
        _cachedThis = address(this);

        // Clear old values
        // Might not be necessary
        //--------------------------------------
        DEPRECATED___owner = address(0);
        DEPRECATED___nominated_owner = address(0);
        DEPRECATED___timelock_address = address(0);

        // Loop through the minter array and set each mapping to false, and each minter_array value to 0x0
        for (uint256 i = 0; i < DEPRECATED___minters_array.length; i++) {
            DEPRECATED___minters[DEPRECATED___minters_array[i]] = false;
            delete DEPRECATED___minters_array[i];
        }
    }

    /* ========== EIP712 FUNCTIONS ========== */

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _cachedThis && block.chainid == _cachedChainId) {
            return _cachedDomainSeparator;
        } else {
            return _buildDomainSeparator();
        }
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(_TYPE_HASH, _hashedName, _hashedVersion, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view returns (bytes32) {
        return MessageHashUtils.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev See {EIP-5267}.
     *
     * _Available since v4.9._
     */
    function eip712Domain()
        public
        view
        virtual
        override
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        return (
            hex"0f", // 01111
            _SStrName.toStringWithFallback(_nameFallback),
            _SStrVersion.toStringWithFallback(_versionFallback),
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
    }

    /* ========== ERC20Permit FUNCTIONS ========== */

    /**
     * @dev Permit deadline has expired.
     */
    error ERC2612ExpiredSignature(uint256 deadline);

    /**
     * @dev Mismatched signature.
     */
    error ERC2612InvalidSigner(address signer, address owner);

    /**
     * @inheritdoc IERC20Permit
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        if (block.timestamp > deadline) {
            revert ERC2612ExpiredSignature(deadline);
        }

        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        if (signer != owner) {
            revert ERC2612InvalidSigner(signer, owner);
        }

        _approve(owner, spender, value);
    }

    /**
     * @inheritdoc IERC20Permit
     */
    function nonces(address owner) public view virtual override(IERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }

    /**
     * @inheritdoc IERC20Permit
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view virtual returns (bytes32) {
        return _domainSeparatorV4();
    }

    /* ========== BACKWARDS COMPATIBILITY ========== */
    /// @notice Backwards compatibility function for burn. Calls withdraw
    /// @param _value Amount of tokens to burn / withdraw
    function burn(uint256 _value) public {
        withdraw(_value);
    }

    /* ========== WETH9-STYLE FUNCTIONS ========== */

    /// @notice Donate ETH for nothing in return
    function donate() public payable {
        // Do nothing
    }

    /// @notice Fallback gas token deposit
    fallback() external payable {
        deposit();
    }

    /// @notice Deposit gas token for wrapped ERC20. Uses msg.value
    function deposit() public payable {
        // Accept the gas tokens and mint the ERC20 to the sender
        _mint(msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Withdraw ERC20 for gas token.
    /// @param wad Amount of gas token to receive / wrapped ERC20 to burn.
    function withdraw(uint256 wad) public {
        // Will revert if sender does not have enough ERC20 tokens
        _burn(msg.sender, wad);

        // Give the sender the gas tokens
        payable(msg.sender).transfer(wad);

        emit Withdrawal(msg.sender, wad);
    }

    /* ========== EVENTS ========== */

    /// @notice Emitted when the gas token is wrapped
    /// @param dst Sender/depositor
    /// @param wad Amount of tokens wrapped
    event Deposit(address indexed dst, uint256 wad);

    /// @notice Emitted when the gas token is unwrapped
    /// @param src Sender / withdrawer
    /// @param wad Amount of tokens unwrapped
    event Withdrawal(address indexed src, uint256 wad);
}
