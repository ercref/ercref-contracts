import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { ethers } from "hardhat";

describe("EndorsibleERC721", function () {
    async function deployFixture() {
        // Contracts are deployed using the first signer/account by default
        const [owner, account1, account2, account3] = await ethers.getSigners();
        const EndorsableERC721 = await ethers.getContractFactory("EndorsableERC721");
        const endorsableERC721 = await EndorsableERC721.deploy();

        return { endorsableERC721, owner, account1, account2, account3 };
    }

    describe("Deployment", function () {
        it("Should be deployable", async function () {
            const { endorsableERC721, account1 } = await loadFixture(deployFixture);
            try {
                await endorsableERC721.mint(account1.address, 1, []);
            } catch (e) {
                console.log(e);
            }

        });
    });
});
