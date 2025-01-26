const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");


describe("BalancerHelper", () => {

    async function deploy() {

        const [keeper, admin] = await ethers.getSigners();

        const Multisig = await ethers.getContractFactory("GnosisSafe");
        const multisig = await Multisig.deploy();
        await multisig.waitForDeployment();

        const AaveCont = await ethers.getContractFactory("DirectContingency");
        const aaveCont = await AaveCont.deploy(await multisig.getAddress(), keeper.address, admin.address);
        await aaveCont.waitForDeployment();

        const BalancerHelper = await ethers.getContractFactory("BalancerHelper");
        const balancerHelper = await BalancerHelper.deploy(
            keeper.address, await multisig.getAddress()
        );
        await balancerHelper.waitForDeployment();

        const addresses: string [] = [
            await multisig.getAddress(),
            await balancerHelper.getAddress(),
            await aaveCont.getAddress()
        ]

        await balancerHelper.connect(keeper).addPools(addresses);

        return{
            addresses, keeper, multisig, balancerHelper
        }
    }

    it("1. Should deploy the contract & populate the pools", async () => {

        const {balancerHelper, addresses} = await loadFixture(deploy);

        const poolCount: bigint = await balancerHelper.poolCount();
        expect(Number(poolCount.toString())).to.equal(addresses.length);

        const pools = await balancerHelper.getPools(0,3);
        expect(pools).to.deep.equal(addresses)

    });

    it("2. Should correctly delete the first pool", async () => {
        const {balancerHelper, keeper, addresses} = await loadFixture(deploy);

        await balancerHelper.connect(keeper).deletePool(0);

        const poolCount: bigint = await balancerHelper.poolCount();
        expect(Number(poolCount.toString())).to.equal(addresses.length - 1);

        const pools = await balancerHelper.getPools(0,3);
        expect(!pools.includes(addresses[0]))

    });

    it("3. Should correctly delete a pool in the middle", async () => {
        const {balancerHelper, keeper, addresses} = await loadFixture(deploy);

        await balancerHelper.connect(keeper).deletePool(1);

        const poolCount: bigint = await balancerHelper.poolCount();
        expect(Number(poolCount.toString())).to.equal(addresses.length - 1);

        const pools = await balancerHelper.getPools(0,3);
        expect(!pools.includes(addresses[1]))

    });

    it("4. Should correctly delete the last pool", async () => {
        const {balancerHelper, keeper, addresses} = await loadFixture(deploy);

        await balancerHelper.connect(keeper).deletePool(2);

        const poolCount: bigint = await balancerHelper.poolCount();
        expect(Number(poolCount.toString())).to.equal(addresses.length - 1);

        const pools = await balancerHelper.getPools(0,3);
        expect(!pools.includes(addresses[2]))

    });

});