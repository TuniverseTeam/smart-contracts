// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./NFTMarket.sol";

contract NFTMarketFactory is Ownable {
    mapping(address => address) public mapNFT_Market;
    mapping(address => address) public mapMarket_NFT;
    mapping(address => bool) public isMarket;

    address public nftMarketManager;
    address[] private arrayMarkets; // Array of all deployed markets
    address[] private arrayNFTs; // Array of all managed NFTs

    event CreateMarket(address indexed nft, address indexed market);
    event OpenMarket(address indexed market);
    event CloseMarket(address indexed market);

    constructor(address _nftMarketManager) {
        nftMarketManager = _nftMarketManager;
    }

    function createMarket(
        address nft,
        uint8 nftType,
        uint256 totalNfts
    ) external onlyOwner returns (address market) {
        require(getMarket(nft) == address(0)); // Must not have a valid market address yet

        NFTMarket newMarket = new NFTMarket(
            nft,
            nftType,
            totalNfts,
            nftMarketManager
        ); // deploy new market
        market = address(newMarket); // Get address of new market

        mapNFT_Market[nft] = market; // Record new market address in MarketFactory
        mapMarket_NFT[market] = nft; // Record new market address in MarketFactory

        arrayMarkets.push(market); // Add market address to the markets array
        arrayNFTs.push(nft); // Add market address to the markets array

        isMarket[market] = true;

        emit CreateMarket(nft, market); // Emit CreateMarket event

        return market;
    }

    function setMarket(address market, address nft) external onlyOwner {
        mapNFT_Market[nft] = market; // Record new market address in MarketFactory
        mapMarket_NFT[market] = nft; // Record new market address in MarketFactory

        arrayMarkets.push(market); // Add market address to the markets array
        arrayNFTs.push(nft); // Add market address to the markets array

        isMarket[market] = true;
    }

    function openMarket(address market) external onlyOwner {
        require(isMarket[market] == false, "Market is opening");
        isMarket[market] = true;
        emit OpenMarket(market); // Emit OpenMarket event
    }

    function closeMarket(address market) external onlyOwner {
        require(isMarket[market] == true, "Market is closing");
        isMarket[market] = false;
        emit CloseMarket(market); // Emit CloseMarket event
    }

    function getMarket(address nft) public view returns (address market) {
        return mapNFT_Market[nft];
    }

    function getNft(address market) public view returns (address nft) {
        return mapMarket_NFT[market];
    }

    function getMarkets() external view returns (address[] memory markets) {
        return arrayMarkets;
    }

    function getNFTs() external view returns (address[] memory nfts) {
        return arrayNFTs;
    }
}
