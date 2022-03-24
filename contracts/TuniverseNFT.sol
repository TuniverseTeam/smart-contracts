//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/ITuniverse.sol";

contract TuniverNFT is
    ITuniver,
    AccessControlUpgradeable,
    ERC721EnumerableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;

    Tuniver[] private _tunivers;
    bool public paused;
    uint256 private PERCENT;
    string private _uri;
    bytes32 public ADMIN_ROLE;
    bytes32 public OPERATOR_ROLE;

    mapping(uint256 => bool) public blacklist;

    function initialize(string memory baseURI) public initializer {
        __ERC721_init_unchained("Tuniver Official NFT", "TNVNFT");
        __AccessControl_init();
        __ReentrancyGuard_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        ADMIN_ROLE = keccak256("ADMIN_ROLE");
        OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
        _uri = baseURI;
    }

    function addTuniverToBlacklist(uint256 tuniverId)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(tuniverId <= _tunivers.length, "TNV: invalid");
        blacklist[tuniverId] = true;
        emit AddTuniverToBlacklist(tuniverId);
    }

    function removeTuniverFromBlacklist(uint256 tuniverId)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(tuniverId <= _tunivers.length);
        blacklist[tuniverId] = false;
        emit RemoveTuniverFromBlacklist(tuniverId);
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
        override(ERC721EnumerableUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
