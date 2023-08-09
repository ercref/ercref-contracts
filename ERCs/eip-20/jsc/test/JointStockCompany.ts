
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

    it("Should be able to support simple purchasing shares ", async function () {
      const {
        contract,
        owner
      } = await loadFixture(deployFixture);
      const SHARES_TO_BUY = 10;
      const pricePerShareFraction = ethers.BigNumber.from(await contract.pricePerShareFraction());
      console.log(`pricePerShareFraction: ${pricePerShareFraction}`);
      const numOfFractionPerShare = ethers.BigNumber.from(10).pow(await contract.decimals());
      console.log(`numOfFractionPerShare: ${numOfFractionPerShare}`);

      expect(pricePerShareFraction.mul(numOfFractionPerShare)).to.equal(ethers.utils.parseEther("0.1"));
      const purchasedAmountInShareFractions = numOfFractionPerShare.mul(SHARES_TO_BUY);
      const payment = pricePerShareFraction.mul(purchasedAmountInShareFractions); // 10 shares
      const tx = await contract.purchaseShares(purchasedAmountInShareFractions, {value: payment});
      expect(await contract.balanceOf(owner.address)).to.equal(purchasedAmountInShareFractions);
      expect(await contract.getShares(owner.address)).to.equal(purchasedAmountInShareFractions);
      expect(await contract.totalSupply()).to.equal(purchasedAmountInShareFractions);
      
      const rc = await tx.wait();
      const transferEvents = rc.events?.filter((x:any) => x.event == "Transfer");
      expect(transferEvents?.length).to.equal(1);
      expect(transferEvents?.[0].args?.[0]).to.equal(ethers.constants.AddressZero);
      expect(transferEvents?.[0].args?.[1]).to.equal(owner.address);
      expect(transferEvents?.[0].args?.[2]).to.equal(SHARES_TO_BUY);

      expect(await contract.withdrawableAmount(
        owner.address, ethers.constants.AddressZero)).to.equal(payment);
      
    });
  });

});