import {ethers} from "hardhat";

async function main() {
    const tokenFactoryErc20LP = await ethers.getContractFactory("ERC20");
    const tokenErc20LP = await tokenFactoryErc20LP.deploy("LP", "LP", 0);
    console.log("Token ERC20 LP address:", tokenErc20LP.address);

    const tokenFactoryErc20 = await ethers.getContractFactory("ERC20");
    const tokenErc20 = await tokenFactoryErc20.deploy("S", "S", 10);
    console.log("Token simple ERC20 address:", tokenErc20.address);

    const [owner] = await ethers.getSigners();

    const tokenFactoryStaking = await ethers.getContractFactory("Staking");
    const tokenStaking = await tokenFactoryStaking.deploy(tokenErc20LP.address, tokenErc20.address, owner.address);
    console.log("Token staking address:", tokenStaking.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
