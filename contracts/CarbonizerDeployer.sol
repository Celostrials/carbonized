// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Carbonizer.sol";
import "./interface/ICarbonizerDeployer.sol";

/// @title CarbonizerDeployer
/// @author Bridger Zoske
contract CarbonizerDeployer is Ownable, ICarbonizerDeployer {
    /* ========== STATE VARIABLES ========== */
    address public gTokenVault;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _gtokenVault) {
        gTokenVault = _gtokenVault;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function deploy(address _carbonizedCollection) external override returns (address) {
        return address(new Carbonizer(gTokenVault, _carbonizedCollection));
    }
}
