pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./utils/AcceptedToken.sol";
import "./interfaces/ITuniverseCollab.sol";

contract TuniverMarket is
    ReentrancyGuard,
    Ownable,
    AcceptedToken,
    IERC721Receiver
{
    using SafeMath for uint256;

    modifier onlyTuniverOwner(uint256 tuniverId, address caller) {
        ownerOf[tuniverId] = caller;
        _;
    }

    event TuniverOfferCanceled(uint256 indexed tuniverId, address buyer);
    event TuniverListed(uint256 tuniverId, uint256 price, address seller);
    event TuniverDelisted(uint256 indexed tunvierId);
    event TuniverBought(
        uint256 indexed tunvierId,
        address buyer,
        address seller,
        uint256 price
    );
    event TuniverOffered(
        uint256 indexed tunvierId,
        address buyer,
        uint256 price
    );

    ITuniverCollab public tuniverContract;

    bool public paused;
    uint256 marketFeeInPercent;
    uint256 constant PERCENT = 100;
    mapping(uint256 => uint256) public tuniversOnSale;
    mapping(uint256 => mapping(address => uint256)) public tuniversOffers;
    mapping(uint256 => address) public ownerOf;

    constructor(ITuniverCollab _tuniverContract, IERC20 _acceptedToken)
        AcceptedToken(_acceptedToken)
    {
        tuniverContract = _tuniverContract;
    }

    function listing(uint256 tuniverId, uint256 price) external {
        require(!paused);
        require(price > 0);

        tuniverContract.safeTransferFrom(msg.sender, address(this), tuniverId);

        tuniversOnSale[tuniverId] = price;
        ownerOf[tuniverId] = msg.sender;

        emit TuniverListed(tuniverId, price, msg.sender);
    }

    function delist(uint256 tuniverId)
        external
        onlyTuniverOwner(tuniverId, msg.sender)
    {
        require(!paused, "TNM: paused");
        require(tuniversOnSale[tuniverId] > 0);

        tuniversOnSale[tuniverId] = 0;
        tuniverContract.transferFrom(address(this), msg.sender, tuniverId);

        emit TuniverDelisted(tuniverId);
    }

    function buy(
        uint256 tuniverId,
        uint256 expectedPrice,
        address buyer
    ) external payable nonReentrant {
        uint256 price = tuniversOnSale[tuniverId];
        address seller = ownerOf[tuniverId];

        require(!paused, "TNM: paused");
        require(buyer != seller);
        require(price == expectedPrice);
        require(price > 0, "TNM: not sale");

        _makeTransaction(tuniverId, buyer, seller, price);

        emit TuniverBought(tuniverId, buyer, seller, price);
    }

    function offer(uint256 tuniverId, uint256 offerPrice)
        external
        payable
        nonReentrant
    {
        require(!paused);
        address buyer = msg.sender;
        uint256 currentOffer = tuniversOffers[tuniverId][buyer];
        bool needRefund = offerPrice < currentOffer;
        uint256 requiredValue = needRefund ? 0 : offerPrice - currentOffer;

        require(buyer != ownerOf[tuniverId]);
        require(offerPrice != currentOffer);
        require(msg.value == requiredValue);

        tuniversOffers[tuniverId][buyer] = offerPrice;

        if (needRefund) {
            uint256 returnedValue = currentOffer - offerPrice;

            collectToken(address(this), buyer, returnedValue);
            // (bool success, ) = buyer.call{value: returnedValue}("");
            // require(success);
        }

        emit TuniverOffered(tuniverId, buyer, offerPrice);
    }

    function acceptOffer(
        uint256 tuniverId,
        address buyer,
        uint256 expectedPrice
    ) external nonReentrant onlyTuniverOwner(tuniverId, msg.sender) {
        require(!paused);
        uint256 offeredPrice = tuniversOffers[tuniverId][buyer];
        address seller = msg.sender;
        require(expectedPrice == offeredPrice);
        require(buyer != seller);

        tuniversOffers[tuniverId][buyer] = 0;

        _makeTransaction(tuniverId, buyer, seller, offeredPrice);

        emit TuniverBought(tuniverId, buyer, seller, offeredPrice);
    }

    function abortOffer(uint256 tuniverId) external nonReentrant {
        address caller = msg.sender;
        uint256 offerPrice = tuniversOffers[tuniverId][caller];

        require(offerPrice > 0);

        tuniversOffers[tuniverId][caller] = 0;

        (bool success, ) = caller.call{value: offerPrice}("");
        require(success);

        emit TuniverOfferCanceled(tuniverId, caller);
    }

    function _makeTransaction(
        uint256 tuniverId,
        address buyer,
        address seller,
        uint256 price
    ) private {
        uint256 marketFee = (price * marketFeeInPercent) / PERCENT;

        tuniversOnSale[tuniverId] = 0;

        collectToken(buyer, seller, price - marketFee);
        // (bool isTransferToSeller, ) = seller.call{value: price - marketFee}("");
        // require(isTransferToSeller);

        collectToken(buyer, owner(), marketFee);
        // (bool isTransferToTreasury, ) = owner().call{value: marketFee}("");
        // require(isTransferToTreasury);

        tuniverContract.transferFrom(address(this), buyer, tuniverId);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external override returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }
}
