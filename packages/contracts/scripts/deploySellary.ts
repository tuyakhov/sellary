import { ethers, upgrades } from "hardhat";

// Rinkeby
const SF_HOST = "0xeD5B5b32110c3Ded02a07c8b8e97513FAfb883B6";
const SF_CFA = "0xF4C5310E51F6079F601a5fb7120bC72a70b96e2A";
const SF_TOKEN_DAIX = "0x745861AeD1EEe363b4AaA5F1994Be40b1e05Ff90";

async function main() {
  const Sellary = await ethers.getContractFactory("Sellary");
  const sellary = await upgrades.deployProxy(Sellary, [
    SF_HOST,
    SF_CFA,
    SF_TOKEN_DAIX,
    "Sellary D_D",
  ]);
  await sellary.deployed();

  console.log("Sellary on Rinkeby:", sellary.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

/*
npx hardhat verify --network rinkeby 0x34F395227848222a254030154e1133ecddA84B0b "0xeD5B5b32110c3Ded02a07c8b8e97513FAfb883B6" "0xF4C5310E51F6079F601a5fb7120bC72a70b96e2A" "0x745861AeD1EEe363b4AaA5F1994Be40b1e05Ff90" "Sellary D_D"

 */
