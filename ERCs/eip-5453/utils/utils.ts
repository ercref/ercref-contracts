import { Contract, Wallet } from "ethers";
import { BytesLike } from "ethers/lib/utils";
import { ethers } from "hardhat";

export enum ERC5453EndorsementType {
    A = "A",
    B = "B",
};

export const computeEndorsement = async (
    erc5453: Contract,
    functionString:string,
    encodeArray: string[],
    parameters:BytesLike[],
    endorsers: Wallet[],
    type: ERC5453EndorsementType,
    {
        numOfBlocksBeforeDeadline = 20,
        validSince = 0,
        validBy = 0,
        currentNonce = 0,
    }): Promise<BytesLike> => {
    const functionParamPacked = ethers.utils.defaultAbiCoder.encode(encodeArray, parameters);

    const functionParamStructHash = await erc5453.computeFunctionParamHash(
        functionString,
        functionParamPacked
    );
    currentNonce = currentNonce || await (await erc5453.eip5453Nonce(erc5453.address)).toNumber();
    const latestBlock = await ethers.provider.getBlock("latest");
    validSince = validSince || latestBlock.number;
    validBy = validBy || latestBlock.number + numOfBlocksBeforeDeadline;
    const finalDigest = await erc5453.computeValidityDigest(
        functionParamStructHash,
        validSince,
        validBy,
        currentNonce);
    if (type == ERC5453EndorsementType.A) {
        const endorser = endorsers[0];
        const signature = endorser._signingKey().signDigest(finalDigest);
        const sigPacked = ethers.utils.joinSignature(signature);
        return await erc5453.computeExtensionDataTypeA(
            currentNonce,
            validSince,
            validBy,
            endorser.address,
            sigPacked);
    } else if (type == ERC5453EndorsementType.B) {
        const sigPackeds = [];

        for (let i = 0; i < endorsers.length; i++) {
            const signature = endorsers[i]._signingKey().signDigest(finalDigest);
            const sigPacked = ethers.utils.joinSignature(signature);
            sigPackeds.push(sigPacked);
        }

        return await erc5453.computeExtensionDataTypeB(
            currentNonce,
            validSince,
            validBy,
            endorsers.map(e=>e.address),
            sigPackeds);
    }
    throw new Error("Invalid type");
};
