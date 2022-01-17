//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./lib/extensions/ERC1155PausableUpgradeable.sol";
import "./interfaces/ITuniverse.sol";

contract Tuniverse is
    ERC1155PausableUpgradeable,
    ITuniverse,
    AccessControlUpgradeable,
    OwnableUpgradeable
{
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    modifier onlyArtist(address _artistAddress) {
        require(
            _artist[_artistAddress].total > 0,
            "Tuniverse: invalid address"
        );
        require(
            _artist[_artistAddress].created <= _artist[_artistAddress].total,
            "Tuniverse: not eligible"
        );
        require(
            _artist[_artistAddress].endTime <= block.timestamp,
            "Tuniverse: not valid time"
        );
        _;
    }

    modifier onlyArtistOfSong(address _artistAddress, uint256 songId) {
        require(_songs[songId].artist == _artistAddress);
        _;
    }

    mapping(address => Artist) public _artist;
    Song[] private _songs;
    uint256 public feeCreateSong;
    bytes32 public SIGNER_ROLE;
    bytes32 public CONTROLLER_ROLE;
    bytes32 public OPERATOR_ROLE;

    function initialize(string memory _uri, uint256 _feeCreateSong)
        public
        initializer
    {
        __ERC1155_init(_uri);
        __ERC1155Pausable_init();
        feeCreateSong = _feeCreateSong;
        SIGNER_ROLE = keccak256("SIGNER_ROLE");
        CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
        OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    }

    function verifySignature(bytes memory _signedSongHash, uint256 songId)
        external
        view
        returns (bool)
    {
        address signer = _verify(_signedSongHash, songId);
        return hasRole(SIGNER_ROLE, signer);
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

    function addArtist(
        address artistAddress,
        uint256 total,
        uint256 endTime
    ) external onlyOwner {
        require(endTime > block.timestamp && total > 0, "Tuniverse: invalid");
        _artist[artistAddress] = Artist(total, 0, endTime);
    }

    function createSong(
        string memory name,
        uint16 maxSupply,
        uint16 royalShare,
        bytes32 songHash,
        Rarity rarity
    ) external payable override onlyArtist(msg.sender) {
        require(maxSupply > 0, "Tuniverse: invalid maxSupply");
        require(msg.value == feeCreateSong, "Tuniverse: Not enough fee");

        _songs.push(
            Song(
                name,
                maxSupply,
                royalShare,
                0,
                0,
                rarity,
                msg.sender,
                songHash
            )
        );
        uint256 songId = _songs.length.sub(1);
        _mint(msg.sender, songId, maxSupply, "");

        _artist[msg.sender].created = _artist[msg.sender].created.add(1);

        (bool isTransferToOwner, ) = owner().call{value: msg.value}("");
        require(isTransferToOwner);

        emit SongCreated(songId, name, maxSupply, rarity);
    }

    function updateSong(
        uint256 songId,
        string memory name,
        uint16 maxSupply
    ) external onlyArtistOfSong(msg.sender, songId) {
        Song storage song = _songs[songId];
        require(maxSupply >= song.minted, "Tuniverse: invalid");
        song.name = name;
        song.maxSupply = maxSupply;
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

    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function _verify(bytes memory _signedSongHash, uint256 songId)
        internal
        view
        returns (address)
    {
        bytes32 songHash = _songs[songId].songHash;
        bytes32 messageHash = ECDSAUpgradeable.toEthSignedMessageHash(songHash);
        address messageSigner = ECDSAUpgradeable.recover(
            messageHash,
            _signedSongHash
        );
        return messageSigner;
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
