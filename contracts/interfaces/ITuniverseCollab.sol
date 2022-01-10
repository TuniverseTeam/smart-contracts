//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface ITuniverse is IERC1155Upgradeable {
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
        uint16 royalShare;
        uint16 minted;
        uint16 burnt;
        Rarity rarity;
        address singer;
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
        uint16 royalShare,
        Rarity rarity
    ) external payable;

    /**
     * @notice Burns ERC1155 songs since it is locked to staking.
     * @dev prefunc for staking.
     */
    function putSongsIntoStorage(address account, uint256[] memory songIds)
        external;

    /**
     * @notice Returns ERC1155 songs back to the owner.
     * @dev prefunc for staking.
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

    /**
     * @notice Check if song is blacklisted.
     */
    function isBlacklisted(uint256 songId) external view returns (bool);

    /**
        @notice transfer func for operator contract
     */
    function transferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}
