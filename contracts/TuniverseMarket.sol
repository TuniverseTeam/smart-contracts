pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "./interfaces/ITuniverseCollab.sol";
import "./utils/AcceptedToken.sol";

contract TuniverseMarket is
    AcceptedToken,
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable,
    ERC1155HolderUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    struct BuyInfo {
        uint256 amount;
        uint256 price;
    }

    uint256 public PERCENT;
    bytes32 public SINGER_ROLE;
    bytes32 public CONTROLLER_ROLE;

    ITuniverse public tuniverseContract;

    uint256 public marketFeeInPercent;
    uint256 public serviceFeeInToken;
    mapping(address => mapping(uint256 => BuyInfo)) public songsOnSale;
    mapping(address => mapping(uint256 => mapping(address => BuyInfo)))
        public songsOffers;
    mapping(address => EnumerableSet.UintSet) private balancesOf;

    function initialize(
        ITuniverse tuniverse_,
        uint256 marketFeeInPercent_,
        uint256 serviceFeeInToken_
    ) public initializer {
        marketFeeInPercent = marketFeeInPercent_;
        serviceFeeInToken = serviceFeeInToken_;
        tuniverseContract = tuniverse_;
    }

    function listing(
        uint256 songId,
        uint256 price,
        uint256 amount
    ) external nonReentrant {
        require(price > 0, "Tuniverse: invalid price");

        tuniverseContract.safeTransferFrom(
            msg.sender,
            address(this),
            songId,
            amount,
            ""
        );

        songsOnSale[msg.sender][songId].price = price;
        songsOnSale[msg.sender][songId].amount = songsOnSale[msg.sender][songId]
            .amount
            .add(amount);
        balancesOf[msg.sender].add(songId);
    }

    function delist(uint256 songId) external nonReentrant {
        uint256 amount = songsOnSale[msg.sender][songId].amount;

        songsOnSale[msg.sender][songId].price = 0;
        songsOnSale[msg.sender][songId].amount = 0;

        tuniverseContract.transferFrom(
            address(this),
            msg.sender,
            songId,
            amount,
            ""
        );
        balancesOf[msg.sender].remove(songId);
    }

    function buy(
        uint256 songId,
        address seller,
        uint256 amount,
        uint256 expectedPrice
    ) external payable nonReentrant {
        uint256 price = songsOnSale[seller][songId].price * amount;
        address buyer = msg.sender;

        require(buyer != seller);
        require(price > 0, "Tunniverse: not on sale");
        require(price == expectedPrice);
        require(msg.value == price, "Tuniverse: not enough");

        _makeTransaction(songId, buyer, seller, price, amount);
    }

    function offer(
        uint256 songId,
        uint256 offerPrice,
        address seller,
        uint256 amount
    ) external payable nonReentrant {
        address buyer = msg.sender;
        uint256 currentOffer = songsOffers[seller][songId][buyer].price;
        bool needRefund = offerPrice < currentOffer;
        uint256 requiredValue = needRefund ? 0 : offerPrice - currentOffer;

        require(buyer != seller, "Tuniverse: cannot offer");
        require(offerPrice != currentOffer, "Tuniverse: same offer");
        require(msg.value == requiredValue, "Tuniverse: value invalid");

        songsOffers[seller][songId][buyer].price = offerPrice;
        songsOffers[seller][songId][buyer].amount = amount;

        if (needRefund) {
            uint256 returnedValue = currentOffer - offerPrice;

            (bool success, ) = buyer.call{value: returnedValue}("");
            require(success);
        }
    }

    function acceptOffer(
        uint256 songId,
        address buyer,
        uint256 expectedPrice
    ) external nonReentrant {
        address seller = msg.sender;
        uint256 offeredPrice = songsOffers[seller][songId][buyer].price;

        uint256 amount = songsOffers[seller][songId][buyer].amount;

        require(expectedPrice == offeredPrice);
        require(buyer != seller);

        songsOffers[seller][songId][buyer].price = 0;
        songsOffers[seller][songId][buyer].amount = 0;

        _makeTransaction(songId, buyer, seller, offeredPrice, amount);
    }

    function abortOffer(uint256 songId, address seller) external nonReentrant {
        address caller = msg.sender;
        uint256 offerPrice = songsOffers[seller][songId][caller].price;

        require(offerPrice > 0);

        songsOffers[seller][songId][caller].price = 0;
        songsOffers[seller][songId][caller].amount = 0;

        (bool success, ) = caller.call{value: offerPrice}("");
        require(success);
    }

    function _makeTransaction(
        uint256 songId,
        address buyer,
        address seller,
        uint256 price,
        uint256 amount
    ) private {
        uint256 marketFee = (price * marketFeeInPercent) / PERCENT;
        BuyInfo storage songInfo = songsOnSale[seller][songId];
        if (amount < songInfo.amount) {
            songsOnSale[seller][songId].amount = songsOnSale[seller][songId]
                .price
                .sub(amount);
        } else {
            songsOnSale[seller][songId].price = 0;
            songsOnSale[seller][songId].amount = 0;
        }

        (bool isTransferToSeller, ) = seller.call{value: price - marketFee}("");
        require(isTransferToSeller);

        (bool isTransferToTreasury, ) = owner().call{value: marketFee}("");
        require(isTransferToTreasury);

        tuniverseContract.transferFrom(
            address(this),
            buyer,
            songId,
            amount,
            ""
        );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155ReceiverUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
