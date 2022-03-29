// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

interface iNFTMARKETFACTORY {
    function createMarket(address, uint8) external returns (address);

    function getMarket(address) external view returns (address);

    function getNft(address) external view returns (address);

    function isMarket(address) external view returns (bool);

    function getMarkets() external view returns (address[] memory);
}
