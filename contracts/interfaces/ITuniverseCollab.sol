//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface ITuniverCollab is IERC721Upgradeable {
    event TuniverCreated(uint256 tuniverId, uint256 typeId);
    event TuniverUpdated(
        uint256 typeId,
        bool isUnlock,
        uint256 royalty,
        uint256 rarity
    );
    event AddTuniverToBlacklist(uint256 tuniverId);
    event RemoveTuniverFromBlacklist(uint256 tuniverId);

    struct Tuniver {
        uint256 typeId;
        bool isUnlock;
        uint256 royalty;
        uint256 rarity;
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
            uint256 typeId,
            bool isUnlock,
            uint256 royalty,
            uint256 rarity
        );

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
     * @dev Function take 3 arguments are address of buyer, amount.
     *
     * Requirements:
     * - onlyOperator
     */
    function mintBox(address buyer, uint256[] memory typeIds) external;

    /**
     * @notice fusion 2 tuniver.
     *
     * @dev Prep function for fusion.
     */
    function fusion(
        uint256[] memory tuniverIds,
        uint256 typeId,
        address caller
    ) external;

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
