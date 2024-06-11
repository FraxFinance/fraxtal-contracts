// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// =========================== Fxtl Points ============================
// ====================================================================

import { OwnedV2 } from "src/contracts/VestedFXS-and-Flox/VestedFXS/OwnedV2.sol";
import { IFxtlPointsEvents } from "./IFxtlPointsEvents.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title FxtlPoints
 * @author Frax Finance
 * @notice A simple Fxtl point tracking smart contract.
 */
contract FxtlPoints is OwnedV2, ERC20, IFxtlPointsEvents {
    uint256 private _totalPointSupply;

    mapping(address => bool) public isFxtlContributor;
    mapping(address => uint256) private fxtlPointsBalances;

    /**
     * @notice Used to initialize the smart contract.
     * @dev The initial owner is set as the deployer of the smart contract.
     */
    constructor() OwnedV2(msg.sender) ERC20("FXTL Points", "FXTL") {}

    /**
     * @notice Retrieves the Fxtl points balances of multiple point owners at the same time.
     * @param _pointOwners An array of point owners
     * @return An array of Fxtl points balances
     */
    function bulkFxtlPointsBalances(address[] memory _pointOwners) external view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](_pointOwners.length);

        for (uint256 i; i < _pointOwners.length; ) {
            balances[i] = fxtlPointsBalances[_pointOwners[i]];

            unchecked {
                ++i;
            }
        }

        return balances;
    }

    /**
     * @notice Adds a Fxtl contributor.
     * @dev Can only be called by the owner.
     * @param _contributor The address of the Fxtl contributor to add
     */
    function addFxtlContributor(address _contributor) external {
        _onlyOwner();
        if (isFxtlContributor[_contributor]) revert AlreadyFxtlContributor();
        isFxtlContributor[_contributor] = true;
        emit FxtlContributorAdded(_contributor);
    }

    /**
     * @notice Removes a Fxtl contributor.
     * @dev Can only be called by the owner.
     * @param _contributor The address of the Fxtl contributor to remove
     */
    function removeFxtlContributor(address _contributor) external {
        _onlyOwner();
        if (!isFxtlContributor[_contributor]) revert NotFxtlContributor();
        isFxtlContributor[_contributor] = false;
        emit FxtlContributorRemoved(_contributor);
    }

    /**
     * @notice Adds Fxtl points to a recipient.
     * @dev Can only be called by a Fxtl contributor.
     * @param _recipient Recipient of the Fxtl points
     * @param _amount Amount of Fxtl points to add to the recipient
     */
    function addFxtlPoints(address _recipient, uint256 _amount) external {
        _onlyFxtlContributor();
        fxtlPointsBalances[_recipient] += _amount;
        _totalPointSupply += _amount;
        emit Transfer(address(0), _recipient, _amount);
    }

    /**
     * @notice Removes Fxtl points from a point owner.
     * @dev Can only be called by a Fxtl contributor.
     * @dev Can only remove the amount of Fxtl points that the point owner has.
     * @param _pointOwner Owner of the Fxtl points being removed
     * @param _amount Amount of Fxtl points to remove from the point owner
     */
    function removeFxtlPoints(address _pointOwner, uint256 _amount) external {
        _onlyFxtlContributor();
        if (fxtlPointsBalances[_pointOwner] < _amount) {
            revert InsufficientFxtlPoints(fxtlPointsBalances[_pointOwner], _amount);
        }
        fxtlPointsBalances[_pointOwner] -= _amount;
        _totalPointSupply -= _amount;
        emit Transfer(_pointOwner, address(0), _amount);
    }

    /**
     * @notice Adds Fxtl points to multiple recipients.
     * @dev Can only be called by a Fxtl contributor.
     * @dev If the arrays are different lengths, the operation will be reverted.
     * @param _recipients An array of recipients of the Fxtl points
     * @param _amounts An array of amounts of Fxtl points to add to the recipients
     */
    function bulkAddFxtlPoints(address[] memory _recipients, uint256[] memory _amounts) external {
        _onlyFxtlContributor();
        if (_recipients.length != _amounts.length) revert ArrayLengthMismatch();
        for (uint256 i; i < _recipients.length; ) {
            fxtlPointsBalances[_recipients[i]] += _amounts[i];
            _totalPointSupply += _amounts[i];
            emit Transfer(address(0), _recipients[i], _amounts[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Removes Fxtl points from multiple point owners.
     * @dev Can only be called by a Fxtl contributor.
     * @dev If the arrays are different lengths, the operation will be reverted.
     * @dev Can only remove the amount of Fxtl points that the point owner has.
     * @param _pointOwners An array of owners of the Fxtl points being removed
     * @param _amounts An array of amounts of Fxtl points to remove from the point owners
     */
    function bulkRemoveFxtlPoints(address[] memory _pointOwners, uint256[] memory _amounts) external {
        _onlyFxtlContributor();
        if (_pointOwners.length != _amounts.length) revert ArrayLengthMismatch();
        for (uint256 i; i < _pointOwners.length; ) {
            if (fxtlPointsBalances[_pointOwners[i]] < _amounts[i]) {
                revert InsufficientFxtlPoints(fxtlPointsBalances[_pointOwners[i]], _amounts[i]);
            }
            fxtlPointsBalances[_pointOwners[i]] -= _amounts[i];
            _totalPointSupply -= _amounts[i];
            emit Transfer(_pointOwners[i], address(0), _amounts[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Checks if an address is a Fxtl contributor.
     * @dev The operation will be reverted if the caller is not a Fxtlx contributor.
     */
    function _onlyFxtlContributor() internal view {
        if (!isFxtlContributor[msg.sender]) revert NotFxtlContributor();
    }

    // *************************************** ERC20 compatibility & overrides ***************************************

    /**
     * @notice Retrieves the number of decimals for the Fxtl points.
     * @dev This function is an override of the ERC20 function, so that we can pass the 0 value.
     */
    function decimals() public pure override returns (uint8) {
        return 0;
    }

    /**
     * @notice Retrieves the total supply of Fxtl points.
     * @dev This overrides the ERC20 function because we don't have access to `_totalSupply` and we aren't using the
     *  internal transfer method.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalPointSupply;
    }

    /**
     * @notice Retrieves the Fxtl points balance of an account.
     * @dev This overrides the ERC20 function because we don't have access to `_totalSupply` and we aren't using the
     *  internal transfer method.
     * @param account The account to retrieve the FXTL points balance of
     * @return The FXLT points balance of the account
     */
    function balanceOf(address account) public view override returns (uint256) {
        return fxtlPointsBalances[account];
    }

    /**
     * @notice The override of the transfer method to prevent the FXTL token from being transferred.
     * @dev This function will always revert as we don't allow FXTL transfers.
     * @param recipient The recipient of the FXTL points
     * @param amount The amount of FXTL points to transfer
     * @return A boolean indicating if the transfer was successful
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        revert TransferNotAllowed();
    }

    /**
     * @notice The override of the transferFrom method to prevent the FXTL token from being transferred.
     * @dev This function will always revert as we don't allow FXTL transfers.
     * @param sender The sender of the FXTL points
     * @param recipient The recipient of the FXTL points
     * @param amount The amount of FXTL points to transfer
     * @return A boolean indicating if the transfer was successful
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        revert TransferNotAllowed();
    }

    /// @notice The address is already a Fxtl contributor
    error AlreadyFxtlContributor();
    /// @notice The array lengths are mismatched
    error ArrayLengthMismatch();
    /**
     * @notice The amount of Fxtl points is insufficient.
     * @param available The amount of Fxtl points available
     * @param attempted The amount of Fxtl points attempted to be removed
     */
    error InsufficientFxtlPoints(uint256 available, uint256 attempted);
    /// @notice Only Fxtl contributor is allowed to perform this call
    error NotFxtlContributor();
    /// @notice The FXTL token is not allowed to be transferred
    error TransferNotAllowed();
}
