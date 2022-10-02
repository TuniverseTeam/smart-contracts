//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/ITunipass.sol";
import "./interfaces/ITuniverRoyalTune.sol";

contract Tunipass is
    ITunipass,
    AccessControl,
    ERC721Enumerable,
    ReentrancyGuard
{
    using SafeMath for uint256;

    Artist[] private _artists;
    Tunipass[] private _tunipasses;

    bool public paused;
    string private _uri;

    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
    bytes32 public constant SERVER_ROLE = keccak256("SERVER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    mapping(uint256 => bool) public blacklist;

    constructor(string memory baseURI) ERC721("Tunipass", "TNP") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // _createTuniver(0, 0); // ignore tuniver with id = 0
        _uri = baseURI;
    }

    function addArtist(Artist memory _artist)
        external
        onlyRole(CONTROLLER_ROLE)
    {
        _artists.push(_artist);
        uint256 artistId = _artists.length - 1;

        emit ArtistInfo(artistId, _artist.supply, _artist.levels);
    }

    function updateArtist(uint256 artistId, Artist memory _artist)
        external
        onlyRole(CONTROLLER_ROLE)
    {
        Artist storage artist = _artists[artistId];
        artist.levels = _artist.levels;
        artist.supply = _artist.supply;

        emit ArtistInfo(
            artistId,
            _artist.supply,
            _artist.levels
        );
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

    function getRequireTuneForNextLevel(uint256 tunipassId) external override view returns(uint256)  {
        Tunipass memory tunipass = _tunipasses[tunipassId];
        uint256 artistId = tunipass.artistId;
        uint256 currentLevel = tunipass.level - 1;
        Artist memory _artist = _artists[artistId];
        uint256 requiredTune = _artist.levels[currentLevel];
        return requiredTune;
    }


    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function levelUp(uint256 tunipassId)
        external
        onlyRole(OPERATOR_ROLE)
    {
        Tunipass storage tunipass = _tunipasses[tunipassId];
        Artist memory artist = _artists[tunipass.artistId];
        uint256 level = tunipass.level.add(1);

        require(level <= artist.levels.length, "exceeded level");

        tunipass.level = level;

        emit LevelUp(level, tunipassId);
    }

    function createTunipass(uint256 artistId, address buyer)
        external
        override
        onlyRole(SERVER_ROLE)
    {
        uint256 tunipassId = _createTunipass(artistId);
        _safeMint(buyer, tunipassId);
    }

    function _createTunipass(uint256 artistId)
        private
        returns (uint256 tunipassId)
    {
        Artist storage artist = _artists[artistId];

        require(
            artist.minted.add(1) <= artist.supply && artist.supply > 0,
            "exceeded"
        );

        artist.minted = artist.minted.add(1);

        _tunipasses.push(Tunipass(artistId, 1, 0));
        tunipassId = _tunipasses.length - 1;

        emit TunipassCreated(tunipassId, artistId);
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
