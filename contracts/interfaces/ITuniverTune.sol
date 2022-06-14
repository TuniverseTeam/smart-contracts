//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITuniverTune {
    event TuneCreated(uint256 indexed tuneId, uint256 typeId, uint256 maxMint);
    event TuneClaimed(
        address indexed account,
        uint256 indexed tuneId,
        uint256 indexed amount
    );

    struct Tune {
        uint256 typeId;
        uint256 minted;
        uint256 burnt;
        uint256 maxMint;
    }

    /**
     * @notice Burns ERC1155 equipment since it is equipped to the user.
     */
    function putTunesIntoStorage(address account, uint256[] memory tuneIds)
        external;

    /**
     * @notice claim tuniver.
     */
    function claim(
        address account,
        uint256[] memory tuneIds,
        uint16[] memory amount
    ) external;

    /**
     * @notice swap to tunipass.
     */
    function swapTunipass(
        uint256 tuneId,
        uint256 amount,
        uint256 collectionId
    ) external;

    /**
     * @notice Create an tuniver tune.
     */
    function createTune(uint256 typeId, uint256 maxMint) external;

    /**
     * @notice Returns ERC1155 equipment back to the owner.
     */
    function returnTunes(address account, uint256[] memory tuneIds) external;

    /**
     * @notice Get informations of item by tuneId
     */

    function getTune(uint256 tuneId) external view returns (Tune memory tune);
}
