// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./erc20.sol";
import "./vault.sol";

contract GameContract {

    enum DungeonStatus {Completed, InComplete}

    struct Dungeon {
        string name;
        uint256 reward;
        uint256 dungeonId;
        DungeonStatus status;
        uint256 key;
        address owner;
    }

    Dungeon[] public dungeons;
    uint256 public dungeonEntryFee;
    ERC20 public token;
    Vault public vault;

    mapping(address => uint256) attemptedDungeon;

    modifier ActiveDungeonOnly(uint256 _id){
        require(dungeons[_id].status != DungeonStatus.Completed, "Dungeon is already completed");
        _;
    }

    constructor(ERC20 _token, Vault _vault, uint256 _dungeonEntryFee) {
        token = _token;
        vault = _vault;
        dungeonEntryFee = _dungeonEntryFee;
    }

    function createDungeon(string memory _name, uint256 _reward, uint256 _key) external {
        require(_reward > 0, "Reward must be greater than 0");
        require(token.balanceOf(msg.sender) >= _reward, "Insufficient token balance");

        uint256 dungeonId = dungeons.length;
        dungeons.push(Dungeon(_name, _reward, dungeonId, DungeonStatus.InComplete, _key, msg.sender));

        // token.transferFrom(msg.sender, address(vault), _reward);

        token.approve(address(this), _reward);
    }

    function attemptDungeon(uint256 _dungeonId) external ActiveDungeonOnly(_dungeonId) {
        require(_dungeonId < dungeons.length, "Invalid dungeon ID");
        require(token.balanceOf(msg.sender) >= dungeonEntryFee, "Insufficient attempt fee");

        token.approve(address(this), dungeonEntryFee);
        token.transferFrom(msg.sender, dungeons[_dungeonId].owner, dungeonEntryFee);
        attemptedDungeon[msg.sender] = _dungeonId;
    }

    function finishDungeon(uint256 _dungeonId, uint256 _key) external {
        require(_dungeonId < dungeons.length, "Invalid dungeon ID");
        require(dungeons[_dungeonId].status != DungeonStatus.Completed, "Dungeon is not completed");
        require(_dungeonId == attemptedDungeon[msg.sender], "you haven't attempted this dungeon");

        if (dungeons[_dungeonId].key == _key) {
            // vault.withdraw(dungeons[_dungeonId].reward);
            token.transferFrom(dungeons[_dungeonId].owner, msg.sender, dungeons[_dungeonId].reward);
        }
    }
}