// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface ICarbonizer {
    function deposit() external payable;

    function withdraw() external;

    function withdrawls() external view returns (uint256 value, uint256 timestamp);

    function getYield() external view returns (uint256);

    function getDeposit() external view returns (uint256);

    function claim(address _receiver) external;
}
