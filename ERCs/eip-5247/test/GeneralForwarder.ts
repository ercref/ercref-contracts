import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { BigNumber, BigNumberish } from "ethers";
import { ethers } from "hardhat";

describe("TheResolver", function () {
    async function deployFixture() {
        // Contracts are deployed using the first signer/account by default
        const [owner, otherAccount] = await ethers.getSigners();

        const GeneralForwarder = await ethers.getContractFactory("GeneralForwarder");
        const contract = await GeneralForwarder.deploy();

        const ERC721ForTesting = await ethers.getContractFactory("ERC721ForTesting");

        const erc721 = await ERC721ForTesting.deploy();
        return { contract, erc721, owner, otherAccount };
    }

    describe("Deployment", function () {
        it("Should compute right namehash for EIP-191 examples", async function () {
            const { contract, erc721, owner } = await loadFixture(deployFixture);
            const callData1 = erc721.interface.encodeFunctionData("mint", [owner.address, 1]);
            const callData2 = erc721.interface.encodeFunctionData("mint", [owner.address, 2]);
            await contract.connect(owner)
                .createProposal(
                    owner.address,
                    0,
                    [erc721.address, erc721.address],
                    [0,0],
                    [0,0],
                    [callData1, callData2]);
            // proposalId = proposalId as BigNumberish;
            // expect(await erc721.balanceOf(owner.address)).to.equal(0);
            // await contract.connect(owner).execute(proposalId, []);
            // expect(await erc721.balanceOf(owner.address)).to.equal(2);
        });

    });
});
