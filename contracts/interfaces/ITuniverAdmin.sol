//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITuniverAdmin {
    event TuniverSupported(address contractAddress, address owner);
    event TuniverCollabSupported(address contractAddress, bool isBool);
    event TuniverMinted(address contractAddress, address to, uint256[] typeIds);
    event TuniverBlacklisted(
        address contractAddress,
        uint256 tuniverId,
        bool _isBlacklisted
    );

    function isSupported(address _contract) external view returns (address);

    function isSupportedCollab(address _contract) external view returns (bool);
}
