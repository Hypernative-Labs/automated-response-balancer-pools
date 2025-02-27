const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");

const zeroAddress = "0x0000000000000000000000000000000000000000";

describe("BalancerHelper", () => {
    async function deploy() {
        var poolNonce = 0;

        const [owner, keeper, user] = await ethers.getSigners();

        const Vault = await ethers.getContractFactory("MockVault");
        const vault = await Vault.deploy();
        await vault.waitForDeployment();

        const Multisig = await ethers.getContractFactory("GnosisSafeL2");
        const multisig = await Multisig.deploy();
        await multisig.waitForDeployment();

        const MockPool = await ethers.getContractFactory("MockPool");
        const mockPool1 = await MockPool.deploy();
        await mockPool1.waitForDeployment();
        await vault.registerPool(await mockPool1.getAddress(), 0);

        const mockPool2 = await MockPool.deploy();
        await mockPool2.waitForDeployment();
        await vault.registerPool(await mockPool2.getAddress(), 0);

        const mockPool3 = await MockPool.deploy();
        await mockPool3.waitForDeployment();
        await vault.registerPool(await mockPool3.getAddress(), 0);

        const mockPool4 = await MockPool.deploy();
        await mockPool4.waitForDeployment();
        await vault.registerPool(await mockPool4.getAddress(), 0);


        const BalancerHelper = await ethers.getContractFactory("BalancerHelper");
        const balancerHelper = await BalancerHelper.deploy(vault.getAddress(),
            keeper.address, await multisig.getAddress()
        );
        await balancerHelper.waitForDeployment();

        
        const addresses: string[] = [
            await mockPool1.getAddress(),
            await mockPool2.getAddress(),
            await mockPool3.getAddress(),
            await mockPool4.getAddress()
        ]

        const poolIds: string[] = [
            await vault._toPoolId(await mockPool1.getAddress(), 0, 0),
            await vault._toPoolId(await mockPool2.getAddress(), 0, 1),
            await vault._toPoolId(await mockPool3.getAddress(), 0, 2),
            await vault._toPoolId(await mockPool4.getAddress(), 0, 3)
        ]

        await balancerHelper.connect(keeper).addPools(poolIds.slice(0,3));

        await balancerHelper.connect(keeper).addPool(poolIds[3]);

        return {
            addresses, keeper, multisig, balancerHelper, owner,
            mockPool1, user, poolIds
        }
    }

    async function deploy1() {

        const [keeper] = await ethers.getSigners();

        const Multisig = await ethers.getContractFactory("GnosisSafe");
        const multisig = await Multisig.deploy();
        await multisig.waitForDeployment();

        const MockPool = await ethers.getContractFactory("MockPool");
        const mockPool1 = await MockPool.deploy();
        await mockPool1.waitForDeployment();


        const Vault = await ethers.getContractFactory("MockVault");
        const vault = await Vault.deploy();
        await vault.waitForDeployment();
        await vault.registerPool(await mockPool1.getAddress(), 0);

        const BalancerHelper = await ethers.getContractFactory("BalancerHelper");
        const balancerHelper = await BalancerHelper.deploy(
            vault.getAddress(),
            keeper.address, 
            await multisig.getAddress()
        );
        await balancerHelper.waitForDeployment();

        const addresses: string[] = [
            await mockPool1.getAddress(),
        ]

        const poolIds: string[] = [
            await vault._toPoolId(await mockPool1.getAddress(), 0, 0),
        ]

        await balancerHelper.connect(keeper).addPools(poolIds);

        return {
            addresses, keeper, multisig, balancerHelper, BalancerHelper, vault,
        }
    }

    async function deploy2() {

        const [owner, keeper] = await ethers.getSigners();

        const Multisig = await ethers.getContractFactory("MockSafe");
        const multisig = await Multisig.deploy(owner.address);
        await multisig.waitForDeployment();
        const multisigWithSigner = multisig.connect(owner);

        const Vault = await ethers.getContractFactory("MockVault");
        const vault = await Vault.deploy();
        await vault.waitForDeployment();
        
        const MockPool = await ethers.getContractFactory("MockPool");
        const mockPool1 = await MockPool.deploy();
        await mockPool1.waitForDeployment();
        await vault.registerPool(await mockPool1.getAddress(), 0);

        const BalancerHelper = await ethers.getContractFactory("BalancerHelper");
        const balancerHelper = await BalancerHelper.deploy(
            vault.getAddress(),
            keeper.address, 
            await multisig.getAddress()
        );
        await balancerHelper.waitForDeployment();

        const balancerHelperAddress = await balancerHelper.getAddress();

        await multisigWithSigner.setModule(balancerHelperAddress);

        const mockPool2 = await MockPool.deploy();
        await mockPool2.waitForDeployment();
        await vault.registerPool(await mockPool2.getAddress(), 0);

        const mockPool3 = await MockPool.deploy();
        await mockPool3.waitForDeployment();
        await vault.registerPool(await mockPool3.getAddress(), 0);

        const mockPool4 = await MockPool.deploy();
        await mockPool4.waitForDeployment();
        await vault.registerPool(await mockPool4.getAddress(), 0);

        const addresses: string[] = [
            await mockPool1.getAddress(),
            await mockPool2.getAddress(),
            await mockPool3.getAddress(),
            await mockPool4.getAddress()
        ]

        const poolIds: string[] = [
            await vault._toPoolId(await mockPool1.getAddress(), 0, 0),
            await vault._toPoolId(await mockPool2.getAddress(), 0, 1),
            await vault._toPoolId(await mockPool3.getAddress(), 0, 2),
            await vault._toPoolId(await mockPool4.getAddress(), 0, 3)
        ]

        await balancerHelper.connect(keeper).addPools(poolIds);

        return {
            addresses, keeper, multisig, balancerHelper, BalancerHelper, vault, multisigWithSigner, poolIds
        }
    }

    it("1. Should deploy the contract & populate the pools", async () => {

        const { balancerHelper, addresses } = await loadFixture(deploy);
        // console.log("addresses %s", addresses);

        const poolCount: bigint = await balancerHelper.poolsLength();
        expect(Number(poolCount.toString())).to.equal(addresses.length);

        const pools = await balancerHelper.getPools(0, 4);
        expect(pools).to.deep.equal(addresses)

    });

    it("2. should delete the one and the only pool", async () => {
        const { balancerHelper, keeper, addresses } = await loadFixture(deploy1);

        var poolCount: bigint = await balancerHelper.poolsLength();
        // console.log("poolcount %s", poolCount.toString());
        expect(Number(poolCount.toString())).to.equal(1);

        await balancerHelper.connect(keeper).deletePool(0);

        poolCount = await balancerHelper.poolsLength();
        expect(Number(poolCount.toString())).to.equal(0);
        expect(Number(poolCount.toString())).to.equal(addresses.length - 1);
    });


    it("3. Should correctly delete the first pool", async () => {
        const { balancerHelper, keeper, addresses } = await loadFixture(deploy);

        await balancerHelper.connect(keeper).deletePool(0);

        const poolCount: bigint = await balancerHelper.poolsLength();
        expect(Number(poolCount.toString())).to.equal(addresses.length - 1);

        const pools = await balancerHelper.getPools(0, 2);
        expect(!pools.includes(addresses[0]))

    });

    it("4. Should correctly delete a pool in the middle", async () => {
        const { balancerHelper, keeper, addresses } = await loadFixture(deploy);

        await balancerHelper.connect(keeper).deletePool(1);

        const poolCount: bigint = await balancerHelper.poolsLength();
        expect(Number(poolCount.toString())).to.equal(addresses.length - 1);

        const pools = await balancerHelper.getPools(0, 2);
        expect(!pools.includes(addresses[1]))

    });

    it("5. Should correctly delete the last pool", async () => {
        const { balancerHelper, keeper, addresses } = await loadFixture(deploy);

        await balancerHelper.connect(keeper).deletePool(2);

        const poolCount: bigint = await balancerHelper.poolsLength();
        expect(Number(poolCount.toString())).to.equal(addresses.length - 1);

        const pools = await balancerHelper.getPools(0, 2);
        expect(!pools.includes(addresses[2]))

    });

    it("6. Should delete a range of pools", async () => {

        const { balancerHelper, keeper, addresses } = await loadFixture(deploy);

        var poolCount = await balancerHelper.poolsLength();
        expect(Number(poolCount.toString())).to.equal(addresses.length);
         
        var pools = await balancerHelper.getPools(0, 10);
        // console.log("pools %s", pools);
        await balancerHelper.connect(keeper).deletePools(0, 3);

        poolCount = await balancerHelper.poolsLength();
        // console.log("poolcount %s", poolCount.toString());
        //expect(poolCount).to.equal(0n);
        pools = await balancerHelper.getPools(0, 10);
        // console.log("pools %s", pools);
    });

    it("7. Should delete all the pools in one transaction", async () => {
        const { balancerHelper, keeper } = await loadFixture(deploy);
        await balancerHelper.connect(keeper).deleteAllPools();
        const poolCount = await balancerHelper.poolsLength();
        expect(poolCount).to.equal(0n);
        await expect(balancerHelper.getPools(0, 3)).to.be.revertedWith(
            "No available pools"
        );
    });

    it("8. Should not delete a pool due to `Out of index range`", async () => {
        const { balancerHelper, keeper } = await loadFixture(deploy);

        await expect(balancerHelper.connect(keeper).deletePool(4)).to.be.revertedWith("Out of index range");
    });

    it("9. Should not get a pool due to `Out of index range`", async () => {
        const { balancerHelper, keeper } = await loadFixture(deploy);

        await expect(balancerHelper.getPool(4)).to.be.revertedWith("Out of index range");
    });

    it("10. It should not deploy the contract `newKeeper is address zero`", async () => {

        const { BalancerHelper, keeper, vault, multisig } = await loadFixture(deploy1);

        await expect(BalancerHelper.deploy(
            vault.getAddress(),
            zeroAddress,
            await multisig.getAddress()
        )).to.be.revertedWith("newKeeper is address zero")

    });

    it("11. Should NOT update the keeper because of `Zero address`", async () => {

        const { balancerHelper, keeper, vault, multisig } = await loadFixture(deploy1);

        await expect( balancerHelper.connect(keeper).updateKeeper(zeroAddress))
        .to.be.revertedWith("Zero address");

    });

    it("12. Should update the keeper and emit an event", async () => {

        const { balancerHelper, keeper, vault, multisig } = await loadFixture(deploy1);

         expect(await balancerHelper.connect(keeper).updateKeeper(keeper))
         .to.emit(balancerHelper, "KeeperUpdated")
         .withArgs(keeper.address);

    });

    
    it("13. Should revert with `from is greater than to`", async () => {

        const { balancerHelper, keeper, vault, multisig } = await loadFixture(deploy1);

        await expect(balancerHelper.getPools(2,1)).to.be.revertedWith("from is greater than to")

    });

    it("14. Should update safe", async () => {

        const { balancerHelper, vault, multisigWithSigner } = await loadFixture(deploy2);

        const vaultAddress = await vault.getAddress();

        await multisigWithSigner.updateSafe(vaultAddress);

        expect(await balancerHelper.safe()).to.equal(vaultAddress)

    });

    it("15. Should update vault", async () => {

        const { balancerHelper, vault, multisigWithSigner } = await loadFixture(deploy2);

        const vaultAddress = await vault.getAddress();

        await multisigWithSigner.updateVault(vaultAddress);

        expect(await balancerHelper.vault()).to.equal(vaultAddress);

    });

    it("16. Should NOT update vault with `newVault is not a contract`", async () => {

        const { balancerHelper, keeper,  multisigWithSigner } = await loadFixture(deploy2);

        await expect(multisigWithSigner.updateVault(keeper.address)).to.be.revertedWith("newVault is not a contract");

    });

    it("17. Should pause pools", async () => {

        const { balancerHelper, keeper,  multisigWithSigner } = await loadFixture(deploy2);

        await multisigWithSigner.pause(0,4);

    });

    it("18. Should pause All the pools", async () => {

        const { balancerHelper, keeper,  multisigWithSigner } = await loadFixture(deploy2);

        await multisigWithSigner.pauseAll();

    });


    it("19. Should NOT pause pools since already paused", async () => {

        const { balancerHelper, keeper,  multisigWithSigner } = await loadFixture(deploy2);

        await multisigWithSigner.pause(0,1);

        await multisigWithSigner.pause(0,1);

    });

    it("20. Should NOT pause All the pools", async () => {

        const { balancerHelper, keeper,  multisigWithSigner } = await loadFixture(deploy2);

        await multisigWithSigner.pauseAll();

        await multisigWithSigner.pauseAll();

    });

    it("21. Should change add & delete a pool from Safe ", async () => {

        const { balancerHelper, keeper,  multisigWithSigner, addresses,  poolIds} = await loadFixture(deploy2);

        await multisigWithSigner.addPool(poolIds[0]);

    });

    it("22. Should change add & delete a pools from Safe ", async () => {

        const { balancerHelper, keeper,  multisigWithSigner, addresses,  poolIds} = await loadFixture(deploy2);

        await multisigWithSigner.addPools(poolIds);

    });

    it("23. Should NOT call addPool - `Unauthorised call`", async () => {

        const { balancerHelper, keeper,  multisigWithSigner, addresses,  poolIds, user} = await loadFixture(deploy);

        await expect( balancerHelper.connect(user).addPool(poolIds[0])).to.be.revertedWith("Unauthorised call");

    });

    it("24. Should NOT call addPools - `Unauthorised call`", async () => {

        const { balancerHelper, keeper,  multisigWithSigner, addresses,  poolIds, user} = await loadFixture(deploy);

        await expect( balancerHelper.connect(user).addPools([poolIds[0]])).to.be.revertedWith("Unauthorised call");

    });

    it("25. Should NOT call deletePool - `Unauthorised call`", async () => {

        const { balancerHelper, keeper,  multisigWithSigner, addresses,  poolIds, user} = await loadFixture(deploy);

        await expect( balancerHelper.connect(user).deletePool(0)).to.be.revertedWith("Unauthorised call");

    });

    it("26. Should NOT call deletePools - `Unauthorised call`", async () => {

        const { balancerHelper, keeper,  multisigWithSigner, addresses,  poolIds, user} = await loadFixture(deploy);

        await expect( balancerHelper.connect(user).deletePools(0, 3)).to.be.revertedWith("Unauthorised call");

    });

    it("27. Should NOT call deleteAllPools - `Unauthorised call`", async () => {

        const { balancerHelper, keeper,  multisigWithSigner, addresses,  poolIds, user} = await loadFixture(deploy);

        await expect( balancerHelper.connect(user).deleteAllPools()).to.be.revertedWith("Unauthorised call");

    });

    it("28. Should NOT call deleteAllPools - `Unauthorised call`", async () => {

        const { balancerHelper, keeper,  multisigWithSigner, addresses,  poolIds, user} = await loadFixture(deploy);

        await expect( balancerHelper.connect(user).deleteAllPools()).to.be.revertedWith("Unauthorised call");

    });

    it("29. Should NOT call pause - `Unauthorised call`", async () => {

        const { balancerHelper, keeper,  multisigWithSigner, addresses,  poolIds, user} = await loadFixture(deploy);

        await expect( balancerHelper.connect(user).pause(0,3)).to.be.revertedWith("Unauthorised call");

    });

    it("30. Should NOT call pauseAll - `Unauthorised call`", async () => {

        const { balancerHelper, keeper,  multisigWithSigner, addresses,  poolIds, user} = await loadFixture(deploy);

        await expect( balancerHelper.connect(user).pauseAll()).to.be.revertedWith("Unauthorised call");

    });

    it("31. Should NOT call updateKeeper - `Unauthorised call`", async () => {

        const { balancerHelper, keeper,  multisigWithSigner, addresses,  poolIds, user} = await loadFixture(deploy);

        await expect( balancerHelper.connect(user).updateKeeper(user.address)).to.be.revertedWith("Unauthorised call");

    });

    it("32. Should NOT call updateSafe - `Unauthorised call`", async () => {

        const { balancerHelper, keeper, multisigWithSigner, addresses,  poolIds, user} = await loadFixture(deploy);

        await expect( balancerHelper.connect(user).updateSafe(addresses[0])).to.be.revertedWith("Unauthorised call");

    });

    it("33. Should NOT call updateVault - `Unauthorised call`", async () => {

        const { balancerHelper, keeper, multisigWithSigner, addresses,  poolIds, user} = await loadFixture(deploy);

        await expect( balancerHelper.connect(user).updateVault(addresses[0])).to.be.revertedWith("Unauthorised call");

    });

    it("34. Should NOT call getPool - `Unauthorised call`", async () => {

        const { balancerHelper, keeper, multisigWithSigner, addresses,  poolIds, user} = await loadFixture(deploy);

        await expect( balancerHelper.connect(user).getPool(10)).to.be.revertedWith("Out of index range");

    });

});