import hre, { ethers } from "hardhat";
import { readENV, sleep } from './utils';
import { ContractFactory } from 'ethers';
import { estimateGasFee } from "./estimate";

async function main() {

    // npx hardhat run ./scripts/deploy.ts --network ...

    const BH_KEEPER: string = readENV("BH_KEEPER");
    const BH_SAFE = readENV("BH_SAFE");

    const contractName: string = "BalancerHelper";

    console.log(`Deploying ${contractName} contract...\n`);

    const factory: ContractFactory = await ethers.getContractFactory(contractName);

    const params = [
        BH_KEEPER,
        BH_SAFE,
    ];

    await estimateGasFee(factory, params);

    const contract = await factory.deploy(...params);
    await contract.waitForDeployment();

    console.log(`${contractName} is deployed to:`, contract.target, "\n");

    // Verifying the contract
    console.log("Waiting for block confirmations...\n");
    await sleep(40_000); // 40 seconds

    console.log("Verifying the contract on Etherscan...\n");

    await hre.run("verify:verify", {
        address: contract.target,
        constructorArguments: params,
    });

    console.log(`${contractName} contract verified.\n`);

}

main()
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
