// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

// Import this file to use console.log
import "@openzeppelin/contracts/access/AccessControl.sol";
import "hardhat/console.sol";
import "./ERC20.sol";

contract Staking is AccessControl {

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint256 public immutable percentInYear = 20;
    ERC20 public immutable stakingToken;
    ERC20 public immutable rewardToken;

    struct Item {
        address user;
        uint256 stakingAmount;
        uint256 lastStakingTime;
        uint256 rewardAmount;
        uint256 lastRewardTime;
    }

    mapping(address => Item) private _balancesItem;
    uint256 private _stakingFreezeOfSeconds;

    constructor(address stakingToken_, address rewardToken_, address admin_) {
        stakingToken = ERC20(stakingToken_);
        rewardToken = ERC20(rewardToken_);
        _setupRole(ADMIN_ROLE, admin_);
        _stakingFreezeOfSeconds = 20 * 60 * 1000;
    }

    function setStakingFreezeInSeconds(uint256 numberOfSeconds) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not a admin");
        _stakingFreezeOfSeconds = numberOfSeconds;
    }

    function stake(uint256 amount) public {
        require(amount > 0, "amount is low than 0");

        _reward();
        _staking(amount);
    }

    function _reward() internal virtual {
        Item memory item = _balancesItem[msg.sender];
        if (item.user != address(0x0)) {
            uint256 currentStakingAmount = item.stakingAmount;
            uint256 rewardAmount = item.rewardAmount;
            uint256 currentTime = block.timestamp;
            uint256 diffSec = currentTime - item.lastRewardTime;
            uint256 amountByPercent = _calculateAmountByPercent(currentStakingAmount, diffSec);
            item.rewardAmount = rewardAmount + amountByPercent;
            item.lastRewardTime = block.timestamp;
            _balancesItem[msg.sender] = item;
        }
    }

    function _calculateAmountByPercent(uint256 amount, uint256 second) internal view virtual returns (uint256) {
        if (amount == 0)
            return 0;

        amount = amount * 1e10;
        uint256 f = (percentInYear * 1e10 / 100) / (365 * 24 * 3600);
        return amount * f * second / 1e10;
    }

    function _staking(uint256 amount) internal virtual {
        Item memory item = _balancesItem[msg.sender];
        if (item.user != address(0x0)) {
            item.stakingAmount += amount;
            item.lastStakingTime = block.timestamp;
            _balancesItem[msg.sender] = item;
        } else {
            item = Item(
                msg.sender,
                amount,
                block.timestamp,
                0,
                block.timestamp
            );
            _balancesItem[msg.sender] = item;
        }

        stakingToken.transferFrom(item.user, address(this), item.stakingAmount);
        console.log("itemStaking amount", item.stakingAmount);
    }

    function claim() public {
        address user = msg.sender;
        Item memory item = _balancesItem[user];
        if (item.user != address(0x0)) {
            _reward();
            rewardToken.transfer(item.user, item.rewardAmount);
            item.rewardAmount = 0;
            _balancesItem[user] = item;
        }
    }

    function unstake() public {
        address user = msg.sender;
        Item memory item = _balancesItem[user];
        require(item.user != address(0x0), "No user staking token");
        require(item.stakingAmount > 0, "Staking amount is empty");
        require(block.timestamp - item.lastStakingTime > _stakingFreezeOfSeconds, "No time passed");

        _reward();

        stakingToken.transfer(user, item.stakingAmount);
        item.stakingAmount = 0;
        item.lastStakingTime = 0;
    }
}
