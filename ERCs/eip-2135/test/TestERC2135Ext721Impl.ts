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
    const { contract, tx } = await deployByName(ethers, "ERC2135Ext721Impl", [version]);

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

  describe("Consumption", function () {
    it("Should consume when minted", async function () {
      const fakeTokenId = "0x1234";
      const { contract, addr1 } = await loadFixture(deployFixture);
      await contract.safeMint(addr1.address, fakeTokenId);
      expect(await contract.balanceOf(addr1.address)).to.equal(1);
      expect(await contract.ownerOf(fakeTokenId)).to.equal(addr1.address);
      expect(await contract.isConsumableBy(addr1.address, fakeTokenId, 1)).to.be.true;
      const tx = await contract.consume(addr1.address, fakeTokenId, 1, []);
      const receipt = await tx.wait();
      const events = receipt.events.filter((x: any) => { return x.event == "OnConsumption" });
      expect(events.length).to.equal(1);
      expect(events[0].args.consumer).to.equal(addr1.address);
      expect(events[0].args.assetId).to.equal(fakeTokenId);
      expect(events[0].args.amount).to.equal(1);
      expect(await contract.balanceOf(addr1.address)).to.equal(0);
      await expect(contract.ownerOf(fakeTokenId))
        .to.be.rejectedWith('ERC721: invalid token ID');
      await expect(contract.isConsumableBy(addr1.address, fakeTokenId, 1))
        .to.be.rejectedWith('ERC721: invalid token ID');
    });
  });

  describe("EIP-165 Identifier", function () {
    it("Should match", async function () {
      const { contract } = await loadFixture(deployFixture);
      expect(await contract.get165()).to.equal("0xdd691946");
      expect(await contract.supportsInterface("0xdd691946")).to.be.true;
    });
  });
});
