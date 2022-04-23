import { Framework } from "@superfluid-finance/sdk-core";
import dotenv from "dotenv-flow";
import { ethers } from "hardhat";
import { abi as daiABI } from "../abis/fDAIABI.json";

dotenv.config();

let employer;

async function main() {
  const accounts = await ethers.getSigners();
  employer = accounts[17];

  const dai = new ethers.Contract(
    process.env.SF_TOKEN_DAI as string,
    daiABI,
    accounts[0]
  );

  await dai.mint(employer.address, ethers.utils.parseEther("1000"));

  const sf = await Framework.create({
    networkName: "custom",
    provider: ethers.provider,
    dataMode: "WEB3_ONLY",
    resolverAddress: process.env.SF_RESOLVER,
    protocolReleaseVersion: "test",
  });
  const daix = await sf.loadSuperToken("fDAIx");

  await dai
    .connect(employer)
    .approve(daix.address, ethers.utils.parseEther("1000"));

  const daixUpgradeOperation = daix.upgrade({
    amount: ethers.utils.parseEther("1000").toString(),
  });

  await daixUpgradeOperation.exec(employer);

  const daixBal = await daix.balanceOf({
    account: employer.address,
    providerOrSigner: employer,
  });
  console.log(`daix ${daix.address} bal for acct 17: `, daixBal);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
