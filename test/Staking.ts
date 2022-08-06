import {ethers} from "hardhat";
import {expect} from "chai";
import { setTimeout } from "timers/promises";

describe("Token contract", function () {
    it('Stake', async () => {
        const [owner, addr1] = await ethers.getSigners();

        const tokenFactoryErc20LP = await ethers.getContractFactory("ERC20");
        const tokenErc20LP = await tokenFactoryErc20LP.deploy("LP", "LP", 0);
        console.log("Token ERC20 LP address:", tokenErc20LP.address);

        const tokenFactoryErc20 = await ethers.getContractFactory("ERC20");
        const tokenErc20 = await tokenFactoryErc20.deploy("S", "S", 10);
        console.log("Token simple ERC20 address:", tokenErc20.address);

        const tokenFactoryStaking = await ethers.getContractFactory("Staking");
        const tokenStaking = await tokenFactoryStaking.deploy(tokenErc20LP.address, tokenErc20.address, owner.address);
        console.log("Token staking address:", tokenStaking.address);

        await tokenErc20LP.transfer(addr1.address, 1000);
        await tokenErc20LP.connect(addr1).approve(tokenStaking.address, 1000);
        await tokenStaking.connect(addr1).stake(50);

        tokenStaking.setStakingFreezeInSeconds(1);
        let balanceAddr1 = await tokenErc20LP.balanceOf(addr1.address);
        expect(950).to.equal(balanceAddr1);
        let balanceStaking = await tokenErc20LP.balanceOf(tokenStaking.address);
        expect(50).to.equal(balanceStaking);

        console.log("addr1", addr1.address);
        await tokenStaking.connect(addr1).unstake();

        balanceAddr1 = await tokenErc20.balanceOf(addr1.address);
        console.log("balanceAddr1", balanceAddr1);
    });

    it('Unstake', async () => {
        const [owner, addr1] = await ethers.getSigners();

        const tokenFactoryErc20LP = await ethers.getContractFactory("ERC20");
        const tokenErc20LP = await tokenFactoryErc20LP.deploy("LP", "LP", 0);
        console.log("Token ERC20 LP address:", tokenErc20LP.address);
        await tokenErc20LP.mint(500000000);

        const tokenFactoryErc20 = await ethers.getContractFactory("ERC20");
        const tokenErc20 = await tokenFactoryErc20.deploy("S", "S", 10);
        console.log("Token simple ERC20 address:", tokenErc20.address);
        await tokenErc20.mint(500000000);

        const tokenFactoryStaking = await ethers.getContractFactory("Staking");
        const tokenStaking = await tokenFactoryStaking.deploy(tokenErc20LP.address, tokenErc20.address, owner.address);
        console.log("Token staking address:", tokenStaking.address);

        await tokenErc20LP.transfer(addr1.address, 1000000);
        await tokenErc20LP.connect(addr1).approve(tokenStaking.address, 1000000);
        await tokenStaking.connect(addr1).stake(1000000);

        tokenStaking.setStakingFreezeInSeconds(5);
        await setTimeout(7000);

        let balanceAddr1 = await tokenErc20LP.balanceOf(addr1.address);
        expect(0).to.equal(balanceAddr1);
        let balanceStaking = await tokenErc20LP.balanceOf(tokenStaking.address);
        expect(1000000).to.equal(balanceStaking);

        console.log("addr1", addr1.address);
        await tokenStaking.connect(addr1).unstake();

        balanceAddr1 = await tokenErc20.balanceOf(addr1.address);
        console.log("balanceAddr1", balanceAddr1);
    });

    it('Claim', async () => {
        const [owner, addr1] = await ethers.getSigners();

        const tokenFactoryErc20LP = await ethers.getContractFactory("ERC20");
        const tokenErc20LP = await tokenFactoryErc20LP.deploy("LP", "LP", 0);
        console.log("Token ERC20 LP address:", tokenErc20LP.address);
        await tokenErc20LP.mint(500000000);

        const tokenFactoryErc20 = await ethers.getContractFactory("ERC20");
        const tokenErc20 = await tokenFactoryErc20.deploy("S", "S", 10);
        console.log("Token simple ERC20 address:", tokenErc20.address);
        await tokenErc20.mint(5000000000);

        const tokenFactoryStaking = await ethers.getContractFactory("Staking");
        const tokenStaking = await tokenFactoryStaking.deploy(tokenErc20LP.address, tokenErc20.address, owner.address);
        console.log("Token staking address:", tokenStaking.address);

        await tokenErc20.transfer(tokenStaking.address, 5000000000);

        await tokenErc20LP.transfer(addr1.address, 1000000);
        await tokenErc20LP.connect(addr1).approve(tokenStaking.address, 1000000);
        await tokenStaking.connect(addr1).stake(1000000);

        tokenStaking.setStakingFreezeInSeconds(5);
        await setTimeout(7000);

        let balanceAddr1 = await tokenErc20LP.balanceOf(addr1.address);
        expect(0).to.equal(balanceAddr1);
        let balanceStaking = await tokenErc20LP.balanceOf(tokenStaking.address);
        expect(1000000).to.equal(balanceStaking);

        console.log("addr1", addr1.address);
        await tokenStaking.connect(addr1).unstake();

        balanceAddr1 = await tokenErc20.balanceOf(addr1.address);
        console.log("balanceAddr1", balanceAddr1);

        console.log("addr1", addr1.address);
        await tokenStaking.connect(addr1).claim();
        balanceAddr1 = await tokenErc20.balanceOf(addr1.address);
        console.log("balanceAddr1balanceAddr1balanceAddr1", balanceAddr1);
    });
});
