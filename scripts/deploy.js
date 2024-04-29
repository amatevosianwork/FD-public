const hre = require("hardhat");
const { ethers, upgrades } = require("hardhat");

async function main() {
    let [theDefaultDeployer] = await hre.ethers.getSigners();

    console.log('Deployer is: ', theDefaultDeployer.address)
    console.log('Deploying Registry...')
    const RegistryContract = await ethers.getContractFactory("FooDriverRegistry");
    const registryContract = await upgrades.deployProxy(RegistryContract);
    await registryContract.waitForDeployment();

    console.log('Registry deployed at', registryContract.target)
    console.log('Deploying Factory...')
    const FactoryContract = await ethers.getContractFactory("FooDriverFactory");
    const factoryContract = await upgrades.deployProxy(FactoryContract, [registryContract.target]);
    await factoryContract.waitForDeployment();
    console.log('Factory deployed at', factoryContract.target)
    await registryContract.setFactory(factoryContract.target)
    console.log('Deploying Token...')
    const TokenContract = await ethers.getContractFactory("FooDriverToken");
    const tokenContract = await upgrades.deployProxy(TokenContract, [theDefaultDeployer.address]);
    await tokenContract.waitForDeployment();
    console.log('Token deployed at', tokenContract.target)
    await registryContract.setToken(tokenContract.target)
    console.log('Registry initialized the Token')
    console.log('Deploying Bank...')
    const BankContract = await ethers.getContractFactory("FooDriverBank");
    const bankContract = await upgrades.deployProxy(BankContract, [registryContract.target, tokenContract.target, "COMMISSION_WALLET"]);
    await bankContract.waitForDeployment();
    console.log('Bank deployed at', bankContract.target)
    await registryContract.setBank(bankContract.target)
    console.log('Registry initialized the Bank')
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
