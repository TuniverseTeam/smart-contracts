//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ITuniver {
    event TuniverCreated(uint256 tuniverId, uint256 rarity, address artist);
    event TuniverUpdated(uint256 tuniverId, uint256 rarity, address artist);
    event AddTuniverToBlacklist(uint256 tuniverId);
    event RemoveTuniverFromBlacklist(uint256 tuniverId);

    struct Tuniver {
        uint256 rarity;
        address artist;
    }

    /**
     * @notice Gets tuniver information.
     *
     * @dev Prep function for staking.
     */
    function getTuniver(uint256 tuniverId)
        external
        view
        returns (
            uint256 royalty,
            uint256 rarity,
            address artist
        );

    /**
     * @notice get royalty of artist with rarity.
     */
    function getRoyaltyOf(address artist, uint256 rarity)
        external
        view
        returns (uint256 royalty);

    /**
     * @notice get rarity by id.
     */
    function getRarityOf(uint256 tuniverId)
        external
        view
        returns (uint256 rarity);

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
     * @notice Upgrade tuniver rarity.
     *
     * @dev Prep function for fusion.
     */
    function upgrade(uint256 tuniverId) external;

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
