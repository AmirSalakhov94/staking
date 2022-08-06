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
        uint256 amount;
        uint256 time;
    }

    mapping(address => Item) private _balancesStakingItem;
    mapping(address => Item) private _balancesRewardItem;

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
        require(amount > 0, "amount = 0");

        _staking(amount);
        Item memory itemStaking = _balancesStakingItem[msg.sender];
        uint256 currentStakingAmount = itemStaking.amount - amount;
        _reward(currentStakingAmount);
    }

    function _reward(uint256 amount) internal virtual {
        Item memory itemReward = _balancesRewardItem[msg.sender];
        if (itemReward.user != address(0x0)) {
            uint256 rewardAmount = itemReward.amount;
            uint256 currentTime = block.timestamp;
            uint256 diffSec = currentTime - itemReward.time;
            uint256 amountByPercent = _calculateAmountByPercent(amount, diffSec);
            rewardAmount = rewardAmount + amountByPercent;
            itemReward.time = currentTime;
            itemReward.amount = rewardAmount;
            _balancesRewardItem[msg.sender] = itemReward;
        } else {
            itemReward = Item(
                msg.sender,
                0,
                block.timestamp
            );
            _balancesRewardItem[msg.sender] = itemReward;
        }
        console.log("itemReward amount", itemReward.amount);
    }

    function _staking(uint256 amount) internal virtual {
        Item memory itemStaking = _balancesStakingItem[msg.sender];
        if (itemStaking.user != address(0x0)) {
            itemStaking.amount += amount;
            itemStaking.time = block.timestamp;
            _balancesStakingItem[msg.sender] = itemStaking;
        } else {
            itemStaking = Item(
                msg.sender,
                amount,
                block.timestamp
            );
            _balancesStakingItem[msg.sender] = itemStaking;
        }

        stakingToken.transferFrom(itemStaking.user, address(this), itemStaking.amount);
        console.log("itemStaking amount", itemStaking.amount);
    }

    function claim() public {
        address user = msg.sender;
        console.log("user user", user);
        Item memory itemStaking = _balancesStakingItem[user];
        console.log("itemStaking itemStaking", itemStaking.user);
        if (itemStaking.user != address(0x0)) {
            _reward(itemStaking.amount);
            console.log("itemStaking1 amount", itemStaking.amount);
            Item memory itemReward = _balancesRewardItem[user];
            if (itemReward.user != address(0x0) && itemReward.amount > 0) {
                rewardToken.transfer(itemReward.user, itemReward.amount);
                itemReward.amount = 0;
                _balancesRewardItem[user] = itemReward;
            }
        }
    }

    function _calculateAmountByPercent(uint256 amount, uint256 second) internal view virtual returns (uint256) {
        amount = amount * 1e10;
        uint256 f = (percentInYear * 1e10 / 100) / (365 * 24 * 3600);
        return amount * f * second / 1e10;
    }

    function unstake() public {
        address user = msg.sender;
        Item memory itemStaking = _balancesStakingItem[user];
        require(itemStaking.amount > 0, "Staking amount is empty");
        require(block.timestamp - itemStaking.time > _stakingFreezeOfSeconds, "No time passed");

        _reward(itemStaking.amount);
        Item memory itemReward = _balancesRewardItem[user];
        if (itemReward.user != address(0x0) && itemReward.amount > 0) {
            console.log("itemReward1111 amount", itemReward.amount);
            rewardToken.transfer(itemReward.user, itemReward.amount);
            itemReward.amount = 0;
            _balancesRewardItem[user] = itemReward;
        }

        stakingToken.transfer(user, itemStaking.amount);
        delete _balancesStakingItem[user];
    }
}
