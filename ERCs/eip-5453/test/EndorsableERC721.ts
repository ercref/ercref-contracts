import { loadFixture, mine } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { BigNumber } from "ethers";
import { ethers } from "hardhat";

describe("EndorsibleERC721", function () {
    async function deployFixture() {
        // Contracts are deployed using the first signer/account by default
        const [owner, mintSender, recipient] = await ethers.getSigners();
        const testSigner = new ethers.utils.SigningKey("0x0000000000000000000000000000000000000000000000000000000000000001");
        const EndorsableERC721 = await ethers.getContractFactory("EndorsableERC721");
        const endorsableERC721 = await EndorsableERC721.deploy();
        await endorsableERC721.deployed();
        const testSignerAddress = ethers.utils.computeAddress(testSigner.publicKey);
        await endorsableERC721.connect(owner).addOwner(testSignerAddress);
        return { endorsableERC721, owner, mintSender, recipient, testSigner, testSignerAddress };
    }

    async function computeExtensionData(
        recipientAddress:any, tokenId:any, {
            numOfBlocksBeforeDeadline = 20,
            validSince = 0,
            validBy = 0,
            currentNonce = 0,
        }) {
        const { endorsableERC721, testSigner, testSignerAddress } = await loadFixture(deployFixture);
        const functionName = "function mint(address _to,uint256 _tokenId)";
        const functionParamPacked = ethers.utils.defaultAbiCoder.encode(["address", "uint256"], [recipientAddress, tokenId]);

        const functionParamStructHash = await endorsableERC721.computeFunctionParamStructHash(
            functionName,
            functionParamPacked
        );
        currentNonce = currentNonce || await (await endorsableERC721.getCurrentNonce()).toNumber();
        const latestBlock = await ethers.provider.getBlock("latest");
        const finalDigest = await endorsableERC721.computeDigestWithBound(
            functionParamStructHash,
            latestBlock.number,
            latestBlock.number +
            numOfBlocksBeforeDeadline,
            currentNonce);
        validSince = validSince || latestBlock.number;
        validBy = validBy || latestBlock.number + numOfBlocksBeforeDeadline;
        const signature = testSigner.signDigest(finalDigest);
        const sigPacked = ethers.utils.joinSignature(signature);
        const generalExtensionDataStruct = await endorsableERC721.computeGeneralExtensionDataStructForSingleEndorsementData(
            currentNonce,
            validSince,
            validBy,
            testSignerAddress,
            sigPacked);
        return generalExtensionDataStruct;
    };

    describe("Deployment", function () {
        it("Should be deployable", async function () {
            await loadFixture(deployFixture);
        });

        it("Should not be mintable if signer doesn't have a endorsement", async function () {
            const { endorsableERC721, mintSender, recipient } = await loadFixture(deployFixture);
            await expect(endorsableERC721.connect(mintSender).mint(recipient.address, 1, [])).to.throw;
        });

        it("Should successfully mint if ONE signer have a valid endorsement", async function () {
            const { endorsableERC721, mintSender, recipient } = await loadFixture(deployFixture);
            expect(await endorsableERC721.balanceOf(recipient.address)).to.equal(0);
            const extensionData = await computeExtensionData(recipient.address, 0x01, {});
            await endorsableERC721.connect(mintSender).mint(recipient.address, 1, extensionData);
            expect(await endorsableERC721.balanceOf(recipient.address)).to.equal(1);
        });

        it("Should successfully mint if ANY signer have a valid endorsement", async function () {
            const { endorsableERC721 } = await loadFixture(deployFixture);
            const signers = await ethers.getSigners();
            for (let i = 0; i < 5; i++) {
                for(let j = 0; j < 5; j++) {
                    const randomRecipient = await ethers.Wallet.createRandom();
                    expect(await endorsableERC721.balanceOf(randomRecipient.address)).to.equal(0);
                    const extensionData = await computeExtensionData(randomRecipient.address, i*5+j, {});
                    await endorsableERC721.connect(signers[j]).mint(randomRecipient.address, i*5+j, extensionData);
                    expect(await endorsableERC721.balanceOf(randomRecipient.address)).to.equal(1);
                }
            }
        });

        it("Should reject if signer have a endorsement for different parameters", async function () {
            const targetTokenId = 0x01;
            const wroteTokenId = 0x02;
            const targetRecipient = await ethers.Wallet.createRandom();
            const wrongRecipient = await ethers.Wallet.createRandom();
            const { endorsableERC721, mintSender } = await loadFixture(deployFixture);
            expect(await endorsableERC721.balanceOf(targetRecipient.address)).to.equal(0);

            // Wrong TokenId
            const extensionData1 = await computeExtensionData(targetRecipient.address, wroteTokenId, {});
            await expect(endorsableERC721.connect(mintSender).mint(targetRecipient.address, targetTokenId, extensionData1)).to.be.rejectedWith("AERC5453Endorsible: invalid signature");

            // Wrong Recipient
            const extensionData2 = await computeExtensionData(wrongRecipient.address, targetTokenId, {});
            await expect(endorsableERC721.connect(mintSender).mint(targetRecipient.address, targetTokenId, extensionData2)).to.be.rejectedWith("AERC5453Endorsible: invalid signature");

            expect(await endorsableERC721.balanceOf(targetRecipient.address)).to.equal(0);
        });

        it("Should reject if signer have a endorsement not valid yet", async function () {
            const targetTokenId = 0x01;
            const targetRecipient = await ethers.Wallet.createRandom();
            const { endorsableERC721, mintSender } = await loadFixture(deployFixture);
            expect(await endorsableERC721.balanceOf(targetRecipient.address)).to.equal(0);

            // blocknum is strictly less than validSince.
            await mine(10);
            const latestBlock = await ethers.provider.getBlock("latest");

            // blocknum is strictly less than validSince.
            const validSince = latestBlock.number - 1;
            const extensionData = await computeExtensionData(targetRecipient.address, targetTokenId, {validSince});
            await expect(endorsableERC721.connect(mintSender).mint(targetRecipient.address, targetTokenId, extensionData))
                .to.be.rejectedWith("Not valid yet");
            expect(await endorsableERC721.balanceOf(targetRecipient.address)).to.equal(0);
        });

        it("Should reject if signer have a endorsement expired", async function () {
            const targetTokenId = 0x01;
            const targetRecipient = await ethers.Wallet.createRandom();
            const { endorsableERC721, mintSender } = await loadFixture(deployFixture);
            expect(await endorsableERC721.balanceOf(targetRecipient.address)).to.equal(0);

            const latestBlock = await ethers.provider.getBlock("latest");
            const numOfBlocksBeforeDeadline = 10;
            const extensionData = await computeExtensionData(targetRecipient.address, targetTokenId, {numOfBlocksBeforeDeadline});
            await mine(numOfBlocksBeforeDeadline + 1);
            await expect(endorsableERC721.connect(mintSender).mint(targetRecipient.address, targetTokenId, extensionData))
                .to.be.rejectedWith("Expired");
            expect(await endorsableERC721.balanceOf(targetRecipient.address)).to.equal(0);
        });

        it("Should reject if signer have a endorsement not matching nonce", async function () {
            const targetTokenId = 0x01;
            const targetRecipient = await ethers.Wallet.createRandom();
            const { endorsableERC721, mintSender } = await loadFixture(deployFixture);
            expect(await endorsableERC721.balanceOf(targetRecipient.address)).to.equal(0);

            const currentNonce = await (await endorsableERC721.getCurrentNonce()).toNumber();
            const extensionData = await computeExtensionData(targetRecipient.address, targetTokenId, {currentNonce: currentNonce + 1});
            await expect(endorsableERC721.connect(mintSender).mint(targetRecipient.address, targetTokenId, extensionData))
                .to.be.rejectedWith("Nonce not matched");
            expect(await endorsableERC721.balanceOf(targetRecipient.address)).to.equal(0);
        });
    });
});
