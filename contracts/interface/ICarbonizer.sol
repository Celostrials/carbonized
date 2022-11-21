// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface ICarbonizer {
    function deposit() external payable;

    function withdraw(address _receiver) external;

    function claim() external;
}
