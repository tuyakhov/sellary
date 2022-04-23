import { Wallet } from ".pnpm/@ethersproject+wallet@5.6.0/node_modules/@ethersproject/wallet";
import { ethers } from "hardhat";

async function main() {
  const provider = ethers.getDefaultProvider("kovan");
  const account = new Wallet(process.env.PRIVATE_KEY as string, provider);
  const SellaryFactory = await ethers.getContractFactory("Sellary", account);

  const sellary = await SellaryFactory.deploy(
    "0xF0d7d1D47109bA426B9D8A3Cde1941327af1eea3",
    "0xECa8056809e7e8db04A8fF6e4E82cD889a46FE2F",
    "0xe3cb950cb164a31c66e32c320a800d477019dcff"
  );

  await sellary.deployed();

  console.log("Sellary:", sellary.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
