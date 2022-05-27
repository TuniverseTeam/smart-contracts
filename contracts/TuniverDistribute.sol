pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./utils/TokenWithdrawableBridge.sol";
import "./interfaces/ITuniver.sol";

contract TuniverDistribute is
    EIP712,
    AccessControl,
    ReentrancyGuard,
    TokenWithdrawableBridge
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Claimed(
        uint256 claimId,
        uint256 totalClaim,
        address receipt,
        address caller
    );

    struct Tuniver {
        uint256 totalClaim;
        uint256 claimId;
        address receipt;
        address token;
    }

    bytes32 public constant SERVER_ROLE = keccak256("SERVER_ROLE");
    string private constant SIGNING_DOMAIN = "LazyDistribute-Tuniver";
    string private constant SIGNATURE_VERSION = "1";
    bool public paused;

    mapping(uint256 => bool) private claimedId;

    constructor() EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        _setupRole(
            DEFAULT_ADMIN_ROLE,
            0x690ad03BF5b366635569C74bEC957F95f73C7D09
        );
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SERVER_ROLE, 0xFFF781b942C19a62683E8A595528e332f684c36A);
    }

    function togglePause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        paused = !paused;
    }

    function claim(Tuniver calldata tuniverNft, bytes memory signature)
        external
    {
        address signer = _verify(tuniverNft, signature);
        IERC20 token = IERC20(tuniverNft.token);

        require(!paused, "TNV: paused");
        require(
            hasRole(SERVER_ROLE, signer),
            "TNV: Signature invalid or unauthorized"
        );
        require(!claimedId[tuniverNft.claimId], "TNV: id claimed");

        token.transfer(tuniverNft.receipt, tuniverNft.totalClaim);
        claimedId[tuniverNft.claimId] = true;

        emit Claimed(
            tuniverNft.claimId,
            tuniverNft.totalClaim,
            tuniverNft.receipt,
            msg.sender
        );
    }

    function _hash(Tuniver calldata tuniverNft)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "Tuniver(uint256 totalClaim,uint256 claimId,address receipt,address token)"
                        ),
                        tuniverNft.totalClaim,
                        tuniverNft.claimId,
                        tuniverNft.receipt,
                        tuniverNft.token
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

    function _verify(Tuniver calldata tuniverNft, bytes memory signature)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hash(tuniverNft);
        return ECDSA.recover(digest, signature);
    }
}
