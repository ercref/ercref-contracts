import { loadFixture, mine } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { erc721 } from "../typechain-types/@openzeppelin/contracts/token";

describe("ThresholdMultiSigForwarder", function () {

    async function computeExtensionData(
        thresholdMultiSigForwarder:any,
        testSigningKeys:any,
        testSigningAddresses:any,
        dest:any,
        value:any,
        gasLimit:any,
        calldata:any,
        {
            amountOfSigners = 1,
            numOfBlocksBeforeDeadline = 20,
            validSince = 0,
            validBy = 0,
            currentNonce = 0,
        }) {
        const functionName = "function forward(address _dest,uint256 _value,uint256 _gasLimit,bytes calldata _calldata)";
        const functionParamPacked = ethers.utils.defaultAbiCoder.encode([
            "address", "uint256", "uint256", "bytes32"], [
            dest, value, gasLimit, ethers.utils.keccak256(calldata)]);

        const functionParamStructHash = await thresholdMultiSigForwarder.computeFunctionParamStructHash(
            functionName,
            functionParamPacked
        );
        currentNonce = currentNonce || await (await thresholdMultiSigForwarder.getCurrentNonce()).toNumber();
        const latestBlock = await ethers.provider.getBlock("latest");
        const finalDigest = await thresholdMultiSigForwarder.computeDigestWithBound(
            functionParamStructHash,
            latestBlock.number,
            latestBlock.number +
            numOfBlocksBeforeDeadline,
            currentNonce);
        validSince = validSince || latestBlock.number;
        validBy = validBy || latestBlock.number + numOfBlocksBeforeDeadline;
        const sigPackeds = [];
        for (let i = 0; i < amountOfSigners; i++) {
            const signature = testSigningKeys[i].signDigest(finalDigest);
            const sigPacked = ethers.utils.joinSignature(signature);
            sigPackeds.push(sigPacked);
        }

        const generalExtensionDataStruct = await thresholdMultiSigForwarder.computeGeneralExtensionDataStructForMultipleEndorsementData(
            currentNonce,
            validSince,
            validBy,
            testSigningAddresses.slice(0, amountOfSigners),
            sigPackeds);
        return generalExtensionDataStruct;
    };

    async function deployFixture() {
        // Contracts are deployed using the first signer/account by default
        const [owner, mintSender, recipient] = await ethers.getSigners();
        const testSigningKeys:any[] = [];
        const testSigningAddresses:any[] = [];
        for (let i = 0; i < 10; i++) {
            testSigningKeys.push(new ethers.utils.SigningKey(ethers.utils.hexlify(ethers.utils.randomBytes(32))));
            testSigningAddresses.push(ethers.utils.computeAddress(testSigningKeys[i].publicKey));
        }
        const ThresholdMultiSigForwarder = await ethers.getContractFactory("ThresholdMultiSigForwarder");
        const thresholdMultiSigForwarder = await ThresholdMultiSigForwarder.deploy();
        await thresholdMultiSigForwarder.deployed();

        const ERC721ForTesting = await ethers.getContractFactory("ERC721ForTesting");
        const erc721ForTesting = await ERC721ForTesting.deploy();
        await erc721ForTesting.deployed();

        return { thresholdMultiSigForwarder, erc721ForTesting, owner, mintSender, recipient, testSigningKeys, testSigningAddresses };
    }

    describe("Deployment", function () {
        it("Should be deployable", async function () {
            await loadFixture(deployFixture);
        });

        it("Should be able to initialize owners", async function () {
            const { thresholdMultiSigForwarder, owner, testSigningKeys, testSigningAddresses} = await loadFixture(deployFixture);
            await thresholdMultiSigForwarder.connect(owner).initialize(testSigningAddresses, 5);
            for (let i = 0; i < testSigningAddresses.length; i++) {
                expect(await thresholdMultiSigForwarder.isEligibleEndorser(testSigningAddresses[i])).to.equal(true);
            }
        });

        it("Should be able to set eligible endorsers", async function () {
            const { thresholdMultiSigForwarder, owner, testSigningKeys, testSigningAddresses} = await loadFixture(deployFixture);
            await thresholdMultiSigForwarder.connect(owner).initialize(testSigningAddresses, 5);
            for (let i = 0; i < testSigningAddresses.length; i++) {
                expect(await thresholdMultiSigForwarder.isEligibleEndorser(testSigningAddresses[i])).to.equal(true);
            }
        });

        it("Should successfully forward a transferForm call to ERC721orTesting with sufficient endorsements", async function () {
            const { thresholdMultiSigForwarder, erc721ForTesting, owner, testSigningKeys, testSigningAddresses} = await loadFixture(deployFixture);
            const targetTokenId = 0x1;
            await erc721ForTesting.connect(owner).mint(thresholdMultiSigForwarder.address, targetTokenId);
            expect(await erc721ForTesting.ownerOf(targetTokenId)).to.equal(thresholdMultiSigForwarder.address);
            expect(await erc721ForTesting.balanceOf(thresholdMultiSigForwarder.address)).to.equal(1);

            const numOfEligibleEndorsers = 5;
            const threshold = 3;
            await thresholdMultiSigForwarder.connect(owner).initialize(testSigningAddresses.slice(0, numOfEligibleEndorsers), threshold);
            for (let i = 0; i < numOfEligibleEndorsers; i++) {
                expect(await thresholdMultiSigForwarder.isEligibleEndorser(testSigningAddresses[i])).to.equal(true);
            }
            const targetRecipient = ethers.utils.computeAddress(ethers.utils.hexlify(ethers.utils.randomBytes(32)));
            const calldata = erc721ForTesting.interface.encodeFunctionData("safeTransferFrom(address,address,uint256)", [thresholdMultiSigForwarder.address, targetRecipient, 1]);
            const extensionData = await computeExtensionData(
                thresholdMultiSigForwarder,
                testSigningKeys,
                testSigningAddresses,
                erc721ForTesting.address,
                0,
                0,
                calldata,
                { amountOfSigners: threshold });
            expect(await erc721ForTesting.balanceOf(targetRecipient)).to.equal(0);
            expect(await erc721ForTesting.balanceOf(thresholdMultiSigForwarder.address)).to.equal(1);
            expect(await erc721ForTesting.ownerOf(targetTokenId)).to.equal(thresholdMultiSigForwarder.address);
            expect(await erc721ForTesting.balanceOf(thresholdMultiSigForwarder.address)).to.equal(1);
            let txForward = await thresholdMultiSigForwarder.connect(owner)
                .forward(
                    erc721ForTesting.address,
                    0, 0,
                    calldata,
                    extensionData);
            let txForwardWaited = await txForward.wait();
            expect(await erc721ForTesting.balanceOf(targetRecipient)).to.equal(1);
        });

        it("Should reject forwarding a transferForm call to ERC721orTesting with insufficient endorsements", async function () {
            const { thresholdMultiSigForwarder, erc721ForTesting, owner, testSigningKeys, testSigningAddresses} = await loadFixture(deployFixture);
            const targetTokenId = 0x1;
            await erc721ForTesting.connect(owner).mint(thresholdMultiSigForwarder.address, targetTokenId);
            expect(await erc721ForTesting.ownerOf(targetTokenId)).to.equal(thresholdMultiSigForwarder.address);
            expect(await erc721ForTesting.balanceOf(thresholdMultiSigForwarder.address)).to.equal(1);

            const numOfEligibleEndorsers = 5;
            const threshold = 3;
            await thresholdMultiSigForwarder.connect(owner).initialize(testSigningAddresses.slice(0, numOfEligibleEndorsers), threshold);
            for (let i = 0; i < numOfEligibleEndorsers; i++) {
                expect(await thresholdMultiSigForwarder.isEligibleEndorser(testSigningAddresses[i])).to.equal(true);
            }
            const targetRecipient = ethers.utils.computeAddress(ethers.utils.hexlify(ethers.utils.randomBytes(32)));
            const calldata = erc721ForTesting.interface.encodeFunctionData("safeTransferFrom(address,address,uint256)", [thresholdMultiSigForwarder.address, targetRecipient, 1]);
            const extensionData = await computeExtensionData(
                thresholdMultiSigForwarder,
                testSigningKeys,
                testSigningAddresses,
                erc721ForTesting.address,
                0,
                0,
                calldata,
                { amountOfSigners: threshold - 1});
            expect(await erc721ForTesting.balanceOf(targetRecipient)).to.equal(0);
            expect(await erc721ForTesting.balanceOf(thresholdMultiSigForwarder.address)).to.equal(1);
            expect(await erc721ForTesting.ownerOf(targetTokenId)).to.equal(thresholdMultiSigForwarder.address);
            expect(await erc721ForTesting.balanceOf(thresholdMultiSigForwarder.address)).to.equal(1);
            await expect(thresholdMultiSigForwarder.connect(owner)
                .forward(
                    erc721ForTesting.address,
                    0, 0,
                    calldata,
                    extensionData)).to.be.rejectedWith("not enough endorsers");
        });
    });
});
