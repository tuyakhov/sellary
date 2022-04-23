import { ethers } from "hardhat";

async function main() {
  const accounts = await ethers.getSigners();
  const SellaryFactory = await ethers.getContractFactory(
    "Sellary",
    accounts[0]
  );

  const sellary = await SellaryFactory.deploy(
    process.env.SF_HOST as string,
    process.env.SF_CFA as string,
    process.env.SF_TOKEN_DAIX as string
  );

  await sellary.deployed();

  console.log("Sellary:", sellary.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
