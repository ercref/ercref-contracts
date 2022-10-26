import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { deployByName } from "../utils/deployUtil";

describe("Contract", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployFixture() {
    const version: string = "0x1234";
    const [owner, addr1, addr2] = await ethers.getSigners();
    const { contract, tx } = await deployByName(ethers, "CommitToMintImpl", [version]);

    return { contract, tx, owner, addr1, addr2 };
  }
  describe("EIP-165 Identifier", function () {
    it("Should match", async function () {
      const { contract } = await loadFixture(deployFixture);
      expect(await contract.get165()).to.equal("0x4ba43d48");
      expect(await contract.supportsInterface("0x4ba43d48")).to.be.true;
    });
  });
});
