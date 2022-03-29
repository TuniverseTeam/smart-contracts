// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/Marketplace/iNFTMARKETMANAGER.sol";

contract NFTMarket is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    address public nft;
    uint8 public nftType;
    uint256 public totalNfts;
    iNFTMARKETMANAGER public nftMarketManager;

    IERC20 tokenUnity;
    address payable public walletFund;

    struct Trade {
        uint256 tradeId;
        uint256 tokenId;
        uint256 price;
        uint256 successDate;
        address seller;
        address buyer;
        bool active;
    }
    Trade[] public trades;

    mapping(uint256 => uint256) public listings; // id to trade id
    mapping(uint256 => mapping(address => uint256)) // tradeId -> address offerer -> price
        public nftsOffers;
    mapping(uint256 => address) private _tradeIdToTradeCloser;

    uint256 public tradeVolume;
    uint256 public highestPrice;
    uint256 public highestPriceTokenId;
    mapping(address => uint256) public accountVolumes; // mapping account and trading volume

    uint256 public TRADE_FEE = 3;
    uint256 public TRADE_FUNDED_FEE;

    constructor(
        address _nft,
        uint8 _nftType,
        uint256 _totalNfts,
        address _nftMarketManager
    ) {
        nft = _nft;
        nftType = _nftType; // 0: ERC721, 1: ERC1155
        totalNfts = _totalNfts;
        nftMarketManager = iNFTMARKETMANAGER(_nftMarketManager);

        // index 0 is a placeholder trade
        trades.push(
            Trade(
                0,
                0,
                0,
                0,
                0x0000000000000000000000000000000000000000,
                0x0000000000000000000000000000000000000000,
                false
            )
        );
    }

    modifier onlyROUTER() {
        require(msg.sender == nftMarketManager.getRouter());
        _;
    }

    function getTotalNfts() external view returns (uint256) {
        return totalNfts;
    }

    function getNftType() external view returns (uint8) {
        return nftType;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getBalanceToken() public view returns (uint256) {
        return tokenUnity.balanceOf(address(this));
    }

    function getTradeCount() public view returns (uint256) {
        return trades.length;
    }

    function getTradeById(uint256 id)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            address,
            address,
            bool
        )
    {
        Trade memory trade = trades[id];
        return (
            trade.tokenId,
            trade.price,
            trade.successDate,
            trade.seller,
            trade.buyer,
            trade.active
        );
    }

    function getTradeVolume() external view returns (uint256) {
        return tradeVolume;
    }

    function getVolumeByAccount(address account)
        external
        view
        returns (uint256)
    {
        return accountVolumes[account];
    }

    function getHighestPrice() external view returns (uint256) {
        return highestPrice;
    }

    function getHighestPriceTokenId() external view returns (uint256) {
        return highestPriceTokenId;
    }

    //Credit to Ether Phrocks for marketplace functions https://etherscan.io/address/0x23fc142a6ba57a37855d9d52702fda2ec4b4fd53
    function listNft(
        address seller,
        uint256 tokenId,
        uint256 price
    ) external onlyROUTER returns (uint256) {
        uint256 currentTradeId = listings[tokenId];
        if (currentTradeId > 0) {
            Trade storage trade = trades[currentTradeId];
            if (trade.active && trade.seller == seller) {
                trade.price = price;
                return currentTradeId;
            }
        }
        uint256 tradeId = trades.length;
        trades.push(
            Trade(
                tradeId,
                tokenId,
                price,
                0,
                seller,
                0x0000000000000000000000000000000000000000,
                true
            )
        );
        listings[tokenId] = tradeId;
        return tradeId;
    }

    function offer(
        address offerer,
        uint256 tokenId,
        uint256 price
    ) external payable onlyROUTER {
        uint256 tradeId = listings[tokenId];
        Trade memory trade = trades[tradeId];
        require(offerer != trade.seller, "invalid offerer");
        require(trade.active, "Not listed");
        nftsOffers[tradeId][offerer] = price;
    }

    function abortOffer(address offerer, uint256 tokenId)
        external
        payable
        onlyROUTER
    {
        uint256 tradeId = listings[tokenId];
        uint256 price = nftsOffers[tradeId][offerer];
        uint256 tradeMarketFee = price.mul(TRADE_FEE).div(10**2);
        TRADE_FUNDED_FEE = TRADE_FUNDED_FEE.add(tradeMarketFee);

        require(price > 0);
        nftsOffers[tradeId][offerer] = 0;

        (bool isRefund, ) = offerer.call{value: price}("");
        require(isRefund);
    }

    function acceptOffer(uint256 tokenId, address offerer) external onlyROUTER {
        uint256 tradeId = listings[tokenId];
        Trade storage trade = trades[tradeId];
        uint256 price = nftsOffers[tradeId][offerer];
        address seller = trade.seller;
        uint256 tradeMarketFee = price.mul(TRADE_FEE).div(10**2);
        TRADE_FUNDED_FEE = TRADE_FUNDED_FEE.add(tradeMarketFee);

        require(tradeId > 0, "Not listed");
        require(price > 0);
        if (nftType == 0) {
            IERC721(nft).safeTransferFrom(seller, offerer, tokenId);
        } else if (nftType == 1) {
            IERC1155(nft).safeTransferFrom(
                seller,
                offerer,
                tokenId,
                1,
                "0000000000000000000000000000000000000000000000000000000000000000"
            );
        }

        trade.active = false;
        trade.buyer = offerer;
        trade.price = price;
        trade.successDate = block.timestamp;
        _tradeIdToTradeCloser[tradeId] = offerer;

        uint256 tradeGetBalance = price.sub(tradeMarketFee);
        (bool success, ) = seller.call{value: tradeGetBalance}("");

        tradeVolume = tradeVolume.add(price);
        accountVolumes[offerer] = accountVolumes[offerer].add(price);

        if (highestPrice < price) {
            highestPrice = price;
            if (highestPriceTokenId != tokenId) {
                highestPriceTokenId = tokenId;
            }
        }

        require(success);
    }

    function delistNft(address seller, uint256 tokenId) external onlyROUTER {
        uint256 tradeId = listings[tokenId];
        Trade storage trade = trades[tradeId];
        trade.active = false;
        _tradeIdToTradeCloser[tradeId] = seller;
        listings[tokenId] = 0;
    }

    function buyNft(address buyer, uint256 tokenId)
        external
        payable
        nonReentrant
        onlyROUTER
    {
        uint256 tradeId = listings[tokenId];
        Trade storage trade = trades[tradeId];

        address seller = trade.seller;
        uint256 price = trade.price;

        uint256 tradeMarketFee = price.mul(TRADE_FEE).div(10**2);
        TRADE_FUNDED_FEE = TRADE_FUNDED_FEE.add(tradeMarketFee);

        if (nftType == 0) {
            IERC721(nft).safeTransferFrom(seller, buyer, tokenId);
        } else if (nftType == 1) {
            IERC1155(nft).safeTransferFrom(
                seller,
                buyer,
                tokenId,
                1,
                "0000000000000000000000000000000000000000000000000000000000000000"
            );
        }

        trade.active = false;
        trade.buyer = buyer;
        trade.successDate = block.timestamp;
        _tradeIdToTradeCloser[tradeId] = buyer;

        uint256 tradeGetBalance = price.sub(tradeMarketFee);
        (bool success, ) = seller.call{value: tradeGetBalance}("");

        tradeVolume = tradeVolume.add(price);
        accountVolumes[buyer] = accountVolumes[buyer].add(price);

        if (highestPrice < price) {
            highestPrice = price;
            if (highestPriceTokenId != tokenId) {
                highestPriceTokenId = tokenId;
            }
        }

        require(success);
    }

    // Owner operator
    function newTrade(
        uint256 tokenId,
        uint256 price,
        uint256 successDate,
        address seller,
        address buyer,
        bool active
    ) external onlyROUTER returns (uint256) {
        uint256 tradeId = listings[tokenId];
        if (tradeId > 0) {
            trades[tradeId].active = false;
        }
        tradeId = trades.length;
        trades.push(
            Trade(tradeId, tokenId, price, successDate, seller, buyer, active)
        );
        listings[tokenId] = tradeId;
        return tradeId;
    }

    function updateTrade(
        uint256 tokenId,
        uint256 price,
        uint256 successDate,
        address seller,
        address buyer,
        bool active
    ) external onlyROUTER {
        uint256 tradeId = listings[tokenId];
        if (tradeId == 0) {
            return;
        }
        trades[tradeId] = Trade(
            tradeId,
            tokenId,
            price,
            successDate,
            seller,
            buyer,
            active
        );
    }

    function ownerDelistNft(address owner, uint256 tokenId)
        external
        onlyROUTER
    {
        uint256 tradeId = listings[tokenId];
        Trade storage trade = trades[tradeId];
        trade.active = false;
        _tradeIdToTradeCloser[tradeId] = owner;
    }

    function updateServiceFee(uint256 amount) external onlyROUTER {
        TRADE_FEE = amount;
    }

    function updateWalletFund(address payable _wallet) external onlyROUTER {
        walletFund = _wallet;
    }

    function setAccountVolumes(
        SharedStructs.AccountVolume[] memory _accountVolumes
    ) external onlyROUTER {
        for (uint256 i = 0; i < _accountVolumes.length; i++) {
            uint256 volume = _accountVolumes[i].volume;
            accountVolumes[_accountVolumes[i].account] = volume;
            tradeVolume = tradeVolume.add(volume);
        }
    }

    function setAccountVolume(SharedStructs.AccountVolume memory _accountVolume)
        external
        onlyROUTER
    {
        accountVolumes[_accountVolume.account] = _accountVolume.volume;
    }

    function setTradeVolume(uint256 volume) external onlyROUTER {
        tradeVolume = volume;
    }

    function setHighestPrice(uint256 price) external onlyROUTER {
        highestPrice = price;
    }

    function setHighestPriceTokenId(uint256 tokenId) external onlyROUTER {
        highestPriceTokenId = tokenId;
    }

    function setTotalNfts(uint256 _totalNfts) external onlyROUTER {
        totalNfts = _totalNfts;
    }

    function withdrawFund(uint256 amount) external onlyROUTER {
        require(amount <= getBalance());
        walletFund.transfer(amount);
    }

    function withdrawAllFund() external onlyROUTER {
        walletFund.transfer(getBalance());
    }

    function withdrawToken(uint256 _amount, address _toAddr)
        external
        onlyROUTER
    {
        require(
            tokenUnity.balanceOf(msg.sender) >= _amount,
            "Market: insufficient token balance"
        );
        tokenUnity.transferFrom(msg.sender, _toAddr, _amount);
    }
}
