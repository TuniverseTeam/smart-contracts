//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/ITuniver.sol";

contract TuniverRoyalTune is
    ITuniver,
    AccessControl,
    ERC721Enumerable,
    ReentrancyGuard
{
    using SafeMath for uint256;

    Tuniver[] private _tunivers; // contain collection ID and royaltyID
    Collection[] private _collections;

    bool public paused;
    uint256 private PERCENT;
    string private _uri;

    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant SERVER_ROLE = keccak256("SERVER_ROLE");

    mapping(uint256 => bool) public blacklist;

    constructor(string memory baseURI) ERC721("Tuniver RoyalTune", "TRT") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _createTuniver(0, 0); // ignore tuniver with id = 0
        _uri = baseURI;
    }

    function addTuniverToBlacklist(uint256 tuniverId)
        external
        onlyRole(CONTROLLER_ROLE)
    {
        require(tuniverId < _tunivers.length, "TNV: invalid");
        blacklist[tuniverId] = true;
    }

    function removeTuniverFromBlacklist(uint256 tuniverId)
        external
        onlyRole(CONTROLLER_ROLE)
    {
        require(tuniverId < _tunivers.length);
        blacklist[tuniverId] = false;
    }

    function addCollection(
        string memory artistName,
        address artist,
        uint256[] memory royalty,
        uint256[] memory royaltyMultiplier,
        uint256 maxSupply
    ) external onlyRole(CONTROLLER_ROLE) {
        require(artist != address(0) && maxSupply != 0);
        _collections.push(
            Collection(
                artistName,
                artist,
                royalty,
                royaltyMultiplier,
                maxSupply,
                0
            )
        );
        uint256 collectionId = _collections.length.sub(1);

        emit CollectionCreated(
            collectionId,
            artistName,
            artist,
            royalty,
            royaltyMultiplier,
            maxSupply
        );
    }

    function updateCollection(
        uint256 collectionId,
        string memory artistName,
        address artist,
        uint256[] memory royalty,
        uint256[] memory royaltyMultiplier,
        uint256 maxSupply
    ) external onlyRole(CONTROLLER_ROLE) {
        Collection storage collection = _collections[collectionId];
        collection.artistName = artistName;
        collection.artist = artist;
        collection.royalty = royalty;
        collection.royaltyMultiplier = royaltyMultiplier;
        collection.maxSupply = maxSupply;

        emit CollectionUpdated(
            collectionId,
            artistName,
            artist,
            royalty,
            royaltyMultiplier,
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

    function getTuniverInBlacklist(uint256 tuniverId)
        external
        view
        returns (bool)
    {
        return blacklist[tuniverId];
    }

    function getTuniverCollectionId(uint256 tuniverId)
        external
        view
        returns (Tuniver memory tuniver)
    {
        tuniver = _tunivers[tuniverId];
    }

    function getTuniver(uint256 tuniverId)
        external
        view
        override
        returns (uint256 royaltyShare, address artist)
    {
        Tuniver memory tuniver = _tunivers[tuniverId];
        Collection memory collection = _collections[tuniver.collectionId];

        royaltyShare = collection.royalty[tuniver.royaltyId];
        artist = collection.artist;
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

    function _createTuniver(uint256 collectionId, uint256 royaltyId)
        private
        returns (uint256 tuniverId)
    {
        _tunivers.push(Tuniver(collectionId, royaltyId));
        tuniverId = _tunivers.length - 1;

        emit TuniverCreated(collectionId, royaltyId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(!paused, "TNV: paused");
        require(!blacklist[tokenId], "TNV: tuniverId blacklisted");
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
        return _tunivers.length - 1;
    }

    function mintFor(Tuniver[] memory tunivers, address buyer)
        external
        nonReentrant
        onlyRole(SERVER_ROLE)
    {
        require(tunivers.length != 0, "TNV: invalid");
        for (uint256 i = 0; i < tunivers.length; i++) {
            Collection storage collection = _collections[
                tunivers[i].collectionId
            ];
            require(
                collection.artist != address(0),
                "TNV: collection not supported"
            );
            require(
                collection.maxSupply != 0 &&
                    collection.maxSupply >= collection.minted.add(1),
                "exceeded"
            ); // check mint exceeded limit nfts per collection

            uint256 tuniverId = _createTuniver(
                tunivers[i].collectionId,
                tunivers[i].royaltyId
            );
            _safeMint(buyer, tuniverId);
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
