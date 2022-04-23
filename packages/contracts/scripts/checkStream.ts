import { Framework } from "@superfluid-finance/sdk-core";
import dotenv from "dotenv-flow";
import { ethers } from "hardhat";

dotenv.config();

let employee;
let buyer;

async function main() {
  const accounts = await ethers.getSigners();
  employee = accounts[18];
  // buyer = accounts[19];

  const sf = await Framework.create({
    networkName: "custom",
    provider: ethers.provider,
    dataMode: "WEB3_ONLY",
    resolverAddress: process.env.SF_RESOLVER as string,
    protocolReleaseVersion: "test",
  });

  const daix = await sf.loadSuperToken("fDAIx");

  const info = await sf.cfaV1.getFlow({
    superToken: daix.address,
    sender: process.env.SF_SELLARY as string,
    receiver: await employee.getAddress(),
    providerOrSigner: employee,
  });

  console.log("employee flow info", info);
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
