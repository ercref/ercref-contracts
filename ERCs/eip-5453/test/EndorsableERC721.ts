import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { providers } from "ethers";
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
        return { endorsableERC721, owner, mintSender, recipient, testSigner };
    }

    describe("Deployment", function () {
        it("Should be deployable", async function () {
            await loadFixture(deployFixture);
        });

        it("Should not be mintable if signer doesn't have a endorsement", async function () {
            const { endorsableERC721, mintSender, recipient } = await loadFixture(deployFixture);
            await expect(endorsableERC721.connect(mintSender).mint(recipient.address, 1, [])).to.throw;
        });

        it("Should mintable if signer have a valid endorsement", async function () {
            const { endorsableERC721, owner, mintSender, recipient, testSigner } = await loadFixture(deployFixture);
            const testSignerAddress = ethers.utils.computeAddress(testSigner.publicKey);
            console.log(`XXX addresses\n${owner.address}\n${mintSender.address}\n${recipient.address}\n${testSignerAddress}`);
            expect(await endorsableERC721.balanceOf(recipient.address)).to.equal(0);
            const functionName = "function mint(address _to,uint256 _tokenId)";
            const functionParamPacked = ethers.utils.defaultAbiCoder.encode(["address", "uint256"], [recipient.address, 0x01]);

            const functionParamStructHash = await endorsableERC721.computeFunctionParamStructHash(
                functionName,
                functionParamPacked
            );
            // console.log(`--------- XXX YYY outside functionName\n${functionName}`);
            console.log(`--------- XXX YYY outside functionParamPacked\n${functionParamPacked}`);
            // console.log(`--------- XXX YYY outside functionParamStructHash\n${functionParamStructHash}`);
            const currentNonce = await endorsableERC721.getCurrentNonce();
            const latestBlock = await ethers.provider.getBlock("latest");
            const numOfBlocksBeforeDeadline = 20;
            const finalDigest = await endorsableERC721.computeDigestWithBound(
                functionParamStructHash,
                latestBlock.number,
                latestBlock.number +
                numOfBlocksBeforeDeadline,
                currentNonce);
            const validSince = latestBlock.number;
            const validBy = latestBlock.number + numOfBlocksBeforeDeadline;
            const signature = testSigner.signDigest(finalDigest);
            console.log(`XXX outside signature\n`, signature.compact);
            console.log(`XXX outside endorser address\n`, testSignerAddress);
            console.log(`XXX outside finalDigest\n`, finalDigest);
            const recoveredAddress = ethers.utils.recoverAddress(finalDigest, signature.compact);
            console.log(`XXX outside signature.length\n`, signature.compact.length);
            console.log(`XXX outside recoveredAddress\n`, recoveredAddress);
            const sigPacked = ethers.utils.joinSignature(signature);
            console.log(`XXX outside sigPacked\n`, sigPacked);
            const generalExtensionDataStruct = await endorsableERC721.computeGeneralExtensionDataStructForSingleEndorsementData(
                currentNonce,
                validSince,
                validBy,
                testSignerAddress,
                sigPacked);

            await endorsableERC721.connect(mintSender).mint(recipient.address, 1, generalExtensionDataStruct);
            expect(await endorsableERC721.balanceOf(recipient.address)).to.equal(1);
        });
    });
});
