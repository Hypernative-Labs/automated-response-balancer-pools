const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");


describe("BalancerHelper", () => {

    async function deploy() {

        const [keeper, admin] = await ethers.getSigners();

        const Multisig = await ethers.getContractFactory("GnosisSafe");
        const multisig = await Multisig.deploy();
        await multisig.waitForDeployment();

        const MockPool = await ethers.getContractFactory("MockPool");
        const mockPool1 = await MockPool.deploy();
        await mockPool1.waitForDeployment();

        const mockPool2 = await MockPool.deploy();
        await mockPool2.waitForDeployment();

        const BalancerHelper = await ethers.getContractFactory("BalancerHelper");
        const balancerHelper = await BalancerHelper.deploy(
            keeper.address, await multisig.getAddress()
        );
        await balancerHelper.waitForDeployment();

        const addresses: string[] = [
            await multisig.getAddress(),
            await balancerHelper.getAddress(),
            await mockPool1.getAddress(),
            await mockPool2.getAddress()
        ]

        await balancerHelper.connect(keeper).addPools(addresses);

        return {
            addresses, keeper, multisig, balancerHelper
        }
    }

    async function deploy1() {

        const [keeper, admin] = await ethers.getSigners();

        const Multisig = await ethers.getContractFactory("GnosisSafe");
        const multisig = await Multisig.deploy();
        await multisig.waitForDeployment();

        const MockPool = await ethers.getContractFactory("MockPool");
        const mockPool1 = await MockPool.deploy();
        await mockPool1.waitForDeployment();

        const mockPool2 = await MockPool.deploy();
        await mockPool2.waitForDeployment();

        const BalancerHelper = await ethers.getContractFactory("BalancerHelper");
        const balancerHelper = await BalancerHelper.deploy(
            keeper.address, await multisig.getAddress()
        );
        await balancerHelper.waitForDeployment();

        const addresses: string[] = [
            await mockPool1.getAddress()
        ]

        await balancerHelper.connect(keeper).addPools(addresses);

        return {
            addresses, keeper, multisig, balancerHelper
        }
    }

    it("1. Should deploy the contract & populate the pools", async () => {

        const { balancerHelper, addresses } = await loadFixture(deploy);

        const poolCount: bigint = await balancerHelper.poolCount();
        expect(Number(poolCount.toString())).to.equal(addresses.length);

        const pools = await balancerHelper.getPools(0, 4);
        expect(pools).to.deep.equal(addresses)

    });

    it("2. should delete the one and the only pool", async () => {
        const { balancerHelper, keeper, addresses } = await loadFixture(deploy1);

        var poolCount: bigint = await balancerHelper.poolCount();
        console.log("poolcount %s", poolCount.toString());
        expect(Number(poolCount.toString())).to.equal(1);

        await balancerHelper.connect(keeper).deletePool(0);

        poolCount = await balancerHelper.poolCount();
        expect(Number(poolCount.toString())).to.equal(0);
        expect(Number(poolCount.toString())).to.equal(addresses.length - 1);
    });


    it("3. Should correctly delete the first pool", async () => {
        const { balancerHelper, keeper, addresses } = await loadFixture(deploy);

        await balancerHelper.connect(keeper).deletePool(0);

        const poolCount: bigint = await balancerHelper.poolCount();
        expect(Number(poolCount.toString())).to.equal(addresses.length - 1);

        const pools = await balancerHelper.getPools(0, 2);
        expect(!pools.includes(addresses[0]))

    });

    it("3. Should correctly delete a pool in the middle", async () => {
        const { balancerHelper, keeper, addresses } = await loadFixture(deploy);

        await balancerHelper.connect(keeper).deletePool(1);

        const poolCount: bigint = await balancerHelper.poolCount();
        expect(Number(poolCount.toString())).to.equal(addresses.length - 1);

        const pools = await balancerHelper.getPools(0, 2);
        expect(!pools.includes(addresses[1]))

    });

    it("4. Should correctly delete the last pool", async () => {
        const { balancerHelper, keeper, addresses } = await loadFixture(deploy);

        await balancerHelper.connect(keeper).deletePool(2);

        const poolCount: bigint = await balancerHelper.poolCount();
        expect(Number(poolCount.toString())).to.equal(addresses.length - 1);

        const pools = await balancerHelper.getPools(0, 2);
        expect(!pools.includes(addresses[2]))

    });

    it("5. Should delete a range of pools", async () => {

        const { balancerHelper, keeper, addresses } = await loadFixture(deploy);

        var poolCount = await balancerHelper.poolCount();
        expect(Number(poolCount.toString())).to.equal(addresses.length);
         
        var pools = await balancerHelper.getPools(0, 10);
        console.log("pools %s", pools);
        await balancerHelper.connect(keeper).deletePools(0, 3);

        poolCount = await balancerHelper.poolCount();
        console.log("poolcount %s", poolCount.toString());
        //expect(poolCount).to.equal(0n);
        pools = await balancerHelper.getPools(0, 10);
        console.log("pools %s", pools);
    });

});