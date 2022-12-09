import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("GeneralForwarder", function () {
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
        it("Should work for a simple case", async function () {
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
            expect(await erc721.balanceOf(owner.address)).to.equal(0);
            await contract.connect(owner).executeProposal(0, []);
            expect(await erc721.balanceOf(owner.address)).to.equal(2);
        });
        const Ns = [0, 25, 50, 75, 100, 125, 150, 175, 200];
        for (let n of Ns) {
            it(`Should work for a big case of ${n}`, async function () {
                const { contract, erc721, owner } = await loadFixture(deployFixture);
                const numOfMint = n;
                const calldatas = [];
                for (let i = 0 ; i < numOfMint; i++) {
                    const callData = erc721.interface.encodeFunctionData("mint", [owner.address, i]);
                    calldatas.push(callData);
                }
                let txCreate = await contract.connect(owner)
                    .createProposal(
                        owner.address,
                        0,
                        Array(numOfMint).fill(erc721.address),
                        Array(numOfMint).fill(0),
                        Array(numOfMint).fill(0),
                        calldatas);
                let txCreateWaited = await txCreate.wait();
                console.log(`Creation TX gas`, txCreateWaited.cumulativeGasUsed.toString());
                expect(await erc721.balanceOf(owner.address)).to.equal(0);
                let txExecute = await contract.connect(owner).executeProposal(0, []);
                let txExecuteWaited = await txExecute.wait();
                console.log(`Execution TX gas`, txExecuteWaited.cumulativeGasUsed.toString());
                expect(await erc721.balanceOf(owner.address)).to.equal(numOfMint);
            });
        }

    });
});
