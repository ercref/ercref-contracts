import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("AERC5453", function () {
    async function deployFixture() {
        // Contracts are deployed using the first signer/account by default
        const [owner, otherAccount] = await ethers.getSigners();
        const Erc5453ForTesting = await ethers.getContractFactory("ERC5453ForTesting");
        const erc5453ForTesting = await Erc5453ForTesting.deploy();
        return { erc5453ForTesting, owner, otherAccount };
    }

    describe("Deployment", function () {
        it("Should be deployable", async function () {
            await loadFixture(deployFixture);
        });

        it("Should be deployable", async function () {
            const { erc5453ForTesting } = await loadFixture(deployFixture);
            
        });
    });
});
