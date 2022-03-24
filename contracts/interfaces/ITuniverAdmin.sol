//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITuniverAdmin {
    function isSupported(address _contract) external view returns (address);

    function isSupportedCollab(address _contract) external view returns (bool);
}
