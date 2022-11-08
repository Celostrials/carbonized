// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./GTokenEscrow.sol";
import "./interface/IEscrowDeployer.sol";

/// @title CarbonizedCollection
/// @author Bridger Zoske
contract EscrowDeployer is Ownable, IEscrowDeployer {
    address public carbonizedCollectionAddress;
    address public gTokenVault;

    constructor(address _carbonizedCollectionAddress, address _gtokenVault) {
        carbonizedCollectionAddress = _carbonizedCollectionAddress;
        gTokenVault = _gtokenVault;
    }

    function deploy() external override returns (address) {
        return address(new GTokenEscrow(gTokenVault));
    }
}
