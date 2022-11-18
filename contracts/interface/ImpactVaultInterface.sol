// SPDX-License-Identifier: Apache-2.0
// https://docs.soliditylang.org/en/v0.8.10/style-guide.html
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ImpactVaultInterface {
    // Returns the depositing asset.
    function asset() external returns (IERC20Upgradeable);

    // claims ready withdrawls
    function claim() external;

    // Returns the yield asset held by the vault.
    function yieldAsset() external returns (IERC20Upgradeable);

    // Deposit asset on behalf of "_receiver".
    function depositETH(address _receiver) external payable;

    // Withdraws asset to owned by "_owner" to "_receiver".
    function withdraw(
        uint256 _amount,
        address _receiver,
        address _owner
    ) external;

    function withdrawals(address _owner) external returns (uint256 value, uint256 timestamp);

    function hasOutstandingWithdrawal(address _owner) external returns (bool);

    function hasWithdrawalReady(address _owner) external returns (bool);

    // Withdraws yield asset owned by "_owner" to "_receiver". Note that
    // "_amount" is denominated in asset so this is converted to the
    // equivalent in yield asset first.
    function withdrawYieldAsset(
        uint256 _amount,
        address _receiver,
        address _owner
    ) external;

    // Returns the total yield earned on vault. Denominated in asset.
    function totalYield() external view returns (uint256);

    // Returns the total yield earned on vault. Denominated in US dollars.
    function totalYieldUSD() external view returns (uint256);

    // Returns the total yield earned by "_address" on vault. Denominated in asset.
    function getYield(address _address) external view returns (uint256);

    // Converts amount of yield asset to amount in asset.
    function convertToAsset(uint256 _amountYieldAsset) external view returns (uint256);

    // Converts amount of asset to amount in yield asset.
    function convertToYieldAsset(uint256 _amountAsset) external view returns (uint256);
}
