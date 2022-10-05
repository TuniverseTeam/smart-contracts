//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/ITuniverRoyalTune.sol";

contract TuniverRoyalTune is
    ITuniverRoyalTune,
    AccessControl,
    ERC721Enumerable,
    ReentrancyGuard
{
    using SafeMath for uint256;

    uint256[] private _royalTunes; // contain collection ID
    Collection[] private _collections;

    bool public paused;
    uint256 private PERCENT;
    string private _uri;

    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant SERVER_ROLE = keccak256("SERVER_ROLE");

    mapping(uint256 => bool) public blacklist;
    mapping(uint256 => bool) public mintFrom;

    constructor(string memory baseURI) ERC721("Tuniver RoyalTune", "TRT") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _collections.push(
            Collection(0, 0)
        ); // ignore tuniver with id = 0
        _royalTunes.push(0); // ignore royaltune id = 0;
        _uri = baseURI;
    }

    function addRoyalTuneToBlacklist(uint256 royalTuneId)
        external
        onlyRole(CONTROLLER_ROLE)
    {
        require(royalTuneId < _royalTunes.length, "TNV: invalid");
        blacklist[royalTuneId] = true;
    }

    function removeRoyalTuneFromBlacklist(uint256 royalTuneId)
        external
        onlyRole(CONTROLLER_ROLE)
    {
        require(royalTuneId < _royalTunes.length);
        blacklist[royalTuneId] = false;
    }

    function addCollection(
        uint256 maxSupply
    ) external onlyRole(CONTROLLER_ROLE) {
        _collections.push(
            Collection(maxSupply, 0)
        );
        uint256 collectionId = _collections.length.sub(1);

        emit CollectionCreated(
            collectionId,
            maxSupply
        );
    }

    function updateCollection(
        uint256 collectionId,
        uint256 maxSupply
    ) external onlyRole(CONTROLLER_ROLE) {
        Collection storage collection = _collections[collectionId];
        collection.maxSupply = maxSupply;

        emit CollectionUpdated(
            collectionId,
            maxSupply
        );
    }

    function setPaused(bool _paused) external onlyRole(CONTROLLER_ROLE) {
        paused = _paused;
    }

    function setBaseURI(string memory baseURI)
        external
        onlyRole(CONTROLLER_ROLE)
    {
        _uri = baseURI;
    }

    function getRoyalTuneInBlacklist(uint256 royalTuneId)
        external
        view
        returns (bool)
    {
        return blacklist[royalTuneId];
    }

    function getRoyalTuneCollectionId(uint256 royalTuneId)
        external
        view
        override
        returns (uint256 collectionId)
    {
        collectionId = _royalTunes[royalTuneId];
    }

    function getCollection(uint256 collectionId)
        external
        view
        override
        returns (Collection memory collection)
    {
        collection = _collections[collectionId];
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function _createRoyalTune(uint256 collectionId, uint256 boxId)
        private
        returns (uint256 royalTuneId)
    {
        require(mintFrom[boxId] != true, "Tunibox already minted");
        _royalTunes.push(collectionId);
        royalTuneId = _royalTunes.length - 1;

        emit RoyalTuneCreated(collectionId, boxId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(!paused, "TNV: paused");
        require(!blacklist[tokenId], "TNV: royalTuneId blacklisted");
    }

    function safeBatchTransfer(
        address from,
        address to,
        uint256[] memory tokenIds
    ) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            safeTransferFrom(from, to, tokenIds[i]);
        }
    }

    function totalSupply() public view override returns (uint256) {
        return _royalTunes.length - 1;
    }

    function mintFor(uint256[] memory royalTunes, uint256[] memory boxIds, address buyer)
        external
        nonReentrant
        onlyRole(SERVER_ROLE)
    {
        require(royalTunes.length != 0, "TNV: invalid");
        for (uint256 i = 0; i < royalTunes.length; i++) {
            Collection storage collection = _collections[royalTunes[i]];
            require(
                collection.maxSupply != 0,
                "TNV: collection not supported"
            );
            require(
                collection.maxSupply != 0 &&
                    collection.maxSupply >= collection.minted.add(1),
                "exceeded"
            ); // check mint exceeded limit nfts per collection

            uint256 royalTuneId = _createRoyalTune(royalTunes[i], boxIds[i]);
            _safeMint(buyer, royalTuneId);
            collection.minted = collection.minted.add(1); // increase minted nft on collection
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
