//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ITuniver {
    event TuniverCreated(
        uint256 collectionType,
        uint256 nftType,
        uint256 royaltyShare
    );
    event AddTuniverToBlacklist(uint256 tuniverId);
    event RemoveTuniverFromBlacklist(uint256 tuniverId);

    struct Tuniver {
        uint256 collectionType;
        uint256 nftType;
        uint256 royaltyShare;
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
            uint256 collectionType,
            uint256 nftType,
            uint256[] memory extraRewards,
            uint256 royaltyShare
        );

    /**
     * @notice tuniver blacklisted.
     */
    function getTuniverInBlacklist(uint256 tuniverId)
        external
        view
        returns (bool);

    /**
     * @notice mint tuniver for specific address.
     *
     * @dev Function take 3 arguments are address of buyer, amount.
     *
     * Requirements:
     * - onlyOperator
     */
    function mintFor(address buyer, Tuniver[] memory tunivers) external;

    /**
     * @notice fusion 2 tuniver.
     *
     * @dev Prep function for fusion.
     */
    function fusion(
        uint256[] memory tuniverIds,
        uint256 collectionType,
        uint256 nftType,
        uint256 royaltyShare,
        address caller
    ) external;
}
