//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./utils/TokenWithdrawableBridge.sol";
import "./interfaces/ITuniverAdmin.sol";
import "./interfaces/ITuniverseCollab.sol";

contract TuniverBridge is
    AccessControl,
    ReentrancyGuard,
    IERC721Receiver,
    Ownable,
    TokenWithdrawableBridge
{
    modifier onlySupportAddress(
        ITuniverCollab tuniverContract,
        IERC721 collabContract
    ) {
        require(
            adminContract.isSupported(address(tuniverContract)) != address(0),
            "TuniverBridge: not supported"
        );
        require(
            adminContract.isSupportedCollab(address(collabContract)),
            "TuniverBridge: not supported collab"
        );
        _;
    }

    ITuniverAdmin public adminContract;
    uint256 public swapFee;
    bool public paused;

    mapping(address => mapping(uint256 => uint256)) public tuniverIdToCollab;
    mapping(address => mapping(uint256 => uint256)) public collabIdToTuniver;

    bytes32 public constant SERVER_ROLE = keccak256("SERVER_ROLE");
    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");

    event SwapTo(address from, address to, uint256 tokenId);
    event SwapFeeUpdated(uint256 _swapFee);
    event Paused(bool isPaused);

    constructor(uint256 _swapFee) {
        swapFee = _swapFee;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setTokenMapping(
        ITuniverCollab tuniverContract,
        IERC721 collabContract,
        uint256[] memory tuniverIds,
        uint256[] memory collabIds
    )
        external
        onlyRole(CONTROLLER_ROLE)
        onlySupportAddress(tuniverContract, collabContract)
    {
        require(
            tuniverIds.length == collabIds.length,
            "TunvierBridge: invalid data"
        );
        for (uint256 i = 0; i < tuniverIds.length; i++) {
            tuniverIdToCollab[address(collabContract)][
                tuniverIds[i]
            ] = collabIds[i];
            collabIdToTuniver[address(tuniverContract)][
                collabIds[i]
            ] = tuniverIds[i];
        }
    }

    function togglePaused() external onlyRole(CONTROLLER_ROLE) {
        paused = !paused;
        emit Paused(paused);
    }

    function swap(
        ITuniverCollab tuniverContract,
        IERC721 collabContract,
        uint256 tokenId,
        address to,
        bool _isSwapIn
    ) external payable nonReentrant {
        require(!paused, "TuniverBridge: paused");
        require(msg.value == swapFee, "TuniverBridge: invalid fee");
        require(
            adminContract.isSupported(address(tuniverContract)) != address(0),
            "TuniverBridge: not supported"
        );
        require(
            adminContract.isSupportedCollab(address(collabContract)),
            "TuniverBridge: not supported collab"
        );

        if (_isSwapIn) {
            uint256 tuniverId = collabIdToTuniver[address(tuniverContract)][
                tokenId
            ];
            require(tuniverId != 0, "TuniverBridge: not supported");
            collabContract.safeTransferFrom(msg.sender, address(this), tokenId);
            tuniverContract.transferFrom(address(this), msg.sender, tuniverId);
        } else {
            uint256 collabId = tuniverIdToCollab[address(collabContract)][
                tokenId
            ];
            require(collabId != 0, "TuniverBridge: not supported");
            tuniverContract.safeTransferFrom(
                msg.sender,
                address(this),
                tokenId
            );
            collabContract.transferFrom(address(this), msg.sender, collabId);
        }

        (bool isTransferToOwner, ) = owner().call{value: msg.value}("");
        require(isTransferToOwner);

        emit SwapTo(msg.sender, to, tokenId);
    }

    function withdrawNFT(
        IERC721 token,
        address to,
        uint256 tokenId
    ) external onlyRole(CONTROLLER_ROLE) {
        token.transferFrom(address(this), to, tokenId);
    }

    function setSwapFee(uint256 _swapFee) external onlyRole(CONTROLLER_ROLE) {
        require(swapFee != _swapFee, "Bridge: invalid fee");
        swapFee = _swapFee;

        emit SwapFeeUpdated(_swapFee);
    }

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
