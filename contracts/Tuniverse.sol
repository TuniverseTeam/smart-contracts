//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./lib/ERC1155.sol";
import "./interfaces/ITuniverse.sol";

contract Tuniverse is
    ERC1155Upgradeable,
    ITuniverse,
    AccessControlUpgradeable,
    OwnableUpgradeable
{
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    modifier onlyNotInBlacklist(uint256 songId) {
        require(blacklist[songId] == false, "Tuniverse: blacklisted");
        _;
    }

    Song[] private _songs;
    uint256 public feeCreateSong;
    bytes32 public SINGER_ROLE;
    bytes32 public CONTROLLER_ROLE;
    bytes32 public OPERATOR_ROLE;

    mapping(uint256 => bool) public blacklist;

    function initialize(string memory _uri, uint256 _feeCreateSong)
        public
        initializer
    {
        __ERC1155_init(_uri);
        feeCreateSong = _feeCreateSong;
        SINGER_ROLE = keccak256("SINGER_ROLE");
        CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
        OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    }

    function setURI(string memory uri) external onlyRole(CONTROLLER_ROLE) {
        _setURI(uri);
    }

    function setFeeCreateSong(uint256 _feeCreateSong)
        external
        onlyRole(CONTROLLER_ROLE)
    {
        feeCreateSong = _feeCreateSong;
    }

    function addBlacklist(uint256 songId) external onlyRole(CONTROLLER_ROLE) {
        require(blacklist[songId] == false, "blacklisted");
        blacklist[songId] = true;
        emit SongBlacklisted(songId, true);
    }

    function removeBlacklist(uint256 songId)
        external
        onlyRole(CONTROLLER_ROLE)
    {
        require(blacklist[songId] == true, "blacklisted");
        blacklist[songId] = false;
        emit SongBlacklisted(songId, false);
    }

    function isBlacklisted(uint256 songId) external view returns (bool) {
        return blacklist[songId];
    }

    function createSong(
        string memory name,
        uint16 maxSupply,
        uint16 royalShare,
        Rarity rarity
    ) external payable override onlyRole(SINGER_ROLE) {
        require(maxSupply > 0, "Tuniverse: invalid maxSupply");
        require(msg.value == feeCreateSong, "Tuniverse: Not enough fee");

        _songs.push(
            Song(name, maxSupply, royalShare, 0, 0, rarity, msg.sender)
        );
        uint256 songId = _songs.length.sub(1);
        _mint(msg.sender, songId, maxSupply, "");

        (bool isTransferToOwner, ) = owner().call{value: msg.value}("");
        require(isTransferToOwner);

        emit SongCreated(songId, name, maxSupply, rarity);
    }

    function putSongsIntoStorage(address account, uint256[] memory songIds)
        external
        override
        onlyRole(OPERATOR_ROLE)
    {
        for (uint256 i = 0; i < songIds.length; i++) {
            require(
                _balances[songIds[i]][account] >= 1,
                "Tuniverse: exceeds balance"
            );
            _balances[songIds[i]][account] = _balances[songIds[i]][account].sub(
                1
            );
        }
        emit SongLocked(songIds, true);
    }

    function returnSongs(address account, uint256[] memory songIds)
        external
        override
        onlyRole(OPERATOR_ROLE)
    {
        for (uint256 i = 0; i < songIds.length; i++) {
            _balances[songIds[i]][account] = _balances[songIds[i]][account].add(
                1
            );
        }
        emit SongLocked(songIds, false);
    }

    function getSong(uint256 songId)
        external
        view
        override
        returns (Song memory song)
    {
        return _songs[songId];
    }

    function isOutOfStock(uint256 songId, uint16 amount)
        external
        view
        override
        returns (bool)
    {
        Song memory song = _songs[songId];
        return song.minted + amount > song.maxSupply;
    }

    function transferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external onlyRole(OPERATOR_ROLE) {
        require(from != address(0), "invalid address");
        _safeTransferFrom(from, to, id, amount, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
