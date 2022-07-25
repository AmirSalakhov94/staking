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

    uint256 private _stakingFreezeOfMilliseconds;

    constructor(address stakingToken_, address rewardToken_, address admin_) {
        stakingToken = ERC20(stakingToken_);
        rewardToken = ERC20(rewardToken_);
        _setupRole(ADMIN_ROLE, admin_);
        _stakingFreezeOfMilliseconds = 20 * 60 * 1000;
    }

    function setStakingFreezeInMinutes(uint numberOfMinutes) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not a admin");
        _stakingFreezeOfMilliseconds = numberOfMinutes * 60 * 1000;
    }

    function stake(uint256 amount) public {
        require(amount > 0, "amount = 0");

        ItemReward memory itemReward = _balancesRewardItem[msg.sender];
        if (itemReward.user != address(0x0)) {
            uint256 currentTime = block.timestamp;
            uint256 diffSec = currentTime - itemReward.enrollmentTime;
            uint256 amountWithPercent = _calculateAmountByPercent(itemReward.amount, diffSec);
            uint256 newAmount = amountWithPercent + amount;
            itemReward.amount = newAmount;
            itemReward.enrollmentTime = currentTime;
        } else {
            itemReward = ItemReward(
                msg.sender,
                amount,
                block.timestamp
            );
            _balancesRewardItem[msg.sender] = itemReward;
        }

        ItemStaking memory itemStaking = _balancesStakingItem[msg.sender];
        if (itemStaking.user != address(0x0)) {
            stakingToken.transferFrom(itemReward.user, address(this), amount);
            itemStaking.amount += amount;
            itemStaking.time = block.timestamp;
        }
    }

    function claim() public {
        address user = msg.sender;
        ItemReward memory itemReward = _balancesRewardItem[user];
        if (itemReward.user != address(0x0) && itemReward.amount > 0) {
            rewardToken.transfer(itemReward.user, itemReward.amount);
            delete _balancesRewardItem[user];
        }
    }

    function unstake() public {
        ItemStaking memory itemStaking = _balancesStakingItem[msg.sender];
        require(itemStaking.amount > 0, "Staking amount is empty");
        require(block.timestamp - itemStaking.time > _stakingFreezeOfMilliseconds, "No time passed");

        stakingToken.transfer(msg.sender, itemStaking.amount);
    }

    function _calculateAmountByPercent(uint256 amount, uint256 second) internal view virtual returns (uint256) {
        return amount * (1 + ((percentInYear / 100) / 365 * 24 * 3600)) ** second;
    }
}
