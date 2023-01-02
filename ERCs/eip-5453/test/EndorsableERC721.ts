import { loadFixture, mine } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { Wallet } from "ethers";
import { ethers } from "hardhat";
import { computeEndorsement, ERC5453EndorsementType } from "../utils/utils";

describe("EndorsibleERC721", function () {
    async function deployFixture() {
        // Contracts are deployed using the first signer/account by default
        const [owner, mintSender, recipient] = await ethers.getSigners();
        const testWallet:Wallet = new ethers.Wallet("0x0000000000000000000000000000000000000000000000000000000000000001");
        const EndorsableERC721 = await ethers.getContractFactory("EndorsableERC721");
        const endorsableERC721 = await EndorsableERC721.deploy();
        await endorsableERC721.deployed();

        const ERC721ForTesting = await ethers.getContractFactory("ERC721ForTesting");
        const erc721ForTesting = await ERC721ForTesting.deploy();
        await endorsableERC721.deployed();

        await endorsableERC721.connect(owner).addOwner(testWallet.address);

        return { endorsableERC721, erc721ForTesting, owner, mintSender, recipient, testWallet };
    }

    describe("Deployment", function () {
        it("Should be deployable", async function () {
            await loadFixture(deployFixture);
        });

        it("Should not be mintable if signer doesn't have a endorsement", async function () {
            const { endorsableERC721, mintSender, recipient } = await loadFixture(deployFixture);
            await expect(endorsableERC721.connect(mintSender).mint(recipient.address, 1, [])).to.throw;
        });

        it("Should successfully mint if ONE signer have a valid endorsement", async function () {
            const targetTokenId = 0x01;
            const { endorsableERC721, mintSender, recipient, testWallet } = await loadFixture(deployFixture);
            expect(await endorsableERC721.balanceOf(recipient.address)).to.equal(0);
            const endorsement = await computeEndorsement(
                endorsableERC721,
                "function mint(address _to,uint256 _tokenId)",
                ["address", "uint256"],
                [recipient.address, ethers.utils.arrayify(0x01)],
                [testWallet], ERC5453EndorsementType.A, { }
            );
            await endorsableERC721.connect(mintSender).mint(recipient.address, targetTokenId, endorsement);
            expect(await endorsableERC721.balanceOf(recipient.address)).to.equal(targetTokenId);
        });

        it("Should successfully mint if ANY signer have a valid endorsement", async function () {
            const { endorsableERC721, testWallet } = await loadFixture(deployFixture);
            const signers = await ethers.getSigners();
            for (let i = 0; i < 5; i++) {
                for (let j = 0; j < 5; j++) {
                    const randomRecipient = await ethers.Wallet.createRandom();
                    expect(await endorsableERC721.balanceOf(randomRecipient.address)).to.equal(0);
                    const endorsement = await computeEndorsement(
                        endorsableERC721,
                        "function mint(address _to,uint256 _tokenId)",
                        ["address", "uint256"],
                        [randomRecipient.address, ethers.utils.arrayify(i * 5 + j)],
                        [testWallet], ERC5453EndorsementType.A, { }
                    );
                    await endorsableERC721.connect(signers[j]).mint(randomRecipient.address, i * 5 + j, endorsement);
                    expect(await endorsableERC721.balanceOf(randomRecipient.address)).to.equal(1);
                }
            }
        });

        it("Should reject if signer have a endorsement for different parameters", async function () {
            const targetTokenId = 0x01;
            const wroteTokenId = 0x02;
            const targetRecipient = await ethers.Wallet.createRandom();
            const wrongRecipient = await ethers.Wallet.createRandom();
            const { endorsableERC721, mintSender, testWallet } = await loadFixture(deployFixture);
            expect(await endorsableERC721.balanceOf(targetRecipient.address)).to.equal(0);

            // Wrong TokenId
            const endorsement1 = await computeEndorsement(
                endorsableERC721,
                "function mint(address _to,uint256 _tokenId)",
                ["address", "uint256"],
                [targetRecipient.address, ethers.utils.arrayify(wroteTokenId)],
                [testWallet], ERC5453EndorsementType.A, { }
            );
            await expect(endorsableERC721.connect(mintSender).mint(targetRecipient.address, targetTokenId, endorsement1))
                .to.be.rejectedWith("AERC5453Endorsible: invalid signature");

            // Wrong Recipient
            const endorsement2 = await computeEndorsement(
                endorsableERC721,
                "function mint(address _to,uint256 _tokenId)",
                ["address", "uint256"],
                [wrongRecipient.address, ethers.utils.arrayify(targetTokenId)],
                [testWallet], ERC5453EndorsementType.A, { }
            );
            await expect(endorsableERC721.connect(mintSender).mint(targetRecipient.address, targetTokenId, endorsement2)).to.be.rejectedWith("AERC5453Endorsible: invalid signature");

            expect(await endorsableERC721.balanceOf(targetRecipient.address)).to.equal(0);
        });

        it("Should reject if signer have a endorsement with time not valid yet", async function () {
            const targetTokenId = 0x01;
            const targetRecipient = await ethers.Wallet.createRandom();
            const { endorsableERC721, mintSender, testWallet } = await loadFixture(deployFixture);
            expect(await endorsableERC721.balanceOf(targetRecipient.address)).to.equal(0);

            // blocknum is strictly less than validSince.
            const latestBlock = await ethers.provider.getBlock("latest");

            // blocknum is strictly less than validSince.
            const validSince = latestBlock.number + 2;
            const endorsement = await computeEndorsement(
                endorsableERC721,
                "function mint(address _to,uint256 _tokenId)",
                ["address", "uint256"],
                [targetRecipient.address, ethers.utils.arrayify(targetTokenId)],
                [testWallet], ERC5453EndorsementType.A, {
                    validSince,
                    validBy: validSince + 10,
                }
            );

            await expect(endorsableERC721.connect(mintSender).mint(targetRecipient.address, targetTokenId, endorsement))
                .to.be.rejectedWith("Not valid yet");
            expect(await endorsableERC721.balanceOf(targetRecipient.address)).to.equal(0);
        });

        it("Should reject if signer have a endorsement with time expired", async function () {
            const targetTokenId = 0x01;
            const targetRecipient = await ethers.Wallet.createRandom();
            const { endorsableERC721, mintSender, testWallet } = await loadFixture(deployFixture);
            expect(await endorsableERC721.balanceOf(targetRecipient.address)).to.equal(0);

            const numOfBlocksBeforeDeadline = 10;
            const endorsement = await computeEndorsement(
                endorsableERC721,
                "function mint(address _to,uint256 _tokenId)",
                ["address", "uint256"],
                [targetRecipient.address, ethers.utils.arrayify(targetTokenId)],
               [testWallet], ERC5453EndorsementType.A, { numOfBlocksBeforeDeadline }
            );

            await mine(numOfBlocksBeforeDeadline + 1);
            await expect(endorsableERC721.connect(mintSender).mint(targetRecipient.address, targetTokenId, endorsement))
                .to.be.rejectedWith("Expired");
            expect(await endorsableERC721.balanceOf(targetRecipient.address)).to.equal(0);
        });

        it("Should reject if signer have a endorsement not matching nonce", async function () {
            const targetTokenId = 0x01;
            const targetRecipient = await ethers.Wallet.createRandom();
            const { endorsableERC721, mintSender, testWallet } = await loadFixture(deployFixture);
            expect(await endorsableERC721.balanceOf(targetRecipient.address)).to.equal(0);

            const currentNonce = await (await endorsableERC721.eip5453Nonce(
                endorsableERC721.address)).toNumber();
            const endorsement = await computeEndorsement(
                endorsableERC721,
                "function mint(address _to,uint256 _tokenId)",
                ["address", "uint256"],
                [targetRecipient.address, ethers.utils.arrayify(targetTokenId)],
                [testWallet], ERC5453EndorsementType.A, { currentNonce: currentNonce + 1 }
            );

            await expect(endorsableERC721.connect(mintSender).mint(targetRecipient.address, targetTokenId, endorsement))
                .to.be.rejectedWith("Nonce not matched");
            expect(await endorsableERC721.balanceOf(targetRecipient.address)).to.equal(0);
        });
    });

    describe("Gas Benchmark", function () {
        let gasBenchmarkReports:any[] = [];
        it("Minting 1 Single Token", async function () {
            const { endorsableERC721, erc721ForTesting, mintSender, recipient, testWallet } = await loadFixture(deployFixture);
            const endorsement = await computeEndorsement(
                endorsableERC721,
                "function mint(address _to,uint256 _tokenId)",
                ["address", "uint256"],
                [recipient.address, ethers.utils.arrayify(0x01)],
                [testWallet], ERC5453EndorsementType.A, { }
            );
            const tx1 = await endorsableERC721.connect(mintSender).mint(recipient.address, 1, endorsement);
            const tx1Receipt = await tx1.wait();
            gasBenchmarkReports.push({
                title: "Mint 1 token",
                tag: "EndorsableERC721",
                gasUsed: tx1Receipt.gasUsed.toString(),
            });

            const tx2 = await erc721ForTesting.connect(mintSender).mint(recipient.address, 1);
            const tx2Receipt = await tx2.wait();
            gasBenchmarkReports.push({
                title: "Mint 1 token",
                tag: "ERC721ForTesting",
                gasUsed: tx2Receipt.gasUsed.toString(),
            });
        });
        this.afterAll(async function () {
            console.table(gasBenchmarkReports);
        });
    });
});
