import { ethers, upgrades } from "hardhat";

async function main() {
  const SellaryRenderer = await ethers.getContractFactory("SellaryRendererV2");
  const newImpl = await upgrades.prepareUpgrade(
    "0xefD06DA5Dd9baB4C6b59c11A16711eB9CD4d8995",
    SellaryRenderer,
    {}
  );

  console.log("new renderer impl: ", newImpl);

  // const Sellary = await ethers.getContractFactory("Sellary");
  // const sellary = await upgrades.upgradeProxy(
  //   "0x98932D5ABe623082EDbeac9C15e4c70faC740cfc",
  //   Sellary,
  //   {}
  // );
  // console.log("sellary upgraded: ", sellary.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

/*
npx hardhat verify --network rinkeby 0x34F395227848222a254030154e1133ecddA84B0b "0xeD5B5b32110c3Ded02a07c8b8e97513FAfb883B6" "0xF4C5310E51F6079F601a5fb7120bC72a70b96e2A" "0x745861AeD1EEe363b4AaA5F1994Be40b1e05Ff90" "Sellary D_D"

 */
