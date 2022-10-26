import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { deployByName } from "../utils/deployUtil";

describe("Contract", function () {
  const version: string = "0x1234";
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployFixture() {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const { contract, tx } = await deployByName(ethers, "CommitToMintImpl", [version]);

    return { contract, tx, owner, addr1, addr2 };
  }

  describe("Deployment", function () {
    it("Should complete without problem", async function () {
      await loadFixture(deployFixture);
    });

    it("Should set the right version", async function () {
      const { tx } = await loadFixture(deployFixture);
      const receipt = await tx.wait();
      let events = receipt.events.filter((x: any) => { return x.event == "ErcRefImplDeploy" });
      expect(events.length).to.equal(1);
      expect(events[0].args.version).to.equal(version);
    });
  });

  describe("CommitToMint", function () {
    it("Should allow minting if has valid commitment", async function () {
        const fakeTokenId = "0x1234";
        const { contract, addr1 } = await loadFixture(deployFixture);
        const salt = ethers.utils.randomBytes(32);
        const solidityCommitment = await contract.calculateCommitment(addr1.address, fakeTokenId, salt);
        const typescriptCommitment = ethers.utils.keccak256(ethers.utils.concat([addr1.address, ethers.utils.zeroPad(fakeTokenId, 32), salt]));
        expect(solidityCommitment).to.equal(typescriptCommitment);
        const commitment = solidityCommitment;
        await contract.commit(commitment, []);
        await contract.safeMint(addr1.address, fakeTokenId, salt);
        expect(await contract.ownerOf(fakeTokenId)).to.equal(addr1.address);
    });

    it("Should allow minting if has invalid commitment", async function () {
        const fakeTokenId = "0x1234";
        const { contract, addr1 } = await loadFixture(deployFixture);
        const invalidCommits = ethers.utils.randomBytes(32);
        const salt = ethers.utils.randomBytes(32);
        await contract.commit(invalidCommits, []);
        await expect(contract.safeMint(addr1.address, fakeTokenId, salt))
             .to.be.rejectedWith('Invalid commitment');
    });

    it("Should disallow minting if no commitment", async function () {
      const fakeTokenId = "0x1234";
      const { contract, addr1 } = await loadFixture(deployFixture);
      await expect(contract.safeMint(addr1.address, fakeTokenId, []))
      .to.be.rejectedWith('extraData');
    });

  });

});
