//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/ITuniverTunipass.sol";
import "./interfaces/ITuniver.sol";

contract Tunipass is
    ITunipass,
    AccessControl,
    ERC721Enumerable,
    ReentrancyGuard
{
    using SafeMath for uint256;

    ITuniver public tuniverContract;

    Tunipass[] private _tunipasses;

    bool public paused;
    string private _uri;

    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    mapping(uint256 => bool) public blacklist;

    constructor(string memory baseURI) ERC721("Tunipass", "TNP") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // _createTuniver(0, 0); // ignore tuniver with id = 0
        _uri = baseURI;
    }

    function addTunipassToBlacklist(uint256 tunipassId)
        external
        override
        onlyRole(CONTROLLER_ROLE)
    {
        require(tunipassId < _tunipasses.length, "TNV: invalid");
        blacklist[tunipassId] = true;
    }

    function removeTunipassFromBlacklist(uint256 tunipassId)
        external
        onlyRole(CONTROLLER_ROLE)
    {
        require(tunipassId < _tunipasses.length);
        blacklist[tunipassId] = false;
    }

    function setPaused(bool _paused)
        external
        override
        onlyRole(CONTROLLER_ROLE)
    {
        paused = _paused;
    }

    function setBaseURI(string memory baseURI)
        external
        onlyRole(CONTROLLER_ROLE)
    {
        _uri = baseURI;
    }

    function getTunipassInBlacklist(uint256 tunipassId)
        external
        view
        returns (bool)
    {
        return blacklist[tunipassId];
    }

    function totalSupply() public view override returns (uint256) {
        return _tunipasses.length - 1;
    }

    function getTunipass(uint256 tunipassId)
        external
        view
        override
        returns (Tunipass memory tunipass)
    {
        tunipass = _tunipasses[tunipassId];
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function createTunipass(uint256 collectionId, address buyer)
        external
        override
        onlyRole(OPERATOR_ROLE)
    {
        uint256 maxSupply = tuniverContract
            .getCollection(collectionId)
            .maxSupply;
        require(maxSupply != 0);
        uint256 tunipassId = _createTunipass(collectionId);
        _safeMint(buyer, tunipassId);
    }

    function _createTunipass(uint256 collectionId)
        private
        returns (uint256 tunipassId)
    {
        _tunipasses.push(Tunipass(collectionId, 0));
        tunipassId = _tunipasses.length - 1;

        emit TunipassCreated(tunipassId, collectionId);
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
