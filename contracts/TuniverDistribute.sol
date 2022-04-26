pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ITuniver.sol";

contract TuniverDistribute is EIP712, AccessControl, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Claimed(string claimId, uint256 totalClaim);

    struct Tuniver {
        uint256 totalClaim;
        string claimId;
        address receipt;
    }

    bytes32 public constant SERVER_ROLE = keccak256("SERVER_ROLE");
    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
    string private constant SIGNING_DOMAIN = "LazyDistribute-Tuniver";
    string private constant SIGNATURE_VERSION = "1";
    bool public paused;

    mapping(IERC20 => bool) acceptedToken;
    mapping(string => bool) private claimedId;

    constructor() EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CONTROLLER_ROLE, msg.sender);
    }

    function setAcceptedToken(IERC20 token, bool isAccept)
        external
        onlyRole(CONTROLLER_ROLE)
    {
        acceptedToken[token] = isAccept;
    }

    function togglePause() external onlyRole(CONTROLLER_ROLE) {
        paused = !paused;
    }

    function claim(
        IERC20 token,
        Tuniver calldata tuniverNft,
        bytes memory signature
    ) external {
        address signer = _verify(tuniverNft, signature);

        require(!paused, "TNV: paused");
        require(
            hasRole(SERVER_ROLE, signer),
            "TNV: Signature invalid or unauthorized"
        );
        require(!claimedId[tuniverNft.claimId], "TNV: id claimed");
        require(acceptedToken[token], "TNV: token not supported");

        token.transfer(tuniverNft.receipt, tuniverNft.totalClaim);
        claimedId[tuniverNft.claimId] = true;

        emit Claimed(tuniverNft.claimId, tuniverNft.totalClaim);
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
                            "Tuniver(uint256 totalClaim, uint256 claimId, uint256 receipt)"
                        ),
                        keccak256(abi.encodePacked(tuniverNft.totalClaim)),
                        keccak256(abi.encodePacked(tuniverNft.claimId)),
                        keccak256(abi.encodePacked(tuniverNft.receipt))
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
