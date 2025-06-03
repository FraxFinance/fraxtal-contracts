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
// ======================== ERC20ExWrappedPPOM ========================
// ====================================================================
// Converts a WETH-like into an ERC20PermitPermissionedOptiMintable.
// WETH and ERC20 state vars were in different orders, so needed to correctly account for that to preserve data
// Combines OZ's ERC20Permit and EIP721 into one contract. This was needed because of upgrade issues
// EIP712's _cached & _hashed immutables needed to be converted to private variables so _buildDomainSeparator works,
// as the token name & symbol changed to "Frax Ether" and "frxETH" respectively

// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna

// Reviewer(s) / Contributor(s)
// Dennis: https://github.com/denett
// Sam Kazemian: https://github.com/samkazemian
//
//
import { ECDSA } from "@openzeppelin-5/contracts/utils/cryptography/ECDSA.sol";
import { ERC20Burnable } from "@openzeppelin-5/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { ERC20Permit, ERC20 } from "@openzeppelin-5/contracts/token/ERC20/extensions/ERC20Permit.sol";
import { ERC20ReorderedState } from "src/contracts/Fraxtal/universal/vanity/ERC20ReorderedState.sol";
import { IERC165 } from "@openzeppelin-5/contracts/utils/introspection/IERC165.sol";
import { IERC20 } from "@openzeppelin-5/contracts/token/ERC20/IERC20.sol";
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
import { OwnedV2 } from "./vanity/OwnedV2.sol";
import { ShortStrings, ShortString } from "@openzeppelin-5/contracts/utils/ShortStrings.sol";
import { EIP712StoragePad } from "src/contracts/Fraxtal/universal/vanity/EIP712StoragePad.sol";

/// @title New contract for frxETH. Formerly wfrxETH.
/**
 * @notice Combines Openzeppelin's ERC20Permit and ERC20Burnable with Synthetix's Owned and Optimism's OptimismMintableERC20.
 *     Also includes a list of authorized minters
 */
/// @dev ERC20PermitPermissionedOptiMintable adheres to EIP-712/EIP-2612 and can use permits
contract ERC20ExWrappedPPOM is
    Initializable,
    IERC20,
    IERC20Permit,
    EIP712StoragePad,
    Nonces,
    ERC20ReorderedState,
    OwnedV2,
    IOptimismMintableERC20,
    ILegacyMintableERC20,
    IERC5267,
    ISemver
{
    using ShortStrings for *;

    // EIP721
    // =======================================
    bytes32 private constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

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

    // ERC20PermitPermissionedOptiMintable
    // =======================================
    /// @notice The timelock address
    address public timelock_address;

    /// @notice Array of the non-bridge minters
    address[] public minters_array;

    /// @notice Mapping of the non-bridge minters
    /// @dev Mapping is used for faster verification
    mapping(address => bool) public minters;

    /// @notice Address of the L2 StandardBridge on this network.
    address public BRIDGE;

    /// @notice Address of the corresponding version of this token on the remote chain.
    address public REMOTE_TOKEN;

    // ISemver
    // =======================================
    /// @custom:semver 1.0.0
    string public version = "1.0.0";

    /* ========== CONSTRUCTOR ========== */

    // /// @custom:semver 1.0.0
    // /// @param _creator_address The contract creator
    // /// @param _timelock_address The timelock
    // /// @param _bridge Address of the L2 standard bridge
    // /// @param _remoteToken Address of the corresponding L1 token
    // /// @param _name ERC20 name
    // /// @param _symbol ERC20 symbol
    // constructor(
    //     address _creator_address,
    //     address _timelock_address,
    //     address _bridge,
    //     address _remoteToken,
    //     string memory _name,
    //     string memory _symbol
    // ) EIP712StoragePad(_name) ERC20ReorderedState(_name, _symbol) OwnedV2(_creator_address) {
    //     REMOTE_TOKEN = _remoteToken;
    //     BRIDGE = _bridge;
    //     timelock_address = _timelock_address;
    // }

    constructor() ERC20ReorderedState("Dummy Token", "DUMMY") OwnedV2(msg.sender) {
        _disableInitializers();
    }

    /// @notice Initializer.
    /// @param _timelock_address The timelock
    /// @param _bridge Address of the L2 standard bridge
    /// @param _remoteToken Address of the corresponding L1 token
    /// @param _initTotalSupply The totalSupply
    /// @param _nameIn ERC20 name
    /// @param _symbolIn ERC20 symbol
    /// @param _versionIn Version
    function initialize(
        address _creator_address,
        address _timelock_address,
        address _bridge,
        address _remoteToken,
        uint256 _initTotalSupply,
        string memory _nameIn,
        string memory _symbolIn,
        string memory _versionIn
    ) public initializer {
        // Set version
        version = _versionIn;

        // Overwrite _totalSupply storage
        //--------------------------------------
        assembly {
            sstore(9, _initTotalSupply)
        }

        // Overwrite ERC20 _name and _symbol storage
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
            sstore(4, or(mload(add(_nameIn, 0x20)), mul(_nameLength, 2)))
            sstore(5, or(mload(add(_symbolIn, 0x20)), mul(_symbolLength, 2)))
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

        // Set owner and timelock
        //--------------------------------------
        owner = _creator_address;
        timelock_address = _timelock_address;

        // Set BRIDGE and REMOTE_TOKEN
        //--------------------------------------
        REMOTE_TOKEN = _remoteToken;
        BRIDGE = _bridge;

        // Move existing gas tokens to the _creator_address
        //--------------------------------------
        (bool success, ) = _creator_address.call{ value: address(this).balance }("");
        if (!success) {
            revert TransferFailed();
        }
    }

    /* ========== MODIFIERS ========== */

    /// @notice A modifier that only allows the contract owner or the timelock to call
    modifier onlyByOwnGov() {
        require(msg.sender == timelock_address || msg.sender == owner, "Not owner or timelock");
        _;
    }

    /// @notice A modifier that only allows a non-bridge minter to call
    modifier onlyMinters() {
        require(minters[msg.sender] == true, "Only minters");
        _;
    }

    /// @notice A modifier that only allows the bridge to call
    modifier onlyBridge() {
        require(msg.sender == BRIDGE, "OptimismMintableERC20: only bridge can mint and burn");
        _;
    }

    /* ========== LEGACY VIEWS ========== */

    /// @custom:legacy
    /// @notice Legacy getter for the remote token. Use REMOTE_TOKEN going forward.
    /// @return address The L1 remote token address
    function l1Token() public view returns (address) {
        return REMOTE_TOKEN;
    }

    /// @custom:legacy
    /// @notice Legacy getter for the bridge. Use BRIDGE going forward.
    /// @return address The bridge address
    function l2Bridge() public view returns (address) {
        return BRIDGE;
    }

    /// @custom:legacy
    /// @notice Legacy getter for REMOTE_TOKEN
    /// @return address The L1 remote token address
    function remoteToken() public view returns (address) {
        return REMOTE_TOKEN;
    }

    /// @custom:legacy
    /// @notice Legacy getter for BRIDGE
    /// @return address The bridge address
    function bridge() public view returns (address) {
        return BRIDGE;
    }

    /// @notice ERC165 interface check function.
    /// @param _interfaceId Interface ID to check.
    /// @return Whether or not the interface is supported by this contract.
    function supportsInterface(bytes4 _interfaceId) external pure virtual returns (bool) {
        bytes4 iface1 = type(IERC165).interfaceId;
        // Interface corresponding to the legacy L2StandardERC20.
        bytes4 iface2 = type(ILegacyMintableERC20).interfaceId;
        // Interface corresponding to the updated OptimismMintableERC20 (this contract).
        bytes4 iface3 = type(IOptimismMintableERC20).interfaceId;
        return _interfaceId == iface1 || _interfaceId == iface2 || _interfaceId == iface3;
    }

    /* ========== RESTRICTED FUNCTIONS [BRIDGE] ========== */

    /// @notice Allows the StandardBridge on this network to mint tokens.
    /// @param _to     Address to mint tokens to.
    /// @param _amount Amount of tokens to mint.
    function mint(
        address _to,
        uint256 _amount
    ) external virtual override(IOptimismMintableERC20, ILegacyMintableERC20) onlyBridge {
        _mint(_to, _amount);
        emit Mint(_to, _amount);
    }

    /// @notice Allows the StandardBridge on this network to burn tokens. No approval needed
    /// @param _from   Address to burn tokens from.
    /// @param _amount Amount of tokens to burn.
    function burn(
        address _from,
        uint256 _amount
    ) external virtual override(IOptimismMintableERC20, ILegacyMintableERC20) onlyBridge {
        _burn(_from, _amount);
        emit Burn(_from, _amount);
    }

    /* ========== RESTRICTED FUNCTIONS [NON-BRIDGE MINTERS] ========== */

    /// @notice Sames as burnFrom. Left here for backwards-compatibility. Used by non-bridge minters to burn tokens. Must have approval first.
    /// @param b_address Address of the account to burn from
    /// @param b_amount Amount of tokens to burn
    function minter_burn_from(address b_address, uint256 b_amount) public onlyMinters {
        burnFrom(b_address, b_amount);
        emit TokenMinterBurned(b_address, msg.sender, b_amount);
    }

    /// @notice Used by non-bridge minters to mint new tokens
    /// @param m_address Address of the account to mint to
    /// @param m_amount Amount of tokens to mint
    function minter_mint(address m_address, uint256 m_amount) public onlyMinters {
        _mint(m_address, m_amount);
        emit TokenMinterMinted(msg.sender, m_address, m_amount);
    }

    /// @notice Adds a non-bridge minter
    /// @param minter_address Address of minter to add
    function addMinter(address minter_address) public onlyByOwnGov {
        require(minter_address != address(0), "Zero address detected");

        require(minters[minter_address] == false, "Address already exists");
        minters[minter_address] = true;
        minters_array.push(minter_address);

        emit MinterAdded(minter_address);
    }

    /// @notice Removes a non-bridge minter
    /// @param minter_address Address of minter to remove
    function removeMinter(address minter_address) public onlyByOwnGov {
        require(minter_address != address(0), "Zero address detected");
        require(minters[minter_address] == true, "Address non-existent");

        // Delete from the mapping
        delete minters[minter_address];

        // 'Delete' from the array by setting the address to 0x0
        for (uint256 i = 0; i < minters_array.length; i++) {
            if (minters_array[i] == minter_address) {
                minters_array[i] = address(0); // This will leave a null in the array and keep the indices the same
                break;
            }
        }

        emit MinterRemoved(minter_address);
    }

    // ERC20Burnable Functions
    // =============================================
    /**
     * @dev Destroys a `value` amount of tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 value) public virtual {
        _burn(_msgSender(), value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, deducting from
     * the caller's allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `value`.
     */
    function burnFrom(address account, uint256 value) public virtual {
        _spendAllowance(account, _msgSender(), value);
        _burn(account, value);
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

    /* ========== RESTRICTED FUNCTIONS [ADMIN-RELATED] ========== */

    /// @notice Adjust the totalSupply
    function adjustTotalSupply(int256 _newTotalSupplyDiff) public onlyByOwnGov {
        if (_newTotalSupplyDiff < 0) {
            _totalSupply -= uint256(-_newTotalSupplyDiff);
        } else {
            _totalSupply += uint256(_newTotalSupplyDiff);
        }
    }

    /// @notice Sets the timelock address
    /// @param _timelock_address Address of the timelock
    function setTimelock(address _timelock_address) public onlyByOwnGov {
        require(_timelock_address != address(0), "Zero address detected");
        timelock_address = _timelock_address;
        emit TimelockChanged(_timelock_address);
    }

    /* ========== EVENTS ========== */

    /// @notice Emitted whenever the bridge burns tokens from an account
    /// @param account Address of the account tokens are being burned from
    /// @param amount  Amount of tokens burned
    event Burn(address indexed account, uint256 amount);

    /// @notice Emitted whenever the bridge mints tokens to an account
    /// @param account Address of the account tokens are being minted for
    /// @param amount  Amount of tokens minted.
    event Mint(address indexed account, uint256 amount);

    /// @notice Emitted when a non-bridge minter is added
    /// @param minter_address Address of the new minter
    event MinterAdded(address minter_address);

    /// @notice Emitted when a non-bridge minter is removed
    /// @param minter_address Address of the removed minter
    event MinterRemoved(address minter_address);

    /// @notice Emitted when the timelock address changes
    /// @param timelock_address Address of the new timelock
    event TimelockChanged(address timelock_address);

    /// @notice Emitted when a non-bridge minter burns tokens
    /// @param from The account whose tokens are burned
    /// @param to The minter doing the burning
    /// @param amount Amount of tokens burned
    event TokenMinterBurned(address indexed from, address indexed to, uint256 amount);

    /// @notice Emitted when a non-bridge minter mints tokens
    /// @param from The minter doing the minting
    /// @param to The account that gets the newly minted tokens
    /// @param amount Amount of tokens minted
    event TokenMinterMinted(address indexed from, address indexed to, uint256 amount);

    /// @notice Error for when the gas token withdrawal in the initializer fails
    error TransferFailed();
}
