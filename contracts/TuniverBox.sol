pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IPancakeRouter02.sol";

contract TuniverBox is IERC721Receiver, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    event SupportedToken(IERC20 _acceptedToken, bool isSupport);

    uint256 priceInBUSD = 1 * 10**18;
    IPancakeRouter02 public pancakeSwapRouter =
        IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    uint256 public slippage = 50;
    uint256 public constant PERCENT = 1000;

    mapping(IERC20 => bool) public supportedToken;

    constructor() {}

    function setSupportedToken(IERC20 _acceptedToken, bool isSupport)
        external
        onlyOwner
    {
        supportedToken[_acceptedToken] = isSupport;
        emit SupportedToken(_acceptedToken, isSupport);
    }

    function getAmountIn(address[] memory pathToken, uint256 amountOut)
        public
        view
        returns (uint256)
    {
        uint256[] memory amounts = pancakeSwapRouter.getAmountsIn(
            amountOut,
            pathToken
        );

        uint256 totalAmountIn = amounts[0] +
            amounts[0].mul(slippage).div(PERCENT);

        return totalAmountIn;
    }

    function buyWithETH(address[] memory pathToken) external {}

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external override returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }
}
