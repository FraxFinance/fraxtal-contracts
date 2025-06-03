// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { SafeERC20 } from "@openzeppelin-4/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin-4/contracts/token/ERC20/IERC20.sol";
import { IIncentivesReceiver } from "../interfaces/IIncentivesReceiver.sol";

contract SnapshotDistributor {
    using SafeERC20 for IERC20;

    IERC20 public snapshotToken;
    IERC20 public distributeToken;
    RegisteredAddress[] public registeredAddresses;
    RegisteredAddress[] public pending;
    mapping(address => bool) public registered;
    address public admin;
    address public operator;
    uint256 public totalBalances;

    struct RegisteredAddress {
        address tokenHolder;
        address incentivesReceiver;
        bool distributeCall;
        uint256 balance;
    }

    constructor(IERC20 _snapshotToken, IERC20 _distributeToken, address _operator) {
        admin = msg.sender;
        snapshotToken = _snapshotToken;
        distributeToken = _distributeToken;
        operator = _operator;
    }

    function requestRegisterAddress(RegisteredAddress memory _addressToRegister) external {
        require(!registered[_addressToRegister.tokenHolder], "Already registered");
        require(_addressToRegister.balance == 0, "Balance should be zero");
        pending.push(_addressToRegister);
    }

    function approvePendingRequests(uint256[] memory _indices) external {
        require(msg.sender == admin, "!Auth");
        for (uint256 i = 0; i < _indices.length; i++) {
            uint256 _index = _indices[i];
            RegisteredAddress memory _addressToRegister = pending[_index];
            require(!registered[_addressToRegister.tokenHolder], "Already registered");
            registered[_addressToRegister.tokenHolder] = true;
            registeredAddresses.push(_addressToRegister);
        }
    }

    function updateAddress(uint256 _index, RegisteredAddress memory _addressToRegister) external {
        require(msg.sender == admin, "!Auth");
        require(_addressToRegister.tokenHolder == registeredAddresses[_index].tokenHolder, "Address mismatch");
        _addressToRegister.balance = registeredAddresses[_index].balance;
        registeredAddresses[_index] = _addressToRegister;
    }

    function deleteAddresses(uint256[] memory _indices) external {
        require(msg.sender == admin, "!Auth");
        uint256 _totalBalances = totalBalances;
        for (uint256 i = 0; i < _indices.length; i++) {
            uint256 _index = _indices[i];
            RegisteredAddress memory _addressToDelete = registeredAddresses[_index];
            registered[_addressToDelete.tokenHolder] = false;
            _totalBalances -= _addressToDelete.balance;
            registeredAddresses[_index] = registeredAddresses[registeredAddresses.length - 1];
            registeredAddresses.pop();
        }
        totalBalances = _totalBalances;
    }

    function distribute() external {
        require(msg.sender == admin || msg.sender == operator, "!Auth");
        IERC20 _snapshotToken = snapshotToken;
        IERC20 _distributeToken = distributeToken;
        uint256 _cummBalances = 0;
        uint256 _totalBalances = totalBalances;
        uint256[] memory _snapshot = new uint256[](registeredAddresses.length);
        for (uint256 i = 0; i < _snapshot.length; ++i) {
            _snapshot[i] = _snapshotToken.balanceOf(registeredAddresses[i].tokenHolder);
            _cummBalances += _snapshot[i];
        }
        uint256 _incentivesPerToken = ((_distributeToken.balanceOf(address(this)) - _totalBalances) * 1e18) /
            _cummBalances;
        for (uint256 i = 0; i < _snapshot.length; ++i) {
            uint256 _incentives = (_incentivesPerToken * _snapshot[i]) / 1e18;
            if (registeredAddresses[i].distributeCall) {
                registeredAddresses[i].balance += _incentives;
                _totalBalances += _incentives;
            } else {
                _distributeToken.safeTransfer(registeredAddresses[i].incentivesReceiver, _incentives);
            }
        }
        totalBalances = _totalBalances;
    }

    function distributeCall(uint256[] memory _indices) external {
        IERC20 _distributeToken = distributeToken;
        uint256 _totalBalances = totalBalances;
        for (uint256 i = 0; i < _indices.length; i++) {
            uint256 _index = _indices[i];
            RegisteredAddress memory _addressToExecute = registeredAddresses[_index];
            uint256 _balance = _addressToExecute.balance;
            if (_balance > 1) {
                _balance--;
                _distributeToken.approve(_addressToExecute.incentivesReceiver, _balance);
                IIncentivesReceiver(_addressToExecute.incentivesReceiver).distribute(
                    _addressToExecute.tokenHolder,
                    _balance
                );
                registeredAddresses[_index].balance = 1; // Safe gas on next distribute by not setting it to zero
                _totalBalances -= _balance;
            }
        }
        totalBalances = _totalBalances;
    }

    function setAmin(address _newAdmin) external {
        require(msg.sender == admin, "!Auth");
        admin = _newAdmin;
    }

    function setOperator(address _newOperator) external {
        require(msg.sender == admin, "!Auth");
        operator = _newOperator;
    }
}
