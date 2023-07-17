
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { deployByName, deployUpgradableByName } from "../utils/deployUtil";
import { loadFixture, mineUpTo} from "@nomicfoundation/hardhat-network-helpers";

describe("Contract", function () {
 // deployFixture 
  async function deployFixture() {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const { proxy, logic, proxyAdmin } = await deployUpgradableByName(
      ethers, 
      upgrades,
      "TestnetClub", 
      []
    );

    console.log(`Proxy: ${proxy.address}`);
    console.log(`Logic: ${logic}`);
    console.log(`ProxyAdmin: ${proxyAdmin.address}`);

    proxy.initialize();
  
    return {
      owner,
      addr1,
      addr2,
      contract: proxy
    };
  }

  describe("TestnetClub", function () {

    it("Should be deployable", async function () {
      const {
        contract,
        owner
       } = await loadFixture(deployFixture);
      expect(contract.address).to.match(/0x[0-9a-fA-F]{40}/);
    });

    it("Should be able to handle purchasing shares ", async function () {
      const {
        contract,
        owner
      } = await loadFixture(deployFixture);
      const price = contract.pricePerShare();
      const payment = ethers.utils.parseEther("0.5"); 
      const shares = payment.div(price);
      await contract.purchaseShares(shares, {value: payment});
    });
  });

});