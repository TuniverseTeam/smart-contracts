// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./iNFTMARKETROUTER.sol";
import "./iNFTMARKETFACTORY.sol";

interface iNFTMARKETMANAGER {
    function getRouter() external view returns (address);

    function getMarketFactory() external view returns (address);

    function owner() external view returns (address);
}

library SharedStructs {
    struct AccountVolume {
        address account;
        uint256 volume;
    }

    struct TokenHighestPrice {
        uint256 tokenId;
        uint256 price;
    }
}
