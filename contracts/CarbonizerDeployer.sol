// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Carbonizer.sol";
import "./interface/ICarbonizerDeployer.sol";

/// @title CarbonizerDeployer
/// @author Bridger Zoske
contract CarbonizerDeployer is Ownable, ICarbonizerDeployer {
    address public gTokenVault;

    constructor(address _gtokenVault) {
        gTokenVault = _gtokenVault;
    }

    function deploy() external override returns (address) {
        return address(new Carbonizer(gTokenVault));
    }
}
