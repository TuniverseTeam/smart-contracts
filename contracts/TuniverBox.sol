//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TuniverBox is ERC721Enumerable, ReentrancyGuard, Ownable {
    event BoxCreated(uint256 boxId, uint256 version);
    event BoxOpened(uint256[] boxIds);

    modifier onlyNotPaused() {
        require(!paused, "Paused");
        _;
    }
    modifier onlyNotBlackListed(uint256 tokenId) {
        require(!blacklist[tokenId], "tokenId blacklisted");
        _;
    }

    using SafeMath for uint256;
    struct Collaborator {
        uint256 maxSupply;
        uint256 minted;
        uint256[] mintedIds;
    }

    mapping(address => Collaborator) public _collaborators;
    mapping(uint256 => bool) public blacklist;

    uint256[] private _boxes; // contain version of sell box
    uint256 public pricePerBox; // will define when deploying
    bool public paused;
    uint256 public version = 1;
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

    function setPricePerBox(uint256 _pricePerBox) external onlyOwner {
        pricePerBox = _pricePerBox;
    }

    function setVersion(uint256 _version) external onlyOwner {
        version = _version;
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function setCollaborator(address _contract, uint256 _maxSupply)
        external
        onlyOwner
    {
        _collaborators[_contract] = Collaborator(
            _maxSupply,
            0,
            new uint256[](0)
        );
    }

    function _createTuniverBox() private returns (uint256 boxId) {
        _boxes.push(version);
        boxId = _boxes.length - 1;

        emit BoxCreated(boxId, version);
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

    function buy(uint256 amount, address buyer)
        external
        nonReentrant
        onlyNotPaused
    {
        Collaborator storage collaborator = _collaborators[msg.sender];
        require(
            collaborator.maxSupply != 0 &&
                collaborator.minted <= collaborator.maxSupply,
            "invalid collaborator"
        );
        collaborator.minted = collaborator.minted.add(amount);
        for (uint256 i = 0; i < amount; i++) {
            uint256 boxId = _createTuniverBox();
            collaborator.mintedIds.push(boxId);
            _safeMint(buyer, boxId);
        }
    }

    function open(uint256[] memory boxIds) external onlyNotPaused {
        for (uint256 i = 0; i < boxIds.length; i++) {
            require(ownerOf(boxIds[i]) == msg.sender, "invalid owner");
            require(!blacklist[boxIds[i]], "box blacklisted");
            _burn(boxIds[i]);
        }
        emit BoxOpened(boxIds);
    }
}
