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
    const { contract, tx } = await deployByName(ethers, "CommitableERC721", [version]);

    return { contract, tx, owner, addr1, addr2 };
  }
  describe("EIP-165 Identifier", function () {
    it("Should match", async function () {
      const { contract } = await loadFixture(deployFixture);
      expect(await contract.get165Core()).to.equal("0xf14fcbc8");
      expect(await contract.supportsInterface("0xf14fcbc8")).to.be.true;
      expect(await contract.get165General()).to.equal("0x67b2ec2c");
      expect(await contract.supportsInterface("0x67b2ec2c")).to.be.true;
    });
  });

});
