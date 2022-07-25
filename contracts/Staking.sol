// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

// Import this file to use console.log
import "hardhat/console.sol";
import "./ERC20.sol";

contract Staking {

    uint256 public immutable percentInYear = 20;
    ERC20 public immutable stakingToken;
    ERC20 public immutable rewardToken;

    struct ItemReward {
        address user;
        uint256 amount;
        uint256 enrollmentTime;
    }

    struct ItemStaking {
        address user;
        uint256 amount;
        uint256 time;
    }

    mapping(address => ItemStaking) private _balancesStakingItem;
    mapping(address => ItemReward) private _balancesRewardItem;
    address private _admin;

    uint256 private _stakingFreezeOfMilliseconds;

    constructor(address stakingToken_, address rewardToken_, address admin_) {
        stakingToken = ERC20(stakingToken_);
        rewardToken = ERC20(rewardToken_);
        _admin = admin_;
        _stakingFreezeOfMilliseconds = 20 * 60 * 1000;
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin, "Not authorized");
        _;
    }

    function setStakingFreezeInMinutes(uint numberOfMinutes) external onlyAdmin {
        _stakingFreezeOfMilliseconds = numberOfMinutes * 60 * 1000;
    }

    function stake(uint256 amount) public {
        require(amount > 0, "amount = 0");

        ItemReward itemReward = _balancesRewardItem[msg.sender];
        if (itemReward != 0) {
            uint256 currentTime = block.timestamp;
            uint256 diffSec = currentTime - itemReward.enrollmentTime;
            uint256 amountWithPercent = _calculateAmountByPercent(itemReward.amount, diffSec);
            uint256 newAmount = amountWithPercent + amount;
            itemReward.amount = newAmount;
            itemReward.enrollmentTime = currentTime;
        } else {
            itemReward = Item(
                msg.sender,
                amount,
                block.timestamp
            );
            _balancesRewardItem[msg.sender] = itemReward;
        }

        ItemStaking itemStaking = _balancesStakingItem[msg.sender];
        if (itemStaking != 0) {
            stakingToken.transferFrom(itemReward.user, address(this), amount);
            itemStaking.amount += amount;
            itemStaking.time = block.timestamp;
        }
    }

    function claim() public {
        address user = msg.sender;
        ItemReward itemReward = _balancesRewardItem[user];
        if (itemReward != 0 && itemReward.amount > 0) {
            rewardToken.transfer(itemReward.user, itemReward.amount);
            delete _itemsMarketAuction[user];
        }
    }

    function unstake() public {
        ItemStaking itemStaking = _balancesStakingItem[msg.sender];
        require(block.timestamp - itemStaking.time > _stakingFreezeOfMilliseconds, "No time passed");

        if (itemStaking.amount > 0 && itemStaking.time) {
            stakingToken.transfer(msg.sender, itemStaking.amount);
        }
    }

    function _calculateAmountByPercent(uint256 amount, uint256 second) internal view virtual returns (uint256) {
        return amount * (1 + ((percentInYear / 100) / 365 * 24 * 3600)) ** second;
    }
}
