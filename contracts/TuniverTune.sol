//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/ITuniverTune.sol";
import "./interfaces/ITunipass.sol";
import "./lib/ERC1155Upgradeable.sol";

contract TuniverTune is
    ERC1155Upgradeable,
    AccessControlUpgradeable,
    ITuniverTune
{
    using AddressUpgradeable for address;
    using SafeMath for uint256;

    bytes32 public MINTER_ROLE;
    bytes32 public CONTROLLER_ROLE;
    bytes32 public OPERATOR_ROLE;

    ITunipass private tunipassContract;

    Tune[] private _tunes;

    uint256 public amountTunePerTunipass = 1;

    function initialize(string memory _uri) public initializer {
        __ERC1155_init(_uri);
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        MINTER_ROLE = keccak256("MINTER_ROLE");
        CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
        OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    }

    function setURI(string memory uri) external onlyRole(CONTROLLER_ROLE) {
        _setURI(uri);
    }

    function createTune(uint256 typeId, uint256 maxMint)
        external
        override
        onlyRole(CONTROLLER_ROLE)
    {
        _tunes.push(Tune(typeId, 0, 0, maxMint));
        uint256 tuneId = _tunes.length - 1;

        emit TuneCreated(tuneId, typeId, maxMint);
    }

    function setAmountTunePerTunipass(uint256 _amountTunePerTunipass)
        external
        onlyRole(CONTROLLER_ROLE)
    {
        require(_amountTunePerTunipass != 0);
        amountTunePerTunipass = _amountTunePerTunipass;
    }

    function updateTuneInfo(
        uint256 tuneId,
        uint256 typeId,
        uint256 maxMint
    ) external onlyRole(CONTROLLER_ROLE) {
        Tune storage tune = _tunes[tuneId];
        tune.typeId = typeId;
        tune.maxMint = maxMint;
    }

    function mintFor(
        address account,
        uint256[] memory tuneIds,
        uint16[] memory amount
    ) external override onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < tuneIds.length; i++) {
            _mintFor(account, tuneIds[i], amount[i]);
        }
    }

    function _mintFor(
        address account,
        uint256 tuneId,
        uint16 amount
    ) private {
        Tune storage tune = _tunes[tuneId];

        require(tune.maxMint >= tune.minted.add(amount), "cannot be exceeded");

        _balances[tuneId][account] += amount;
        tune.minted += amount;

        emit TransferSingle(msg.sender, address(0), account, tuneId, amount);
        emit TuneClaimed(account, tuneId, amount);
    }

    function swapTunipass(
        uint256 tuneId,
        uint256 amount,
        uint256 artistId
    ) external override {
        uint256 totalTunipass = amount.div(amountTunePerTunipass);
        uint256 remainderTune = amount.mod(amountTunePerTunipass);
        _burn(msg.sender, tuneId, amount.sub(remainderTune));

        for (uint256 i = 0; i < totalTunipass; i++) {
            tunipassContract.createTunipass(artistId, msg.sender);
        }
    }

    function levelUpTunipass(uint256 tuneId, uint256 tunipassId) external {
        uint256 requireTune = tunipassContract.getRequireTuneForNextLevel(tunipassId);
        _burn(msg.sender, tuneId, requireTune);
        tunipassContract.levelUp(tunipassId);
    }

    function putTunesIntoStorage(address account, uint256[] memory tuneIds)
        external
        override
        onlyRole(OPERATOR_ROLE)
    {
        for (uint256 i = 0; i < tuneIds.length; i++) {
            require(_balances[tuneIds[i]][account] >= 1, "exceeds balance");
            _balances[tuneIds[i]][account] -= 1;
        }
    }

    function returnTunes(address account, uint256[] memory tuneIds)
        external
        override
        onlyRole(OPERATOR_ROLE)
    {
        for (uint256 i = 0; i < tuneIds.length; i++) {
            _balances[tuneIds[i]][account] += 1;
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external {
        _safeTransferFrom(from, to, id, amount, data);
    }

    function getTune(uint256 tuneId)
        external
        view
        override
        returns (Tune memory tune)
    {
        return _tunes[tuneId];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
