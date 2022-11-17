import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("TheResolver", function () {
    async function deployOneYearLockFixture() {
        // Contracts are deployed using the first signer/account by default
        const [owner, otherAccount] = await ethers.getSigners();

        const TheResolver = await ethers.getContractFactory("TheResolver");
        const theResolver = await TheResolver.deploy();

        return { theResolver, owner, otherAccount };
    }

    describe("Deployment", function () {
        it("Should compute right namehash for EIP-191 examples", async function () {
            const { theResolver } = await loadFixture(deployOneYearLockFixture);
            expect(await theResolver.computeNamehash(""))
                .to.equal("0x0000000000000000000000000000000000000000000000000000000000000000");
            expect(await theResolver.computeNamehash("eth"))
                .to.equal("0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae");
            expect(await theResolver.computeNamehash("foo.eth"))
                .to.equal("0xde9b09fd7c5f901e23a3f19fecc54828e9c848539801e86591bd9801b019f84f");
        });

        it("Should compute right namehash xinbenlvethsf.eth", async function () {
            const { theResolver } = await loadFixture(deployOneYearLockFixture);
            expect(await theResolver.computeNamehash("xinbenlvethsf.eth"))
                .to.equal("0x95d84257fea04fd81e4f758f1027e8e23c4a80f0b4770cc410011b3663eb3f35");
            expect(await theResolver.computeNamehash("alice.xinbenlvethsf.eth"))
                .to.equal("0x39f210baec7a8b61048af5d1d560c394815c03622778254b17600be38d3a5f7a");
            expect(await theResolver.computeNamehash("bob.xinbenlvethsf.eth"))
                .to.equal("0xa275314f48a1386c1987a4f4348539fb8de8d85e02dc879662036e52ed7e6f76");
            expect(await theResolver.computeNamehash("charlie.xinbenlvethsf.eth"))
                .to.equal("0xeba6caacf1cf33c9d5b1fe10ec2add0aa95537bfe0140eb36adad37b75bc6255");
        });

        it("Should compute right namehash charlie.xinbenlvethsf.eth", async function () {
            const { theResolver } = await loadFixture(deployOneYearLockFixture);
            expect(await theResolver.computeNamehash("xinbenlvethsf.eth"))
                .to.equal("0x95d84257fea04fd81e4f758f1027e8e23c4a80f0b4770cc410011b3663eb3f35");
            expect(ethers.utils.keccak256(ethers.utils.toUtf8Bytes("charlie")))
                .to.equal("0x87a213ce1ee769e28decedefb98f6fe48890a74ba84957ebf877fb591e37e0de");
            expect(await theResolver.computeNamehash("charlie.xinbenlvethsf.eth"))
                .to.equal("0xeba6caacf1cf33c9d5b1fe10ec2add0aa95537bfe0140eb36adad37b75bc6255");
        });
    });
});
