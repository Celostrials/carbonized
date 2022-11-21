// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface ICarbonizerDeployer {
    function deploy(address _carbonizedCollection) external returns (address);
}
