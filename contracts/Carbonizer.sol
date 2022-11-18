// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/ImpactVaultInterface.sol";
import "./interface/ICarbonizer.sol";
import "hardhat/console.sol";

/// @title Carbonizer
/// @author Bridger Zoske
contract Carbonizer is Ownable, ICarbonizer {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    ImpactVaultInterface public gTokenVault;

    constructor(address _gTokenVaultAddress) {
        gTokenVault = ImpactVaultInterface(_gTokenVaultAddress);
    }

    function deposit() external payable override {
        gTokenVault.depositETH{value: msg.value}(address(this));
    }

    function withdraw() external override {
        gTokenVault.withdrawAll(address(this), address(this));
    }

    function withdrawls() external view returns (uint256 value, uint256 timestamp) {
        return gTokenVault.withdrawals(address(this));
    }

    function claim() external override {
        gTokenVault.claim();
    }

    function getYield() external view returns (uint256) {
        return gTokenVault.getYield(address(this));
    }

    // TODO: only callable by CarbonizedCollection Contract
}
