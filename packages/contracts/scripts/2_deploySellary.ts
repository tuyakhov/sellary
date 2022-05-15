import { ethers, upgrades } from "hardhat";

async function main() {
  const SellaryRenderer = await ethers.getContractFactory("SellaryRenderer");
  const sellaryRenderer = await upgrades.deployProxy(SellaryRenderer, []);

  console.log("renderer: ", sellaryRenderer.address);

  const Sellary = await ethers.getContractFactory("Sellary");
  const sellary = await upgrades.deployProxy(Sellary, [
    process.env.SF_HOST as string,
    process.env.SF_CFA as string,
    process.env.SF_TOKEN_DAIX as string,
    sellaryRenderer.address,
    "Sellary",
  ]);

  await sellary.deployed();
  console.log("Sellary:", sellary.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
