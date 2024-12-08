import hre, { ethers } from "hardhat";
import { readENV, sleep } from './utils';
import { ContractFactory } from 'ethers';

export async function estimateGasFee(factory: ContractFactory, params: any[]) {
    // Create deployment transaction
    const deployTransaction = await factory.getDeployTransaction(...params);

    // Estimate the gas for the deployment
    const estimatedGas = await ethers.provider.estimateGas(deployTransaction);

    // Get current gas price settings
    const { maxFeePerGas, maxPriorityFeePerGas } = await ethers.provider.getFeeData();

    // Calculate total estimated gas cost
    const estimatedTotalFee = estimatedGas * maxFeePerGas!;

    console.log(`Estimated gas cost: ${ethers.formatUnits(estimatedTotalFee, "ether")} ETH`);
}

async function main() {

    // npx hardhat run ./scripts/deploy_BalancerHelper.ts --network ...

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

}

main()
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
