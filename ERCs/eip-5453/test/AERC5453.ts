import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("AERC5453", function () {
    async function deployFixture() {
        // Contracts are deployed using the first signer/account by default
        const [owner, account1, account2, account3] = await ethers.getSigners();
        const Erc5453ForTesting = await ethers.getContractFactory("ERC5453ForTesting");
        const erc5453ForTesting = await Erc5453ForTesting.deploy();

        const Erc721ForTesting = await ethers.getContractFactory("ERC721ForTesting");
        const erc721ForTesting = await Erc721ForTesting.deploy();
        await erc721ForTesting.transferOwnership(erc5453ForTesting.address);
        return { erc5453ForTesting, erc721ForTesting, owner, account1, account2, account3 };
    }

    describe("Deployment", function () {
        it("Should be deployable", async function () {
            await loadFixture(deployFixture);
        });
    });
});
