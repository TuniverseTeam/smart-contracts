pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/ITuniverse.sol";

contract TuniverAdmin is AccessControlUpgradeable {
    modifier onlySupportedAddress(ITuniver _tuniverContract) {
        require(
            isSupported(address(_tuniverContract)) != address(0),
            "TNV: unsupported"
        );
        _;
    }

    mapping(address => address) supportedAddress;
    bytes32 public CONTROLLER_ROLE;
    bytes32 public OPERATOR_ROLE;
    address public receiverFee;
    uint256 public fee;

    function initialize() public initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        receiverFee = msg.sender;
        CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
        OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    }

    function setSupportedAddress(address _contractSupported, address _artist)
        external
        onlyRole(CONTROLLER_ROLE)
    {
        supportedAddress[_contractSupported] = _artist;
    }

    function setReceiverFee(address _receiverFee)
        external
        onlyRole(CONTROLLER_ROLE)
    {
        receiverFee = _receiverFee;
    }

    function setFee(uint256 _fee) external onlyRole(CONTROLLER_ROLE) {
        fee = _fee;
    }

    function isSupported(address _contract) public view returns (address) {
        return supportedAddress[_contract];
    }

    function mint(
        ITuniver tuniverContract,
        address to,
        uint256[] memory typeIds
    ) external payable {
        require(
            isSupported(address(tuniverContract)) != address(0),
            "TNV: unsupported"
        );
        require(msg.value == fee, "invalid fee");
        tuniverContract.mintBox(to, typeIds);
        (bool isTransferToOwner, ) = receiverFee.call{value: fee}("");
        require(isTransferToOwner);
    }

    function addTuniverFromBlacklist(
        ITuniver tuniverContract,
        uint256 tuniverId
    ) external onlyRole(CONTROLLER_ROLE) onlySupportedAddress(tuniverContract) {
        tuniverContract.addTuniverToBlacklist(tuniverId);
    }

    function removeTuniverFromBlacklist(
        ITuniver tuniverContract,
        uint256 tuniverId
    ) external onlyRole(CONTROLLER_ROLE) onlySupportedAddress(tuniverContract) {
        require(
            isSupported(address(tuniverContract)) != address(0),
            "TNV: unsupported"
        );
        tuniverContract.removeTuniverFromBlacklist(tuniverId);
    }
}
