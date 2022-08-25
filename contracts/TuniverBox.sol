//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract TuniverBox is ERC721EnumerableUpgradeable, ERC721BurnableUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    event CollectionUpdated(uint256 collectionId, bool isSupported);
    event BoxCreated(uint256 boxId, uint256 collectionId, address owner);
    event BoxOpened(uint256 boxId, uint256 collectionId);

    modifier onlyNotPaused() {
        require(!paused, "Paused");
        _;
    }
    modifier onlyNotBlackListed(uint256 tokenId) {
        require(!blacklist[tokenId], "tokenId blacklisted");
        _;
    }

    struct Collaborator {
        uint256 maxSupply;
        uint256 minted;
        uint256[] mintedIds;
    }

    mapping(address => mapping(uint256 => Collaborator)) public _collaborators; // adress collab => collectionId
    mapping(uint256 => bool) public blacklist;

    bool[] private collections; // is Supported or not
    uint256[] private _boxes; // contain collectionId
    uint256 public pricePerBox; // will define when deploying
    bool public paused;
    string private _uri;

    function initialize(string memory baseURI) public initializer {
        __ERC721_init("TuniverBox", "TNB");
        __Ownable_init();
        _uri = baseURI;
        collections.push(false); //ignore id 0
    }

    function togglePaused() external onlyOwner {
        paused = !paused;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _uri = baseURI;
    }

    function addCollection() external onlyOwner {
        collections.push(true);
        uint256 collectionId = collections.length - 1;
        emit CollectionUpdated(collectionId, true);
    }
    
    function removeCollection(uint256 collectionId) external onlyOwner {
        collections[collectionId] = false;
        emit CollectionUpdated(collectionId, false);
    }

    function setPricePerBox(uint256 _pricePerBox) external onlyOwner {
        pricePerBox = _pricePerBox;
    }

    function getPricePerBox() public view returns(uint256) {
        return pricePerBox;
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function setCollaborator(address _contract, uint256 _maxSupply, uint256 collectionId)
        external
        onlyOwner
    {
        require(collections[collectionId], "collection not supported");
        _collaborators[_contract][collectionId] = Collaborator(
            _maxSupply,
            0,
            new uint256[](0)
        );
    }

    function _createTuniverBox(address owner, uint256 collectionId) private returns (uint256 boxId) {
        _boxes.push(collectionId);
        boxId = _boxes.length - 1;

        emit BoxCreated(boxId, collectionId, owner);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        require(!paused, "paused");
        require(!blacklist[tokenId], "blacklisted");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function totalSupply() public view override returns (uint256) {
        return _boxes.length - 1;
    }

    function buy(uint256 amount, address buyer, uint256 collectionId)
        external
        nonReentrant
        onlyNotPaused
    {
        require(collections[collectionId], "collection not supported");
        Collaborator storage collaborator = _collaborators[msg.sender][collectionId];
        uint256 totalMinted = collaborator.minted.add((amount));
        require(
            collaborator.maxSupply != 0 &&
                totalMinted <= collaborator.maxSupply,
            "invalid collaborator"
        );

        collaborator.minted = totalMinted;

        for (uint256 i = 0; i < amount; i++) {
            uint256 boxId = _createTuniverBox(buyer, collectionId);
            collaborator.mintedIds.push(boxId);
            _safeMint(buyer, boxId);
        }
    }

    function open(uint256[] memory boxIds) external onlyNotPaused {
        for (uint256 i = 0; i < boxIds.length; i++) {
            uint256 id = boxIds[i];
            require(!blacklist[id], "Box blacklisted");
            require(ownerOf(id) == msg.sender, "invalid owner");
            _burn(id);
            emit BoxOpened(id, _boxes[id]);
        }
       
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }
}
