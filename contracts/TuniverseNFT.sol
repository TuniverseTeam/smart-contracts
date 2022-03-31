//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/ITuniverse.sol";

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
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    mapping(uint256 => bool) public blacklist;

    constructor(string memory baseURI, address adminContract)
        ERC721("Tuniver Official NFT", "TNVNFT")
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, adminContract);
        _uri = baseURI;
    }

    function addTuniverToBlacklist(uint256 tuniverId)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(tuniverId <= _tunivers.length, "TNV: invalid");
        blacklist[tuniverId] = true;
    }

    function removeTuniverFromBlacklist(uint256 tuniverId)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(tuniverId <= _tunivers.length);
        blacklist[tuniverId] = false;
    }

    function setPaused(bool _paused) external onlyRole(ADMIN_ROLE) {
        paused = _paused;
    }

    function setBaseURI(string memory baseURI) external onlyRole(ADMIN_ROLE) {
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
            uint256 typeId,
            bool isUnlock,
            uint256 royalty,
            uint256 rarity
        )
    {
        Tuniver memory tuniver = _tunivers[tuniverId.sub(1)];

        typeId = tuniver.typeId;
        royalty = tuniver.royalty;
        rarity = tuniver.rarity;
        isUnlock = tuniver.isUnlock;
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function _createTuniver(uint256 typeId)
        private
        returns (uint256 tuniverId)
    {
        _tunivers.push(Tuniver(typeId, false, 0, 0));
        tuniverId = _tunivers.length;

        emit TuniverCreated(tuniverId, typeId);
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
        return _tunivers.length;
    }

    function mintBox(address buyer, uint256[] memory typeIds)
        external
        nonReentrant
        onlyRole(ADMIN_ROLE)
    {
        require(typeIds.length != 0, "TNV: invalid");
        for (uint256 i = 0; i < typeIds.length; i++) {
            uint256 tuniverId = _createTuniver(typeIds[i]);
            _safeMint(buyer, tuniverId);
        }
    }

    function unbox(
        uint256 tuniverId,
        uint256 royalty,
        uint256 rarity
    ) external onlyRole(OPERATOR_ROLE) {
        Tuniver storage tuniver = _tunivers[tuniverId.sub(1)];

        require(!tuniver.isUnlock, "TNV: unboxed");

        tuniver.isUnlock = true;
        tuniver.royalty = royalty;
        tuniver.rarity = rarity;

        emit TuniverUpdated(tuniver.typeId, true, royalty, rarity);
    }

    function fusion(
        uint256[] memory tuniverIds,
        uint256 typeId,
        address caller
    ) external onlyRole(OPERATOR_ROLE) {
        require(tuniverIds.length == 2, "TNV: invalid tuniverId");
        for (uint256 i = 0; i < tuniverIds.length; i = i.add(1)) {
            require(tuniverIds[i] <= _tunivers.length, "TNV: invalid Id");
            _burn(tuniverIds[i]);
        }
        uint256 tuniverId = _createTuniver(typeId);
        _safeMint(caller, tuniverId);
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
