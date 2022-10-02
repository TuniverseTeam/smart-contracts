//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ITuniverBox.sol";


contract TuniverCollaborator is EIP712, AccessControl {
    using SafeERC20 for IERC20;

    modifier onlyNotPaused() {
        require(!paused, "Paused");
        _;
    }

    ITuniverBox public boxContract = ITuniverBox(0xF1dbEddA8885292A9cafeaeC9A14ede53828A445);

    bytes32 public constant SERVER_ROLE = keccak256("SERVER_ROLE");
    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
    string private constant SIGNING_DOMAIN = "LazyCollaborator-Tuniver";
    string private constant SIGNATURE_VERSION = "1";
    address public receiver;
    bool public paused;

    struct Buyer {
        uint256 amount;
        address buyerAddress;
        uint256 totalPrice;
        address tokenAddress;
        uint256 collectionId;
    }

    constructor() EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        _setupRole(
            DEFAULT_ADMIN_ROLE,
            0x87D5Af2F2DFf06d79e7Ab26d9eC0335a5e5dAE9F
        );
        _setupRole(CONTROLLER_ROLE, msg.sender);
        _setupRole(SERVER_ROLE, 0xFFF781b942C19a62683E8A595528e332f684c36A);
        receiver = 0x87D5Af2F2DFf06d79e7Ab26d9eC0335a5e5dAE9F;
    }

    function togglePause() external onlyRole(CONTROLLER_ROLE) {
        paused = !paused;
    }

    function setAddressReceiver(address _receiver) external onlyRole(CONTROLLER_ROLE) {
        require(_receiver != address(0));
        receiver = _receiver;
    }

    function setBoxContract(ITuniverBox _boxContract) external onlyRole(CONTROLLER_ROLE) {
        boxContract = _boxContract;
    }

    function buy(Buyer calldata buyer, bytes memory signature)  external payable onlyNotPaused {
        address signer = _verify(buyer, signature);
        bool isNativeToken = buyer.tokenAddress == address(0);
        IERC20 token = IERC20(buyer.tokenAddress);

        uint256 amount = buyer.amount;
        uint256 totalPrice = buyer.totalPrice;

        require(buyer.buyerAddress == msg.sender, "invalid signature");
        require(
            hasRole(SERVER_ROLE, signer),
            "TNV: Signature invalid or unauthorized"
        );
        if(isNativeToken) {
            require(msg.value == totalPrice, "not enough fee");
            (bool isSuccess, ) = address(receiver).call{value: totalPrice}("");
            require(isSuccess);
        } else {
            token.safeTransferFrom(msg.sender, receiver, totalPrice);
        }

        
        boxContract.buy(amount, msg.sender, buyer.collectionId);
    }

    function _hash(Buyer calldata buyer)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "Buyer(uint256 amount,address buyerAddress,uint256 totalPrice,address tokenAddress,uint256 collectionId)"
                        ),
                        buyer.amount,
                        buyer.buyerAddress,
                        buyer.totalPrice,
                        buyer.tokenAddress,
                        buyer.collectionId
                    )
                )
            );
    }

    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function _verify(Buyer calldata buyer, bytes memory signature)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hash(buyer);
        return ECDSA.recover(digest, signature);
    }
}