import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { hexlify } from "ethers/lib/utils";
import { ethers } from "hardhat";

describe("ProposalExecutor", function () {
    async function deployFixture() {
        // Contracts are deployed using the first signer/account by default
        const [owner, otherAccount] = await ethers.getSigners();

        const ProposalExecutor = await ethers.getContractFactory("ProposalExecutor");
        const contract = await ProposalExecutor.deploy();

        const ERC721ForTesting = await ethers.getContractFactory("ERC721ForTesting");
        const erc721 = await ERC721ForTesting.deploy();

        const SimpleForwarder = await ethers.getContractFactory("SimpleForwarder");
        const forwarder = await SimpleForwarder.deploy();
        return { contract, erc721, forwarder, owner, otherAccount };
    }

    describe("Deployment", function () {
        it("Should work for a simple case", async function () {
            const { contract, erc721, owner } = await loadFixture(deployFixture);
            const callData1 = erc721.interface.encodeFunctionData("mint", [owner.address, 1]);
            const callData2 = erc721.interface.encodeFunctionData("mint", [owner.address, 2]);
            await contract.connect(owner)
                .createProposal(
                    0,
                    [erc721.address, erc721.address],
                    [0,0],
                    [0,0],
                    [callData1, callData2],
                    []);
            expect(await erc721.balanceOf(owner.address)).to.equal(0);
            await contract.connect(owner).executeProposal(0, []);
            expect(await erc721.balanceOf(owner.address)).to.equal(2);
        });
        const Ns = [0, 50, 100, 150, 200];
        for (let n of Ns) {
            it(`Should work for a proposal case of ${n}`, async function () {
                const { contract, erc721, owner } = await loadFixture(deployFixture);
                const numOfMint = n;
                const calldatas = [];
                for (let i = 0 ; i < numOfMint; i++) {
                    const callData = erc721.interface.encodeFunctionData("mint", [owner.address, i]);
                    calldatas.push(callData);
                }
                let txCreate = await contract.connect(owner)
                    .createProposal(
                        0,
                        Array(numOfMint).fill(erc721.address),
                        Array(numOfMint).fill(0),
                        Array(numOfMint).fill(0),
                        calldatas,
                        []);
                let txCreateWaited = await txCreate.wait();
                console.log(`Creation TX gas`, txCreateWaited.gasUsed.toString());
                console.log(`Gas per mint`, parseInt(txCreateWaited.gasUsed.toString()) / numOfMint);
                expect(await erc721.balanceOf(owner.address)).to.equal(0);
                let txExecute = await contract.connect(owner).executeProposal(0, []);
                let txExecuteWaited = await txExecute.wait();
                console.log(`Execution TX gas`, txExecuteWaited.gasUsed.toString());
                console.log(`Gas per mint`, parseInt(txExecuteWaited.gasUsed.toString()) / numOfMint);
                expect(await erc721.balanceOf(owner.address)).to.equal(numOfMint);
            });
        }
    });
    describe("Gas Benchmark", function () {
        const gasBenchmarkReports:any[] = [];
        this.afterAll(function () {
            console.log(`Gas Benchmark Report`);
            console.log(gasBenchmarkReports);
        });

        it(`Should work for a forwarding case for 200 mints same address`, async function () {
            const { forwarder, erc721, owner } = await loadFixture(deployFixture);
            const numOfMint = 200;
            const calldatas = [];
            for (let i = 0 ; i < numOfMint; i++) {
                const callData = erc721.interface.encodeFunctionData("mint", [owner.address, i]);
                calldatas.push(callData);
            }
            expect(await erc721.balanceOf(owner.address)).to.equal(0);
            let txForward = await forwarder.connect(owner)
                .forward(
                    Array(numOfMint).fill(erc721.address),
                    Array(numOfMint).fill(0),
                    Array(numOfMint).fill(0),
                    calldatas);
            let txForwardWaited = await txForward.wait();
            gasBenchmarkReports.push({
                title: `Mint 200 tokens using forwarder`,
                TotalGasUsed: parseInt(txForwardWaited.gasUsed.toString()),
                GasUsedPerMint: parseInt(txForwardWaited.gasUsed.toString()),
            });
            console.log(`txForwardWaited TX gas`, txForwardWaited.gasUsed.toString());

            console.log(`Gas per mint for same addresses via forwarder`, parseInt(txForwardWaited.gasUsed.toString()) / numOfMint);
            expect(await erc721.balanceOf(owner.address)).to.equal(numOfMint);
        });

        it(`Should work for a forwarding case for 200 mints different address`, async function () {
            const { forwarder, erc721, owner } = await loadFixture(deployFixture);
            const numOfMint = 200;
            const calldatas = [];
            for (let i = 0 ; i < numOfMint; i++) {
                const callData = erc721.interface.encodeFunctionData(
                    "mint", [hexlify(ethers.utils.randomBytes(20)), i]);
                calldatas.push(callData);
            }
            expect(await erc721.balanceOf(owner.address)).to.equal(0);
            let txForward = await forwarder.connect(owner)
                .forward(
                    Array(numOfMint).fill(erc721.address),
                    Array(numOfMint).fill(0),
                    Array(numOfMint).fill(0),
                    calldatas);
            let txForwardWaited = await txForward.wait();

            console.log(`txForwardWaited TX gas`, txForwardWaited.gasUsed.toString());

            console.log(`Gas per mint for different addresses via forwarder`, parseInt(txForwardWaited.gasUsed.toString()) / numOfMint);
        });

        it(`Should work for erc721 batchMint with same addresses`, async function () {
            const { erc721, owner } = await loadFixture(deployFixture);
            const numOfMint = 200;
            const tokenIds = [];
            const addresses = [];

            for (let i = 0 ; i < numOfMint; i++) {
                addresses.push(owner.address);// addresses.push(hexlify(ethers.utils.randomBytes(20)));
                tokenIds.push(i);
            }
            const tx = await erc721.connect(owner).batchMint(addresses, tokenIds);
            const txWaited = await tx.wait();
            console.log(`batchMint TX gas`, txWaited.gasUsed.toString());
            console.log(`At ${numOfMint} Gas per mint`, parseInt(txWaited.gasUsed.toString()) / numOfMint);
        })

        it(`Should work for erc721 batchMint with different addresses`, async function () {
            const { erc721, owner } = await loadFixture(deployFixture);
            const numOfMint = 200;
            const tokenIds = [];
            const addresses = [];

            for (let i = 0 ; i < numOfMint; i++) {
                addresses.push(hexlify(ethers.utils.randomBytes(20)));
                tokenIds.push(i);
            }
            const tx = await erc721.connect(owner).batchMint(addresses, tokenIds);
            const txWaited = await tx.wait();
            console.log(`batchMint TX gas`, txWaited.gasUsed.toString());
            console.log(`At ${numOfMint} Gas per mint`, parseInt(txWaited.gasUsed.toString()) / numOfMint);
        });


        it(`Should work for erc721 batchSafeMint with same addresses`, async function () {
            const { erc721, owner } = await loadFixture(deployFixture);
            const numOfMint = 400;
            const tokenIds = [];
            const addresses = [];

            for (let i = 0 ; i < numOfMint; i++) {
                addresses.push(owner.address);// addresses.push(hexlify(ethers.utils.randomBytes(20)));
                tokenIds.push(i);
            }
            const tx = await erc721.connect(owner).batchSafeMint(addresses, tokenIds);
            const txWaited = await tx.wait();
            console.log(`batchSafeMint TX gas`, txWaited.gasUsed.toString());
            console.log(`At ${numOfMint} Gas per mint`, parseInt(txWaited.gasUsed.toString()) / numOfMint);
        });

        it(`Should work for erc721 batchSafeMint with different addresses`, async function () {
            const { erc721, owner } = await loadFixture(deployFixture);
            const numOfMint = 400;
            const tokenIds = [];
            const addresses = [];

            for (let i = 0 ; i < numOfMint; i++) {
                addresses.push(hexlify(ethers.utils.randomBytes(20)));
                tokenIds.push(i);
            }
            const tx = await erc721.connect(owner).batchSafeMint(addresses, tokenIds);
            const txWaited = await tx.wait();
            console.log(`batchSafeMint TX gas`, txWaited.gasUsed.toString());
            console.log(`At ${numOfMint} the Gas per mint`, parseInt(txWaited.gasUsed.toString()) / numOfMint);
        });
    });
});
