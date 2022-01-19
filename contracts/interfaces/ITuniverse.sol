//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITuniverse {
    enum Rarity {
        COMMON,
        UNCOMMON,
        RARE,
        EPIC,
        LEGENDARY,
        MYTHICAL
    }

    struct Song {
        string name;
        uint16 maxSupply;
        uint16 minted;
        uint16 burnt;
        Rarity rarity;
        address artist;
        bytes32 songHash;
    }

    event SongCreated(
        uint256 indexed songId,
        string name,
        uint16 maxSupply,
        Rarity rarity
    );
    event SongLocked(uint256[] indexed songIds, bool isLocked);
    event SongBlacklisted(uint256 indexed songIds, bool isBlacklisted);

    /**
     * @notice Create a song.
     */
    function createSong(
        string memory name,
        uint16 maxSupply,
        bytes32 songHash,
        Rarity rarity
    ) external payable;

    /**
     * @notice Burns ERC1155 songs since it is locked to staking.
     *
     */
    function putSongsIntoStorage(address account, uint256[] memory songIds)
        external;

    /**
     * @notice Returns ERC1155 songs back to the owner.
     *
     */
    function returnSongs(address account, uint256[] memory songIds) external;

    /**
     * @notice Gets song information.
     */
    function getSong(uint256 songId) external view returns (Song memory song);

    /**
     * @notice Check if song is out of stock.
     */
    function isOutOfStock(uint256 songId, uint16 amount)
        external
        view
        returns (bool);
}
