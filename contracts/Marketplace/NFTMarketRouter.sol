// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/Marketplace/iNFTMARKETMANAGER.sol";
import "../interfaces/Marketplace/iNFTMARKETFACTORY.sol";
import "../interfaces/Marketplace/iNFTMARKET.sol";

contract NFTMarketRouter is ReentrancyGuard {
    using SafeMath for uint256;

    iNFTMARKETMANAGER public nftMarketManager;

    event List(address indexed market, uint256 indexed tokenId, uint256 value);
    event Delist(address indexed market, uint256 indexed tokenId);
    event TradeExecuted(
        address indexed market,
        address indexed seller,
        address indexed buyer,
        uint256 tokenId,
        uint256 value
    );
    event Offer(
        address indexed market,
        uint256 indexed tokenId,
        address offerer,
        uint256 price
    );
    event AbortOffer(
        address indexed market,
        uint256 indexed tokenId,
        address offerer
    );
    event AcceptOffer(
        address indexed market,
        uint256 indexed tokenId,
        address offerer,
        uint256 indexed price
    );

    constructor(address _nftMarketManager) {
        nftMarketManager = iNFTMARKETMANAGER(_nftMarketManager);
    }

    modifier onlyOwner() {
        require(msg.sender == nftMarketManager.owner());
        _;
    }

    function getTotalNfts(address _market) external view returns (uint256) {
        iNFTMARKETFACTORY _marketFactory = iNFTMARKETFACTORY(
            nftMarketManager.getMarketFactory()
        );
        require(
            _marketFactory.isMarket(_market) == true,
            "Market must be valid"
        );
        return iNFTMARKET(_market).getTotalNfts();
    }

    function getPriceByTokenId(address _market, uint256 tokenId)
        external
        view
        returns (uint256)
    {
        iNFTMARKETFACTORY _marketFactory = iNFTMARKETFACTORY(
            nftMarketManager.getMarketFactory()
        );
        require(
            _marketFactory.isMarket(_market) == true,
            "Market must be valid"
        );
        iNFTMARKET market = iNFTMARKET(_market);
        uint256 tradeId = market.listings(tokenId);
        (, uint256 price, , , , bool active) = market.getTradeById(tradeId);
        if (active) {
            return price;
        }
        return 0;
    }

    function getTradeVolume(address _market) external view returns (uint256) {
        iNFTMARKETFACTORY _marketFactory = iNFTMARKETFACTORY(
            nftMarketManager.getMarketFactory()
        );
        require(
            _marketFactory.isMarket(_market) == true,
            "Market must be valid"
        );
        return iNFTMARKET(_market).getTradeVolume();
    }

    function getTradeVolumeAllMarkets() external view returns (uint256) {
        iNFTMARKETFACTORY _marketFactory = iNFTMARKETFACTORY(
            nftMarketManager.getMarketFactory()
        );
        address[] memory markets = _marketFactory.getMarkets();
        uint256 volume;
        for (uint256 i = 0; i < markets.length; i++) {
            if (_marketFactory.isMarket(markets[i])) {
                volume = volume.add(iNFTMARKET(markets[i]).getTradeVolume());
            }
        }
        return volume;
    }

    function getVolumeByAccount(address _market, address account)
        external
        view
        returns (uint256)
    {
        iNFTMARKETFACTORY _marketFactory = iNFTMARKETFACTORY(
            nftMarketManager.getMarketFactory()
        );
        require(
            _marketFactory.isMarket(_market) == true,
            "Market must be valid"
        );
        return iNFTMARKET(_market).getVolumeByAccount(account);
    }

    function getVolumeByAccountAllMarkets(address account)
        external
        view
        returns (uint256)
    {
        iNFTMARKETFACTORY _marketFactory = iNFTMARKETFACTORY(
            nftMarketManager.getMarketFactory()
        );
        address[] memory markets = _marketFactory.getMarkets();
        uint256 volume;
        for (uint256 i = 0; i < markets.length; i++) {
            if (_marketFactory.isMarket(markets[i])) {
                volume = volume.add(
                    iNFTMARKET(markets[i]).getVolumeByAccount(account)
                );
            }
        }
        return volume;
    }

    function getHighestPrice(address _market) external view returns (uint256) {
        iNFTMARKETFACTORY _marketFactory = iNFTMARKETFACTORY(
            nftMarketManager.getMarketFactory()
        );
        require(
            _marketFactory.isMarket(_market) == true,
            "Market must be valid"
        );
        return iNFTMARKET(_market).getHighestPrice();
    }

    function getMarketStats(address _market)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        iNFTMARKETFACTORY _marketFactory = iNFTMARKETFACTORY(
            nftMarketManager.getMarketFactory()
        );
        require(
            _marketFactory.isMarket(_market) == true,
            "Market must be valid"
        );
        iNFTMARKET market = iNFTMARKET(_market);
        uint256 totalNfts = market.getTotalNfts();
        uint256 highestPrice = market.getHighestPrice();
        uint256 tradeVolume = market.getTradeVolume();
        return (totalNfts, highestPrice, tradeVolume);
    }

    function listNft(
        address _market,
        uint256 tokenId,
        uint256 price
    ) public nonReentrant returns (uint256) {
        require(price > 0, "invalid price");
        iNFTMARKETFACTORY _marketFactory = iNFTMARKETFACTORY(
            nftMarketManager.getMarketFactory()
        );
        require(
            _marketFactory.isMarket(_market) == true,
            "Market must be valid"
        );
        iNFTMARKET market = iNFTMARKET(_market);
        address nft = _marketFactory.getNft(_market);
        uint8 nftType = market.getNftType();
        require(nftType == 0 || nftType == 1, "invalid nft type");
        if (nftType == 0) {
            require(
                IERC721(nft).ownerOf(tokenId) == msg.sender,
                "Only owner can list"
            );
            require(
                IERC721(nft).getApproved(tokenId) == _market ||
                    IERC721(nft).isApprovedForAll(msg.sender, _market),
                "Owner must set approve for market"
            );
        } else if (nftType == 1) {
            require(
                IERC1155(nft).balanceOf(msg.sender, tokenId) >= 1,
                "Invalid token balance"
            );
            require(
                IERC1155(nft).isApprovedForAll(msg.sender, _market),
                "Owner must set approve for market"
            );
        }
        uint256 tradeId = market.listNft(msg.sender, tokenId, price);
        emit List(_market, tokenId, price);
        return tradeId;
    }

    function offer(
        address _market,
        uint256 tokenId,
        uint256 price
    ) external payable nonReentrant {
        require(price > 0 && msg.value == price, "invalid price");
        iNFTMARKETFACTORY _marketFactory = iNFTMARKETFACTORY(
            nftMarketManager.getMarketFactory()
        );
        require(
            _marketFactory.isMarket(_market) == true,
            "Market must be valid"
        );
        iNFTMARKET market = iNFTMARKET(_market);
        address nft = _marketFactory.getNft(_market);
        uint8 nftType = market.getNftType();
        require(nftType == 0 || nftType == 1, "invalid nft type");
        if (nftType == 0) {
            require(
                IERC721(nft).ownerOf(tokenId) == msg.sender,
                "Only owner can list"
            );
            require(
                IERC721(nft).getApproved(tokenId) == _market ||
                    IERC721(nft).isApprovedForAll(msg.sender, _market),
                "Owner must set approve for market"
            );
        } else if (nftType == 1) {
            require(
                IERC1155(nft).balanceOf(msg.sender, tokenId) >= 1,
                "Invalid token balance"
            );
            require(
                IERC1155(nft).isApprovedForAll(msg.sender, _market),
                "Owner must set approve for market"
            );
        }
        market.offer{value: msg.value}(msg.sender, tokenId, price);
        emit Offer(_market, tokenId, msg.sender, price);
    }

    function abortOffer(address _market, uint256 tokenId)
        external
        nonReentrant
    {
        iNFTMARKETFACTORY _marketFactory = iNFTMARKETFACTORY(
            nftMarketManager.getMarketFactory()
        );
        require(
            _marketFactory.isMarket(_market) == true,
            "Market must be valid"
        );
        iNFTMARKET market = iNFTMARKET(_market);

        iNFTMARKET(market).abortOffer(msg.sender, tokenId);
        emit AbortOffer(address(market), tokenId, msg.sender);
    }

    function acceptOffer(
        address _market,
        uint256 tokenId,
        address offerer
    ) external {
        iNFTMARKETFACTORY _marketFactory = iNFTMARKETFACTORY(
            nftMarketManager.getMarketFactory()
        );
        require(
            _marketFactory.isMarket(_market) == true,
            "Market must be valid"
        );
        iNFTMARKET market = iNFTMARKET(_market);
        market.acceptOffer(tokenId, offerer);
    }

    function buyNft(address _market, uint256 tokenId)
        public
        payable
        nonReentrant
    {
        iNFTMARKETFACTORY _marketFactory = iNFTMARKETFACTORY(
            nftMarketManager.getMarketFactory()
        );
        require(
            _marketFactory.isMarket(_market) == true,
            "Market must be valid"
        );
        iNFTMARKET market = iNFTMARKET(_market);
        uint256 tradeId = market.listings(tokenId);
        (, uint256 price, , address seller, , bool active) = market
            .getTradeById(tradeId);
        require(active, "NFT: not on sale");
        require(seller != msg.sender, "NFT: cannot buy your own NFT");
        require(price == msg.value, "NFT: incorrect value");
        iNFTMARKET(market).buyNft{value: msg.value}(msg.sender, tokenId);
        emit TradeExecuted(_market, seller, msg.sender, tokenId, msg.value);
    }

    function delistNft(address _market, uint256 tokenId) public nonReentrant {
        iNFTMARKETFACTORY _marketFactory = iNFTMARKETFACTORY(
            nftMarketManager.getMarketFactory()
        );
        require(
            _marketFactory.isMarket(_market) == true,
            "Market must be valid"
        );
        iNFTMARKET market = iNFTMARKET(_market);
        uint256 tradeId = market.listings(tokenId);
        (, , , address seller, , ) = market.getTradeById(tradeId);
        require(seller == msg.sender, "Only owner can delist");
        iNFTMARKET(market).delistNft(msg.sender, tokenId);
        emit Delist(_market, tokenId);
    }

    // Owner operator
    function ownerDelistNft(address market, uint256 tokenId)
        external
        onlyOwner
    {
        iNFTMARKETFACTORY _marketFactory = iNFTMARKETFACTORY(
            nftMarketManager.getMarketFactory()
        );
        require(
            _marketFactory.isMarket(market) == true,
            "Market must be valid"
        );
        iNFTMARKET(market).ownerDelistNft(msg.sender, tokenId);
        emit Delist(market, tokenId);
    }

    function setAccountVolumes(
        address _market,
        SharedStructs.AccountVolume[] memory _accountVolumes
    ) external onlyOwner {
        iNFTMARKETFACTORY _marketFactory = iNFTMARKETFACTORY(
            nftMarketManager.getMarketFactory()
        );
        require(
            _marketFactory.isMarket(_market) == true,
            "Market must be valid"
        );
        iNFTMARKET(_market).setAccountVolumes(_accountVolumes);
    }

    function setAccountVolume(
        address _market,
        SharedStructs.AccountVolume memory _accountVolume
    ) external onlyOwner {
        iNFTMARKETFACTORY _marketFactory = iNFTMARKETFACTORY(
            nftMarketManager.getMarketFactory()
        );
        require(
            _marketFactory.isMarket(_market) == true,
            "Market must be valid"
        );
        iNFTMARKET(_market).setAccountVolume(_accountVolume);
    }

    function setHighestPrice(address _market, uint256 price)
        external
        onlyOwner
    {
        iNFTMARKETFACTORY _marketFactory = iNFTMARKETFACTORY(
            nftMarketManager.getMarketFactory()
        );
        require(
            _marketFactory.isMarket(_market) == true,
            "Market must be valid"
        );
        iNFTMARKET(_market).setHighestPrice(price);
    }

    function setTotalNfts(address _market, uint256 _totalNfts)
        external
        onlyOwner
    {
        iNFTMARKETFACTORY _marketFactory = iNFTMARKETFACTORY(
            nftMarketManager.getMarketFactory()
        );
        require(
            _marketFactory.isMarket(_market) == true,
            "Market must be valid"
        );
        iNFTMARKET(_market).setTotalNfts(_totalNfts);
    }

    function setTradeVolume(address _market, uint256 volume)
        external
        onlyOwner
    {
        iNFTMARKETFACTORY _marketFactory = iNFTMARKETFACTORY(
            nftMarketManager.getMarketFactory()
        );
        require(
            _marketFactory.isMarket(_market) == true,
            "Market must be valid"
        );
        iNFTMARKET(_market).setTradeVolume(volume);
    }

    function updateServiceFee(address market, uint256 amount)
        external
        onlyOwner
    {
        iNFTMARKETFACTORY _marketFactory = iNFTMARKETFACTORY(
            nftMarketManager.getMarketFactory()
        );
        require(
            _marketFactory.isMarket(market) == true,
            "Market must be valid"
        );
        iNFTMARKET(market).updateServiceFee(amount);
    }

    function updateWalletFund(address market, address payable _wallet)
        external
        onlyOwner
    {
        iNFTMARKETFACTORY _marketFactory = iNFTMARKETFACTORY(
            nftMarketManager.getMarketFactory()
        );
        require(
            _marketFactory.isMarket(market) == true,
            "Market must be valid"
        );
        iNFTMARKET(market).updateWalletFund(_wallet);
    }

    function withdrawFund(address market, uint256 amount) external onlyOwner {
        iNFTMARKETFACTORY _marketFactory = iNFTMARKETFACTORY(
            nftMarketManager.getMarketFactory()
        );
        require(
            _marketFactory.isMarket(market) == true,
            "Market must be valid"
        );
        iNFTMARKET(market).withdrawFund(amount);
    }

    function withdrawFundAllMarkets() external onlyOwner {
        iNFTMARKETFACTORY _marketFactory = iNFTMARKETFACTORY(
            nftMarketManager.getMarketFactory()
        );
        address[] memory markets = _marketFactory.getMarkets();
        for (uint256 i = 0; i < markets.length; i++) {
            if (_marketFactory.isMarket(markets[i])) {
                iNFTMARKET(markets[i]).withdrawAllFund();
            }
        }
    }
}
