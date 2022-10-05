//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ITuniverRoyalTune {
    event RoyalTuneCreated(uint256 collectionId, uint256 boxId);
    event CollectionCreated(
        uint256 collectionId,
        uint256 maxSupply
    );

    event CollectionUpdated(
        uint256 collectionId,
        uint256 maxSupply
    );

    event AddRoyalTuneToBlacklist(uint256 royalTuneId);
    event RemoveRoyalTuneFromBlacklist(uint256 royalTuneId);

    struct Collection {
        uint256 maxSupply;
        uint256 minted;
    }

    /**
     * @notice getTuniver collection ID.
     *
     * @dev Prep function for staking.
     */
    function getRoyalTuneCollectionId(uint256 royaltuneId)
        external
        view
        returns (uint256 collectionId);

    function getCollection(uint256 collectionId)
        external
        view
        returns (Collection memory collection);

    /**
     * @notice tuniver blacklisted.
     */
    function getRoyalTuneInBlacklist(uint256 royalTuneId)
        external
        view
        returns (bool);

    /**
     * @notice mint tuniver for specific address.
     */
    function mintFor(uint256[] memory royalTunes, address buyer) external;
}
