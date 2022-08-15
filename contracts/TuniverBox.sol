//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TuniverBox is ERC721Enumerable, ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    event ArtistCreated(uint256 artistId, string artistName);
    event ArtistRemoved(uint256 artistId);
    event BoxCreated(uint256 boxId, uint256 artistId, address owner);
    event BoxOpened(uint256 boxId, uint256 artistId);

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

    mapping(address => mapping(uint256 => Collaborator)) public _collaborators; // adress collab => artistId
    mapping(uint256 => bool) public blacklist;

    string[] private _artists; // contain name of artist
    uint256[] private _boxes; // contain artistId
    uint256 public pricePerBox; // will define when deploying
    bool public paused;
    string private _uri;

    constructor(string memory baseURI) ERC721("TuniverBox", "TNB") {
        _uri = baseURI;
    }

    function togglePaused() external onlyOwner {
        paused = !paused;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _uri = baseURI;
    }

    function addArtist(string memory name) external onlyOwner {
        _artists.push(name);
        uint256 artistId = _artists.length - 1;
        emit ArtistCreated(artistId, name);
    }
    
    function removeArtistSupported(uint256 artistId) external onlyOwner {
        
        delete _artists[artistId];
        emit ArtistRemoved(artistId);
    }

    function setPricePerBox(uint256 _pricePerBox) external onlyOwner {
        pricePerBox = _pricePerBox;
    }

    function getPricePerBox() public view returns(uint256) {
        return pricePerBox;
    }

    function getArtistName(uint256 artistId) external view returns(string memory) {
        return _artists[artistId];
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function setCollaborator(address _contract, uint256 _maxSupply, uint256 artistId)
        external
        onlyOwner
    {
        _collaborators[_contract][artistId] = Collaborator(
            _maxSupply,
            0,
            new uint256[](0)
        );
    }

    function _createTuniverBox(address owner, uint256 artistId) private returns (uint256 boxId) {
        _boxes.push(artistId);
        boxId = _boxes.length - 1;

        emit BoxCreated(boxId, artistId, owner);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(!paused, "paused");
        require(!blacklist[tokenId], "blacklisted");
    }

    function totalSupply() public view override returns (uint256) {
        return _boxes.length - 1;
    }

    function buy(uint256 amount, address buyer, uint256 artistId)
        external
        nonReentrant
        onlyNotPaused
    {
        require(bytes(_artists[artistId]).length != 0, "artist not supported");
        Collaborator storage collaborator = _collaborators[msg.sender][artistId];
        uint256 totalMinted = collaborator.minted.add((amount));
        require(
            collaborator.maxSupply != 0 &&
                totalMinted <= collaborator.maxSupply,
            "invalid collaborator"
        );
        collaborator.minted = totalMinted;
        for (uint256 i = 0; i < amount; i++) {
            uint256 boxId = _createTuniverBox(buyer, artistId);
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
}
