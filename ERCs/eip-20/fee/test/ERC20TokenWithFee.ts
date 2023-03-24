
import { expect } from "chai";
import { ethers } from "hardhat";
import { deployByName } from "../utils/deployUtil";

describe("Contract", function () {

  describe("ERC20TokenWithFee", function () {
    it("Should match", async function () {
        const [owner, addr1, addr2] = await ethers.getSigners();
        const { contract } = await deployByName(
          ethers, 
          "ERC20TokenWithFee", 
          []
        );

        await contract.mint(addr1.address, 1000);
        expect(await contract.balanceOf(addr1.address)).to.equal(1000);
        let tx = await contract.transferFrom(addr1.address, addr2.address, 100);
        expect(await contract.balanceOf(addr1.address)).to.equal(900);
        expect(await contract.balanceOf(addr2.address)).to.equal(90);
        // ensure events are emited correctly 
        await expect(tx).to.emit(contract, 'Transfer').withArgs(addr1.address, owner.address, 10);
        await expect(tx).to.emit(contract, 'Transfer').withArgs(addr1.address, addr2.address, 90);
    });
  });

});