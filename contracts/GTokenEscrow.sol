// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/ImpactVaultInterface.sol";

/// @title CarbonizedCollection
/// @author Bridger Zoske
contract GTokenEscrow is Ownable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    ImpactVaultInterface public gTokenVault;

    uint256 public gTokenBalance;

    constructor(address _gTokenVaultAddress) {
        gTokenVault = ImpactVaultInterface(_gTokenVaultAddress);
    }

    function deposit() external payable {
        gTokenBalance += msg.value;
        gTokenVault.asset().safeTransferFrom(msg.sender, address(this), msg.value);
        gTokenVault.asset().approve(address(gTokenVault), msg.value);
        gTokenVault.deposit(msg.value, address(this));
    }

    function withdraw() external payable {
        require(
            !gTokenVault.hasWithdrawalReady(address(this)),
            "CarbonizedCollection: tokenId already decarbonized"
        );
        require(
            !gTokenVault.hasOutstandingWithdrawal(address(this)),
            "CarbonizedCollection: tokenId is decarbonizing"
        );
        gTokenVault.withdraw(gTokenBalance, msg.sender, msg.sender);
    }

    function withdrawls() external returns (uint256 value, uint256 timestamp) {
        return gTokenVault.withdrawals(address(this));
    }

    function claim() external payable {
        require(
            gTokenVault.hasWithdrawalReady(address(this)),
            "CarbonizedCollection: no withdrawal ready for tokenId"
        );
        gTokenVault.claim();
    }
}
