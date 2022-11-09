// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Carbonizer.sol";
import "./interface/ICarbonizerDeployer.sol";

/// @title CarboizerDeployer
/// @author Bridger Zoske
contract CarboizerDeployer is Ownable, ICarbonizerDeployer {
    address public carbonizedCollectionAddress;
    address public gTokenVault;

    constructor(address _carbonizedCollectionAddress, address _gtokenVault) {
        carbonizedCollectionAddress = _carbonizedCollectionAddress;
        gTokenVault = _gtokenVault;
    }

    function deploy() external override returns (address) {
        return address(new Carbonizer(gTokenVault));
    }
}
