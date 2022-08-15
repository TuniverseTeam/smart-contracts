pragma solidity ^0.8.0;

interface ITuniverBox {
    function getPricePerBox() external view returns(uint256);
    function buy(uint256 amount, address buyer, uint256 artistId) external;
}