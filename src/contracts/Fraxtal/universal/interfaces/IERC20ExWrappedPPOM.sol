// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20ExWrappedPPOM {
    error ECDSAInvalidSignature();
    error ECDSAInvalidSignatureLength(uint256 length);
    error ECDSAInvalidSignatureS(bytes32 s);
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);
    error ERC20InvalidApprover(address approver);
    error ERC20InvalidReceiver(address receiver);
    error ERC20InvalidSender(address sender);
    error ERC20InvalidSpender(address spender);
    error ERC2612ExpiredSignature(uint256 deadline);
    error ERC2612InvalidSigner(address signer, address owner);
    error InvalidAccountNonce(address account, uint256 currentNonce);
    error InvalidInitialization();
    error InvalidOwnershipAcceptance();
    error InvalidShortString();
    error NotInitializing();
    error OnlyOwner();
    error OwnerCannotBeZero();
    error StringTooLong(string str);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed account, uint256 amount);
    event EIP712DomainChanged();
    event Initialized(uint64 version);
    event Mint(address indexed account, uint256 amount);
    event MinterAdded(address minter_address);
    event MinterRemoved(address minter_address);
    event OwnerChanged(address oldOwner, address newOwner);
    event OwnerNominated(address newOwner);
    event TimelockChanged(address timelock_address);
    event TokenMinterBurned(address indexed from, address indexed to, uint256 amount);
    event TokenMinterMinted(address indexed from, address indexed to, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function BRIDGE() external view returns (address);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function REMOTE_TOKEN() external view returns (address);
    function acceptOwnership() external;
    function addMinter(address minter_address) external;
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function bridge() external view returns (address);
    function burn(uint256 value) external;
    function burn(address _from, uint256 _amount) external;
    function burnFrom(address account, uint256 value) external;
    function decimals() external view returns (uint8);
    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );
    function initialize(
        address _creator_address,
        address _timelock_address,
        address _bridge,
        address _remoteToken,
        uint256 _initTotalSupply,
        string memory _nameIn,
        string memory _symbolIn,
        string memory _versionIn
    ) external;
    function l1Token() external view returns (address);
    function l2Bridge() external view returns (address);
    function mint(address _to, uint256 _amount) external;
    function minter_burn_from(address b_address, uint256 b_amount) external;
    function minter_mint(address m_address, uint256 m_amount) external;
    function minters(address) external view returns (bool);
    function minters_array(uint256) external view returns (address);
    function name() external view returns (string memory);
    function nominateNewOwner(address _owner) external;
    function nominatedOwner() external view returns (address);
    function nonces(address owner) external view returns (uint256);
    function owner() external view returns (address);
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
    function remoteToken() external view returns (address);
    function removeMinter(address minter_address) external;
    function setTimelock(address _timelock_address) external;
    function supportsInterface(bytes4 _interfaceId) external pure returns (bool);
    function symbol() external view returns (string memory);
    function timelock_address() external view returns (address);
    function totalSupply() external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function version() external view returns (string memory);
}
