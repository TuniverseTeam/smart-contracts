// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./iNFTMARKETMANAGER.sol";

interface iNFTMARKET {
    function getTotalNfts() external view returns (uint256);

    function getNftType() external view returns (uint8);

    function listings(uint256) external view returns (uint256);

    function getTradeById(uint256)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            address,
            address,
            bool
        );

    function getPriceByTokenId(uint256) external view returns (uint256);

    function getTradeVolume() external view returns (uint256);

    function getHighestPrice() external view returns (uint256);

    function getVolumeByAccount(address) external view returns (uint256);

    function listNft(
        address,
        uint256,
        uint256
    ) external returns (uint256);

    function offer(
        address,
        uint256,
        uint256
    ) external payable;

    function abortOffer(address, uint256) external payable;

    function acceptOffer(uint256, address) external payable;

    function buyNft(address, uint256) external payable;

    function delistNft(address, uint256) external;

    function ownerDelistNft(address, uint256) external;

    function setTotalNfts(uint256) external;

    function setTradeVolume(uint256) external;

    function setAccountVolumes(
        SharedStructs.AccountVolume[] memory _accountVolumes
    ) external;

    function setAccountVolume(SharedStructs.AccountVolume memory _accountVolume)
        external;

    function setHighestPrice(uint256) external;

    function updateServiceFee(uint256) external;

    function updateWalletFund(address) external;

    function withdrawFund(uint256) external;

    function withdrawAllFund() external;
}
