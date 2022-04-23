import { Framework } from "@superfluid-finance/sdk-core";
import dotenv from "dotenv-flow";
import { ethers } from "hardhat";

dotenv.config();

let employer;
let employee;

async function main() {
  const accounts = await ethers.getSigners();
  employer = accounts[17];
  employee = accounts[18];

  const sf = await Framework.create({
    networkName: "custom",
    provider: ethers.provider,
    dataMode: "WEB3_ONLY",
    resolverAddress: process.env.SF_RESOLVER,
    protocolReleaseVersion: "test",
  });

  const daix = await sf.loadSuperToken("fDAIx");

  const info = await sf.cfaV1.getFlow({
    superToken: daix.address,
    sender: process.env.SF_SELLARY as string,
    receiver: await employee.getAddress(),
    providerOrSigner: employee,
  });

  const bal = await daix.balanceOf({
    account: await employee.getAddress(),
    providerOrSigner: ethers.provider,
  });

  console.log("employee fDAIx Balance", bal);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
