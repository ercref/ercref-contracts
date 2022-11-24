import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers, web3 } from "hardhat";
import { deployByName } from "../utils/deployUtils";

const TEST_MESSAGE = web3.utils.sha3('ERC-Ref') as string;


function toEthSignedMessageHash(messageHex: string) {
  const messageBuffer = Buffer.from(messageHex.substring(2), 'hex');
  const prefix = Buffer.from(`\u0019Ethereum Signed Message:\n${messageBuffer.length}`);
  return web3.utils.sha3(Buffer.concat([prefix, messageBuffer]));
}

describe("Contract", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployFixture() {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const { contract, tx } = await deployByName(ethers, "ERC191Mock", [], false);

    return { contract, tx, owner, addr1, addr2 };
  }

  describe("Deployment", function () {
    it("Should complete without problem", async function () {
      await loadFixture(deployFixture);
    });
  });
  describe("Functionality", function () {
    it("Should recover the signature", async function () {
      const { owner, contract } = await deployFixture();
      const signature = await web3.eth.sign(TEST_MESSAGE, owner.address);
      expect(await contract.recover(toEthSignedMessageHash(TEST_MESSAGE), signature)).to.equal(owner.address);
    });
  });

});
