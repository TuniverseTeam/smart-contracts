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
    bytes32 public CONTROLLER_ROLE;
    bytes32 public OPERATOR_ROLE;

    mapping(uint256 => bool) public blacklist;

    function initialize(string memory baseURI) public initializer {
        __ERC721_init_unchained("TuniverNFT", "TNV");
        __AccessControl_init();
        __ReentrancyGuard_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
        OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
        _uri = baseURI;
    }

    function addTuniverToBlacklist(uint256 tuniverId)
        external
        onlyRole(CONTROLLER_ROLE)
    {
        require(tuniverId <= _tunivers.length, "WAW: invalid");
        blacklist[tuniverId] = true;
        emit AddTuniverToBlacklist(tuniverId);
    }

    function removeTuniverFromBlacklist(uint256 tuniverId)
        external
        onlyRole(CONTROLLER_ROLE)
    {
        require(tuniverId <= _tunivers.length);
        blacklist[tuniverId] = false;
        emit RemoveTuniverFromBlacklist(tuniverId);
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

    function getTuniver(uint256 tuniverId)
        external
        view
        returns (
            uint256 collectionType,
            uint256 nftType,
            uint256[] memory extraRewards,
            uint256 royaltyShare
        )
    {
        Tuniver memory tuniver = _tunivers[tuniverId.sub(1)];

        collectionType = tuniver.collectionType;
        nftType = tuniver.nftType;
        extraRewards = tuniver.extraRewards;
        royaltyShare = tuniver.royaltyShare;
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function _createTuniver(
        uint256 collectionType,
        uint256 nftType,
        uint256[] memory extraRewards,
        uint256 royaltyShare
    ) private returns (uint256 tuniverId) {
        _tunivers.push(
            Tuniver(collectionType, nftType, extraRewards, royaltyShare)
        );
        tuniverId = _tunivers.length;

        emit TuniverCreated(
            collectionType,
            nftType,
            extraRewards,
            royaltyShare
        );
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

    function mintFor(address buyer, Tuniver[] memory tunivers)
        external
        nonReentrant
        onlyRole(OPERATOR_ROLE)
    {
        require(tunivers.length != 0, "TNV: invalid");
        for (uint256 i = 0; i < tunivers.length; i++) {
            uint256 tuniverId = _createTuniver(
                tunivers[i].collectionType,
                tunivers[i].nftType,
                tunivers[i].extraRewards,
                tunivers[i].royaltyShare
            );
            _safeMint(buyer, tuniverId);
        }
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
