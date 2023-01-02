import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { computeEndorsement, ERC5453EndorsementType } from "../utils/utils";

const ZERO = ethers.utils.arrayify(ethers.utils.hexZeroPad("0x0", 32));

describe("ThresholdMultiSigForwarder", function () {
    async function deployFixture() {
        // Contracts are deployed using the first signer/account by default
        const [owner, mintSender, recipient] = await ethers.getSigners();
        const testWallets = [...Array(10)].map(i=> ethers.Wallet.createRandom());

        const ThresholdMultiSigForwarder = await ethers.getContractFactory("ThresholdMultiSigForwarder");
        const thresholdMultiSigForwarder = await ThresholdMultiSigForwarder.deploy();
        await thresholdMultiSigForwarder.deployed();

        const ERC721ForTesting = await ethers.getContractFactory("ERC721ForTesting");
        const erc721ForTesting = await ERC721ForTesting.deploy();
        await erc721ForTesting.deployed();

        return { thresholdMultiSigForwarder, erc721ForTesting, owner, mintSender, recipient, testWallets };
    }

    describe("Deployment", function () {
        it("Should be deployable", async function () {
            await loadFixture(deployFixture);
        });

        it("Should be able to initialize owners", async function () {
            const { thresholdMultiSigForwarder, owner, testWallets } = await loadFixture(deployFixture);
            await thresholdMultiSigForwarder.connect(owner).initialize(testWallets.map(w=>w.address), 5);
            for (let i = 0; i < testWallets.length; i++) {
                expect(await thresholdMultiSigForwarder.isEligibleEndorser(testWallets[i].address)).to.equal(true);
            }
        });

        it("Should be able to set eligible endorsers", async function () {
            const { thresholdMultiSigForwarder, owner, testWallets } = await loadFixture(deployFixture);
            await thresholdMultiSigForwarder.connect(owner).initialize(testWallets.map(w=>w.address), 5);
            for (let i = 0; i < testWallets.length; i++) {
                expect(await thresholdMultiSigForwarder.isEligibleEndorser(testWallets[i].address)).to.equal(true);
            }
        });

        it("Should successfully forward a transferForm call to ERC721orTesting with sufficient endorsements", async function () {
            const { thresholdMultiSigForwarder, erc721ForTesting, owner, testWallets } = await loadFixture(deployFixture);
            const targetTokenId = 0x1;
            await erc721ForTesting.connect(owner).mint(thresholdMultiSigForwarder.address, targetTokenId);
            expect(await erc721ForTesting.ownerOf(targetTokenId)).to.equal(thresholdMultiSigForwarder.address);
            expect(await erc721ForTesting.balanceOf(thresholdMultiSigForwarder.address)).to.equal(1);

            const numOfEligibleEndorsers = 5;
            const threshold = 3;
            await thresholdMultiSigForwarder.connect(owner).initialize(testWallets.map(w=>w.address).slice(0, numOfEligibleEndorsers), threshold);
            for (let i = 0; i < numOfEligibleEndorsers; i++) {
                expect(await thresholdMultiSigForwarder.isEligibleEndorser(testWallets[i].address)).to.equal(true);
            }
            const targetRecipient = ethers.utils.computeAddress(ethers.utils.hexlify(ethers.utils.randomBytes(32)));
            const calldata = erc721ForTesting.interface.encodeFunctionData("safeTransferFrom(address,address,uint256)", [thresholdMultiSigForwarder.address, targetRecipient, 1]);
            const endorsement = await computeEndorsement(
                thresholdMultiSigForwarder,
                "function forward(address _dest,uint256 _value,uint256 _gasLimit,bytes calldata _calldata)",
                ["address", "uint256", "uint256", "bytes32"],
                [erc721ForTesting.address, ZERO, ZERO, ethers.utils.keccak256(calldata)],
                testWallets.slice(0, threshold), ERC5453EndorsementType.B, { }
            );

            expect(await erc721ForTesting.balanceOf(targetRecipient)).to.equal(0);
            expect(await erc721ForTesting.balanceOf(thresholdMultiSigForwarder.address)).to.equal(1);
            expect(await erc721ForTesting.ownerOf(targetTokenId)).to.equal(thresholdMultiSigForwarder.address);
            expect(await erc721ForTesting.balanceOf(thresholdMultiSigForwarder.address)).to.equal(1);
            let txForward = await thresholdMultiSigForwarder.connect(owner)
                .forward(
                    erc721ForTesting.address,
                    ZERO, ZERO,
                    calldata,
                    endorsement);
            let txForwardWaited = await txForward.wait();
            expect(await erc721ForTesting.balanceOf(targetRecipient)).to.equal(1);
        });

        it("Should reject forwarding a transferForm call to ERC721orTesting with insufficient endorsements", async function () {
            const { thresholdMultiSigForwarder, erc721ForTesting, owner, testWallets } = await loadFixture(deployFixture);
            const targetTokenId = 0x1;
            await erc721ForTesting.connect(owner).mint(thresholdMultiSigForwarder.address, targetTokenId);
            expect(await erc721ForTesting.ownerOf(targetTokenId)).to.equal(thresholdMultiSigForwarder.address);
            expect(await erc721ForTesting.balanceOf(thresholdMultiSigForwarder.address)).to.equal(1);

            const numOfEligibleEndorsers = 5;
            const threshold = 3;
            await thresholdMultiSigForwarder.connect(owner).initialize(testWallets.map(w=>w.address).slice(0, numOfEligibleEndorsers), threshold);
            for (let i = 0; i < numOfEligibleEndorsers; i++) {
                expect(await thresholdMultiSigForwarder.isEligibleEndorser(testWallets[i].address)).to.equal(true);
            }
            const targetRecipient = ethers.utils.computeAddress(ethers.utils.hexlify(ethers.utils.randomBytes(32)));
            const calldata = erc721ForTesting.interface.encodeFunctionData("safeTransferFrom(address,address,uint256)", [thresholdMultiSigForwarder.address, targetRecipient, 1]);
            const endorsement = await computeEndorsement(
                thresholdMultiSigForwarder,
                "function forward(address _dest,uint256 _value,uint256 _gasLimit,bytes calldata _calldata)",
                ["address", "uint256", "uint256", "bytes32"],
                [erc721ForTesting.address, ZERO, ZERO, ethers.utils.keccak256(calldata)],
                testWallets.slice(0, threshold - 1), ERC5453EndorsementType.B, { }
            );
            expect(await erc721ForTesting.balanceOf(targetRecipient)).to.equal(0);
            expect(await erc721ForTesting.balanceOf(thresholdMultiSigForwarder.address)).to.equal(1);
            expect(await erc721ForTesting.ownerOf(targetTokenId)).to.equal(thresholdMultiSigForwarder.address);
            expect(await erc721ForTesting.balanceOf(thresholdMultiSigForwarder.address)).to.equal(1);
            await expect(thresholdMultiSigForwarder.connect(owner)
                .forward(
                    erc721ForTesting.address,
                    0, 0,
                    calldata,
                    endorsement)).to.be.rejectedWith("not enough endorsers");
        });
    });
});
