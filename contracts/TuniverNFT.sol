//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/ITuniver.sol";

contract TuniverNFT is
    ITuniver,
    AccessControl,
    ERC721Enumerable,
    ReentrancyGuard
{
    using SafeMath for uint256;

    Tuniver[] private _tunivers;
    bool public paused;
    uint256 private PERCENT;
    string private _uri;

    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant SERVER_ROLE = keccak256("SERVER_ROLE");

    mapping(uint256 => bool) public blacklist;
    mapping(address => mapping(uint256 => uint256)) public royaltyOf;

    constructor(string memory baseURI, address adminContract)
        ERC721("Tuniver Official NFT", "TNVNFT")
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CONTROLLER_ROLE, adminContract);
        _createTuniver(address(0), 0, 0); // ignore tuniver with id = 0
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

    function setPaused(bool _paused) external onlyRole(CONTROLLER_ROLE) {
        paused = _paused;
    }

    function setRoyaltyOf(
        address artist,
        uint256[] memory rarity,
        uint256[] memory royalty
    ) external onlyRole(CONTROLLER_ROLE) {
        require(rarity.length == royalty.length, "TNV: invalid");
        for (uint256 i = 0; i < rarity.length; i++) {
            royaltyOf[artist][rarity[i]] = royalty[i];
        }
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

    function getTuniver(uint256 tuniverId)
        external
        view
        returns (
            uint256 royalty,
            uint256 rarity,
            address artist
        )
    {
        Tuniver memory tuniver = _tunivers[tuniverId];

        royalty = tuniver.royalty;
        rarity = tuniver.rarity;
        artist = tuniver.artist;
    }

    function getRarityOf(uint256 tuniverId)
        external
        view
        returns (uint256 rarity)
    {
        Tuniver memory tuniver = _tunivers[tuniverId];

        rarity = tuniver.rarity;
    }

    function getRoyaltyOf(address artist, uint256 rarity)
        external
        view
        returns (uint256 royalty)
    {
        royalty = royaltyOf[artist][rarity];
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function _createTuniver(
        address artist,
        uint256 royalty,
        uint256 rarity
    ) private returns (uint256 tuniverId) {
        _tunivers.push(Tuniver(royalty, rarity, artist));
        tuniverId = _tunivers.length - 1;

        emit TuniverCreated(tuniverId, artist);
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

    function mintFor(TuniverInput[] memory tunivers, address buyer)
        external
        nonReentrant
        onlyRole(SERVER_ROLE)
    {
        require(tunivers.length != 0, "TNV: invalid");
        for (uint256 i = 0; i < tunivers.length; i++) {
            uint256 royalty = royaltyOf[tunivers[i].artist][tunivers[i].rarity];
            require(royalty != 0, "TNV: rarity not supported");

            uint256 tuniverId = _createTuniver(
                tunivers[i].artist,
                royalty,
                tunivers[i].rarity
            );
            _safeMint(buyer, tuniverId);
        }
    }

    function upgrade(uint256 tuniverId) external onlyRole(OPERATOR_ROLE) {
        Tuniver storage tuniver = _tunivers[tuniverId];
        uint256 rarityUpdate = tuniver.rarity.add(1);
        uint256 royaltyUpdate = royaltyOf[tuniver.artist][rarityUpdate];

        require(royaltyUpdate != 0, "rarity not support");

        tuniver.rarity = rarityUpdate;
        tuniver.royalty = royaltyUpdate;
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
