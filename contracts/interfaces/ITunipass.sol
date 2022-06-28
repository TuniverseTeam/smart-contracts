//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ITunipass {
    event TunipassCreated(uint256 tunipassId, uint256 artistId);
    event AddTunipassToBlacklist(uint256 tunipassId);
    event ArtistInfo(
        uint256 artistId,
        address _artist,
        uint256 maxSupply,
        uint256[] multiplied
    );
    event LevelUp(uint256 level, uint256 tunipassId);
    event RemoveTunipassFromBlacklist(uint256 tunipassId);

    struct Artist {
        address _artist;
        uint256 maxSupply;
        uint256[] multiplied; // mul by level require length === max level
        uint256 minted;
    }

    struct Tunipass {
        uint256 artistId;
        uint256 level;
        uint256 equipting; // equipting address
    }

    /**
     * @notice Gets tunipass information.
     *
     * @dev Prep function for staking.
     */
    function getTunipass(uint256 tunipassId)
        external
        view
        returns (Tunipass memory tunipass);

    /**
     * @notice tunipass blacklisted.
     */
    function getTunipassInBlacklist(uint256 tunipassId)
        external
        view
        returns (bool);

    /**
     * @notice add tunipassId to blacklist.
     */
    function addTunipassToBlacklist(uint256 tunipassId) external;

    /**
     * @notice remove tunipassId to blacklist.
     */
    function removeTunipassFromBlacklist(uint256 tunipassId) external;

    /**
     * @notice mint tunipass for specific address.
     *
     * @dev Function take 2 arguments.
     *
     */
    function createTunipass(uint256 collectionId, address buyer) external;

    /**
     * @notice paused function.
     *
     * @dev Prep function for admin contract.
     */
    function setPaused(bool _paused) external;

    /**
     * @notice set uri function.
     *
     * @dev Prep function for admin contract.
     */
    function setBaseURI(string memory baseURI) external;
}
