// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface ICarbonizer {
    function gTokenBalance() external view returns (uint256);

    function deposit() external payable;

    function withdraw() external;

    function claim() external;
}
