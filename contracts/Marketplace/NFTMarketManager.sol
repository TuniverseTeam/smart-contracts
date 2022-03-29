// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/Marketplace/iNFTMARKETROUTER.sol";
import "../interfaces/Marketplace/iNFTMARKETFACTORY.sol";

contract NFTMarketManager is Ownable {
    iNFTMARKETROUTER public router;
    iNFTMARKETFACTORY public marketFactory;

    function setAddresses(address _router, address _marketFactory)
        external
        onlyOwner
    {
        router = iNFTMARKETROUTER(_router);
        marketFactory = iNFTMARKETFACTORY(_marketFactory);
    }

    function getRouter() external view returns (iNFTMARKETROUTER) {
        return router;
    }

    function getMarketFactory() external view returns (iNFTMARKETFACTORY) {
        return marketFactory;
    }
}
