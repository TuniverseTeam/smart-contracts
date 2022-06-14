//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ITuniver {
    event TuniverCreated(uint256 collectionId, uint256 tuniverId);
    event CollectionCreated(
        uint256 collectionId,
        string artistName,
        address artist,
        uint256[] royalty,
        uint256[] royaltyMultiplier,
        uint256 maxSupply
    );

    event CollectionUpdated(
        uint256 collectionId,
        string artistName,
        address artist,
        uint256[] royalty,
        uint256[] royaltyMultiplier,
        uint256 maxSupply
    );

    event AddTuniverToBlacklist(uint256 tuniverId);
    event RemoveTuniverFromBlacklist(uint256 tuniverId);

    struct Tuniver {
        uint256 collectionId;
        uint256 royaltyId;
    }

    struct Collection {
        string artistName;
        address artist;
        uint256[] royalty;
        uint256[] royaltyMultiplier;
        uint256 maxSupply;
        uint256 minted;
    }

    /**
     * @notice Gets tuniver information.
     *
     * @dev Prep function for staking.
     */
    function getTuniver(uint256 tuniverId)
        external
        view
        returns (uint256 royaltyShare, address artist);

    /**
     * @notice getTuniver collection ID.
     *
     * @dev Prep function for staking.
     */
    function getTuniverCollectionId(uint256 tuniverId)
        external
        view
        returns (Tuniver memory tuniver);

    function getCollection(uint256 collectionId)
        external
        view
        returns (Collection memory collection);

    /**
     * @notice tuniver blacklisted.
     */
    function getTuniverInBlacklist(uint256 tuniverId)
        external
        view
        returns (bool);

    /**
     * @notice add tuniverId to blacklist.
     */
    function addTuniverToBlacklist(uint256 tuniverId) external;

    /**
     * @notice remove tuniverId to blacklist.
     */
    function removeTuniverFromBlacklist(uint256 tuniverId) external;

    /**
     * @notice mint tuniver for specific address.
     *
     * @dev Function take 2 arguments are amount and artist.
     *
     */
    function mintFor(Tuniver[] memory tunivers, address buyer) external;

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
