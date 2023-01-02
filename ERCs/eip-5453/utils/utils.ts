import { Contract, Wallet } from "ethers";
import { BytesLike } from "ethers/lib/utils";
import { ethers } from "hardhat";

export const computeEndorsement = async (
    erc5453: Contract,
    functionString:string,
    encodeArray: string[], // ["address", "uint256"]
    parameters:BytesLike[],
    testWallet: Wallet,
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
    const finalDigest = await erc5453.computeValidityDigest(
        functionParamStructHash,
        latestBlock.number,
        latestBlock.number +
        numOfBlocksBeforeDeadline,
        currentNonce);
    validSince = validSince || latestBlock.number;
    validBy = validBy || latestBlock.number + numOfBlocksBeforeDeadline;
    console.log(`XXX validSince: ${validSince}, validBy: ${validBy}, currentNonce: ${currentNonce}`);

    const signature = testWallet._signingKey().signDigest(finalDigest);
    const sigPacked = ethers.utils.joinSignature(signature);
    const generalExtensionDataStruct = await erc5453.computeExtensionDataTypeA(
        currentNonce,
        validSince,
        validBy,
        testWallet.address,
        sigPacked);
    return generalExtensionDataStruct;
};
