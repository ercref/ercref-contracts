# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.ts
```

## Developers

### Circuits

- [Install circom compiler](https://docs.circom.io/getting-started/installation/#installing-circom)
- [Download the ptau file to `contracts/circuits`](https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_13.ptau)

- Update the value you want to be the solution of the puzzle

```shell
cd contracts/circuits
cp hash_input.json.template hash_input.json
circom mimcsponge.circom --r1cs --wasm
npx snarkjs plonk setup mimcsponge.r1cs powersOfTau28_hez_final_13.ptau mimcsponge.zkey
npx snarkjs zkey export solidityverifier mimcsponge.zkey mimcsponge.sol
# test proving
node mimcsponge_js/generate_witness.js mimcsponge_js/mimcsponge.wasm hash_input.json mimcsponge.wtns
npx snarkjs plonk prove mimcsponge.zkey mimcsponge.wtns mimcsponge_proof.json mimcsponge_public.json
# generate calldata for the smartcontract
npx snarkjs zkey export soliditycalldata mimcsponge_public.json \
mimcsponge_proof.json | sed $$'s/,/\\\n/' > \
mimcsponge_calldata.dat
```
