// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

interface iNFTMARKETROUTER {
    function listNft(
        address,
        uint256,
        uint256
    ) external returns (uint256);

    function buyNft(address, uint256) external payable;

    function delistNft(address, uint256) external;

    function getPriceByTokenId(uint256) external returns (uint256);

    function updateServiceFee(address, uint256) external;

    function updateWalletFund(address, address) external;

    function withdrawFund(address, uint256) external;
}
