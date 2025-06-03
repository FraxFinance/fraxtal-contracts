// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ============================ FPISMerger ============================
// ====================================================================

import { IERC20 } from "@openzeppelin-4/contracts/token/ERC20/IERC20.sol";

contract FPISMerger {
    /// @notice FPIS is used for locking
    address public constant FPIS = 0xfc00000000000000000000000000000000000004;

    /// @notice FXS is used for unlocking
    address public constant FXS = 0xFc00000000000000000000000000000000000002;

    /// @notice Unlock time for all users
    uint256 public constant unlockTime = 1_834_617_600; // Sun Feb 20 2028 00:00:00 GMT+0000

    /// @notice max duration of lock = 4 years
    uint256 constant MAXTIME = 4 * 365 * 86_400;

    /// @notice total amount of FPIS locked
    uint256 public totalLocked;

    /// @notice total amount of FXS unlocked
    uint256 public totalUnlocked;

    Locked[] public totalLockedHist;

    /// @notice Struct holding lock information of the user
    struct Locked {
        uint256 amount;
        uint256 timestamp;
        uint256 blockNo;
    }

    /// @notice Lock information of the given user.
    mapping(address => Locked[]) public lockedAmount;

    /// @notice Has the given user unlocked yet
    mapping(address => bool) public unlocked;

    /// @notice Lock FPIS
    /// @param _amount Amount of FPIS to lock
    function lock(uint256 _amount) external {
        if (_amount == 0) revert ZeroAmount();
        if (block.timestamp >= unlockTime) revert AlreadyUnlocked();

        IERC20(FPIS).transferFrom(msg.sender, address(this), _amount);

        Locked[] storage lockedArray = lockedAmount[msg.sender];
        uint256 _newAmount = _amount + (lockedArray.length > 0 ? lockedArray[lockedArray.length - 1].amount : 0);
        if (lockedArray.length > 1 && block.timestamp - lockedArray[lockedArray.length - 2].timestamp < 6 * 3600) {
            // Update instead of add every 6 hours
            lockedArray[lockedArray.length - 1].amount = _newAmount;
        } else {
            lockedArray.push(Locked(_newAmount, block.timestamp, block.number));
        }

        totalLocked += _amount;
        if (
            totalLockedHist.length > 1 &&
            block.timestamp - totalLockedHist[totalLockedHist.length - 2].timestamp < 6 * 3600
        ) {
            // Update instead of add every 6 hours
            totalLockedHist[totalLockedHist.length - 1].amount = totalLocked;
        } else {
            totalLockedHist.push(Locked(totalLocked, block.timestamp, block.number));
        }

        emit Lock(msg.sender, _amount);
    }

    /// @notice Unlock FXS
    /// @param _user User to unlock
    function unlock(address _user) external {
        if (block.timestamp < unlockTime) revert NotYetUnlocked();
        if (unlocked[_user]) revert UserAlreadyUnlocked();
        unlocked[_user] = true;
        uint256 _amount = locked(_user).amount;
        totalUnlocked += _amount;
        IERC20(FXS).transfer(_user, _amount);
        emit Unlock(_user, _amount);
    }

    /// @notice Locked information of the user
    /// @param _user User to get the information of.
    /// @return _locked The Locked struct of a user
    function locked(address _user) public view returns (Locked memory _locked) {
        Locked[] storage lockedArray = lockedAmount[_user];
        if (lockedArray.length > 0) _locked = lockedArray[lockedArray.length - 1];
    }

    /// @notice Balance of the user including timelock boost
    /// @param _user User to get the balance of
    /// @return _balance Balance of the user
    function balanceOf(address _user) external view returns (uint256 _balance) {
        _balance = balanceOf(_user, block.timestamp);
    }

    /// @notice Balance of the user including timelock boost
    /// @param _user User to get the balance of
    /// @param _time timstamp to get the balance of
    /// @return _balance Balance of the user
    function balanceOf(address _user, uint256 _time) public view returns (uint256 _balance) {
        if (_time < unlockTime) {
            Locked memory _locked = locked(_user);
            _balance = _locked.amount + (_locked.amount * 3 * (unlockTime - _time)) / MAXTIME;
        }
    }

    /// @notice Balance of the user including timelock boost at the given block
    /// @param _user User to get the balance of
    /// @param _block block to get the balance of
    /// @return _balance Balance of the user
    function balanceOfAt(address _user, uint256 _block) public view returns (uint256 _balance) {
        _balance = balanceAt(lockedAmount[_user], _block);
    }

    /// @notice Total timelock boosted balance of all users
    /// @param _time timstamp to get the balance of
    /// @return _totalSupply total timelock boosted balance
    function totalSupply(uint256 _time) external view returns (uint256 _totalSupply) {
        if (_time < unlockTime) {
            _totalSupply = totalLocked + (totalLocked * 3 * (unlockTime - _time)) / MAXTIME;
        }
    }

    /// @notice Total timelock boosted balance of all users at the given block
    /// @param _block block to get the balance of
    /// @return _balance total timelock boosted balance
    function totalSupplyAt(uint256 _block) public view returns (uint256 _balance) {
        _balance = balanceAt(totalLockedHist, _block);
    }

    function balanceAt(Locked[] storage lockedArray, uint256 _block) internal view returns (uint256 _balance) {
        if (_block > block.number) revert InvalidBlockNumber();
        if (lockedArray.length > 0) {
            Locked memory _locked;
            uint256 i = lockedArray.length - 1;
            while (true) {
                if (lockedArray[i].blockNo <= _block) {
                    _locked = lockedArray[i];
                    break;
                }
                if (i == 0) break;
                --i;
            }
            if (_locked.amount > 0) {
                uint256 _time = _locked.timestamp;
                if (block.number > _locked.blockNo) {
                    _time +=
                        ((block.timestamp - _locked.timestamp) * (_block - _locked.blockNo)) /
                        (block.number - _locked.blockNo);
                }
                if (_time < unlockTime) {
                    _balance = _locked.amount + (_locked.amount * 3 * (unlockTime - _time)) / MAXTIME;
                }
            }
        }
    }

    // events
    /// @notice Emitted a user locks FPIS
    /// @param user The user locking
    /// @param amount The amount of FPIS being locked
    event Lock(address indexed user, uint256 amount);

    /// @notice Emitted a user is unlocked
    /// @param user The user being unlocked
    /// @param amount The amount of FXS being unlocked
    event Unlock(address indexed user, uint256 amount);

    // errors
    error ZeroAmount();
    error NotYetUnlocked();
    error AlreadyUnlocked();
    error UserAlreadyUnlocked();
    error TooManyLocks();
    error InvalidBlockNumber();
}
